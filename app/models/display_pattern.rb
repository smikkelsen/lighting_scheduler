class DisplayPattern < ApplicationRecord
  belongs_to :display
  belongs_to :pattern

  # Ensure zones is always an array, never a YAML string
  before_save :ensure_zones_is_array

  def self.ransackable_associations(auth_object = nil)
    ["display", "pattern"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["zones", "display_id", "pattern_id", "created_at", "updated_at"]
  end

  # Note: serialize :zones removed - JSONB columns handle serialization automatically in Rails 7

  private

  def ensure_zones_is_array
    if zones.is_a?(String) && zones.start_with?('---')
      # Convert YAML string to array
      self.zones = YAML.load(zones)
    elsif !zones.is_a?(Array)
      self.zones = Array.wrap(zones)
    end

    # Remove blank entries (empty strings, whitespace-only strings, nil)
    self.zones = zones.reject(&:blank?) if zones.is_a?(Array)
  end
end
