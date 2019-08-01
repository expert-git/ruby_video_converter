# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "#{ENV['RAILS_FORCE_SSL'].present? ? 'https' : 'http'}://#{Rails.application.credentials[Rails.env.to_sym][:HTTP_HOST]}"

SitemapGenerator::Sitemap.create do
  # Put links creation logic here.
  #
  # The root path '/' and sitemap index file are added automatically for you.
  # Links are added to the Sitemap in the order they are specified.
  #
  # Usage: add(path, options={})
  #        (default options are used if you don't specify)
  #
  # Defaults: :priority => 0.5, :changefreq => 'weekly',
  #           :lastmod => Time.now, :host => default_host
  #
  # Examples:
  #
  # Add '/articles'
  #
  #   add articles_path, :priority => 0.7, :changefreq => 'daily'
  #
  # Add all articles:
  #
  #   Article.find_each do |article|
  #     add article_path(article), :lastmod => article.updated_at
  #   end

  add about_path
  add faq_path
  add terms_path
  add privacy_path
  add dmca_path
  add new_contact_form_path
  add new_member_session_path
  add new_member_password_path
  add new_member_registration_path
  add new_member_confirmation_path
  add new_membership_path

end
