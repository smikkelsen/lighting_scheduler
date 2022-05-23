class Display < ApplicationRecord
  include ZoneHelper
  has_many :display_patterns
  accepts_nested_attributes_for :display_patterns
  before_create :init_workflow_state

  validates_presence_of :workflow_state, :name
  validates_uniqueness_of :name, case_sensitive: false
  
  def activate
    display_patterns.each do |dp|
      dp.pattern.activate(dp.zones)
    end
  end

  private
  def init_workflow_state
    self.workflow_state ||= 'active'
  end
end
