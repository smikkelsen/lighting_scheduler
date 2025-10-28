require 'rails_helper'

RSpec.describe Display, type: :model do
  describe 'associations' do
    it { should belong_to(:zone_set) }
    it { should have_many(:display_patterns).dependent(:destroy) }
    it { should have_many(:patterns).through(:display_patterns) }
    it { should have_many(:display_tags).dependent(:destroy) }
    it { should have_many(:tags).through(:display_tags) }
  end

  describe 'validations' do
    subject { build(:display) }

    # Note: workflow_state presence is handled by before_validation callback, not validation
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).case_insensitive }
  end

  describe 'scopes' do
    describe '.active' do
      let!(:active_display) { create(:display, workflow_state: 'active') }
      let!(:inactive_display) { create(:display, workflow_state: 'inactive') }

      it 'returns only active displays' do
        expect(Display.active).to include(active_display)
        expect(Display.active).not_to include(inactive_display)
      end
    end
  end

  describe 'ransackable' do
    it 'defines ransackable_associations' do
      expect(Display.ransackable_associations).to include('display_patterns', 'display_tags', 'patterns', 'tags', 'zone_set')
    end

    it 'defines ransackable_attributes' do
      expect(Display.ransackable_attributes).to include('name', 'workflow_state', 'zone_set_id')
    end
  end

  describe 'callbacks' do
    it 'initializes workflow_state to active' do
      display = create(:display, workflow_state: nil)
      expect(display.workflow_state).to eq('active')
    end
  end

  describe '#activate' do
    it 'responds to activate method' do
      display = build(:display)
      expect(display).to respond_to(:activate)
    end
  end

  describe 'nested attributes' do
    it { should accept_nested_attributes_for(:display_patterns) }
    it { should accept_nested_attributes_for(:tags) }
  end
end