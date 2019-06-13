Rails.application.routes.draw do
  devise_for :admins
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
  
  resources :quizzes, :schools
  resources :subject_maps, only: [:update]
  resources :leaderboard, only:[:show, :index]
  resources :classrooms, only: [:show]
  resources :questions
  resources :answers
  resources :topics
  resources :homeworks
  resources :users, only:[:show, :index, :update]

  get 'quizzes/new/:subject', to: 'quizzes#new'
  get 'dashboard/', to: 'dashboard#show'
  get 'customise/', to: 'customise#show'
  post 'customise/', to: 'customise#update'
  get "/pages/*id" => 'pages#show', as: :page, format: false

  authenticated :user do
    root to: 'dashboard#show', as: :authenticated_root
  end

  authenticate :admin, -> (admin) { admin.super? } do
    mount PgHero::Engine, at: "pghero"
  end

  # if routing the root path, update for your controller
  root to: 'pages#show', id: 'home'
end
