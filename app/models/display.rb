class Display < ApplicationRecord
  include ZoneHelper

  belongs_to :zone_set
  has_many :display_patterns, dependent: :destroy
  has_many :patterns, through: :display_patterns
  accepts_nested_attributes_for :display_patterns
  has_many :display_tags, dependent: :destroy
  has_many :tags, through: :display_tags
  accepts_nested_attributes_for :tags

  def self.ransackable_associations(auth_object = nil)
    ["display_patterns", "display_tags", "patterns", "tags", "zone_set"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["name", "workflow_state", "zone_set_id", "created_at", "updated_at"]
  end

  before_validation :init_workflow_state

  validates_presence_of :workflow_state, :name
  validates_uniqueness_of :name, case_sensitive: false

  scope :active, -> { where(workflow_state: 'active') }

  def activate
    turn_off(:all)
    sleep(0.6)
    zone_set.activate
    sleep(0.6)
    display_patterns.each do |dp|
      dp.pattern.activate(dp.zones)
    end
  end

  private
  def init_workflow_state
    self.workflow_state ||= 'active'
  end
end
