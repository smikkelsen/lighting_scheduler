# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Rails 7.2 application (Ruby 3.3.10) for managing and controlling holiday/decorative lighting displays. It interfaces with a Jellyfish Lighting controller via WebSocket to control patterns, zones, and lighting displays. The application provides both a web UI (via ActiveAdmin) and a REST API for programmatic control.

## Core Architecture

### Hardware Integration Layer
- **WebsocketMessageHandler** (`app/lib/websocket_message_handler.rb`): Core communication module that sends JSON commands to the Jellyfish controller via WebSocket on port 9000
- Controller IP configured via `WEBSOCKET_CONTROLLER_IP` environment variable
- All hardware communication uses EventMachine for async WebSocket connections

### Domain Model Hierarchy

**Pattern**: Individual lighting animations/effects stored on the controller
- Cached from controller's `patternFileList`
- Can be organized in folders (e.g., 'Halloween')
- Has JSON pattern data that can be cached locally
- Can be activated on specific zones or `:all` zones

**Zone**: Physical lighting segments (e.g., "Front Peak", "Garage")
- Defined by `pixel_count` and `port_map` (hardware configuration)
- UUID generated from hardware config for stable identity across renames
- "Current zones" are those actively loaded in the controller (where `zone_set_id` is nil)
- Zones in a ZoneSet have a `zone_set_id`

**ZoneSet**: Saved configurations of zones
- Allows different zone arrangements for different display types
- Can be marked as `default_zone_set` (used when activating patterns via tags)
- Activating a ZoneSet overwrites controller's zone configuration

**Display**: A complete lighting scene
- Combines a ZoneSet with one or more Patterns mapped to specific zones via DisplayPattern join model
- Multiple patterns can run simultaneously on different zones
- Each DisplayPattern specifies which zones its pattern should activate on

**Tag**: Category system for organizing Patterns and Displays
- Used for seasonal grouping (e.g., 'July', 'Christmas')
- Supports random activation from tagged items

### ZoneHelper Concern
Shared module (`app/models/concerns/zone_helper.rb`) used by Pattern, Display, and Zone models:
- `parameterize_zones(zones)`: Converts various zone representations (`:all`, `:default`, IDs, names, UUIDs, Zone objects) into zone name arrays
- `turn_off(zones)`: Sends state: 0 command to controller
- `uuid_from_attributes`: Generates deterministic UUID from zone's hardware config

### Activation Flow

**Pattern activation**:
```ruby
pattern.activate(:all)  # Activates on all current zones
pattern.activate([zone1, zone2])  # Activates on specific zones
```

**Display activation** (`Display#activate`):
1. Turn off all zones
2. Sleep 0.6s
3. Activate the Display's ZoneSet (loads zones into controller)
4. Sleep 0.6s
5. Activate each pattern on its configured zones

**Tag-based random activation**:
- `tag.activate_random_pattern`: Activates default ZoneSet, then random pattern from tag on `:all` zones
- `tag.activate_random_display`: Activates random display (which handles its own ZoneSet)
- `tag.activate_random`: Chooses randomly from both patterns and displays

## Environment Configuration

Create `.env.development.local` (gitignored) with:
- `WEBSOCKET_CONTROLLER_IP`: IP address of Jellyfish controller
- `API_KEY`: HTTP Basic auth username for API endpoints
- `API_TOKEN`: HTTP Basic auth password for API endpoints

## Database Commands

```bash
# Setup database
bin/rails db:create db:migrate db:seed

# Run migrations
bin/rails db:migrate

# Seed creates default admin user in development:
# Email: admin@example.com
# Password: password
```

## Server Commands

```bash
# Start Rails server (with CSS compilation via dartsass)
bin/dev

# Or start Rails server only
bundle exec rails server

# Start console
bundle exec rails console

# Access ActiveAdmin UI
# Navigate to http://localhost:3000 and login with seeded credentials
```

## Syncing with Controller

The controller is the source of truth for Patterns and Zones. Sync them periodically:

```ruby
# Sync patterns from controller
Pattern.update_cached  # Creates/updates pattern records
Pattern.cache_pattern_data  # Downloads full JSON data for each pattern

# Sync zones from controller
Zone.update_cached  # Updates current zones, deletes removed ones
```

Before syncing zones, save current zone configuration if needed:
```ruby
ZoneSet.create_from_current('My Current Setup')
```

## API Endpoints

All API endpoints use HTTP Basic Authentication with `API_KEY`/`API_TOKEN`.

**Displays**:
- `GET /api/v1/displays` - List all displays
- `GET /api/v1/displays/:id/activate` - Activate specific display
- `GET /api/v1/displays/turn_off` - Turn off all lights

**Tags**:
- `GET /api/v1/tags` - List all tags
- `GET /api/v1/tags/:id/activate_random` - Random pattern or display from tag
- `GET /api/v1/tags/:id/activate_random_display` - Random display from tag
- `GET /api/v1/tags/:id/activate_random_pattern` - Random pattern from tag

## Important Implementation Notes

- All Display and Pattern activations include `sleep(0.6)` delays between operations to allow controller processing time
- Zone UUIDs are deterministic hashes of `pixel_count` + `port_map`, allowing zones to be renamed without losing identity
- "Current zones" (`Zone.current`) are the live zones in the controller; zones in ZoneSets are snapshots
- Only one ZoneSet can be marked as `default_zone_set` at a time (enforced by `after_save` callback)
- When a Display is deleted, its ZoneSet cannot have any other Displays referencing it (`dependent: :restrict_with_exception`)