Rails.application.routes.draw do
  # Devise routes with custom controllers
  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions: "users/sessions"
  }

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Subdomain constraint for tenant-specific routes
  constraints subdomain: /^(?!www$)(?!$)/ do
    root "dashboard#index", as: :tenant_root
    get "dashboard", to: "dashboard#index", as: :dashboard

    # Future tenant-specific routes will go here
    # resources :documents
    # resources :templates
    # resources :team_members
  end

  # Root domain routes (no subdomain or www)
  constraints subdomain: /^(www)?$/ do
    root "welcome#index"
    get "pricing", to: "welcome#pricing"
    get "features", to: "welcome#features"
    get "about", to: "welcome#about"
  end
end
