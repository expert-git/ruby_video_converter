# require "sidekiq/web"

Rails.application.routes.draw do

  # if Rails.env.production?
  #   Sidekiq::Web.use Rack::Auth::Basic do |username, password|
  #     ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(username), ::Digest::SHA256.hexdigest(ENV["SIDEKIQ_USERNAME"])) &
  #     ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(password), ::Digest::SHA256.hexdigest(ENV["SIDEKIQ_PASSWORD"]))
  #   end
  # end

  # mount Sidekiq::Web => "/sidekiq"
  mount ForestLiana::Engine => "/forest"
  root "pages#homepage"

  get "/robots.:format" => "pages#robots"
  get "about", to: "pages#about"
  # get "blog", to: "pages#blog"
  get "faq", to: "pages#faq"
  get "terms", to: "pages#terms"
  get "privacy", to: "pages#privacy"
  get "dmca", to: "pages#dmca"

  resources "contact_forms", only: [:new, :create], path: "contact", path_names: { new: "" }

  devise_for  :members,
              path: "",
              path_names: {sign_up: "signup", sign_in: "login", sign_out: "logout", edit: "profile"},
              controllers: { omniauth_callbacks: "omniauth_callbacks", registrations: "registrations", sessions: "sessions" }

  # memberships
  mount Payola::Engine => "/payola", as: :payola
  get "membership/new", to: "memberships#new", as: :new_membership
  get "membership/new/special", to: "memberships#new_special", as: :new_membership_special
  get "membership", to: "memberships#subscriptions", as: :subscriptions
  get "thanks", to: "memberships#thanks", as: :thanks
  # resources :memberships, except: [:new]

  # resources :subscriptions

  # videos
  get "videos/search", to: "videos#search", as: :videos_search
  get "videos/videos", to: "videos#video", as: :video
  get "videos/convert", to: "videos#convert", as: :convert_video
  get "videos/download_history", to: "videos#download_history", as: :download_history
  get "videos/download", to: "videos#download", as: :download_video
  get "videos/delay_download", to: "videos#delay_download", as: :delay_download
  get "videos/:title", to: "videos#video", as: :video_title
  get "videos/:converted_video_id/dispatch_download_file", to: "videos#dispatch_download_file", as: :dispatch_download_file

end
