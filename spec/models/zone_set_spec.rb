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
  end
end