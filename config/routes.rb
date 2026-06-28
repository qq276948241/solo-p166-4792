Rails.application.routes.draw do
  post "auth/register", to: "auth#register"
  post "auth/login", to: "auth#login"
  get "auth/me", to: "auth#me"
  put "auth/profile", to: "auth#update_profile"

  resources :addresses, only: [:index, :show, :create, :update, :destroy] do
    member do
      post :set_default
    end
  end

  get "wallet", to: "wallets#show"
  post "wallet/recharge", to: "wallets#recharge"
  get "wallet/transactions", to: "wallets#transactions"

  resources :subscriptions, only: [:index, :show, :create, :update, :destroy] do
    member do
      post :pause
      post :resume
      post :cancel
      post :skip_week
      post :unskip_week
      get :skip_weeks_list
    end
  end

  resources :vegetables, only: [:index, :show, :create, :update, :destroy]

  resources :weekly_boxes, only: [:index, :show, :create, :update, :destroy] do
    collection do
      get :upcoming
      get :current
      post :check_lock
    end
    member do
      get :items
      post :add_item
      put :update_item
      delete :remove_item
      post :lock
    end
  end

  resources :orders, only: [:index, :show] do
    collection do
      get :admin_index
    end
    member do
      get :items
      post :sign
      post :cancel
      post :swap_vegetable
      post :update_tracking
    end
  end

  scope :admin do
    get "dashboard", to: "admin#dashboard"
    get "users", to: "admin#users"
    post "users/:user_id/recharge", to: "admin#manual_recharge"
  end
end
