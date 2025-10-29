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

  describe '.update_cached' do
    let(:zones_response) do
      {
        "zones" => {
          "Front Porch" => {
            "numPixels" => 100,
            "portMap" => [{ "ctlrName" => "JellyFish", "phyPort" => 1, "phyStartIdx" => 0, "phyEndIdx" => 99 }]
          },
          "Back Yard" => {
            "numPixels" => 200,
            "portMap" => [{ "ctlrName" => "JellyFish", "phyPort" => 2, "phyStartIdx" => 0, "phyEndIdx" => 199 }]
          }
        }
      }
    end

    before do
      allow(WebsocketMessageHandler).to receive(:msg).and_return(zones_response)
    end

    it 'fetches zones from controller' do
      expect(WebsocketMessageHandler).to receive(:msg).with(
        hash_including(
          cmd: 'toCtlrGet',
          get: [['zones']]
        )
      )

      Zone.update_cached
    end

    it 'creates new zones from controller response' do
      expect {
        Zone.update_cached
      }.to change { Zone.current.count }.by(2)

      expect(Zone.current.find_by(name: 'Front Porch')).to be_present
      expect(Zone.current.find_by(name: 'Back Yard')).to be_present
    end

    it 'sets zone attributes correctly' do
      Zone.update_cached

      front_porch = Zone.current.find_by(name: 'Front Porch')
      expect(front_porch.pixel_count).to eq(100)
      expect(front_porch.port_map).to be_an(Array)
      expect(front_porch.port_map.first['ctlrName']).to eq('JellyFish')
    end

    it 'generates consistent UUIDs based on hardware config' do
      Zone.update_cached
      zone1 = Zone.current.find_by(name: 'Front Porch')
      uuid1 = zone1.uuid

      # Update cached again
      Zone.update_cached
      zone2 = Zone.current.find_by(name: 'Front Porch')
      uuid2 = zone2.uuid

      # UUID should remain the same since hardware config is same
      expect(uuid2).to eq(uuid1)
    end

    it 'updates existing zones with matching UUID' do
      # Create a zone with matching hardware config but different name
      existing_zone = Zone.create!(
        name: 'Old Name',
        pixel_count: 100,
        port_map: [{ "ctlrName" => "JellyFish", "phyPort" => 1, "phyStartIdx" => 0, "phyEndIdx" => 99 }],
        zone_set: nil
      )

      # zones_response has 2 zones, so count will go from 1 to 2
      # But the existing zone should be updated, not deleted
      original_id = existing_zone.id

      Zone.update_cached

      # Name should be updated
      existing_zone.reload
      expect(existing_zone.name).to eq('Front Porch')
      expect(existing_zone.id).to eq(original_id) # Same record, just updated

      # Total zones should now be 2 (existing updated + new one created)
      expect(Zone.current.count).to eq(2)
    end

    it 'deletes zones no longer in controller response' do
      old_zone = create(:zone, name: 'Deleted Zone', zone_set: nil)

      Zone.update_cached

      expect(Zone.find_by(id: old_zone.id)).to be_nil
    end

    it 'does not delete zones in zone sets' do
      zone_in_set = create(:zone, :in_set, name: 'Set Zone')

      Zone.update_cached

      expect(Zone.find_by(id: zone_in_set.id)).to be_present
    end

    it 'stores port_map as JSON array, not YAML string' do
      Zone.update_cached

      zone = Zone.current.first
      expect(zone.port_map).to be_an(Array)
      expect(zone.port_map).not_to be_a(String)
    end

    context 'with zone rename' do
      it 'preserves zone identity when hardware config unchanged' do
        Zone.update_cached
        original_zone = Zone.current.find_by(name: 'Front Porch')
        original_id = original_zone.id
        original_uuid = original_zone.uuid

        # Simulate controller returning renamed zone
        renamed_response = {
          "zones" => {
            "Front Entrance" => {  # Renamed
              "numPixels" => 100,
              "portMap" => [{ "ctlrName" => "JellyFish", "phyPort" => 1, "phyStartIdx" => 0, "phyEndIdx" => 99 }]
            }
          }
        }
        allow(WebsocketMessageHandler).to receive(:msg).and_return(renamed_response)

        Zone.update_cached

        # Should update existing zone, not create new one
        expect(Zone.current.count).to eq(1)
        renamed_zone = Zone.current.find_by(uuid: original_uuid)
        expect(renamed_zone.id).to eq(original_id)
        expect(renamed_zone.name).to eq('Front Entrance')
      end
    end

    context 'with hardware config change' do
      it 'creates new zone when pixel_count changes' do
        Zone.update_cached
        original_zone = Zone.current.find_by(name: 'Front Porch')
        original_uuid = original_zone.uuid

        # Change pixel count - this creates a different hardware config
        # so a new zone with new UUID should be created
        modified_response = {
          "zones" => {
            "Front Porch" => {
              "numPixels" => 150,  # Changed
              "portMap" => [{ "ctlrName" => "JellyFish", "phyPort" => 1, "phyStartIdx" => 0, "phyEndIdx" => 149 }]
            }
          }
        }
        allow(WebsocketMessageHandler).to receive(:msg).and_return(modified_response)

        Zone.update_cached

        # Count should go from 2 to 1 (only one zone in new response)
        expect(Zone.current.count).to eq(1)

        # Should have new UUID due to different hardware config
        zone = Zone.current.find_by(name: 'Front Porch')
        expect(zone.pixel_count).to eq(150)
        expect(zone.uuid).not_to eq(original_uuid) # Different UUID
      end
    end
  end

  describe '#turn_off' do
    let(:zone) { create(:zone, name: 'Test Zone', zone_set: nil) }

    before do
      allow(WebsocketMessageHandler).to receive(:msg)
    end

    it 'calls turn_off with itself as the zone' do
      expect(zone).to receive(:turn_off).and_call_original
      expect(WebsocketMessageHandler).to receive(:msg).with(
        hash_including(
          cmd: 'toCtlrSet',
          runPattern: hash_including(
            state: 0,
            zoneName: ['Test Zone']
          )
        )
      )

      zone.turn_off
    end

    it 'can turn off specific zones when passed as parameter' do
      other_zone = create(:zone, name: 'Other Zone', zone_set: nil)

      expect(WebsocketMessageHandler).to receive(:msg).with(
        hash_including(
          runPattern: hash_including(
            zoneName: ['Other Zone']
          )
        )
      )

      zone.turn_off(other_zone)
    end
  end
end