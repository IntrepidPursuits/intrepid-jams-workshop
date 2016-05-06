Rails.application.routes.draw do
  # get '/games' => 'games#index'
  resources :games, only: [:index]
end
