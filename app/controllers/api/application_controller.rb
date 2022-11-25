class API::ApplicationController < ActionController::Base
  before_action :authenticate_user_with_token

  private

  def authenticate_user_with_token
    authenticate_or_request_with_http_basic do |api_key, api_token|
      if ActiveSupport::SecurityUtils.secure_compare(api_key, ENV['API_KEY']) &&
        ActiveSupport::SecurityUtils.secure_compare(api_token, ENV['API_TOKEN'])
        return true
      else
        sleep 2
        handle_bad_authentication
      end
    end
  end

  def handle_bad_authentication
    render json: { message: "Unauthorized" }, status: :unauthorized
  end

end
