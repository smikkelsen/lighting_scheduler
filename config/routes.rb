Rails.application.routes.draw do
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
      get 'activate_random_display'
    end
  end
end
