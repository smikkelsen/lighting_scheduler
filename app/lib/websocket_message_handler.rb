module WebsocketMessageHandler

  def self.msg(msg)
    Rails.logger.debug('=' * 80)
    msg = msg.to_json if msg.is_a?(Hash)
    response = nil

    EM.run do
      ws = Faye::WebSocket::Client.new("ws://#{ENV['WEBSOCKET_CONTROLLER_IP']}:9000/ws")

      ws.on(:open) do |_event|
        Rails.logger.debug "Connected"
        Rails.logger.debug("sending msg: ***#{msg}***")
        ws.send(msg)
      end

      ws.on(:close) { |_event| Rails.logger.debug "Disconnected" }

      ws.on(:message) do |resp|
        Rails.logger.debug "Received message: #{resp.data}"
        response = JSON.parse(resp.data)
        ws.close
        EM.stop
      end

    end
    Rails.logger.debug('=' * 80)
    response
  end
end