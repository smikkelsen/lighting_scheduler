module WebsocketMessageHandler

  def self.msg(msg)
    Rails.logger.debug('=' * 80)
    msg = msg.to_json if msg.is_a?(Hash)
    response = nil
    timed_out = false

    EM.run do
      ws = Faye::WebSocket::Client.new("ws://#{ENV['WEBSOCKET_CONTROLLER_IP']}:9000/ws")

      # Timeout after 5 seconds
      timeout_timer = EM.add_timer(5) do
        Rails.logger.error "WebSocket timeout - controller did not respond within 5 seconds"
        timed_out = true
        ws.close
        EM.stop
      end

      ws.on(:open) do |_event|
        Rails.logger.debug "Connected"
        Rails.logger.debug("sending msg: ***#{msg}***")
        ws.send(msg)
      end

      ws.on(:close) { |_event| Rails.logger.debug "Disconnected" }

      ws.on(:message) do |resp|
        Rails.logger.debug "Received message: #{resp.data}"
        response = JSON.parse(resp.data)
        EM.cancel_timer(timeout_timer)
        ws.close
        EM.stop
      end

      ws.on(:error) do |error|
        Rails.logger.error "WebSocket error: #{error.message}"
        EM.cancel_timer(timeout_timer)
        ws.close
        EM.stop
      end

    end
    Rails.logger.debug('=' * 80)

    if timed_out
      Rails.logger.error "Returning nil due to timeout"
      return nil
    end

    response
  end
end