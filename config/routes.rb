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
                   registrations: 'api/v1/registrations',
                   passwords: 'api/v1/passwords'
                 },
                 path: '',
                 path_names: {
                   sign_in: 'login',
                   sign_out: 'logout',
                   registration: 'signup',
                   password: 'password'
                 }

      resources :users, only: [:index, :show, :update, :destroy] do
        collection do
          get :shared_users
        end
        member do
          patch :update_locale
        end
      end

      resources :children, only: [:index, :show, :create, :update, :destroy]

      resources :groups do
        resources :memberships
        resources :invitations, only: [:index, :create] do
          collection do
            post :send_email
          end
        end
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

      # Route pour envoyer un message via le formulaire de contact
      post 'contact', to: 'contacts#create'

      # Route pour s'abonner à la newsletter via Brevo
      post 'newsletter/subscribe', to: 'newsletter_subscriptions#create'

      # Route pour se désabonner de la newsletter
      delete 'newsletter/unsubscribe', to: 'newsletter_subscriptions#destroy'
    end
  end

  root "home#index"
end
