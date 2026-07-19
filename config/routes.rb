Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post "users", to: "users#create"
      post "login", to: "sessions#create"
      delete "logout", to: "sessions#destroy"
      post "refresh", to: "auth#refresh"
      get "me", to: "auth#me"
      post "verify-phone", to: "auth#verify_phone"
      get "teams", to: "teams#index"
      get "liveness/:session_id/results", to: "liveness#results"

      namespace :frontend do
        post "face-poses/validate", to: "face_poses#validate"
        post "users", to: "users#create"
      end
    end

    namespace :admin do
      post "login", to: "sessions#create"
      delete "logout", to: "sessions#destroy"

      get "dashboard", to: "dashboard#index"

      resources :users, only: [:index, :show, :update, :destroy] do
        get :face_records, on: :member
      end
      resources :teams
      resources :point_actions
      resources :point_transactions, only: [:index]
      resources :audit_logs, only: [:index]
    end
  end

  get "up", to: proc { [200, {}, ["ok"]] }
end
