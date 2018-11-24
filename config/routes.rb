Rails.application.routes.draw do
  devise_for :admins
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
  
  resources :quizzes, :schools
  resources :subject_maps, only: [:update]
  get 'quizzes/new/:subject', to: 'quizzes#new'
  get 'leaderboard/(:subject)', to: 'leaderboard#show'
end
