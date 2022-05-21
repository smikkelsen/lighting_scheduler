require 'iodine'

class WebsocketMessageHandler
  attr_reader :response

  def self.msg(msg)
    msg = msg.to_json.to_s if msg.is_a?(Hash)
    handler = WebsocketMessageHandler.new(msg)
    Iodine.threads = 1
    Iodine.connect url: "ws://#{ENV['WEBSOCKET_CONTROLLER_IP']}:9000/ws", handler: handler
    Iodine.start
    handler.response
  end

  def initialize(cmd = nil)
    @messages = []
    add_message(cmd)
  end

  def add_message(msg)
    @messages << msg
  end

  def on_open(connection)
    send_one_message(connection)
  end

  def on_message(connection, message)
    @response = JSON.parse(message)
    send_one_message(connection)
  end

  def on_close(connection)
    # in this example, we stop iodine once the client is closed
    Rails.logger.debug "* Client closed."
    Iodine.stop
  end

  # We use this method to pop messages from the queue and send them
  #
  # When the queue is empty, we disconnect the client.
  def send_one_message(connection)
    msg = @messages.shift
    Rails.logger.debug msg
    if (msg)
      connection.write msg
    else
      connection.close
    end
  end

  def close(connection)
    connection.close
  end
end

