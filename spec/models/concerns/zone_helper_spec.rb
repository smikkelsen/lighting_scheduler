require 'rails_helper'

RSpec.describe ZoneHelper, type: :model do
  # Create a test class that includes the concern
  let(:test_class) do
    Class.new do
      include ZoneHelper
      attr_accessor :pixel_count, :port_map
    end
  end
  let(:test_instance) { test_class.new }

  describe '#parameterize_zones' do
    context 'with :all symbol' do
      let!(:zone1) { create(:zone, name: 'Zone 1', zone_set: nil) }
      let!(:zone2) { create(:zone, name: 'Zone 2', zone_set: nil) }
      let!(:zone_in_set) { create(:zone, :in_set, name: 'Set Zone') }

      it 'returns all current zone names' do
        result = test_instance.parameterize_zones(:all)
        expect(result).to contain_exactly('Zone 1', 'Zone 2')
        expect(result).not_to include('Set Zone')
      end
    end

    context 'with :default symbol' do
      let!(:default_zone_set) { create(:zone_set, :default, :with_zones) }
      let!(:other_zone_set) { create(:zone_set, :with_zones) }

      it 'returns zone names from default zone set' do
        default_zone_names = default_zone_set.zones.pluck(:name)
        result = test_instance.parameterize_zones(:default)

        expect(result).to match_array(default_zone_names)
      end

      it 'raises error when no default zone set exists' do
        ZoneSet.update_all(default_zone_set: false)
        # When no default zone set exists, ZoneSet.default returns an empty relation
        # Calling &.zones on a relation that returned nil from .first causes an error
        expect {
          test_instance.parameterize_zones(:default)
        }.to raise_error(NoMethodError)
      end
    end

    context 'with Zone objects' do
      let!(:zone1) { create(:zone, name: 'Test Zone 1') }
      let!(:zone2) { create(:zone, name: 'Test Zone 2') }

      it 'returns zone names for single Zone object' do
        result = test_instance.parameterize_zones(zone1)
        expect(result).to eq(['Test Zone 1'])
      end

      it 'returns zone names for array of Zone objects' do
        result = test_instance.parameterize_zones([zone1, zone2])
        expect(result).to contain_exactly('Test Zone 1', 'Test Zone 2')
      end
    end

    context 'with zone IDs' do
      let!(:zone1) { create(:zone, name: 'ID Zone 1') }
      let!(:zone2) { create(:zone, name: 'ID Zone 2') }

      it 'returns zone name for single integer ID' do
        result = test_instance.parameterize_zones(zone1.id)
        expect(result).to eq(['ID Zone 1'])
      end

      it 'returns zone names for array of integer IDs' do
        result = test_instance.parameterize_zones([zone1.id, zone2.id])
        expect(result).to contain_exactly('ID Zone 1', 'ID Zone 2')
      end

      it 'returns zone name for string ID' do
        result = test_instance.parameterize_zones(zone1.id.to_s)
        expect(result).to eq(['ID Zone 1'])
      end
    end

    context 'with zone names' do
      let!(:zone1) { create(:zone, name: 'Front Porch') }
      let!(:zone2) { create(:zone, name: 'Back Yard') }

      it 'returns zone name for single string name' do
        result = test_instance.parameterize_zones('Front Porch')
        expect(result).to eq(['Front Porch'])
      end

      it 'returns zone names for array of string names' do
        result = test_instance.parameterize_zones(['Front Porch', 'Back Yard'])
        expect(result).to contain_exactly('Front Porch', 'Back Yard')
      end
    end

    context 'with zone UUIDs' do
      let!(:zone1) { create(:zone, name: 'UUID Zone', uuid: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11') }

      it 'returns zone name for valid UUID string' do
        result = test_instance.parameterize_zones('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11')
        expect(result).to eq(['UUID Zone'])
      end
    end

    context 'with mixed input types' do
      let!(:zone1) { create(:zone, name: 'Zone A') }
      let!(:zone2) { create(:zone, name: 'Zone B') }
      let!(:zone3) { create(:zone, name: 'Zone C') }

      it 'handles array with Zone objects, IDs, and names' do
        result = test_instance.parameterize_zones([zone1, zone2.id, 'Zone C'])
        expect(result).to contain_exactly('Zone A', 'Zone B', 'Zone C')
      end
    end

    context 'with invalid zones' do
      it 'filters out nil values for non-existent zones' do
        result = test_instance.parameterize_zones([99999, 'NonExistent'])
        expect(result).to eq([])
      end

      it 'returns only valid zones when mixed with invalid' do
        zone = create(:zone, name: 'Valid Zone')
        result = test_instance.parameterize_zones([zone.id, 99999, 'Invalid'])
        expect(result).to eq(['Valid Zone'])
      end
    end
  end

  describe '#turn_off' do
    let!(:zone1) { create(:zone, name: 'Living Room', zone_set: nil) }
    let!(:zone2) { create(:zone, name: 'Bedroom', zone_set: nil) }

    it 'sends state: 0 command to WebsocketMessageHandler' do
      expect(WebsocketMessageHandler).to receive(:msg).with(
        hash_including(
          cmd: 'toCtlrSet',
          runPattern: hash_including(
            state: 0,
            file: "",
            data: "",
            id: ""
          )
        )
      )

      test_instance.turn_off(:all)
    end

    it 'includes zone names in the command' do
      expect(WebsocketMessageHandler).to receive(:msg).with(
        hash_including(
          runPattern: hash_including(
            zoneName: ['Living Room']
          )
        )
      )

      test_instance.turn_off(zone1)
    end

    it 'defaults to :all zones when no parameter provided' do
      expect(WebsocketMessageHandler).to receive(:msg).with(
        hash_including(
          runPattern: hash_including(
            zoneName: contain_exactly('Living Room', 'Bedroom')
          )
        )
      )

      test_instance.turn_off
    end
  end

  describe '#uuid_from_attributes' do
    it 'generates consistent UUID from pixel_count and port_map' do
      test_instance.pixel_count = 512
      test_instance.port_map = [{"ctlrName" => "Test", "phyPort" => 1}]

      uuid1 = test_instance.uuid_from_attributes
      uuid2 = test_instance.uuid_from_attributes

      expect(uuid1).to eq(uuid2)
      expect(uuid1).to match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/)
    end

    it 'generates different UUIDs for different attributes' do
      test_instance.pixel_count = 512
      test_instance.port_map = [{"ctlrName" => "Test1", "phyPort" => 1}]
      uuid1 = test_instance.uuid_from_attributes

      test_instance.port_map = [{"ctlrName" => "Test2", "phyPort" => 1}]
      uuid2 = test_instance.uuid_from_attributes

      expect(uuid1).not_to eq(uuid2)
    end
  end

  describe '.turn_off (class method)' do
    let!(:zone) { create(:zone, name: 'Test Zone', zone_set: nil) }

    it 'creates new instance and calls instance method' do
      expect(WebsocketMessageHandler).to receive(:msg).with(
        hash_including(
          cmd: 'toCtlrSet',
          runPattern: hash_including(state: 0)
        )
      )

      test_class.turn_off(:all)
    end
  end

  describe '.uuid_from_json (class method)' do
    it 'generates UUID from zone JSON data' do
      zone_data = {
        'numPixels' => 512,
        'portMap' => [{"ctlrName" => "JellyFish", "phyPort" => 1}]
      }

      uuid = test_class.uuid_from_json(zone_data)

      expect(uuid).to be_present
      expect(uuid).to match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/)
    end

    it 'generates consistent UUIDs for same data' do
      zone_data = {
        'numPixels' => 512,
        'portMap' => [{"ctlrName" => "JellyFish", "phyPort" => 1}]
      }

      uuid1 = test_class.uuid_from_json(zone_data)
      uuid2 = test_class.uuid_from_json(zone_data)

      expect(uuid1).to eq(uuid2)
    end
  end
end