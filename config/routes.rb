# frozen_string_literal: true

Rails.application.routes.draw do
  get '/.well-known/appspecific/com.chrome.devtools.json', to: proc { [204, {}, ['']] }

  # Lightweight health check for the platform load balancer (Render, etc.)
  get 'up' => 'rails/health#show', as: :rails_health_check

  devise_for :admins, controllers: { invitations: 'admins/invitations' }
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
  
  
  resources :quizzes
  resources :schools do
    collection do
      get 'show_stats'
    end
    member do
      patch 'reset_all_passwords'
      patch 'sync'
    end
  end
  resources :leaderboard, only:[:show, :index]
  resources :classrooms, only: [:show, :index, :update] do
    collection do
      get 'gap_analysis'
    end
    member do
      get 'gaps'
      get 'gaps/student/:student_id', to: 'classrooms#student_gap', as: :student_gap
    end
  end
  resources :questions do
    collection do
      get 'topic' 
      get 'lesson' 
      get 'download_topic'
      get 'import_topic'
      post 'import'    
    end
    member do
      patch 'reset_flags'
    end
  end
  resources :answers
  resources :app_errors, only: %i[index show]
  resources :topics do
    member do
      patch 'archive'
    end
    collection do
      get 'flagged_questions' 
    end
  end
  resources :subjects
  resources :homeworks
  resources :users, only:[:show, :index, :update] do
      member do
        patch 'set_role'
        patch 'reset_password'
        patch 'update_email'
        post 'send_welcome_email'
        post 'remove_role'
        delete 'unlink_oauth_account'
      end
      collection do
        get 'manage_roles'
      end
  end
  resources :admins, only:[:show, :destroy] do
    member do
      post 'become'
      post 'reset_password'
      post 'reset_year'
    end
  end

  resources :flagged_questions, only:[:create]
  resources :school_groups
  resources :lessons
  resources :customisations, only: [] do
    collection do
      get 'show_available'
      post 'toggle_mode'
      delete 'preview', action: :stop_preview, as: :stop_preview
    end
    member do
      post 'buy'
      post 'equip'
      post 'preview'
    end
  end

  get 'quizzes/new/:subject', to: 'quizzes#new'
  resource :settings, only: %i[show update]
  get 'dashboard/', to: 'dashboard#show'

  # Dev-only skin styleguide (Plan 01, Phase 0). Blocked in production by the controller.
  get 'styleguide', to: 'styleguide#show' unless Rails.env.production?

  # Shareable clean URL for the teacher-facing marketing page (renders pages/teachers).
  get '/for-teachers', to: 'pages#show', id: 'teachers', as: :for_teachers

  get "/pages/*id" => 'pages#show', as: :page, format: false

  authenticated :user do
    root to: 'dashboard#show', as: :authenticated_root
  end

  # if routing the root path, update for your controller
  root to: 'pages#show', id: 'home'
end
