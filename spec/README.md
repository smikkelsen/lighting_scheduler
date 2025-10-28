# RSpec Test Suite

This project uses RSpec for unit testing along with FactoryBot for test data and Shoulda Matchers for cleaner assertion syntax.

## Setup

Install the testing gems:

```bash
bundle install
```

Create and migrate the test database:

```bash
RAILS_ENV=test bin/rails db:create db:migrate
```

## Running Tests

Run all tests:

```bash
bundle exec rspec
```

Run specific test file:

```bash
bundle exec rspec spec/models/user_spec.rb
```

Run tests matching a pattern:

```bash
bundle exec rspec spec/models/
```

Run tests with documentation format:

```bash
bundle exec rspec --format documentation
```

## Test Coverage

The test suite covers:

### Models (spec/models/)
- **User**: Authentication, validations, Ransack configuration
- **Zone**: Associations, validations, scopes (current/in_set), UUID generation
- **ZoneSet**: Associations, validations, default zone set logic
- **Pattern**: Associations, full_path method, Ransack configuration
- **Tag**: Associations, activation methods
- **Display**: Associations, validations, workflow state, nested attributes
- **DisplayPattern**: JSONB zones storage, associations
- **DisplayTag**: Join model associations
- **PatternTag**: Join model associations

### API Request Specs (spec/requests/api/v1/)
- **Displays API**:
  - `GET /api/v1/displays` - List active displays
  - `GET /api/v1/displays/:id/activate` - Activate specific display
  - `GET /api/v1/displays/turn_off` - Turn off all displays
  - HTTP Basic authentication tests
  - Error handling (404, 401)

- **Tags API**:
  - `GET /api/v1/tags` - List all tags
  - `GET /api/v1/tags/:id/activate_random` - Activate random pattern or display
  - `GET /api/v1/tags/:id/activate_random_display` - Activate random display
  - `GET /api/v1/tags/:id/activate_random_pattern` - Activate random pattern
  - HTTP Basic authentication tests
  - Error handling (404, 401)

### Factories (spec/factories/)
All models have corresponding factories with traits for different scenarios:
- Default factories for basic object creation
- Traits for specific states (`:default`, `:custom`, `:with_tags`, etc.)
- Nested object creation support

### Shared Examples (spec/support/)
- **API Authentication**: Reusable authentication tests for all API endpoints

## Testing Patterns

### Associations
```ruby
it { should belong_to(:zone_set) }
it { should have_many(:patterns).through(:display_patterns) }
```

### Validations
```ruby
it { should validate_presence_of(:name) }
it { should validate_uniqueness_of(:name).case_insensitive }
```

### Scopes
```ruby
describe '.active' do
  it 'returns only active displays' do
    active = create(:display, workflow_state: 'active')
    expect(Display.active).to include(active)
  end
end
```

### Instance Methods
```ruby
describe '#full_path' do
  it 'combines folder and name' do
    pattern = build(:pattern, folder: 'Halloween', name: 'Spooky')
    expect(pattern.full_path).to eq('Halloween/Spooky')
  end
end
```

### API Request Specs
```ruby
describe 'GET /api/v1/displays' do
  include_context 'API authentication'

  it 'returns active displays with valid auth' do
    display = create(:display, workflow_state: 'active')
    get '/api/v1/displays', headers: auth_headers

    expect(response).to have_http_status(:success)
    json = JSON.parse(response.body)
    expect(json.first['id']).to eq(display.id)
  end

  it 'returns 401 without auth' do
    get '/api/v1/displays'
    expect(response).to have_http_status(:unauthorized)
  end
end
```

## Gems Used

- **rspec-rails**: Rails integration for RSpec
- **factory_bot_rails**: Test data generation
- **faker**: Realistic fake data
- **shoulda-matchers**: Cleaner test syntax for common Rails patterns

## Tips

1. Use `build` instead of `create` when you don't need database persistence
2. Use factories with traits to create specific test scenarios
3. Test associations, validations, scopes, and important business logic
4. Keep tests focused and readable
5. Use `let` and `let!` for test data setup
