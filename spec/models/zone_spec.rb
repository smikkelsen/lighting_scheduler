require 'rails_helper'

RSpec.describe Zone, type: :model do
  describe 'associations' do
    it { should belong_to(:zone_set).optional }
  end

  describe 'validations' do
    subject { build(:zone) }

    # Note: uuid presence is handled by before_validation callback, not validation
    it { should validate_uniqueness_of(:uuid).scoped_to(:zone_set_id).case_insensitive }
  end

  describe 'scopes' do
    let!(:current_zone) { create(:zone, zone_set: nil) }
    let!(:set_zone) { create(:zone, :in_set) }

    describe '.current' do
      it 'returns zones not in a zone set' do
        expect(Zone.current).to include(current_zone)
        expect(Zone.current).not_to include(set_zone)
      end
    end

    describe '.in_set' do
      it 'returns zones in a zone set' do
        expect(Zone.in_set).to include(set_zone)
        expect(Zone.in_set).not_to include(current_zone)
      end
    end
  end

  describe 'ransackable' do
    it 'defines ransackable_associations' do
      expect(Zone.ransackable_associations).to eq(['zone_set'])
    end

    it 'defines ransackable_attributes' do
      expect(Zone.ransackable_attributes).to include('name', 'uuid', 'pixel_count', 'port_map')
    end
  end

  describe 'callbacks' do
    it 'sets uuid before creation when not provided' do
      # Create a zone without specifying uuid in factory override
      zone = Zone.new(
        name: 'Test Zone',
        pixel_count: 100,
        port_map: [1, 2, 3]
      )
      expect(zone.uuid).to be_nil
      zone.save!
      expect(zone.uuid).to be_present
    end

    it 'preserves uuid if already set' do
      custom_uuid = SecureRandom.uuid
      zone = Zone.create!(
        name: 'Test Zone',
        pixel_count: 100,
        port_map: [1, 2, 3],
        uuid: custom_uuid
      )
      expect(zone.uuid).to eq(custom_uuid)
    end
  end

  describe '#turn_off' do
    it 'responds to turn_off method' do
      zone = build(:zone)
      expect(zone).to respond_to(:turn_off)
    end
  end
end