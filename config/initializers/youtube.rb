# VideoInfo.provider_api_keys = {
  # youtube: Rails.application.credentials[Rails.env.to_sym][:YOUTUBE_API_KEY],
  # vimeo: Rails.application.credentials[Rails.env.to_sym][:VIMEO_API_KEY]
# }

Yt.configure do |config|
  config.api_key = Rails.application.credentials[Rails.env.to_sym][:YOUTUBE_API_KEY]
  config.log_level = :debug if Rails.env.development?
end
