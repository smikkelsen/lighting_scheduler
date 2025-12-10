class Tag < ApplicationRecord
  has_many :display_tags, dependent: :destroy
  has_many :displays, through: :display_tags
  has_many :pattern_tags, dependent: :destroy
  has_many :patterns, through: :pattern_tags

  def self.ransackable_associations(auth_object = nil)
    ["display_tags", "displays", "pattern_tags", "patterns"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["name", "created_at", "updated_at"]
  end

  validates_presence_of :name

  def activate_random
    selected_displays = self.displays.shuffle
    selected_patterns = self.patterns.shuffle
    Rails.logger.debug("#{selected_displays.count} displays and #{selected_patterns.count} patterns selected for tag #{self.name}")
    resource = selected_displays.to_a.concat(selected_patterns.to_a).shuffle.first
    if resource.is_a?(Pattern)
      Rails.logger.debug("Pattern selected: #{resource.name}")
      activate_pattern(resource)
    elsif resource.is_a?(Display)
      Rails.logger.debug("Display selected: #{resource.name}")
      resource.activate
    else
      Rails.logger.debug("No resource found")
    end
    resource
  end

  def activate_random_display
    display = self.displays.shuffle&.first
    display&.activate
    display
  end

  def activate_random_pattern
    pattern = self.patterns.shuffle&.first
    activate_pattern(pattern)
    pattern
  end

  private
  def activate_pattern(pattern)
    Display.turn_off(:all)
    sleep(0.6)
    default_zs = ZoneSet.default
    return unless default_zs
    default_zs.activate
    sleep(0.6)
    pattern&.activate(:all)
  end

end
