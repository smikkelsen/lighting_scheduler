class DisplayPattern < ApplicationRecord
  belongs_to :display
  belongs_to :pattern

  serialize :zones
end
