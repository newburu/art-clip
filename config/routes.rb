Rails.application.routes.draw do
  resources :events do
    collection do
      get :fetch_ogp
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  get "/auth/:provider/callback", to: "sessions#create"
  get "/auth/failure", to: redirect("/")
  delete "/signout", to: "sessions#destroy", as: "signout"

  root "events#index"

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
