class PatternTag < ApplicationRecord
  belongs_to :pattern
  belongs_to :tag

  def self.ransackable_associations(auth_object = nil)
    ["pattern", "tag"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["pattern_id", "tag_id", "created_at", "updated_at"]
  end
end
