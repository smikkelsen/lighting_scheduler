class ZoneBuilder
  def initialize(attributes)
    @ports = []
    @controller_name = Zone.current.first&.port_map.first['ctlrName']
    raise "Please add a zone and update cached prior to using the zone builder!" if @controller_name.blank?
    @zone = Zone.new(attributes)
  end

  def save!
    @zone.pixel_count = rgb_count
    @zone.port_map = @ports
    @zone.save!
  end

  # The start and end params should not be zero indexed. They will be converted automatically
  def add(port_number, start_light, end_light, reverse = false)
    sl = (reverse ? end_light : start_light) - 1
    el = (reverse ? start_light : end_light) - 1
    @ports << { "ctlrName" => @controller_name, "phyEndIdx" => el, "phyPort" => port_number, "phyStartIdx" => sl, "zoneRGBStartIdx" => rgb_count }
  end

  # private
  def rgb_count
    @ports.map do |port|
      (port["phyEndIdx"] - port["phyStartIdx"]).abs  + 1
    end.sum
  end
end