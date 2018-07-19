Rails.application.routes.draw do
  get 'quizzes/new/:subject', to: 'quizzes#new'
  resources :quizzes
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
  get 'leaderboard/(:subject)', to: 'leaderboard#show'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'quizzes#index'
end
