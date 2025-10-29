require 'rails_helper'

RSpec.describe Tag, type: :model do
  describe 'associations' do
    it { should have_many(:display_tags).dependent(:destroy) }
    it { should have_many(:displays).through(:display_tags) }
    it { should have_many(:pattern_tags).dependent(:destroy) }
    it { should have_many(:patterns).through(:pattern_tags) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
  end

  describe 'ransackable' do
    it 'defines ransackable_associations' do
      expect(Tag.ransackable_associations).to include('display_tags', 'displays', 'pattern_tags', 'patterns')
    end

    it 'defines ransackable_attributes' do
      expect(Tag.ransackable_attributes).to include('name', 'created_at', 'updated_at')
    end
  end

  describe '#activate_random' do
    let(:tag) { create(:tag) }
    let!(:pattern1) { create(:pattern, name: 'Pattern 1') }
    let!(:pattern2) { create(:pattern, name: 'Pattern 2') }
    let!(:display1) { create(:display, name: 'Display 1') }
    let!(:display2) { create(:display, name: 'Display 2') }
    let!(:default_zone_set) { create(:zone_set, :default, :with_zones) }

    before do
      tag.patterns << [pattern1, pattern2]
      tag.displays << [display1, display2]

      # Mock WebSocket calls
      allow(WebsocketMessageHandler).to receive(:msg)
      allow(Zone).to receive(:update_cached)
    end

    it 'returns a random pattern or display from the tag' do
      result = tag.activate_random
      expect([pattern1, pattern2, display1, display2]).to include(result)
    end

    context 'when random resource is a Pattern' do
      before do
        # Force pattern selection by only having patterns in the array
        allow(tag).to receive(:displays).and_return(Display.none)
        allow(tag).to receive(:patterns).and_return(Pattern.where(id: [pattern1.id, pattern2.id]))
      end

      it 'activates the default zone set first' do
        expect(default_zone_set).to receive(:activate)
        tag.activate_random
      end

      it 'activates the pattern' do
        expect_any_instance_of(Pattern).to receive(:activate)
        tag.activate_random
      end

      it 'returns the activated pattern' do
        result = tag.activate_random
        expect([pattern1, pattern2]).to include(result)
      end
    end

    context 'when random resource is a Display' do
      before do
        # Force display selection
        allow(tag).to receive(:patterns).and_return(Pattern.none)
        allow(tag).to receive(:displays).and_return(Display.where(id: [display1.id, display2.id]))
      end

      it 'activates the display directly' do
        expect_any_instance_of(Display).to receive(:activate)
        tag.activate_random
      end

      it 'does not activate the default zone set' do
        expect(default_zone_set).not_to receive(:activate)
        tag.activate_random
      end

      it 'returns the activated display' do
        result = tag.activate_random
        expect([display1, display2]).to include(result)
      end
    end

    context 'when no default zone set exists' do
      before do
        ZoneSet.update_all(default_zone_set: false)
        allow(tag).to receive(:displays).and_return(Display.none)
        allow(tag).to receive(:patterns).and_return(Pattern.where(id: [pattern1.id]))
      end

      it 'returns nil and does not activate pattern' do
        expect_any_instance_of(Pattern).not_to receive(:activate)
        result = tag.activate_random
        expect(result).to be_nil
      end
    end

    context 'when tag has no patterns or displays' do
      it 'returns nil' do
        empty_tag = create(:tag)
        result = empty_tag.activate_random
        expect(result).to be_nil
      end
    end
  end

  describe '#activate_random_display' do
    let(:tag) { create(:tag) }
    let!(:display1) { create(:display, name: 'Display 1') }
    let!(:display2) { create(:display, name: 'Display 2') }

    before do
      tag.displays << [display1, display2]
      allow(WebsocketMessageHandler).to receive(:msg)
      allow(Zone).to receive(:update_cached)
    end

    it 'activates a random display from the tag' do
      expect_any_instance_of(Display).to receive(:activate)
      tag.activate_random_display
    end

    it 'returns the activated display' do
      result = tag.activate_random_display
      expect([display1, display2]).to include(result)
    end

    context 'when tag has no displays' do
      it 'returns nil' do
        empty_tag = create(:tag)
        result = empty_tag.activate_random_display
        expect(result).to be_nil
      end
    end
  end

  describe '#activate_random_pattern' do
    let(:tag) { create(:tag) }
    let!(:pattern1) { create(:pattern, name: 'Pattern 1') }
    let!(:pattern2) { create(:pattern, name: 'Pattern 2') }
    let!(:default_zone_set) { create(:zone_set, :default, :with_zones) }

    before do
      tag.patterns << [pattern1, pattern2]
      allow(WebsocketMessageHandler).to receive(:msg)
      allow(Zone).to receive(:update_cached)
    end

    it 'turns off all displays first' do
      expect(Display).to receive(:turn_off).with(:all)
      tag.activate_random_pattern
    end

    it 'activates the default zone set' do
      allow(Display).to receive(:turn_off)
      expect_any_instance_of(ZoneSet).to receive(:activate)
      tag.activate_random_pattern
    end

    it 'activates a random pattern from the tag on all zones' do
      allow(Display).to receive(:turn_off)
      expect_any_instance_of(Pattern).to receive(:activate).with(:all)
      tag.activate_random_pattern
    end

    it 'returns the activated pattern' do
      allow(Display).to receive(:turn_off)
      result = tag.activate_random_pattern
      expect([pattern1, pattern2]).to include(result)
    end

    it 'sleeps between operations' do
      allow(Display).to receive(:turn_off)
      expect(tag).to receive(:sleep).with(0.6).twice
      tag.activate_random_pattern
    end

    context 'when tag has no patterns' do
      it 'returns nil' do
        empty_tag = create(:tag)
        allow(Display).to receive(:turn_off)
        result = empty_tag.activate_random_pattern
        expect(result).to be_nil
      end
    end

    context 'when no default zone set exists' do
      before do
        ZoneSet.update_all(default_zone_set: false)
      end

      it 'does not error and handles gracefully' do
        allow(Display).to receive(:turn_off)
        expect { tag.activate_random_pattern }.not_to raise_error
      end
    end
  end
end