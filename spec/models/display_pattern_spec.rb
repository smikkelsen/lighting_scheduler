require 'rails_helper'

RSpec.describe DisplayPattern, type: :model do
  describe 'associations' do
    it { should belong_to(:display) }
    it { should belong_to(:pattern) }
  end

  describe 'ransackable' do
    it 'defines ransackable_associations' do
      expect(DisplayPattern.ransackable_associations).to eq(['display', 'pattern'])
    end

    it 'defines ransackable_attributes' do
      expect(DisplayPattern.ransackable_attributes).to include('zones', 'display_id', 'pattern_id')
    end
  end

  describe 'zones attribute' do
    it 'stores zones as JSONB array' do
      display_pattern = create(:display_pattern, zones: ['Zone 1', 'Zone 2'])
      expect(display_pattern.zones).to eq(['Zone 1', 'Zone 2'])
    end

    it 'handles empty zones array' do
      display_pattern = create(:display_pattern, zones: [])
      expect(display_pattern.zones).to eq([])
    end

    it 'stores zone IDs as strings' do
      display_pattern = create(:display_pattern, zones: ['38', '43'])
      expect(display_pattern.zones).to eq(['38', '43'])
      expect(display_pattern.zones.first).to be_a(String)
    end

    it 'handles zone names with special characters' do
      zones = ["Corners Bottom Peak", "Zone's \"Name\"", "<Zone> & More"]
      display_pattern = create(:display_pattern, zones: zones)
      expect(display_pattern.zones).to eq(zones)
    end
  end

  describe 'callbacks' do
    describe '#ensure_zones_is_array' do
      it 'converts YAML string to array on save' do
        display_pattern = build(:display_pattern)
        # Manually set zones as YAML string (simulating old data)
        display_pattern.zones = "---\n- '38'\n- '43'\n"
        display_pattern.save!

        display_pattern.reload
        expect(display_pattern.zones).to be_an(Array)
        expect(display_pattern.zones).to eq(['38', '43'])
      end

      it 'removes empty strings from zones array on save' do
        display_pattern = create(:display_pattern, zones: ['', '38', '43'])
        expect(display_pattern.zones).to eq(['38', '43'])
      end

      it 'wraps non-array values in array' do
        display_pattern = build(:display_pattern, zones: '38')
        display_pattern.save!

        expect(display_pattern.zones).to eq(['38'])
      end

      it 'leaves valid arrays unchanged' do
        display_pattern = create(:display_pattern, zones: ['38', '43'])
        expect(display_pattern.zones).to eq(['38', '43'])
      end
    end
  end

  describe 'legacy data migration' do
    context 'with YAML serialized zones from old serialize directive' do
      it 'handles YAML with empty strings' do
        display_pattern = build(:display_pattern)
        display_pattern.zones = "---\n- ''\n- '39'\n- '40'\n"
        display_pattern.save!

        display_pattern.reload
        expect(display_pattern.zones).to eq(['39', '40'])
        expect(display_pattern.zones).not_to include('')
      end

      it 'handles complex YAML arrays' do
        yaml_string = "---\n- 'Zone 1'\n- 'Zone 2'\n- 'Zone 3'\n"
        display_pattern = build(:display_pattern, zones: yaml_string)
        display_pattern.save!

        expect(display_pattern.zones).to eq(['Zone 1', 'Zone 2', 'Zone 3'])
      end

      it 'handles YAML with special characters' do
        yaml_string = "---\n- 'Zone''s Name'\n- 'Zone & More'\n"
        display_pattern = build(:display_pattern, zones: yaml_string)
        display_pattern.save!

        expect(display_pattern.zones).to be_an(Array)
        expect(display_pattern.zones.count).to eq(2)
      end
    end
  end

  describe 'integration with Display activation' do
    let(:zone_set) { create(:zone_set, :with_zones) }
    let(:display) { create(:display, zone_set: zone_set) }
    let(:pattern) { create(:pattern) }
    let!(:zone1) { create(:zone, name: 'Test Zone 1', zone_set: nil) }
    let!(:zone2) { create(:zone, name: 'Test Zone 2', zone_set: nil) }

    before do
      allow(WebsocketMessageHandler).to receive(:msg)
      allow(Zone).to receive(:update_cached)
    end

    it 'activates pattern with zone IDs as strings' do
      display_pattern = create(:display_pattern,
        display: display,
        pattern: pattern,
        zones: [zone1.id.to_s, zone2.id.to_s]
      )

      # The pattern receives the zones array from DisplayPattern
      expect_any_instance_of(Pattern).to receive(:activate).with([zone1.id.to_s, zone2.id.to_s])

      display.activate
    end

    it 'handles empty zones array gracefully' do
      display_pattern = create(:display_pattern,
        display: display,
        pattern: pattern,
        zones: []
      )

      # Pattern activation is called with empty array
      expect_any_instance_of(Pattern).to receive(:activate).with([])

      display.activate
    end
  end

  describe 'edge cases' do
    it 'handles nil zones' do
      display_pattern = build(:display_pattern, zones: nil)
      display_pattern.save!

      display_pattern.reload
      expect(display_pattern.zones).to be_an(Array)
    end

    it 'handles zones with numeric values' do
      display_pattern = create(:display_pattern, zones: ['1', '2', '999'])
      expect(display_pattern.zones).to eq(['1', '2', '999'])
    end

    it 'handles zones with whitespace' do
      display_pattern = create(:display_pattern, zones: ['  ', 'Zone 1', '  Zone 2  '])
      # Empty strings and whitespace should be removed
      expect(display_pattern.zones).to eq(['Zone 1', '  Zone 2  '])
    end

    it 'handles very long zone arrays' do
      long_array = (1..100).map(&:to_s)
      display_pattern = create(:display_pattern, zones: long_array)
      expect(display_pattern.zones.count).to eq(100)
    end
  end

  describe 'factory' do
    it 'creates a valid display_pattern' do
      display_pattern = build(:display_pattern)
      expect(display_pattern).to be_valid
    end

    it 'creates display_pattern with zones' do
      display_pattern = create(:display_pattern, zones: ['Zone 1', 'Zone 2'])
      expect(display_pattern.zones).to be_present
      expect(display_pattern.zones.count).to eq(2)
    end
  end
end
