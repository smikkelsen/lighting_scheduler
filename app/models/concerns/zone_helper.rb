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
        Zone.find_by_id(z)&.name
      elsif z.is_a? Zone
        z.name
      elsif z.is_a? String
        z
      end
    end
    zones = zones - Array.wrap(nil)
    return zones
  end

  def turn_off(zones = :all)
    pattern = { zoneName: parameterize_zones(zones), state: 0, file: "", data: "", id: "" }
    WebsocketMessageHandler.msg({ cmd: 'toCtlrSet', "runPattern": pattern })
  end

  class_methods do
    def turn_off(zones = :all)
      self.new.turn_off(zones)
    end
  end
end
