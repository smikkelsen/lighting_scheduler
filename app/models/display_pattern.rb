class DisplayPattern < ApplicationRecord
  belongs_to :display
  belongs_to :pattern

  # Note: serialize :zones removed - JSONB columns handle serialization automatically in Rails 7
end
