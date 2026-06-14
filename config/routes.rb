# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :admins, controllers: {invitations: "system/invitations"}
  devise_for :users, controllers: {omniauth_callbacks: "users/omniauth_callbacks"}

  namespace :system do
    resources :school_groups
    resources :subjects
    resources :customisations, except: %i[show destroy]
    resources :schools do
      collection do
        get :stats
      end
      member do
        patch :sync
      end
    end
    resources :admins, only: [:show] do
      member do
        post :become
        post :reset_year
      end
    end
    resources :users, only: [] do
      collection do
        get :manage_roles
      end
      member do
        patch :set_role
        delete :remove_role
        patch :update_email
        post :send_welcome_email
      end
    end
  end

  resources :quizzes
  resources :schools, only: [] do
    member do
      patch :sync
      patch :reset_all_passwords
    end
  end
  resources :leaderboard, only: %i[show index]
  resources :classrooms, only: %i[show index update]
  resources :questions do
    collection do
      get "topic"
      get "lesson"
      get "download_topic"
      get "import_topic"
      get "flagged_questions"
      post "import"
    end
    member do
      patch "reset_flags"
    end
  end
  resources :answers
  resources :topics
  resources :homeworks
  resources :users, only: %i[show index update] do
    member do
      patch "reset_password"
      delete "unlink_oauth_account"
    end
  end
  resources :flagged_questions, only: [:create]
  resources :lessons
  resources :customisations, only: [] do
    collection do
      get "show_available"
    end
    member do
      post "buy"
    end
  end

  get "quizzes/new/:subject", to: "quizzes#new"
  get "dashboard/", to: "dashboard#show"

  get "/pages/*id", to: "pages#show", as: :page, format: false

  authenticated :user do
    root to: "dashboard#show", as: :authenticated_root
  end

  # if routing the root path, update for your controller
  root to: "pages#show", id: "home"
end
