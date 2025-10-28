class DisplayPattern < ApplicationRecord
  belongs_to :display
  belongs_to :pattern

  def self.ransackable_associations(auth_object = nil)
    ["display", "pattern"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["zones", "display_id", "pattern_id", "created_at", "updated_at"]
  end

  # Note: serialize :zones removed - JSONB columns handle serialization automatically in Rails 7
end
