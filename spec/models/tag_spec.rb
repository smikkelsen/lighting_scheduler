require 'rails_helper'

RSpec.describe Tag, type: :model do
  describe 'associations' do
    it { should have_many(:display_tags).dependent(:destroy) }
    it { should have_many(:displays).through(:display_tags) }
    it { should have_many(:pattern_tags).dependent(:destroy) }
    it { should have_many(:patterns).through(:pattern_tags) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
  end

  describe 'ransackable' do
    it 'defines ransackable_associations' do
      expect(Tag.ransackable_associations).to include('display_tags', 'displays', 'pattern_tags', 'patterns')
    end

    it 'defines ransackable_attributes' do
      expect(Tag.ransackable_attributes).to include('name', 'created_at', 'updated_at')
    end
  end

  describe '#activate_random' do
    it 'responds to activate_random method' do
      tag = build(:tag)
      expect(tag).to respond_to(:activate_random)
    end
  end

  describe '#activate_random_display' do
    it 'responds to activate_random_display method' do
      tag = build(:tag)
      expect(tag).to respond_to(:activate_random_display)
    end
  end

  describe '#activate_random_pattern' do
    it 'responds to activate_random_pattern method' do
      tag = build(:tag)
      expect(tag).to respond_to(:activate_random_pattern)
    end
  end
end