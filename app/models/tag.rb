class Tag < ApplicationRecord
  has_many :display_tags, dependent: :destroy
  has_many :displays, through: :display_tags
  has_many :pattern_tags, dependent: :destroy
  has_many :patterns, through: :pattern_tags

  validates_presence_of :name

  def activate_random
    self.displays.concat(self.patterns).shuffle.first.activate
  end

  def activate_random_display
    display = self.displays.shuffle&.first
    display&.activate
    display
  end

  def activate_random_pattern
    Display.turn_off(:all)
    sleep(0.6)
    ZoneSet.default.first&.activate
    sleep(0.6)
    self.patterns.shuffle&.first&.activate(:all)
  end

end
