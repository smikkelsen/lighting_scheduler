class Display < ApplicationRecord
  include ZoneHelper

  belongs_to :zone_set
  has_many :display_patterns, dependent: :destroy
  accepts_nested_attributes_for :display_patterns
  has_many :display_tags, dependent: :destroy
  has_many :tags, through: :display_tags
  accepts_nested_attributes_for :tags

  before_validation :init_workflow_state

  validates_presence_of :workflow_state, :name
  validates_uniqueness_of :name, case_sensitive: false

  scope :active, -> { where(workflow_state: 'active') }

  def activate
    turn_off(:all)
    sleep(1)
    zone_set.activate
    sleep(1)
    display_patterns.each do |dp|
      dp.pattern.activate(dp.zones)
    end
  end

  private
  def init_workflow_state
    self.workflow_state ||= 'active'
  end
end
