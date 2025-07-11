Rails.application.routes.draw do
  # API routes (no subdomain constraint for APIs)
  namespace :api do
    namespace :v1 do
      resources :document_extractions, only: [:create, :show] do
        member do
          get :status
        end
        collection do
          post :batch, to: 'document_extractions#batch_create'
        end
      end
    end
  end
  
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
    get "test_theme", to: "dashboard#test_theme", as: :test_theme

    resources :documents do
      member do
        patch :approve
        patch :reject
      end
      collection do
        get :bulk_upload
        post :bulk_create
        post :bulk_actions
        get :export
      end
      resources :comments, only: [:create, :update, :destroy]
    end
    
    resources :extraction_templates do
      member do
        post :duplicate
        post :test
        get :export
      end
      collection do
        post :import
        get :library
        post :install_from_library
      end
    end
    
    # API Key Management
    resource :api_key, only: [:show] do
      post :regenerate
    end
    
    # Team Management
    resources :team, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
      member do
        post :resend_invitation
      end
      collection do
        get :activity
        post :cancel_invitation
      end
    end
    
    # Team Invitations
    get 'invitations/:token', to: 'team#accept_invitation', as: :accept_invitation
    
    # Settings
    scope :settings do
      get '/', to: 'settings#index', as: :settings
      get 'profile', to: 'settings#profile', as: :profile_settings
      patch 'profile', to: 'settings#update_profile'
      get 'notifications', to: 'settings#notifications', as: :notifications_settings
      patch 'notifications', to: 'settings#update_notifications'
      get 'collaboration', to: 'settings#collaboration', as: :collaboration_settings
      patch 'collaboration', to: 'settings#update_collaboration'
      get 'api', to: 'settings#api', as: :api_settings
      post 'api/regenerate', to: 'settings#regenerate_api_token', as: :regenerate_api_token
      get 'organization', to: 'settings#tenant', as: :tenant_settings
      patch 'organization', to: 'settings#update_tenant'
      get 'billing', to: 'settings#billing', as: :billing_settings
      get 'integrations', to: 'settings#integrations', as: :integrations_settings
      patch 'integrations', to: 'settings#update_integrations'
      get 'security', to: 'settings#security', as: :security_settings
      patch 'security', to: 'settings#update_security'
    end
    
    # Webhooks
    resources :webhooks do
      member do
        post :test
        get :events
      end
    end
    
    # Document Queues
    resources :document_queues, only: [:index] do
      member do
        post :requeue
        patch :priority
      end
      collection do
        post :clear_stale
      end
    end
    
    # Claude Code AI features
    namespace :claude_code do
      get :api_builder
      get :test
      post :generate_template
      post :optimize_prompt
      post :generate_api
      post :analyze_quality
      post :generate_webhook
      post :generate_migration
    end
  end

  # Root domain routes (no subdomain or www)
  constraints subdomain: /^(www)?$/ do
    root "welcome#index"
    get "pricing", to: "welcome#pricing"
    get "features", to: "welcome#features"
    get "about", to: "welcome#about"
    
    # Add contact and other static pages
    get "contact", to: "pages#contact"
    get "privacy", to: "pages#privacy"
    get "terms", to: "pages#terms"
  end

  # Marketing pages
  get "help", to: "pages#help"
  get "blog", to: "pages#blog"
  get "careers", to: "pages#careers"
  get "press", to: "pages#press"
  get "contact", to: "pages#contact"
  get "partners", to: "pages#partners"
  get "security", to: "pages#security"
  get "privacy", to: "pages#privacy"
  get "terms", to: "pages#terms"
  get "cookies", to: "pages#cookies"
  get "gdpr", to: "pages#gdpr"
  get "status", to: "pages#status"

  # API and documentation
  get "api-docs", to: "docs#api"
  get "changelog", to: "docs#changelog"
  get "roadmap", to: "docs#roadmap"

  # Solution pages
  get "solutions/:industry", to: "solutions#show", as: :solution
  
  # Test route (available on all subdomains)
  get "test/theme", to: "test#theme"

end
