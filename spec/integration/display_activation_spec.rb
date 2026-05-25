require 'rails_helper'

RSpec.describe 'Display Activation Integration', type: :integration do
  let!(:zone_set) { create(:zone_set, name: 'Test Zones') }
  let!(:zone1) { create(:zone, name: 'Zone A', pixel_count: 50, zone_set: zone_set, port_map: [{ 'phyPort' => 1 }]) }
  let!(:zone2) { create(:zone, name: 'Zone B', pixel_count: 50, zone_set: zone_set, port_map: [{ 'phyPort' => 2 }]) }
  let!(:current_zone) { create(:zone, name: 'Current Zone', zone_set: nil, pixel_count: 100, port_map: [{ 'phyPort' => 1 }]) }

  let(:display) { create(:display, name: 'Test Display', zone_set: zone_set) }
  let(:pattern1) { create(:pattern, name: 'Pattern 1', folder: 'Test') }
  let(:pattern2) { create(:pattern, name: 'Pattern 2', folder: 'Test') }

  before do
    # Mock WebSocket responses
    allow(WebsocketMessageHandler).to receive(:msg) do |message|
      case message[:cmd]
      when 'toCtlrGet'
        if message[:get] == [['zones']]
          # Return current zones from controller
          {
            'zones' => {
              'Current Zone' => {
                'numPixels' => 100,
                'portMap' => [{ 'phyPort' => 1 }]
              }
            }
          }
        end
      when 'toCtlrSet'
        if message[:zones]
          # Zone configuration update
          { 'cmd' => 'fromCtlr', 'save' => true, 'zones' => message[:zones] }
        elsif message[:runPattern]
          # Pattern activation
          { 'cmd' => 'fromCtlr', 'ledPower' => message[:runPattern][:state] == 1 }
        end
      end
    end

    # Mock Zone.update_cached to simulate successful zone sync
    allow(Zone).to receive(:update_cached) do
      # Update current zones to match what was just set
      Zone.where(zone_set_id: nil).destroy_all
      zone_set.zones.each do |z|
        Zone.create!(
          name: z.name,
          pixel_count: z.pixel_count,
          port_map: z.port_map,
          uuid: z.uuid,
          zone_set_id: nil
        )
      end
    end
  end

  describe 'Full display activation workflow' do
    it 'successfully activates a display with multiple patterns' do
      # Create display patterns
      create(:display_pattern, display: display, pattern: pattern1, zones: [zone1.id.to_s])
      create(:display_pattern, display: display, pattern: pattern2, zones: [zone2.id.to_s])

      expect { display.activate }.not_to raise_error

      # Verify WebSocket commands were sent
      expect(WebsocketMessageHandler).to have_received(:msg).at_least(:once)
    end

    it 'handles display with no patterns' do
      expect { display.activate }.not_to raise_error
    end

    it 'turns off zones before activating new zone set' do
      create(:display_pattern, display: display, pattern: pattern1, zones: [zone1.id.to_s])

      # Expect turn_off command first
      expect(WebsocketMessageHandler).to receive(:msg).with(
        hash_including(
          cmd: 'toCtlrSet',
          runPattern: hash_including(state: 0)
        )
      ).ordered

      # Then zone set activation
      expect(WebsocketMessageHandler).to receive(:msg).with(
        hash_including(
          cmd: 'toCtlrSet',
          zones: hash_including('Zone A', 'Zone B')
        )
      ).ordered

      # Then pattern activation
      expect(WebsocketMessageHandler).to receive(:msg).with(
        hash_including(
          cmd: 'toCtlrSet',
          runPattern: hash_including(
            state: 1,
            file: 'Test/Pattern 1'
          )
        )
      ).ordered

      # Mock Zone.update_cached
      allow(Zone).to receive(:update_cached)

      display.activate
    end
  end

  describe 'YAML serialization regression tests' do
    context 'with legacy YAML string in zones field' do
      it 'converts YAML to array before activation' do
        # Simulate old data with YAML string
        dp = create(:display_pattern, display: display, pattern: pattern1)
        dp.update_column(:zones, "---\n- '#{zone1.id}'\n- '#{zone2.id}'\n")

        # This should trigger before_save callback when activated
        dp.reload
        dp.save! # Trigger the callback

        expect(dp.zones).to be_an(Array)
        expect(dp.zones).to include(zone1.id.to_s, zone2.id.to_s)
      end

      it 'removes empty strings from YAML arrays' do
        dp = create(:display_pattern, display: display, pattern: pattern1)
        dp.update_column(:zones, "---\n- ''\n- '#{zone1.id}'\n")

        dp.reload
        dp.save!

        expect(dp.zones).not_to include('')
        expect(dp.zones).to eq([zone1.id.to_s])
      end
    end
  end

  describe 'Zone synchronization during activation' do
    it 'updates current zones after zone set activation' do
      create(:display_pattern, display: display, pattern: pattern1, zones: [zone1.id.to_s])

      # Before activation, current zone is different
      expect(Zone.current.pluck(:name)).to eq(['Current Zone'])

      display.activate

      # After activation, current zones should match zone set
      expect(Zone.current.pluck(:name)).to contain_exactly('Zone A', 'Zone B')
    end

    it 'handles zone set with no zones' do
      empty_zone_set = create(:zone_set, name: 'Empty')
      empty_display = create(:display, zone_set: empty_zone_set)

      expect { empty_display.activate }.not_to raise_error
    end
  end

  describe 'Error handling' do
    context 'when WebSocket times out' do
      before do
        allow(WebsocketMessageHandler).to receive(:msg).and_return(nil)
      end

      it 'does not crash the application' do
        create(:display_pattern, display: display, pattern: pattern1, zones: [zone1.id.to_s])

        expect { display.activate }.not_to raise_error
      end
    end

    context 'when zone IDs do not exist' do
      it 'logs error and continues' do
        # Create pattern with non-existent zone IDs
        create(:display_pattern, display: display, pattern: pattern1, zones: ['99999', '88888'])

        expect(Rails.logger).to receive(:error).with(/No matching zones/)

        display.activate
      end
    end

    context 'when zones array contains invalid data' do
      it 'handles empty strings gracefully' do
        create(:display_pattern, display: display, pattern: pattern1, zones: ['', zone1.id.to_s, ''])

        # Should filter out empty strings and activate with valid zones
        expect { display.activate }.not_to raise_error
      end

      it 'handles whitespace-only strings' do
        create(:display_pattern, display: display, pattern: pattern1, zones: ['  ', zone1.id.to_s])

        expect { display.activate }.not_to raise_error
      end
    end
  end

  describe 'Timing and sequencing' do
    it 'includes appropriate delays between operations' do
      create(:display_pattern, display: display, pattern: pattern1, zones: [zone1.id.to_s])

      expect(display).to receive(:sleep).with(0.6).twice

      display.activate
    end
  end

  describe 'Pattern activation with zone resolution' do
    it 'converts zone IDs to zone names for controller' do
      create(:display_pattern, display: display, pattern: pattern1, zones: [zone1.id.to_s, zone2.id.to_s])

      # Mock Zone.update_cached to create current zones
      allow(Zone).to receive(:update_cached) do
        Zone.where(zone_set_id: nil).destroy_all
        [zone1, zone2].each do |z|
          Zone.create!(
            name: z.name,
            pixel_count: z.pixel_count,
            port_map: z.port_map,
            uuid: z.uuid,
            zone_set_id: nil
          )
        end
      end

      # Expect pattern activation with zone names, not IDs
      expect(WebsocketMessageHandler).to receive(:msg).with(
        hash_including(
          cmd: 'toCtlrSet',
          runPattern: hash_including(
            zoneName: contain_exactly('Zone A', 'Zone B')
          )
        )
      )

      display.activate
    end
  end
end
