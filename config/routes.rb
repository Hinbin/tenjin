# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :admins
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
  
  resources :quizzes
  resources :schools do
    member do
      patch 'reset_all_passwords'
      patch 'sync'
    end
  end
  resources :leaderboard, only:[:show, :index]
  resources :classrooms, only: [:show, :index, :update]
  resources :questions do
    collection do
      get 'topic_questions' 
      get 'flagged_questions'     
    end
    member do
      patch 'reset_flags'
    end
  end
  resources :answers
  resources :topics
  resources :homeworks
  resources :users, only:[:show, :index, :update] do
      member do
        patch 'set_role'
        delete 'remove_role'
        patch 'reset_password'
      end
      collection do
        get 'manage_roles'
      end
  end
  resources :admins, only:[:show] do
    member do
      post 'become'
    end
  end

  resources :flagged_questions, only:[:create]
  resources :school_groups
  resources :lessons

  get 'quizzes/new/:subject', to: 'quizzes#new'
  get 'dashboard/', to: 'dashboard#show'
  get 'customise/', to: 'customise#show'
  post 'customise/', to: 'customise#update'
  get "/pages/*id" => 'pages#show', as: :page, format: false

  authenticated :user do
    root to: 'dashboard#show', as: :authenticated_root
  end

  # if routing the root path, update for your controller
  root to: 'pages#show', id: 'home'
end
