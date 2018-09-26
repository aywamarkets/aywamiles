Rails.application.routes.draw do
  devise_for :administrators
  devise_for :partners

  root :to => 'home#index'
  namespace :administrators do
    root :to => 'home#index'
    resources :administrators, :only => [:new, :create, :index]
    resources :partner_organizations
    resources :partners
  end

  namespace :partners do
  end
end
