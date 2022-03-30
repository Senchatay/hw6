Rails.application.routes.draw do
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
end
