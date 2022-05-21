class Display < ApplicationRecord
  include ZoneHelper
  has_many :display_patterns
  accepts_nested_attributes_for :display_patterns

  def activate
    display_patterns.each do |dp|
      dp.pattern.activate(dp.zones)
    end
  end
end
