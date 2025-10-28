require 'rails_helper'

RSpec.describe ZoneSet, type: :model do
  describe 'associations' do
    it { should have_many(:zones).dependent(:destroy) }
    it { should have_many(:displays).dependent(:restrict_with_exception) }
  end

  describe 'validations' do
    subject { build(:zone_set) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).case_insensitive }
  end

  describe 'scopes' do
    describe '.default' do
      let!(:default_zone_set) { create(:zone_set, :default) }
      let!(:other_zone_set) { create(:zone_set) }

      it 'returns the default zone set' do
        expect(ZoneSet.default).to eq(default_zone_set)
      end
    end
  end

  describe 'ransackable' do
    it 'defines ransackable_associations' do
      expect(ZoneSet.ransackable_associations).to eq(['zones', 'displays'])
    end

    it 'defines ransackable_attributes' do
      expect(ZoneSet.ransackable_attributes).to include('name', 'default_zone_set')
    end
  end

  describe 'callbacks' do
    describe 'update_default_zone_set' do
      let!(:first_default) { create(:zone_set, :default) }
      let!(:second_default) { create(:zone_set) }

      it 'ensures only one default zone set' do
        second_default.update(default_zone_set: true)
        first_default.reload
        expect(first_default.default_zone_set).to be false
        expect(second_default.default_zone_set).to be true
      end
    end
  end

  describe '#activate' do
    it 'responds to activate method' do
      zone_set = build(:zone_set)
      expect(zone_set).to respond_to(:activate)
    end
  end
end