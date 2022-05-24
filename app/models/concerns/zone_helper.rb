module ZoneHelper
  extend ActiveSupport::Concern

  def parameterize_zones(zones)
    if zones == :all
      zones = Zone.all.pluck(:name)
    else
      zones = Array.wrap(zones)
    end
    zones = zones.map do |z|
      if z.is_a? Integer
        Zone.current.find_by_id(z)&.name
      elsif z.is_a? Zone
        Zone.current.find_by_id(z.id)&.name
      elsif z.is_a? String
        if z.size == 36 && z.split('-').size == 5
          Zone.current.find_by_uuid(z)&.name
        else
          Zone.current.find_by_name(z)&.name
        end
      end
    end
    puts zones
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
    Digest::UUID.uuid_from_hash(Digest::SHA1, "ZoneHash", data.to_json)
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
