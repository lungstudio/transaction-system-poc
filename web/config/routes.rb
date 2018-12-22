Rails.application.routes.draw do
  post 'transactions/reset_all' => 'transactions#reset_all', as: :reset_all
  post 'transactions/toggle_producer' => 'transactions#toggle_producer', as: :toggle_producer
  post 'transactions/start_all_producers' => 'transactions#start_all_producers', as: :start_all_producers
  post 'transactions/stop_all_producers' => 'transactions#stop_all_producers', as: :stop_all_producers
  resources :transactions, only: [:index]
end
