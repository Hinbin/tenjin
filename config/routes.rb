Rails.application.routes.draw do
  resources :subjects
  resources :quizzes
  devise_for :users


  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: "quizzes#index"
end
