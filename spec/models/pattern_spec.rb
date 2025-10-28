require 'rails_helper'

RSpec.describe Pattern, type: :model do
  describe 'associations' do
    it { should have_many(:pattern_tags).dependent(:destroy) }
    it { should have_many(:tags).through(:pattern_tags) }
  end

  describe 'ransackable' do
    it 'defines ransackable_associations' do
      expect(Pattern.ransackable_associations).to eq(['pattern_tags', 'tags'])
    end

    it 'defines ransackable_attributes' do
      expect(Pattern.ransackable_attributes).to include('name', 'folder', 'custom', 'data')
    end
  end

  describe '#full_path' do
    it 'returns the full path with folder and name' do
      pattern = build(:pattern, folder: 'Halloween', name: 'Spooky')
      expect(pattern.full_path).to eq('Halloween/Spooky')
    end

    it 'returns only name when folder is nil' do
      pattern = build(:pattern, folder: nil, name: 'Simple')
      expect(pattern.full_path).to eq('Simple')
    end
  end

  describe '#activate' do
    it 'responds to activate method' do
      pattern = build(:pattern)
      expect(pattern).to respond_to(:activate)
    end
  end

  describe 'factory' do
    it 'creates a valid pattern' do
      pattern = build(:pattern)
      expect(pattern).to be_valid
    end

    it 'creates a custom pattern' do
      pattern = build(:pattern, :custom)
      expect(pattern.custom).to be true
    end
  end
end