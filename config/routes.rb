Rails.application.routes.draw do
  resources :displays, only: [:index, :activate]  do
    member do
      get 'activate'
    end
  end
end
