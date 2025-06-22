Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # API routes
  namespace :api do
    resources :sleep_records, only: [] do
      collection do
        post :clock_in
        post :clock_out
        get :feeds
        get :clock_in_history
      end
    end

    # Follow/unfollow routes
    resources :users, only: [], param: :other_user_id do
      member do
        post "follow", to: "followerships#create", as: :follow
        delete "unfollow", to: "followerships#destroy", as: :unfollow
      end
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"

  if Rails.env.development?
    mount Rswag::Ui::Engine => "/api-docs"
  end
end
