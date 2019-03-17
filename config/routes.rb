Rails.application.routes.draw do
  devise_for :admins
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
  
  resources :quizzes, :schools
  resources :subject_maps, only: [:update]
  resources :leaderboard, only:[:show, :index]
  get 'quizzes/new/:subject', to: 'quizzes#new'
  get 'dashboard/', to: 'dashboard#show'
  get 'customise/', to: 'customise#show'
  get "/pages/*id" => 'pages#show', as: :page, format: false

  authenticated :user do
    root to: 'dashboard#show', as: :authenticated_root
  end

  # if routing the root path, update for your controller
  root to: 'pages#show', id: 'home'
end
