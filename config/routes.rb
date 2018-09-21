Rails.application.routes.draw do
  devise_for :agents
  devise_for :merchants
  devise_for :partners
  devise_for :resellers
  devise_for :officers
  devise_for :users
  devise_for :administrators
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'home#index'
end
