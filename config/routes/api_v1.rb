namespace :api do
  namespace :v1 do
    devise_for :users, only: [:sessions, :registrations]
    resources :users
    resources :admin_users
    resources :jwt_blacklists, only: [:index, :show, :create, :destroy]
  end
end
