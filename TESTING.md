# Testing Guide

## Overview

This application has comprehensive RSpec test coverage for models, concerns, API endpoints, and integration scenarios.

## Running Tests

```bash
# Run all specs
bundle exec rspec

# Run specific spec files
bundle exec rspec spec/models/display_pattern_spec.rb
bundle exec rspec spec/lib/websocket_message_handler_spec.rb
bundle exec rspec spec/integration/display_activation_spec.rb

# Run with documentation format
bundle exec rspec --format documentation

# Run specific examples
bundle exec rspec spec/models/display_pattern_spec.rb:45
```

## Test Coverage

### Model Specs

- **DisplayPattern** (`spec/models/display_pattern_spec.rb`)
  - JSONB array storage
  - YAML to JSON conversion (legacy data migration)
  - Empty string removal from zones arrays
  - before_save callback validation
  - Integration with Display activation
  - Edge cases: nil, whitespace, special characters, large arrays

- **Display** (`spec/models/display_spec.rb`)
  - Activation workflow
  - Zone set management
  - Pattern activation
  - Validation and associations

- **Pattern** (`spec/models/pattern_spec.rb`)
  - Activation on zones
  - Controller synchronization
  - Pattern data caching

- **Zone** (`spec/models/zone_spec.rb`)
  - UUID generation
  - Current vs zone set scoping
  - Controller synchronization

- **ZoneSet** (`spec/models/zone_set_spec.rb`)
  - Default zone set exclusivity
  - Zone configuration activation
  - Snapshot creation from current zones

- **Tag** (`spec/models/tag_spec.rb`)
  - Random activation
  - Pattern and display associations

- **ZoneHelper** (`spec/models/concerns/zone_helper_spec.rb`)
  - Zone parameterization (IDs, names, UUIDs, objects)
  - Turn off functionality
  - UUID generation

### Library Specs

- **WebsocketMessageHandler** (`spec/lib/websocket_message_handler_spec.rb`)
  - Connection handling
  - Timeout protection (5 seconds)
  - Error handling
  - Message logging
  - Different command types (toCtlrGet, toCtlrSet, runPattern)

### Integration Specs

- **Display Activation** (`spec/integration/display_activation_spec.rb`)
  - Full activation workflow
  - YAML serialization regression tests
  - Zone synchronization
  - Error handling (timeouts, missing zones)
  - Timing and sequencing
  - Zone resolution (ID to name conversion)

### API Specs

- **Displays API** (`spec/requests/api/v1/displays_spec.rb`)
  - HTTP Basic authentication
  - Listing displays
  - Activating displays
  - Turning off all lights

- **Tags API** (`spec/requests/api/v1/tags_spec.rb`)
  - Random activation endpoints
  - Pattern vs display activation

## Key Testing Scenarios

### Legacy Data Migration

The specs test conversion of old YAML-serialized zones to proper JSON arrays:

```ruby
# Old data (before Oct 2025)
zones: "---\n- '38'\n- '43'\n"

# New data (after conversion)
zones: ["38", "43"]
```

Tests ensure:
- YAML strings are converted to arrays on save
- Empty strings are removed
- Data integrity is maintained

### WebSocket Timeout Protection

Tests verify the 5-second timeout prevents hangs:

```ruby
it 'returns nil after timeout' do
  result = WebsocketMessageHandler.msg(test_message)
  expect(result).to be_nil
end
```

### Display Activation Flow

Integration tests verify the complete workflow:

1. Turn off current zones
2. Sleep 0.6s
3. Activate new zone set
4. Sleep 0.6s
5. Activate each pattern on specified zones

## Test Data Factories

Factories are defined in `spec/factories/` for:
- Displays
- Patterns
- Zones
- ZoneSets
- DisplayPatterns
- Tags
- Users

## Mocking WebSocket Calls

Tests mock `WebsocketMessageHandler.msg` to avoid real hardware dependencies:

```ruby
before do
  allow(WebsocketMessageHandler).to receive(:msg).and_return({ 'zones' => {} })
end
```

## Known Issues Tested

1. **YAML Serialization Bug** (Fixed Oct 2025)
   - Old records had `serialize :zones` causing YAML storage
   - Tests ensure conversion works correctly

2. **Empty Strings in Zones**
   - Some records had `["", "38", "43"]`
   - Tests ensure these are cleaned up

3. **Timeout Hangs**
   - WebSocket calls could hang forever
   - Tests verify 5-second timeout works

## Continuous Integration

To run tests in CI:

```bash
# Prepare test database
RAILS_ENV=test bundle exec rails db:create db:migrate

# Run specs
bundle exec rspec

# Generate coverage report (if using SimpleCov)
bundle exec rspec --require spec_helper
open coverage/index.html
```

## Test Database

The test database schema is maintained automatically by:

```ruby
ActiveRecord::Migration.maintain_test_schema!
```

If migrations are pending, run:

```bash
RAILS_ENV=test bundle exec rails db:migrate
```

## Debugging Tests

```bash
# Run with binding.pry breakpoints
bundle exec rspec spec/models/display_pattern_spec.rb

# Show detailed failure output
bundle exec rspec --format documentation --backtrace

# Run only failed examples
bundle exec rspec --only-failures

# Profile slow tests
bundle exec rspec --profile
```
