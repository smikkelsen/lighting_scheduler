class Display < ApplicationRecord
  include ZoneHelper
  has_many :display_patterns
  accepts_nested_attributes_for :display_patterns

  def self.turn_off(p_zones=:all)
    if p_zones == :all
      p_zones = zones.keys rescue nil
    else
      p_zones = Array.wrap(p_zones)
    end
    pattern = { file: "", state: 0, data: "", id: "" }
    pattern[:zoneName] = p_zones if p_zones
    run_cmd({ cmd: 'toCtlrSet', "runPattern": pattern })
  end

  def activate
    display_patterns.each do |dp|
      dp.pattern.activate(dp.zones)
    end
  end
end
