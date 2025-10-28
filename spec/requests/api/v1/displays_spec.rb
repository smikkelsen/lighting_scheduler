require 'rails_helper'

RSpec.describe 'API::V1::Displays', type: :request do
  include_context 'API authentication'

  describe 'GET /api/v1/displays' do
    let!(:active_display) { create(:display, workflow_state: 'active') }
    let!(:inactive_display) { create(:display, workflow_state: 'inactive') }

    context 'without authentication' do
      it 'returns 401 unauthorized' do
        get '/api/v1/displays'
        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include('Access denied')
      end
    end

    context 'with invalid credentials' do
      it 'returns 401 unauthorized' do
        get '/api/v1/displays', headers: { 'Authorization' => ActionController::HttpAuthentication::Basic.encode_credentials('wrong', 'credentials') }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with valid authentication' do
      it 'returns a list of active displays' do
        get '/api/v1/displays', headers: auth_headers

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)

        expect(json).to be_an(Array)
        expect(json.length).to eq(1)
        expect(json.first['id']).to eq(active_display.id)
        expect(json.first['name']).to eq(active_display.name)
      end

      it 'does not include inactive displays' do
        get '/api/v1/displays', headers: auth_headers

        json = JSON.parse(response.body)
        display_ids = json.map { |d| d['id'] }

        expect(display_ids).to include(active_display.id)
        expect(display_ids).not_to include(inactive_display.id)
      end

      it 'returns JSON format' do
        get '/api/v1/displays', headers: auth_headers
        expect(response.content_type).to match(/application\/json/)
      end
    end
  end

  describe 'GET /api/v1/displays/:id/activate' do
    let!(:display) { create(:display, :with_patterns) }

    context 'without authentication' do
      it 'returns 401 unauthorized' do
        get "/api/v1/displays/#{display.id}/activate"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with valid authentication' do
      it 'activates the display' do
        # Mock the activate method to avoid WebSocket calls in tests
        allow_any_instance_of(Display).to receive(:activate).and_return(true)

        get "/api/v1/displays/#{display.id}/activate", headers: auth_headers

        expect(response).to have_http_status(:success)
      end

      it 'calls the activate method on the display' do
        expect_any_instance_of(Display).to receive(:activate)

        get "/api/v1/displays/#{display.id}/activate", headers: auth_headers
      end

      context 'with non-existent display' do
        it 'returns 404 not found' do
          get '/api/v1/displays/99999/activate', headers: auth_headers
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe 'GET /api/v1/displays/turn_off' do
    context 'without authentication' do
      it 'returns 401 unauthorized' do
        get '/api/v1/displays/turn_off'
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with valid authentication' do
      it 'turns off all displays' do
        # Mock the turn_off class method to avoid WebSocket calls
        allow(Display).to receive(:turn_off).and_return(true)

        get '/api/v1/displays/turn_off', headers: auth_headers

        expect(response).to have_http_status(:success)
      end

      it 'calls Display.turn_off' do
        expect(Display).to receive(:turn_off)

        get '/api/v1/displays/turn_off', headers: auth_headers
      end
    end
  end
end
