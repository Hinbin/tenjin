Rails.application.routes.draw do
  devise_for :admins
  get 'quizzes/new/:subject', to: 'quizzes#new'
  resources :quizzes, :classrooms, :permitted_schools
  resources :settings, as: 'user_settings'
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
  get 'leaderboard/(:subject)', to: 'leaderboard#show'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
