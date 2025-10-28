require 'rails_helper'

RSpec.describe 'API::V1::Tags', type: :request do
  include_context 'API authentication'

  describe 'GET /api/v1/tags' do
    let!(:tag1) { create(:tag, name: 'Christmas') }
    let!(:tag2) { create(:tag, name: 'Halloween') }

    context 'without authentication' do
      it 'returns 401 unauthorized' do
        get '/api/v1/tags'
        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include('Access denied')
      end
    end

    context 'with invalid credentials' do
      it 'returns 401 unauthorized' do
        get '/api/v1/tags', headers: { 'Authorization' => ActionController::HttpAuthentication::Basic.encode_credentials('wrong', 'credentials') }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with valid authentication' do
      it 'returns a list of all tags' do
        get '/api/v1/tags', headers: auth_headers

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)

        expect(json).to be_an(Array)
        expect(json.length).to eq(2)

        tag_names = json.map { |t| t['name'] }
        expect(tag_names).to include('Christmas', 'Halloween')
      end

      it 'returns JSON format' do
        get '/api/v1/tags', headers: auth_headers
        expect(response.content_type).to match(/application\/json/)
      end
    end
  end

  describe 'GET /api/v1/tags/:id/activate_random' do
    let!(:tag) { create(:tag, :with_patterns, :with_displays) }

    context 'without authentication' do
      it 'returns 401 unauthorized' do
        get "/api/v1/tags/#{tag.id}/activate_random"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with valid authentication' do
      it 'activates a random resource from the tag' do
        # Mock the activate_random method to avoid WebSocket calls
        allow_any_instance_of(Tag).to receive(:activate_random).and_return(tag.patterns.first)

        get "/api/v1/tags/#{tag.id}/activate_random", headers: auth_headers

        expect(response).to have_http_status(:success)
      end

      it 'calls the activate_random method on the tag' do
        allow_any_instance_of(Tag).to receive(:activate_random).and_return(tag.patterns.first)
        expect_any_instance_of(Tag).to receive(:activate_random)

        get "/api/v1/tags/#{tag.id}/activate_random", headers: auth_headers
      end

      context 'with non-existent tag' do
        it 'returns 404 not found' do
          get '/api/v1/tags/99999/activate_random', headers: auth_headers
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe 'GET /api/v1/tags/:id/activate_random_display' do
    let!(:tag) { create(:tag, :with_displays) }

    context 'without authentication' do
      it 'returns 401 unauthorized' do
        get "/api/v1/tags/#{tag.id}/activate_random_display"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with valid authentication' do
      it 'activates a random display from the tag' do
        # Mock to avoid WebSocket calls
        allow_any_instance_of(Tag).to receive(:activate_random_display).and_return(tag.displays.first)

        get "/api/v1/tags/#{tag.id}/activate_random_display", headers: auth_headers

        expect(response).to have_http_status(:success)
      end

      it 'calls the activate_random_display method' do
        allow_any_instance_of(Tag).to receive(:activate_random_display).and_return(tag.displays.first)
        expect_any_instance_of(Tag).to receive(:activate_random_display)

        get "/api/v1/tags/#{tag.id}/activate_random_display", headers: auth_headers
      end

      context 'with non-existent tag' do
        it 'returns 404 not found' do
          get '/api/v1/tags/99999/activate_random_display', headers: auth_headers
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe 'GET /api/v1/tags/:id/activate_random_pattern' do
    let!(:tag) { create(:tag, :with_patterns) }
    let!(:default_zone_set) { create(:zone_set, :default, :with_zones) }

    context 'without authentication' do
      it 'returns 401 unauthorized' do
        get "/api/v1/tags/#{tag.id}/activate_random_pattern"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with valid authentication' do
      it 'activates a random pattern from the tag' do
        # Mock to avoid WebSocket calls
        allow_any_instance_of(Tag).to receive(:activate_random_pattern).and_return(tag.patterns.first)

        get "/api/v1/tags/#{tag.id}/activate_random_pattern", headers: auth_headers

        expect(response).to have_http_status(:success)
      end

      it 'calls the activate_random_pattern method' do
        allow_any_instance_of(Tag).to receive(:activate_random_pattern).and_return(tag.patterns.first)
        expect_any_instance_of(Tag).to receive(:activate_random_pattern)

        get "/api/v1/tags/#{tag.id}/activate_random_pattern", headers: auth_headers
      end

      context 'with non-existent tag' do
        it 'returns 404 not found' do
          get '/api/v1/tags/99999/activate_random_pattern', headers: auth_headers
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
