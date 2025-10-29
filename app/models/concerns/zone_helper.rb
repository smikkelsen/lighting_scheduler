module ZoneHelper
  extend ActiveSupport::Concern

  def parameterize_zones(zones)
    if zones == :all
      zones = Zone.current.pluck(:name)
    elsif zones == :default
      zones = ZoneSet.default&.zones&.pluck(:name)
    else
      zones = Array.wrap(zones)
    end
    zones = zones.map do |z|
      zone = if z.is_a? Integer
               Zone.find_by_id(z)
             elsif z.is_a? Zone
               Zone.find_by_id(z.id)
             elsif z.is_a? String
               if z.size == 36 && z.split('-').size == 5
                 Zone.find_by_uuid(z)
               elsif z.to_i != 0
                 Zone.find_by_id(z.to_i)
               else
                 Zone.find_by_name(z)
               end
             end
      zone&.name
    end
    Rails.logger.debug(zones.to_s)
    return zones - [nil]
  end

  def turn_off(zones = :all)
    pattern = { zoneName: parameterize_zones(zones), state: 0, file: "", data: "", id: "" }
    WebsocketMessageHandler.msg({ cmd: 'toCtlrSet', "runPattern": pattern })
  end

  def uuid_from_attributes
    data = {
      pixel_count: self.pixel_count,
      port_map: self.port_map
    }
    Digest::UUID.uuid_from_hash(Digest::SHA1, "8b958e0b-5baf-45d0-b5a2-6d7d8c6c3b4e", data.to_json)
  end

  class_methods do
    def turn_off(zones = :all)
      self.new.turn_off(zones)
    end

    def uuid_from_json(zone)
      Zone.new(pixel_count: zone['numPixels'], port_map: zone['portMap']).uuid_from_attributes
    end
  end
end
