class Tag < ApplicationRecord
  has_many :display_tags, dependent: :destroy
  has_many :displays, through: :display_tags

  validates_presence_of :name

  def activate_random_display
    self.displays.shuffle&.first&.activate
  end

end
