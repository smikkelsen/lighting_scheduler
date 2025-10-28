require 'rails_helper'

RSpec.describe DisplayPattern, type: :model do
  describe 'associations' do
    it { should belong_to(:display) }
    it { should belong_to(:pattern) }
  end

  describe 'ransackable' do
    it 'defines ransackable_associations' do
      expect(DisplayPattern.ransackable_associations).to eq(['display', 'pattern'])
    end

    it 'defines ransackable_attributes' do
      expect(DisplayPattern.ransackable_attributes).to include('zones', 'display_id', 'pattern_id')
    end
  end

  describe 'zones attribute' do
    it 'stores zones as JSONB array' do
      display_pattern = create(:display_pattern, zones: ['Zone 1', 'Zone 2'])
      expect(display_pattern.zones).to eq(['Zone 1', 'Zone 2'])
    end

    it 'handles empty zones array' do
      display_pattern = create(:display_pattern, zones: [])
      expect(display_pattern.zones).to eq([])
    end
  end

  describe 'factory' do
    it 'creates a valid display_pattern' do
      display_pattern = build(:display_pattern)
      expect(display_pattern).to be_valid
    end
  end
end
