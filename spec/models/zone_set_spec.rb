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
      let!(:second_zone_set) { create(:zone_set) }

      it 'ensures only one default zone set when updating existing' do
        second_zone_set.update(default_zone_set: true)
        first_default.reload
        expect(first_default.default_zone_set).to be false
        expect(second_zone_set.default_zone_set).to be true
      end

      it 'clears previous default when creating new default' do
        third_zone_set = create(:zone_set, default_zone_set: true)
        first_default.reload

        expect(first_default.default_zone_set).to be false
        expect(third_zone_set.default_zone_set).to be true
      end

      it 'allows multiple non-default zone sets' do
        third = create(:zone_set)
        fourth = create(:zone_set)

        expect(ZoneSet.where(default_zone_set: false).count).to be >= 3
      end

      it 'does not affect other zone sets when saving non-default' do
        second_zone_set.update(name: 'New Name')
        first_default.reload

        expect(first_default.default_zone_set).to be true
      end

      it 'ensures exactly one default exists after multiple updates' do
        # Create multiple zone sets
        third = create(:zone_set)
        fourth = create(:zone_set)

        # Toggle defaults multiple times
        second_zone_set.update(default_zone_set: true)
        third.update(default_zone_set: true)
        fourth.update(default_zone_set: true)

        # Should only have one default
        expect(ZoneSet.where(default_zone_set: true).count).to eq(1)
        expect(fourth.reload.default_zone_set).to be true
      end

      it 'handles setting default to false' do
        first_default.update(default_zone_set: false)

        # No defaults should exist now
        expect(ZoneSet.where(default_zone_set: true).count).to eq(0)
      end
    end
  end

  describe '.create_from_current' do
    let!(:current_zone1) { create(:zone, name: 'Current 1', pixel_count: 100, port_map: [{"port" => 1}], zone_set: nil) }
    let!(:current_zone2) { create(:zone, name: 'Current 2', pixel_count: 200, port_map: [{"port" => 2}], zone_set: nil) }
    let!(:zone_in_set) { create(:zone, :in_set, name: 'Already in set') }

    it 'creates a new zone set with the given name' do
      zone_set = ZoneSet.create_from_current('My Snapshot')
      expect(zone_set).to be_persisted
      expect(zone_set.name).to eq('My Snapshot')
    end

    it 'copies all current zones to the new zone set' do
      zone_set = ZoneSet.create_from_current('My Snapshot')
      expect(zone_set.zones.count).to eq(2)
      expect(zone_set.zones.pluck(:name)).to contain_exactly('Current 1', 'Current 2')
    end

    it 'does not copy zones already in a zone set' do
      zone_set = ZoneSet.create_from_current('My Snapshot')
      expect(zone_set.zones.pluck(:name)).not_to include('Already in set')
    end

    it 'copies zone attributes correctly' do
      zone_set = ZoneSet.create_from_current('My Snapshot')
      copied_zone = zone_set.zones.find_by(name: 'Current 1')

      expect(copied_zone.pixel_count).to eq(100)
      expect(copied_zone.port_map).to eq([{"port" => 1}])
    end

    it 'handles zones with JSON port_map correctly' do
      json_zone = create(:zone, name: 'JSON Zone', pixel_count: 400, port_map: [{"ctlrName" => "Test2"}], zone_set: nil)

      zone_set = ZoneSet.create_from_current('JSON Snapshot')
      copied_zone = zone_set.zones.find_by(name: 'JSON Zone')

      expect(copied_zone.port_map).to eq([{"ctlrName" => "Test2"}])
    end
  end

  describe '#activate' do
    let(:zone_set) { create(:zone_set) }
    let!(:zone1) { create(:zone, name: 'Zone A', pixel_count: 100, port_map: [{"port" => 1}], zone_set: zone_set) }
    let!(:zone2) { create(:zone, name: 'Zone B', pixel_count: 200, port_map: [{"port" => 2}], zone_set: zone_set) }

    before do
      # Mock Zone.update_cached to avoid actual WebSocket calls
      allow(Zone).to receive(:update_cached)
    end

    it 'sends zone configuration to WebsocketMessageHandler' do
      expect(WebsocketMessageHandler).to receive(:msg) do |arg|
        expect(arg[:cmd]).to eq('toCtlrSet')
        expect(arg[:save]).to be true
        expect(arg[:zones]).to be_a(Hash)
        expect(arg[:zones]['Zone A']).to be_present
        expect(arg[:zones]['Zone B']).to be_present
        expect(arg[:zones]['Zone A'][:numPixels]).to eq(100)
        expect(arg[:zones]['Zone B'][:numPixels]).to eq(200)
      end

      zone_set.activate
    end

    it 'includes port_map in zone configuration' do
      expect(WebsocketMessageHandler).to receive(:msg) do |arg|
        expect(arg[:zones]['Zone A'][:portMap]).to eq([{"port" => 1}])
      end

      zone_set.activate
    end

    it 'handles JSON port_map correctly' do
      expect(WebsocketMessageHandler).to receive(:msg) do |arg|
        expect(arg[:zones]['Zone A'][:portMap]).to be_an(Array)
        expect(arg[:zones]['Zone A'][:portMap]).to eq([{"port" => 1}])
      end

      zone_set.activate
    end

    it 'calls Zone.update_cached after activating' do
      allow(WebsocketMessageHandler).to receive(:msg)
      expect(Zone).to receive(:update_cached)

      zone_set.activate
    end

    context 'with zone set that has no zones' do
      let(:empty_zone_set) { create(:zone_set) }

      it 'sends empty zones hash to controller' do
        expect(WebsocketMessageHandler).to receive(:msg) do |arg|
          expect(arg[:zones]).to eq({})
        end

        empty_zone_set.activate
      end
    end

    context 'with zone names containing special characters' do
      let!(:special_zone) { create(:zone, name: "Zone's \"Special\" <Name>", pixel_count: 50, port_map: [{"port" => 3}], zone_set: zone_set) }

      it 'handles special characters in zone names' do
        expect(WebsocketMessageHandler).to receive(:msg) do |arg|
          expect(arg[:zones]["Zone's \"Special\" <Name>"]).to be_present
        end

        zone_set.activate
      end
    end
  end

  describe 'deletion restrictions' do
    let(:zone_set) { create(:zone_set) }
    let(:display) { create(:display, zone_set: zone_set) }

    it 'prevents deletion when displays reference the zone set' do
      display # Create the display

      expect {
        zone_set.destroy
      }.to raise_error(ActiveRecord::DeleteRestrictionError)

      expect(ZoneSet.find_by(id: zone_set.id)).to be_present
    end

    it 'allows deletion when no displays reference the zone set' do
      expect {
        zone_set.destroy
      }.not_to raise_error

      expect(ZoneSet.find_by(id: zone_set.id)).to be_nil
    end

    it 'deletes associated zones when zone set is deleted' do
      zone1 = create(:zone, zone_set: zone_set)
      zone2 = create(:zone, zone_set: zone_set)

      zone_set.destroy

      expect(Zone.find_by(id: zone1.id)).to be_nil
      expect(Zone.find_by(id: zone2.id)).to be_nil
    end
  end

  describe '.create_from_current edge cases' do
    context 'when no current zones exist' do
      it 'creates zone set with no zones' do
        zone_set = ZoneSet.create_from_current('Empty Set')
        expect(zone_set).to be_persisted
        expect(zone_set.zones.count).to eq(0)
      end
    end

    context 'with duplicate names' do
      it 'fails when creating zone set with duplicate name' do
        create(:zone_set, name: 'Duplicate Name')
        # create_from_current doesn't use create! so it won't raise on validation error
        # It creates the zone set, then reloads it which will fail if save failed
        expect {
          ZoneSet.create_from_current('Duplicate Name')
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end