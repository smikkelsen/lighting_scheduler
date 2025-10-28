require 'rails_helper'

RSpec.describe DisplayTag, type: :model do
  describe 'associations' do
    it { should belong_to(:display) }
    it { should belong_to(:tag) }
  end

  describe 'ransackable' do
    it 'defines ransackable_associations' do
      expect(DisplayTag.ransackable_associations).to eq(['display', 'tag'])
    end

    it 'defines ransackable_attributes' do
      expect(DisplayTag.ransackable_attributes).to include('display_id', 'tag_id')
    end
  end

  describe 'factory' do
    it 'creates a valid display_tag' do
      display_tag = build(:display_tag)
      expect(display_tag).to be_valid
    end
  end
end
