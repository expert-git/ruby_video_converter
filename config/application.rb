# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module GetAudioFromVideoRails
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    config.autoload_paths += Dir["#{config.root}/app/services/**/"]

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.active_job.queue_adapter = if Rails.env.production?
                                        # config.active_job.queue_adapter = :sidekiq
                                        :active_elastic_job
                                      else
                                        :async
                                      end

    config.exception_handler = {
      dev: nil, # => default "nil" => to "false" for dev mode
      db: nil, # => default "nil" => to :errors if true, else use "table_name" / :table_name
      email: nil, # => requires string email and ActionMailer
      social: {
        facebook: nil,
        twitter: nil,
        youtube: nil,
        linkedin: nil,
        fusion: nil
      },
      exceptions: {
        all: { layout: nil }, # -> this will inherit from ApplicationController's layout
        # => 4xx errors should be nil
        400 => { layout: 'exception' },
        401 => { layout: 'exception' },
        402 => { layout: 'exception' },
        403 => { layout: 'exception' },
        404 => { layout: 'exception' },
        405 => { layout: 'exception' },
        407 => { layout: 'exception' },
        410 => { layout: 'exception' },
        # => 5xx errors should be "exception" but can be nil if explicitly defined
        500 => { layout: 'exception' },
        501 => { layout: 'exception' },
        502 => { layout: 'exception' },
        503 => { layout: 'exception' },
        504 => { layout: 'exception' },
        505 => { layout: 'exception' },
        507 => { layout: 'exception' },
        510 => { layout: 'exception' }
      }
    }

    config.generators do |g|
      g.test_framework :rspec
      g.template_engine :slim
    end

    config.action_mailer.preview_path = "#{Rails.root}/spec/mailers/previews"

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
