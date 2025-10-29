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
end