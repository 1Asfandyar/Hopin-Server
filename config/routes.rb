Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config

  ActiveAdmin.application.load!
  admin_resources = ActiveAdmin.application.namespaces[:admin].resources
  comment_resource = admin_resources[ActiveAdmin::Comment] if defined?(ActiveAdmin::Comment)
  admin_resources.instance_variable_get(:@collection).delete(comment_resource.resource_name) if comment_resource
  ActiveAdmin::Router.new(router: self, namespaces: ActiveAdmin.application.namespaces).apply

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  root to: redirect("/admin")
end
