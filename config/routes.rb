Notable::Application.routes.draw do
  devise_for :users, :module => "users", :path => ''

  resources :notes
  resources :evernote
  resources :notebooks

  get "start" => "evernote#start"
  get "finish" => "evernote#finish"
  get "sync" => "evernote#sync"

  get "search" => "notes#search"

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
