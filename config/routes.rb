Rails.application.routes.draw do
  resources :users
  root "orders#calc"

  resources :orders

  get "hello/index"
  
  resources :orders do
    member do
      get "approve"
    end
  end
  resources :orders do
    get "last", on: :collection
  end
  resource :login, only: [:show, :create, :destroy]
 
end
