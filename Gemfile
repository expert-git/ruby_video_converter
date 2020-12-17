# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby ENV['RUBY_VERSION'] || '2.5.3'
gem 'coffee-rails', '~> 4.2'
gem 'jbuilder', '~> 2.7'
gem 'jquery-rails'
gem 'pg', '~> 1.1.4'
gem 'puma', '~> 3.11'
gem 'rails', '~> 5.2.3'
gem 'sass-rails', '~> 5.0'
gem 'turbolinks', '~> 5'
gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'mini_racer', platforms: :ruby

# Template customization
gem 'html2slim'
gem 'nokogiri'
gem 'slim-rails'

# Frontend
gem 'bootstrap', '~> 4.3.1'
gem 'exception_handler', '~> 0.8.0.0'
gem 'font-awesome-rails'
gem 'will_paginate-bootstrap4'

# User authentication
gem 'devise', '~> 4.7.1'
# gem "devise-async"
gem 'gravatarify', '~> 3.1.1'
gem 'mailgun-ruby', '~>1.1.11'
gem 'omniauth-facebook', '~> 5.0'
gem 'omniauth-google-oauth2', '~> 0.7.0'
gem 'omniauth-rails_csrf_protection'
gem 'premailer-rails'
gem 'recaptcha', require: 'recaptcha/rails'

# Permissions
gem 'pundit'

# Youtube API to search/display videos
gem 'yt', '~> 0.32.4'
gem 'yt-url', '~> 1.0.0'

# Youtube video downloads
gem 'carrierwave'
gem 'youtube-dl.rb', github: 'valdemarua/youtube-dl.rb'

# Payments
gem 'payola-payments', github: 'payolapayments/payola'

# Servers
gem 'foreman', require: false

# Background processing
# gem "sidekiq"
gem 'active_elastic_job'
gem 'carrierwave-aws'
gem 'evercookie', path: 'vendor/gems/evercookie'
gem 'faraday'
gem 'faraday_middleware'
gem 'friendly_id', '~> 5.2.4'
gem 'gon'
gem 'streamio-ffmpeg'

# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 4.0'

# Contact us form
gem 'gibbon'
gem 'mail_form'

# Admin dashboard
gem 'forest_liana'
gem 'newrelic_rpm'

# Exception tracking
gem 'rollbar'

# AWS
gem 'aws-sdk'

# Sitemap generator
gem 'sitemap_generator', require: false

# Github security issues
gem 'ffi', '>= 1.11.1'
gem 'loofah', '>= 2.2.3'
gem 'rack', '>= 2.0.7'
gem 'rubyzip', '>= 1.2.3'

# Use ActiveModel has_secure_password
# gem "bcrypt", "~> 3.1.7"

# Use Capistrano for deployment
# gem "capistrano-rails", group: :development

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

group :development, :test do
  gem 'rails_real_favicon'
  # gem "mailcatcher"  # Don't uncomment, instead run 'gem install mailcatcher' in terminal
  gem 'pry-rails'
  gem 'scout_apm'
  gem 'ultrahook'
  # gem "pry-byebug"
  gem 'awesome_print', require: 'awesome_print'
  gem 'better_errors'
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'capybara', '>= 2.15'
  gem 'faker'
  gem 'rack-mini-profiler'
  gem 'selenium-webdriver'
  gem 'table_print', require: 'table_print'
end

group :test do
  # gem "therubyracer"
  gem 'database_cleaner'
  gem 'email_spec'
  gem 'factory_bot_rails'
  gem 'geckodriver-helper'
  gem 'rspec-rails', '~> 3.6'
  gem 'simplecov', require: false
  gem 'stripe-ruby-mock', '~> 2.5.8', require: 'stripe_mock'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'web-console', '>= 3.3.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
