require 'rails_helper'

RSpec.describe Display, type: :model do
  describe 'associations' do
    it { should belong_to(:zone_set) }
    it { should have_many(:display_patterns).dependent(:destroy) }
    it { should have_many(:patterns).through(:display_patterns) }
    it { should have_many(:display_tags).dependent(:destroy) }
    it { should have_many(:tags).through(:display_tags) }
  end

  describe 'validations' do
    subject { build(:display) }

    # Note: workflow_state presence is handled by before_validation callback, not validation
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).case_insensitive }
  end

  describe 'scopes' do
    describe '.active' do
      let!(:active_display) { create(:display, workflow_state: 'active') }
      let!(:inactive_display) { create(:display, workflow_state: 'inactive') }

      it 'returns only active displays' do
        expect(Display.active).to include(active_display)
        expect(Display.active).not_to include(inactive_display)
      end
    end
  end

  describe 'ransackable' do
    it 'defines ransackable_associations' do
      expect(Display.ransackable_associations).to include('display_patterns', 'display_tags', 'patterns', 'tags', 'zone_set')
    end

    it 'defines ransackable_attributes' do
      expect(Display.ransackable_attributes).to include('name', 'workflow_state', 'zone_set_id')
    end
  end

  describe 'callbacks' do
    it 'initializes workflow_state to active' do
      display = create(:display, workflow_state: nil)
      expect(display.workflow_state).to eq('active')
    end
  end

  describe '#activate' do
    let(:zone_set) { create(:zone_set, :with_zones) }
    let(:display) { create(:display, zone_set: zone_set) }
    let!(:pattern1) { create(:pattern, name: 'Pattern 1') }
    let!(:pattern2) { create(:pattern, name: 'Pattern 2') }
    let!(:display_pattern1) { create(:display_pattern, display: display, pattern: pattern1, zones: ['Zone 1']) }
    let!(:display_pattern2) { create(:display_pattern, display: display, pattern: pattern2, zones: ['Zone 2']) }

    before do
      allow(WebsocketMessageHandler).to receive(:msg)
      allow(Zone).to receive(:update_cached)
    end

    it 'turns off all zones first' do
      expect(display).to receive(:turn_off).with(:all)
      display.activate
    end

    it 'activates the zone set' do
      allow(display).to receive(:turn_off)
      expect(zone_set).to receive(:activate)
      display.activate
    end

    it 'activates each pattern with its configured zones' do
      allow(display).to receive(:turn_off)
      allow(zone_set).to receive(:activate)

      # Verify patterns are activated with correct zones
      activations = []
      allow_any_instance_of(Pattern).to receive(:activate) do |pattern, zones|
        activations << { pattern: pattern.name, zones: zones }
      end

      display.activate

      expect(activations).to contain_exactly(
        { pattern: 'Pattern 1', zones: ['Zone 1'] },
        { pattern: 'Pattern 2', zones: ['Zone 2'] }
      )
    end

    it 'sleeps 0.6 seconds between operations' do
      allow(display).to receive(:turn_off)
      allow(zone_set).to receive(:activate)
      allow_any_instance_of(Pattern).to receive(:activate)

      expect(display).to receive(:sleep).with(0.6).twice

      display.activate
    end

    it 'performs operations in correct order' do
      allow(display).to receive(:sleep)

      call_order = []
      allow(display).to receive(:turn_off) { call_order << :turn_off }
      allow(zone_set).to receive(:activate) { call_order << :zone_set }
      allow_any_instance_of(Pattern).to receive(:activate) { call_order << :pattern }

      display.activate

      expect(call_order.first).to eq(:turn_off)
      expect(call_order[1]).to eq(:zone_set)
      # Should have activated 2 patterns after zone_set
      expect(call_order[2..-1]).to all(eq(:pattern))
      expect(call_order[2..-1].length).to eq(2)
    end

    context 'with display having no patterns' do
      let(:empty_display) { create(:display, zone_set: zone_set) }

      it 'still activates zone set without errors' do
        allow(empty_display).to receive(:turn_off)
        expect(zone_set).to receive(:activate)
        expect { empty_display.activate }.not_to raise_error
      end
    end
  end

  describe 'nested attributes' do
    it { should accept_nested_attributes_for(:display_patterns) }
    it { should accept_nested_attributes_for(:tags) }
  end

  describe 'edge cases' do
    context 'with display names' do
      it 'handles extremely long display names' do
        long_name = 'D' * 1000
        display = create(:display, name: long_name)
        expect(display.name).to eq(long_name)
      end

      it 'handles display names with special characters' do
        special_name = "Display's \"Name\" <with> & symbols!"
        display = create(:display, name: special_name)
        expect(display.name).to eq(special_name)
      end

      it 'handles display names with Unicode characters' do
        unicode_name = '显示 🎄 Дисплей'
        display = create(:display, name: unicode_name)
        expect(display.name).to eq(unicode_name)
      end

      it 'prevents duplicate display names (case insensitive)' do
        create(:display, name: 'Holiday Display')
        duplicate = build(:display, name: 'HOLIDAY DISPLAY')

        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:name]).to include('has already been taken')
      end

      it 'allows same name after first display is deleted' do
        first = create(:display, name: 'Holiday Display')
        first.destroy

        second = build(:display, name: 'Holiday Display')
        expect(second).to be_valid
      end
    end

    context 'with workflow_state' do
      it 'defaults to active when not specified' do
        display = create(:display, workflow_state: nil)
        expect(display.workflow_state).to eq('active')
      end

      it 'accepts custom workflow states' do
        display = create(:display, workflow_state: 'archived')
        expect(display.workflow_state).to eq('archived')
      end

      it 'validates workflow_state presence (callback always sets it)' do
        display = Display.new(name: 'Test', zone_set: create(:zone_set))
        # The before_validation callback always sets workflow_state to 'active'
        # so setting it to nil and validating will reset it
        display.workflow_state = nil
        display.validate
        # After validation, the callback will have set it back to 'active'
        expect(display.workflow_state).to eq('active')
      end
    end

    context 'with zone_set association' do
      it 'requires a zone_set' do
        display = build(:display, zone_set: nil)
        expect(display).not_to be_valid
      end

      it 'prevents deletion of zone_set when display references it' do
        zone_set = create(:zone_set)
        display = create(:display, zone_set: zone_set)

        expect {
          zone_set.destroy
        }.to raise_error(ActiveRecord::DeleteRestrictionError)
      end
    end

    context 'with display_patterns' do
      let(:display) { create(:display) }
      let(:pattern1) { create(:pattern) }
      let(:pattern2) { create(:pattern) }

      it 'deletes display_patterns when display is deleted' do
        dp1 = create(:display_pattern, display: display, pattern: pattern1)
        dp2 = create(:display_pattern, display: display, pattern: pattern2)

        display.destroy

        expect(DisplayPattern.find_by(id: dp1.id)).to be_nil
        expect(DisplayPattern.find_by(id: dp2.id)).to be_nil
      end

      it 'allows creating display with nested display_patterns' do
        display = Display.create(
          name: 'Nested Display',
          zone_set: create(:zone_set),
          display_patterns_attributes: [
            { pattern_id: pattern1.id, zones: ['Zone 1'] },
            { pattern_id: pattern2.id, zones: ['Zone 2'] }
          ]
        )

        expect(display.display_patterns.count).to eq(2)
      end

      it 'handles empty zones array in display_patterns' do
        dp = create(:display_pattern, display: display, pattern: pattern1, zones: [])
        expect(dp.zones).to eq([])
      end

      it 'handles zones with special characters in display_patterns' do
        special_zones = ["Zone's \"Name\"", "<Zone> & More"]
        dp = create(:display_pattern, display: display, pattern: pattern1, zones: special_zones)
        expect(dp.zones).to eq(special_zones)
      end
    end
  end

  describe '#activate edge cases' do
    let(:zone_set) { create(:zone_set, :with_zones) }
    let(:display) { create(:display, zone_set: zone_set) }

    before do
      allow(WebsocketMessageHandler).to receive(:msg)
      allow(Zone).to receive(:update_cached)
    end

    context 'when zone_set activation fails' do
      it 'handles errors from zone_set.activate' do
        allow(zone_set).to receive(:activate).and_raise(StandardError, 'WebSocket error')

        expect {
          display.activate
        }.to raise_error(StandardError, 'WebSocket error')
      end
    end

    context 'when pattern activation fails' do
      let(:pattern) { create(:pattern) }
      let!(:display_pattern) { create(:display_pattern, display: display, pattern: pattern, zones: ['Zone 1']) }

      it 'handles errors from pattern.activate' do
        allow(display).to receive(:turn_off)
        allow(display).to receive(:sleep)
        allow(zone_set).to receive(:activate)
        allow_any_instance_of(Pattern).to receive(:activate).and_raise(StandardError, 'Pattern error')

        expect {
          display.activate
        }.to raise_error(StandardError, 'Pattern error')
      end
    end

    context 'with multiple patterns on overlapping zones' do
      let(:pattern1) { create(:pattern, name: 'Pattern 1') }
      let(:pattern2) { create(:pattern, name: 'Pattern 2') }
      let!(:dp1) { create(:display_pattern, display: display, pattern: pattern1, zones: ['Zone 1', 'Zone 2']) }
      let!(:dp2) { create(:display_pattern, display: display, pattern: pattern2, zones: ['Zone 2', 'Zone 3']) }

      it 'activates all patterns in order' do
        allow(display).to receive(:turn_off)
        allow(display).to receive(:sleep)
        allow(zone_set).to receive(:activate)

        activations = []
        allow_any_instance_of(Pattern).to receive(:activate) do |instance, zones|
          activations << { pattern: instance.name, zones: zones }
        end

        display.activate

        expect(activations.length).to eq(2)
        expect(activations[0][:pattern]).to eq('Pattern 1')
        expect(activations[1][:pattern]).to eq('Pattern 2')
      end
    end
  end

  describe 'association cascades' do
    let(:display) { create(:display) }

    it 'deletes display_tags when display is deleted' do
      tag = create(:tag)
      display.tags << tag

      display_tag_id = display.display_tags.first.id
      display.destroy

      expect(DisplayTag.find_by(id: display_tag_id)).to be_nil
    end

    it 'does not delete tags when display is deleted' do
      tag = create(:tag)
      display.tags << tag
      tag_id = tag.id

      display.destroy

      expect(Tag.find_by(id: tag_id)).to be_present
    end

    it 'does not delete patterns when display is deleted' do
      pattern = create(:pattern)
      create(:display_pattern, display: display, pattern: pattern)
      pattern_id = pattern.id

      display.destroy

      expect(Pattern.find_by(id: pattern_id)).to be_present
    end
  end
end