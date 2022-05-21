class DisplayPattern < ApplicationRecord
  belongs_to :display
  belongs_to :pattern
  has_many :display_pattern_zones
  has_many :zones, through: :display_pattern_zones
end
