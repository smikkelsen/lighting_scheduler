RSpec.shared_examples 'API authentication' do |method, path|
  context 'without authentication' do
    it 'returns 401 unauthorized' do
      send(method, path)
      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)['message']).to eq('Unauthorized')
    end
  end

  context 'with invalid credentials' do
    it 'returns 401 unauthorized' do
      send(method, path, headers: { 'Authorization' => ActionController::HttpAuthentication::Basic.encode_credentials('wrong', 'credentials') })
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'with valid credentials' do
    let(:auth_headers) do
      { 'Authorization' => ActionController::HttpAuthentication::Basic.encode_credentials(ENV['API_KEY'], ENV['API_TOKEN']) }
    end

    it 'allows access' do
      send(method, path, headers: auth_headers)
      expect(response).not_to have_http_status(:unauthorized)
    end
  end
end

RSpec.shared_context 'API authentication' do
  let(:api_key) { ENV['API_KEY'] || 'test_api_key' }
  let(:api_token) { ENV['API_TOKEN'] || 'test_api_token' }
  let(:auth_headers) do
    { 'Authorization' => ActionController::HttpAuthentication::Basic.encode_credentials(api_key, api_token) }
  end

  before do
    # Set ENV variables for tests
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('API_KEY').and_return(api_key)
    allow(ENV).to receive(:[]).with('API_TOKEN').and_return(api_token)
  end
end
