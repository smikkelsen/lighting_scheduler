class Zone < ApplicationRecord
  include ZoneHelper

  def self.update_cached
    zones = WebsocketMessageHandler.msg({ cmd: 'toCtlrGet', get: [['zones']] })["zones"]
    updated = []
    zones.each do |name, data|
      z = Zone.where(name: name).first_or_initialize
      z.pixel_count = data['numPixels']
      z.save
      updated << z.id
    end
    Zone.where.not(id: updated).destroy_all
  end

  def turn_off(zones=nil)
    zones ||= self
    super(zones)
  end

end
