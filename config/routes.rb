Notable::Application.routes.draw do
  devise_for :users, :module => "users", :path => ''

  resources :notes
  resources :notebooks

	devise_scope :user do
		get "active_user" => "users/sessions#index"
    put "active_user/:id" => "users/sessions#update"
	end

  get "connect" => "evernote#connect"
  get "finish" => "evernote#finish"
  get "search" => "notes#search"

  get "sync" => "evernote#begin_sync_data"
  post "sync" => "evernote#send_sync_data"

  UpgradeController.action_methods.each do |action|
    get "/#{action}", to: "upgrade##{action}", as: "#{action}_page"
  end

  match ':action' => 'pages#:action'

  root :to => 'scaffold#index'

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

end
