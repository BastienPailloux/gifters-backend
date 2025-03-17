Rails.application.routes.draw do
  # devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  namespace :api do
    namespace :v1, defaults: { format: :json } do
      devise_for :users,
                 controllers: {
                   sessions: 'api/v1/sessions',
                   registrations: 'api/v1/registrations'
                 },
                 path: '',
                 path_names: {
                   sign_in: 'login',
                   sign_out: 'logout',
                   registration: 'signup'
                 }

      resources :users, only: [:index, :show, :update, :destroy]

      resources :groups do
        resources :memberships
        resources :invitations, only: [:index, :create]
        member do
          delete 'leave'
        end
      end

      resources :gift_ideas do
        member do
          put 'mark_as_buying'
          put 'mark_as_bought'
        end
      end

      resources :invitations, only: [:show, :destroy], param: :token do
        collection do
          post 'accept'
        end
      end

      # Route pour récupérer les métadonnées d'une URL
      post 'metadata/fetch', to: 'metadata#fetch'
    end
  end

  root "home#index"
end
