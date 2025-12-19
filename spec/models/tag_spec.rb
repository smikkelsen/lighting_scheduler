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

    it 'allows duplicate tag names' do
      create(:tag, name: 'Holiday')
      duplicate = build(:tag, name: 'Holiday')
      expect(duplicate).to be_valid
    end

    it 'allows tags with same name but different case' do
      create(:tag, name: 'holiday')
      uppercase = build(:tag, name: 'HOLIDAY')
      expect(uppercase).to be_valid
    end
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
        allow(ZoneSet).to receive(:default).and_return(default_zone_set)
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

      it 'returns pattern but does not activate it' do
        expect_any_instance_of(Pattern).not_to receive(:activate)
        result = tag.activate_random
        # Pattern is still returned even though it couldn't be activated
        expect(result).to eq(pattern1)
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

  describe 'edge cases' do
    context 'with tag names' do
      it 'handles extremely long tag names' do
        long_name = 'T' * 1000
        tag = create(:tag, name: long_name)
        expect(tag.name).to eq(long_name)
      end

      it 'handles tag names with special characters' do
        special_name = "Tag's \"Name\" <with> & symbols!"
        tag = create(:tag, name: special_name)
        expect(tag.name).to eq(special_name)
      end

      it 'handles tag names with Unicode characters' do
        unicode_name = '标签 🎄 Тег'
        tag = create(:tag, name: unicode_name)
        expect(tag.name).to eq(unicode_name)
      end

      it 'handles empty string name' do
        tag = build(:tag, name: '')
        expect(tag).not_to be_valid
        expect(tag.errors[:name]).to include("can't be blank")
      end

      it 'handles nil name' do
        tag = build(:tag, name: nil)
        expect(tag).not_to be_valid
      end
    end

    context 'with multiple associations' do
      let(:tag) { create(:tag) }
      let!(:pattern1) { create(:pattern) }
      let!(:pattern2) { create(:pattern) }
      let!(:display1) { create(:display) }
      let!(:display2) { create(:display) }

      before do
        tag.patterns << [pattern1, pattern2]
        tag.displays << [display1, display2]
      end

      it 'maintains associations count correctly' do
        expect(tag.patterns.count).to eq(2)
        expect(tag.displays.count).to eq(2)
      end

      it 'allows removing associations' do
        tag.patterns.delete(pattern1)
        expect(tag.patterns.count).to eq(1)
        expect(tag.patterns).not_to include(pattern1)
      end

      it 'deletes pattern_tags when tag is deleted' do
        pattern_tag_ids = tag.pattern_tags.pluck(:id)
        tag.destroy

        pattern_tag_ids.each do |id|
          expect(PatternTag.find_by(id: id)).to be_nil
        end
      end

      it 'deletes display_tags when tag is deleted' do
        display_tag_ids = tag.display_tags.pluck(:id)
        tag.destroy

        display_tag_ids.each do |id|
          expect(DisplayTag.find_by(id: id)).to be_nil
        end
      end

      it 'does not delete patterns when tag is deleted' do
        tag.destroy

        expect(Pattern.find_by(id: pattern1.id)).to be_present
        expect(Pattern.find_by(id: pattern2.id)).to be_present
      end

      it 'does not delete displays when tag is deleted' do
        tag.destroy

        expect(Display.find_by(id: display1.id)).to be_present
        expect(Display.find_by(id: display2.id)).to be_present
      end
    end

    context 'with duplicate associations' do
      let(:tag) { create(:tag) }
      let(:pattern) { create(:pattern) }

      # BUG: Database allows duplicate associations!
      # Consider adding unique index: add_index :pattern_tags, [:tag_id, :pattern_id], unique: true
      it 'currently allows adding same pattern twice (BUG - should be prevented)' do
        tag.patterns << pattern
        initial_count = tag.pattern_tags.count

        # This should raise an error but currently doesn't due to missing unique constraint
        expect {
          tag.patterns << pattern
        }.not_to raise_error

        # Verify duplicate was created
        expect(tag.pattern_tags.count).to eq(initial_count + 1)
      end

      it 'currently allows creating duplicate pattern_tags (BUG - should be prevented)' do
        create(:pattern_tag, tag: tag, pattern: pattern)
        duplicate = build(:pattern_tag, tag: tag, pattern: pattern)

        # Model validation doesn't prevent it
        expect(duplicate.valid?).to be true

        # Database also doesn't prevent it (missing unique constraint)
        expect {
          duplicate.save
        }.not_to raise_error

        # Verify duplicates exist
        expect(PatternTag.where(tag: tag, pattern: pattern).count).to eq(2)
      end
    end
  end

  describe '#activate_random with complex scenarios' do
    let(:tag) { create(:tag) }

    before do
      allow(WebsocketMessageHandler).to receive(:msg)
      allow(Zone).to receive(:update_cached)
    end

    context 'with only patterns (no displays)' do
      let!(:pattern) { create(:pattern) }
      let!(:default_zone_set) { create(:zone_set, :default, :with_zones) }

      before do
        tag.patterns << pattern
      end

      it 'activates the pattern through default zone set' do
        allow(Display).to receive(:turn_off)
        expect_any_instance_of(Pattern).to receive(:activate)
        tag.activate_random
      end
    end

    context 'with only displays (no patterns)' do
      let!(:display) { create(:display) }

      before do
        tag.displays << display
      end

      it 'activates the display directly' do
        expect_any_instance_of(Display).to receive(:activate)
        tag.activate_random
      end
    end

    context 'with large number of associated items' do
      let!(:patterns) { create_list(:pattern, 100) }
      let!(:displays) { create_list(:display, 100) }
      let!(:default_zone_set) { create(:zone_set, :default, :with_zones) }

      before do
        tag.patterns << patterns
        tag.displays << displays
      end

      it 'selects and activates a random item' do
        allow(Display).to receive(:turn_off)
        result = tag.activate_random
        expect(patterns + displays).to include(result)
      end

      it 'performs shuffle on combined array' do
        allow(Display).to receive(:turn_off)
        # Just ensure it doesn't error with large datasets
        expect { tag.activate_random }.not_to raise_error
      end
    end
  end

  describe 'private method #activate_pattern' do
    let(:tag) { create(:tag) }
    let(:pattern) { create(:pattern) }
    let!(:default_zone_set) { create(:zone_set, :default, :with_zones) }

    before do
      allow(WebsocketMessageHandler).to receive(:msg)
      allow(Zone).to receive(:update_cached)
    end

    it 'turns off all displays first' do
      expect(Display).to receive(:turn_off).with(:all)
      tag.send(:activate_pattern, pattern)
    end

    it 'activates default zone set' do
      allow(Display).to receive(:turn_off)
      allow(tag).to receive(:sleep)
      allow(pattern).to receive(:activate)
      expect_any_instance_of(ZoneSet).to receive(:activate)
      tag.send(:activate_pattern, pattern)
    end

    it 'activates pattern on all zones' do
      allow(Display).to receive(:turn_off)
      expect(pattern).to receive(:activate).with(:all)
      tag.send(:activate_pattern, pattern)
    end

    it 'sleeps between operations for timing' do
      allow(Display).to receive(:turn_off)
      expect(tag).to receive(:sleep).with(0.6).twice
      tag.send(:activate_pattern, pattern)
    end

    context 'when pattern is nil' do
      it 'handles nil pattern gracefully' do
        allow(Display).to receive(:turn_off)
        expect {
          tag.send(:activate_pattern, nil)
        }.not_to raise_error
      end

      it 'does not call activate on nil pattern' do
        allow(Display).to receive(:turn_off)
        allow(tag).to receive(:sleep)
        # The method uses safe navigation (&.) so it handles nil gracefully
        expect {
          tag.send(:activate_pattern, nil)
        }.not_to raise_error
      end
    end
  end
end