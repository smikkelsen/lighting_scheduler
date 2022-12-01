Rails.application.routes.draw do
  devise_for :users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  # resources :patterns, only: [] do
  #   get 'update_cached'
  # end

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :displays, only: [:index] do
        collection do
          get 'turn_off'
        end
        member do
          get 'activate'
        end
      end

      resources :tags, only: [:index] do
        member do
          get 'activate_random'
          get 'activate_random_display'
          get 'activate_random_pattern'
        end
      end
    end
  end

end
