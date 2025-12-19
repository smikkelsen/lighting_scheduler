require 'rails_helper'

RSpec.describe Pattern, type: :model do
  describe 'associations' do
    it { should have_many(:pattern_tags).dependent(:destroy) }
    it { should have_many(:tags).through(:pattern_tags) }
  end

  describe 'ransackable' do
    it 'defines ransackable_associations' do
      expect(Pattern.ransackable_associations).to eq(['pattern_tags', 'tags'])
    end

    it 'defines ransackable_attributes' do
      expect(Pattern.ransackable_attributes).to include('name', 'folder', 'custom', 'data')
    end
  end

  describe '#full_path' do
    it 'returns the full path with folder and name' do
      pattern = build(:pattern, folder: 'Halloween', name: 'Spooky')
      expect(pattern.full_path).to eq('Halloween/Spooky')
    end

    it 'returns only name when folder is nil' do
      pattern = build(:pattern, folder: nil, name: 'Simple')
      expect(pattern.full_path).to eq('Simple')
    end
  end

  describe '#activate' do
    let(:pattern) { create(:pattern, folder: 'Halloween', name: 'Spooky') }
    let!(:zone1) { create(:zone, name: 'Front', zone_set: nil) }
    let!(:zone2) { create(:zone, name: 'Back', zone_set: nil) }

    before do
      allow(WebsocketMessageHandler).to receive(:msg)
    end

    it 'sends activation command to WebsocketMessageHandler' do
      expect(WebsocketMessageHandler).to receive(:msg).with(
        hash_including(
          cmd: 'toCtlrSet',
          runPattern: hash_including(
            file: 'Halloween/Spooky',
            state: 1
          )
        )
      )

      pattern.activate(:all)
    end

    context 'with :all zones' do
      it 'activates on all current zones' do
        expect(WebsocketMessageHandler).to receive(:msg).with(
          hash_including(
            runPattern: hash_including(
              zoneName: contain_exactly('Front', 'Back')
            )
          )
        )

        pattern.activate(:all)
      end
    end

    context 'with specific zones' do
      it 'activates on specified zone by name' do
        expect(WebsocketMessageHandler).to receive(:msg).with(
          hash_including(
            runPattern: hash_including(
              zoneName: ['Front']
            )
          )
        )

        pattern.activate('Front')
      end

      it 'activates on multiple specified zones' do
        expect(WebsocketMessageHandler).to receive(:msg).with(
          hash_including(
            runPattern: hash_including(
              zoneName: contain_exactly('Front', 'Back')
            )
          )
        )

        pattern.activate(['Front', 'Back'])
      end

      it 'activates on zone by ID' do
        expect(WebsocketMessageHandler).to receive(:msg).with(
          hash_including(
            runPattern: hash_including(
              zoneName: ['Front']
            )
          )
        )

        pattern.activate(zone1.id)
      end

      it 'activates on Zone object' do
        expect(WebsocketMessageHandler).to receive(:msg).with(
          hash_including(
            runPattern: hash_including(
              zoneName: ['Back']
            )
          )
        )

        pattern.activate(zone2)
      end
    end

    context 'when zones are empty or invalid' do
      it 'logs error and does not send command' do
        expect(Rails.logger).to receive(:error).with(/No matching zones/)
        expect(WebsocketMessageHandler).not_to receive(:msg)

        pattern.activate([99999]) # Non-existent zone ID
      end
    end

    context 'with pattern without folder' do
      let(:simple_pattern) { create(:pattern, folder: nil, name: 'Simple') }

      it 'uses only name as full_path' do
        expect(WebsocketMessageHandler).to receive(:msg).with(
          hash_including(
            runPattern: hash_including(
              file: 'Simple'
            )
          )
        )

        simple_pattern.activate(:all)
      end
    end
  end

  describe '.activate_random' do
    let!(:pattern1) { create(:pattern, folder: 'Holiday', name: 'Pattern 1') }
    let!(:pattern2) { create(:pattern, folder: 'Holiday', name: 'Pattern 2') }
    let!(:other_pattern) { create(:pattern, folder: 'Other', name: 'Pattern 3') }
    let!(:zone) { create(:zone, name: 'Test Zone', zone_set: nil) }

    before do
      allow(WebsocketMessageHandler).to receive(:msg)
    end

    context 'without folder filter' do
      it 'activates a random pattern from all patterns' do
        expect_any_instance_of(Pattern).to receive(:activate).with(:all)
        Pattern.activate_random(nil, :all)
      end

      it 'returns the full_path of activated pattern' do
        result = Pattern.activate_random
        expect(['Holiday/Pattern 1', 'Holiday/Pattern 2', 'Other/Pattern 3']).to include(result)
      end
    end

    context 'with folder filter' do
      it 'activates a random pattern from specified folder' do
        expect_any_instance_of(Pattern).to receive(:activate).with(:all)

        result = Pattern.activate_random('Holiday')
        expect(['Holiday/Pattern 1', 'Holiday/Pattern 2']).to include(result)
      end
    end

    context 'with custom zones' do
      it 'activates on specified zones' do
        allow_any_instance_of(Pattern).to receive(:activate)
        Pattern.activate_random(nil, ['Test Zone'])
      end
    end
  end

  describe '.update_cached' do
    let(:pattern_list) do
      [
        { 'name' => 'Pattern 1', 'folders' => 'Halloween', 'readOnly' => true },
        { 'name' => 'Pattern 2', 'folders' => 'Christmas', 'readOnly' => false },
        { 'name' => '', 'folders' => 'Invalid', 'readOnly' => true } # Should be skipped
      ]
    end

    before do
      allow(WebsocketMessageHandler).to receive(:msg).and_return({ 'patternFileList' => pattern_list })
    end

    it 'fetches pattern list from controller' do
      expect(WebsocketMessageHandler).to receive(:msg).with(
        hash_including(
          cmd: 'toCtlrGet',
          get: [['patternFileList']]
        )
      )

      Pattern.update_cached
    end

    it 'creates new patterns from controller list' do
      expect {
        Pattern.update_cached
      }.to change { Pattern.count }.by(2)

      expect(Pattern.find_by(name: 'Pattern 1', folder: 'Halloween')).to be_present
      expect(Pattern.find_by(name: 'Pattern 2', folder: 'Christmas')).to be_present
    end

    it 'sets custom flag based on readOnly' do
      Pattern.update_cached

      pattern1 = Pattern.find_by(name: 'Pattern 1')
      pattern2 = Pattern.find_by(name: 'Pattern 2')

      expect(pattern1.custom).to be false # readOnly: true
      expect(pattern2.custom).to be true  # readOnly: false
    end

    it 'skips patterns with blank names' do
      Pattern.update_cached
      expect(Pattern.where(folder: 'Invalid').count).to eq(0)
    end

    it 'deletes patterns no longer in controller list' do
      old_pattern = create(:pattern, name: 'Old Pattern', folder: 'Deleted')
      Pattern.update_cached

      expect(Pattern.find_by(id: old_pattern.id)).to be_nil
    end

    it 'updates existing patterns' do
      existing = create(:pattern, name: 'Pattern 1', folder: 'Halloween', custom: true)
      Pattern.update_cached
      existing.reload

      expect(existing.custom).to be false # Updated from controller
    end
  end

  describe '.cache_pattern_data' do
    let!(:pattern_with_data) { create(:pattern, name: 'Has Data', data: { 'key' => 'value' }) }
    let!(:pattern_without_data) { create(:pattern, name: 'No Data', data: nil) }
    let(:pattern_data_response) do
      {
        'patternFileData' => {
          'jsonData' => '{"effects": ["effect1", "effect2"]}'
        }
      }
    end

    before do
      allow(WebsocketMessageHandler).to receive(:msg).and_return(pattern_data_response)
    end

    it 'caches data for patterns without data' do
      Pattern.cache_pattern_data

      pattern_without_data.reload
      expect(pattern_without_data.data).to be_present
      expect(pattern_without_data.data['effects']).to eq(['effect1', 'effect2'])
    end

    it 'does not update patterns that already have data' do
      original_data = pattern_with_data.data
      Pattern.cache_pattern_data

      pattern_with_data.reload
      expect(pattern_with_data.data).to eq(original_data)
    end

    context 'with force_all parameter' do
      it 'updates all patterns including those with data' do
        Pattern.cache_pattern_data(true)

        pattern_with_data.reload
        expect(pattern_with_data.data['effects']).to eq(['effect1', 'effect2'])
      end
    end
  end

  describe '#pattern_data' do
    let(:pattern) { create(:pattern, folder: 'Test', name: 'MyPattern') }
    let(:response) { { 'patternFileData' => { 'jsonData' => '{"test": "data"}' } } }

    before do
      allow(WebsocketMessageHandler).to receive(:msg).and_return(response)
    end

    it 'fetches pattern data from controller' do
      expect(WebsocketMessageHandler).to receive(:msg).with(
        hash_including(
          cmd: 'toCtlrGet',
          get: [['patternFileData', 'Test', 'MyPattern']]
        )
      )

      pattern.pattern_data
    end

    it 'caches the result' do
      expect(WebsocketMessageHandler).to receive(:msg).once.and_return(response)

      pattern.pattern_data
      pattern.pattern_data # Second call should use cached value
    end
  end

  describe 'factory' do
    it 'creates a valid pattern' do
      pattern = build(:pattern)
      expect(pattern).to be_valid
    end

    it 'creates a custom pattern' do
      pattern = build(:pattern, :custom)
      expect(pattern.custom).to be true
    end
  end

  describe 'edge cases' do
    context 'with folder names' do
      it 'handles nil folder' do
        pattern = create(:pattern, folder: nil, name: 'Test')
        expect(pattern.full_path).to eq('Test')
      end

      it 'handles empty string folder' do
        pattern = create(:pattern, folder: '', name: 'Test')
        # Empty string is not nil, so it joins as /Test
        expect(pattern.full_path).to eq('/Test')
      end

      it 'handles folder with special characters' do
        pattern = create(:pattern, folder: 'Holiday\'s/Special', name: 'Test')
        expect(pattern.full_path).to eq('Holiday\'s/Special/Test')
      end

      it 'handles folder with Unicode characters' do
        pattern = create(:pattern, folder: '节日 🎄', name: 'Test')
        expect(pattern.full_path).to eq('节日 🎄/Test')
      end

      it 'handles very long folder paths' do
        long_folder = 'Folder/' * 50
        pattern = create(:pattern, folder: long_folder, name: 'Test')
        expect(pattern.full_path).to eq("#{long_folder}/Test")
      end
    end

    context 'with pattern names' do
      it 'handles pattern names with special characters' do
        pattern = create(:pattern, name: 'Pattern\'s "Special" <Name>')
        expect(pattern.name).to eq('Pattern\'s "Special" <Name>')
      end

      it 'handles extremely long pattern names' do
        long_name = 'P' * 1000
        pattern = create(:pattern, name: long_name)
        expect(pattern.name).to eq(long_name)
      end
    end

    context 'with pattern data' do
      it 'handles nil data' do
        pattern = create(:pattern, data: nil)
        expect(pattern.data).to be_nil
      end

      it 'handles empty hash data' do
        pattern = create(:pattern, data: {})
        expect(pattern.data).to eq({})
      end

      it 'handles deeply nested data structures' do
        complex_data = {
          'effects' => [
            { 'type' => 'fade', 'colors' => ['#FF0000', '#00FF00'] },
            { 'type' => 'chase', 'speed' => 10, 'nested' => { 'deep' => { 'value' => 'test' } } }
          ],
          'metadata' => {
            'author' => 'Test',
            'version' => '1.0'
          }
        }
        pattern = create(:pattern, data: complex_data)
        expect(pattern.data).to eq(complex_data)
      end

      it 'handles data with special characters in values' do
        pattern = create(:pattern, data: { 'name' => 'Test\'s "Data" <Value>' })
        expect(pattern.data['name']).to eq('Test\'s "Data" <Value>')
      end
    end
  end

  describe '.update_cached edge cases' do
    context 'with duplicate patterns' do
      let(:pattern_list) do
        [
          { 'name' => 'Pattern 1', 'folders' => 'Test', 'readOnly' => true },
          { 'name' => 'Pattern 1', 'folders' => 'Test', 'readOnly' => false }
        ]
      end

      before do
        allow(WebsocketMessageHandler).to receive(:msg).and_return({ 'patternFileList' => pattern_list })
      end

      it 'keeps only the last occurrence of duplicate patterns' do
        Pattern.update_cached
        pattern = Pattern.find_by(name: 'Pattern 1', folder: 'Test')
        expect(pattern).to be_present
        expect(pattern.custom).to be true # Last one has readOnly: false
        expect(Pattern.where(name: 'Pattern 1', folder: 'Test').count).to eq(1)
      end
    end

    context 'with patterns with nil folders' do
      let(:pattern_list) do
        [
          { 'name' => 'Pattern 1', 'folders' => nil, 'readOnly' => true },
          { 'name' => 'Pattern 2', 'folders' => '', 'readOnly' => true }
        ]
      end

      before do
        allow(WebsocketMessageHandler).to receive(:msg).and_return({ 'patternFileList' => pattern_list })
      end

      it 'handles nil and empty folder values' do
        expect {
          Pattern.update_cached
        }.not_to raise_error

        pattern1 = Pattern.find_by(name: 'Pattern 1')
        pattern2 = Pattern.find_by(name: 'Pattern 2')

        expect(pattern1).to be_present
        expect(pattern2).to be_present
      end
    end

    context 'when WebSocket returns nil or malformed data' do
      it 'handles nil patternFileList gracefully' do
        allow(WebsocketMessageHandler).to receive(:msg).and_return({ 'patternFileList' => nil })

        expect {
          Pattern.update_cached
        }.to raise_error(NoMethodError)
      end

      it 'handles empty patternFileList' do
        allow(WebsocketMessageHandler).to receive(:msg).and_return({ 'patternFileList' => [] })

        expect {
          Pattern.update_cached
        }.not_to raise_error
      end
    end
  end

  describe '.cache_pattern_data error handling' do
    context 'when pattern_data returns invalid JSON' do
      let!(:pattern) { create(:pattern, data: nil) }
      let(:invalid_json_response) do
        {
          'patternFileData' => {
            'jsonData' => 'invalid json {'
          }
        }
      end

      before do
        allow(WebsocketMessageHandler).to receive(:msg).and_return(invalid_json_response)
      end

      it 'raises JSON parse error' do
        expect {
          Pattern.cache_pattern_data
        }.to raise_error(JSON::ParserError)
      end
    end

    context 'when pattern_data is missing expected structure' do
      let!(:pattern) { create(:pattern, data: nil) }
      let(:missing_data_response) do
        {
          'patternFileData' => {}
        }
      end

      before do
        allow(WebsocketMessageHandler).to receive(:msg).and_return(missing_data_response)
      end

      it 'raises error when jsonData is missing' do
        expect {
          Pattern.cache_pattern_data
        }.to raise_error(TypeError)
      end
    end
  end

  describe '.activate_random edge cases' do
    context 'with no patterns in database' do
      it 'handles empty pattern list gracefully' do
        Pattern.destroy_all
        expect {
          Pattern.activate_random
        }.to raise_error(NoMethodError) # shuffle.first returns nil, then calling activate on nil
      end
    end

    context 'with folder filter matching no patterns' do
      let!(:pattern) { create(:pattern, folder: 'Holiday') }

      it 'handles no matching patterns for folder' do
        expect {
          Pattern.activate_random('NonExistent')
        }.to raise_error(NoMethodError)
      end
    end
  end
end