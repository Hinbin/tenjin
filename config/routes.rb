Rails.application.routes.draw do
  resources :quizzes
  devise_for :users
  get 'leaderboard', to: 'leaderboard_entry#show'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'quizzes#index'
end