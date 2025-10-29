require 'rails_helper'

RSpec.describe WebsocketMessageHandler do
  let(:test_message) { { cmd: 'toCtlrGet', get: [['zones']] } }
  let(:response_data) { { "cmd" => "fromCtlr", "zones" => { "Zone 1" => { "numPixels" => 100 } } } }
  let(:mock_ws) { instance_double(Faye::WebSocket::Client) }

  before do
    # Mock environment variable
    allow(ENV).to receive(:[]).with('WEBSOCKET_CONTROLLER_IP').and_return('192.168.1.100')
    allow(ENV).to receive(:[]).and_call_original
  end

  describe '.msg' do
    context 'with successful WebSocket connection' do
      before do
        # Mock EventMachine
        allow(EM).to receive(:run) do |&block|
          block.call
        end

        # Mock WebSocket client
        allow(Faye::WebSocket::Client).to receive(:new).and_return(mock_ws)

        # Setup mock WebSocket event handlers
        @on_open_callback = nil
        @on_message_callback = nil
        @on_close_callback = nil

        allow(mock_ws).to receive(:on) do |event, &callback|
          case event
          when :open
            @on_open_callback = callback
          when :message
            @on_message_callback = callback
          when :close
            @on_close_callback = callback
          end
        end

        allow(mock_ws).to receive(:send)
        allow(mock_ws).to receive(:close)
        allow(EM).to receive(:stop)
      end

      it 'creates WebSocket connection to correct URL' do
        expect(Faye::WebSocket::Client).to receive(:new).with('ws://192.168.1.100:9000/ws').and_return(mock_ws)

        # Trigger connection but don't call callbacks
        allow(EM).to receive(:run)
        WebsocketMessageHandler.msg(test_message)
      end

      it 'converts hash message to JSON before sending' do
        expect(mock_ws).to receive(:send).with('{"cmd":"toCtlrGet","get":[["zones"]]}')

        # Simulate the full flow
        allow(EM).to receive(:run) do |&block|
          block.call
          @on_open_callback.call(nil) if @on_open_callback
        end

        WebsocketMessageHandler.msg(test_message)
      end

      it 'sends string message as-is' do
        json_string = '{"cmd":"test"}'
        expect(mock_ws).to receive(:send).with(json_string)

        allow(EM).to receive(:run) do |&block|
          block.call
          @on_open_callback.call(nil) if @on_open_callback
        end

        WebsocketMessageHandler.msg(json_string)
      end

      it 'parses and returns JSON response' do
        allow(EM).to receive(:run) do |&block|
          block.call
          @on_open_callback.call(nil) if @on_open_callback

          # Simulate receiving a message
          mock_event = double('event', data: response_data.to_json)
          @on_message_callback.call(mock_event) if @on_message_callback
        end

        result = WebsocketMessageHandler.msg(test_message)

        expect(result).to eq(response_data)
      end

      it 'stops EventMachine after receiving message' do
        allow(EM).to receive(:run) do |&block|
          block.call
          @on_open_callback.call(nil) if @on_open_callback

          mock_event = double('event', data: response_data.to_json)
          @on_message_callback.call(mock_event) if @on_message_callback
        end

        expect(EM).to receive(:stop)

        WebsocketMessageHandler.msg(test_message)
      end

      it 'closes WebSocket connection after receiving message' do
        allow(EM).to receive(:run) do |&block|
          block.call
          @on_open_callback.call(nil) if @on_open_callback

          mock_event = double('event', data: response_data.to_json)
          @on_message_callback.call(mock_event) if @on_message_callback
        end

        expect(mock_ws).to receive(:close)

        WebsocketMessageHandler.msg(test_message)
      end
    end

    context 'with complex nested JSON response' do
      let(:complex_response) do
        {
          "cmd" => "fromCtlr",
          "patternFileList" => [
            { "name" => "Pattern 1", "folders" => "Halloween", "readOnly" => true },
            { "name" => "Pattern 2", "folders" => "Christmas", "readOnly" => false }
          ]
        }
      end

      before do
        allow(EM).to receive(:run) do |&block|
          block.call
        end

        allow(Faye::WebSocket::Client).to receive(:new).and_return(mock_ws)
        allow(mock_ws).to receive(:on)
        allow(mock_ws).to receive(:send)
        allow(mock_ws).to receive(:close)
        allow(EM).to receive(:stop)
      end

      it 'correctly parses complex nested JSON structures' do
        allow(EM).to receive(:run) do |&block|
          block.call

          # Setup and trigger callbacks
          on_message_callback = nil
          allow(mock_ws).to receive(:on) do |event, &callback|
            on_message_callback = callback if event == :message
          end

          mock_event = double('event', data: complex_response.to_json)
          on_message_callback.call(mock_event) if on_message_callback
        end

        result = WebsocketMessageHandler.msg(test_message)

        expect(result['patternFileList']).to be_an(Array)
        expect(result['patternFileList'].length).to eq(2)
        expect(result['patternFileList'].first['name']).to eq('Pattern 1')
      end
    end

    context 'logging' do
      before do
        allow(EM).to receive(:run)
        allow(Faye::WebSocket::Client).to receive(:new).and_return(mock_ws)
        allow(mock_ws).to receive(:on)
        allow(mock_ws).to receive(:send)
        allow(Rails.logger).to receive(:debug)
      end

      it 'logs debug separator lines' do
        expect(Rails.logger).to receive(:debug).with('=' * 80).at_least(:once)

        WebsocketMessageHandler.msg(test_message)
      end

      it 'logs the outgoing message' do
        expect(Rails.logger).to receive(:debug).with(/sending msg:/)

        allow(EM).to receive(:run) do |&block|
          block.call
          on_open_callback = nil
          allow(mock_ws).to receive(:on) do |event, &callback|
            on_open_callback = callback if event == :open
          end
          on_open_callback.call(nil) if on_open_callback
        end

        WebsocketMessageHandler.msg(test_message)
      end

      it 'logs received messages' do
        expect(Rails.logger).to receive(:debug).with(/Received message:/)

        allow(EM).to receive(:run) do |&block|
          block.call
          on_message_callback = nil
          allow(mock_ws).to receive(:on) do |event, &callback|
            on_message_callback = callback if event == :message
          end

          mock_event = double('event', data: response_data.to_json)
          on_message_callback.call(mock_event) if on_message_callback
        end

        WebsocketMessageHandler.msg(test_message)
      end

      it 'logs connection status' do
        expect(Rails.logger).to receive(:debug).with('Connected')

        allow(EM).to receive(:run) do |&block|
          block.call
          on_open_callback = nil
          allow(mock_ws).to receive(:on) do |event, &callback|
            on_open_callback = callback if event == :open
          end
          on_open_callback.call(nil) if on_open_callback
        end

        WebsocketMessageHandler.msg(test_message)
      end

      it 'logs disconnection status' do
        expect(Rails.logger).to receive(:debug).with('Disconnected')

        allow(EM).to receive(:run) do |&block|
          block.call
          on_close_callback = nil
          allow(mock_ws).to receive(:on) do |event, &callback|
            on_close_callback = callback if event == :close
          end
          on_close_callback.call(nil) if on_close_callback
        end

        WebsocketMessageHandler.msg(test_message)
      end
    end
  end
end