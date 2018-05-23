Rails.application.routes.draw do
  devise_for :users

  resources :questions

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: "questions#index"
end
