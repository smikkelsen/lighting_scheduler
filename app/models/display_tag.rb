class DisplayTag < ApplicationRecord
  belongs_to :display
  belongs_to :tag

  def self.ransackable_associations(auth_object = nil)
    ["display", "tag"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["display_id", "tag_id", "created_at", "updated_at"]
  end
end
