require 'rails_helper'

RSpec.describe PatternTag, type: :model do
  describe 'associations' do
    it { should belong_to(:pattern) }
    it { should belong_to(:tag) }
  end

  describe 'ransackable' do
    it 'defines ransackable_associations' do
      expect(PatternTag.ransackable_associations).to eq(['pattern', 'tag'])
    end

    it 'defines ransackable_attributes' do
      expect(PatternTag.ransackable_attributes).to include('pattern_id', 'tag_id')
    end
  end

  describe 'factory' do
    it 'creates a valid pattern_tag' do
      pattern_tag = build(:pattern_tag)
      expect(pattern_tag).to be_valid
    end
  end
end
