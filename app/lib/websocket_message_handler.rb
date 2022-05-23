module WebsocketMessageHandler

  def self.msg(msg)
    msg = msg.to_json if msg.is_a?(Hash)
    EM.run do
      ws = Faye::WebSocket::Client.new("ws://#{ENV['WEBSOCKET_CONTROLLER_IP']}:9000/ws")

      ws.on(:open) do |_event|
        Rails.logger.debug "Connected"
        Rails.logger.debug("sending msg: #{msg}")
        ws.send(msg)
      end

      ws.on(:close) { |_event| Rails.logger.debug "Disconnected" }

      ws.on(:message) do |resp|
        Rails.logger.debug "Received message: #{resp.data}"
        ws.close
        return JSON.parse(resp.data)
      end

    end
  end
end