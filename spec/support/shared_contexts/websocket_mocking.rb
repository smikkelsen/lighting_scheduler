RSpec.shared_context 'mocked websocket' do
  before do
    allow(WebsocketMessageHandler).to receive(:msg) do |message|
      case message[:cmd]
      when 'toCtlrGet'
        if message[:get] == [['zones']]
          ControllerResponses.zones_response(ControllerResponses.simple_zone)
        elsif message[:get]&.first&.first == 'patternFileList'
          ControllerResponses.pattern_list_response
        elsif message[:get]&.first&.first == 'patternFileData'
          ControllerResponses.pattern_data_response
        end
      when 'toCtlrSet'
        if message[:zones]
          ControllerResponses.zones_response(message[:zones])
        elsif message[:runPattern]
          ControllerResponses.pattern_activation_response(message[:runPattern][:state])
        end
      end
    end
  end
end

RSpec.shared_context 'mocked websocket complex zones' do
  before do
    allow(WebsocketMessageHandler).to receive(:msg) do |message|
      case message[:cmd]
      when 'toCtlrGet'
        if message[:get] == [['zones']]
          ControllerResponses.zones_response(ControllerResponses.complex_zones)
        elsif message[:get]&.first&.first == 'patternFileList'
          ControllerResponses.pattern_list_response
        end
      when 'toCtlrSet'
        if message[:zones]
          ControllerResponses.zones_response(message[:zones])
        elsif message[:runPattern]
          ControllerResponses.pattern_activation_response(message[:runPattern][:state])
        end
      end
    end
  end
end

RSpec.shared_context 'mocked websocket with timeout' do
  before do
    # Simulate controller timeout
    allow(WebsocketMessageHandler).to receive(:msg).and_return(nil)
  end
end

RSpec.shared_context 'mocked zone sync' do
  before do
    # Mock Zone.update_cached to avoid actual database operations during tests
    allow(Zone).to receive(:update_cached) do
      # Optionally update current zones in test database
      # This can be overridden in individual tests
    end
  end
end
