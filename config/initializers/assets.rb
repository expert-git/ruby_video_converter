# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join('node_modules')

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
Rails.application.config.assets.precompile += %w( *.png *.jpg *.jpeg *.gif *.svg *.ico cable.js jintervals.js jquery-confirm.js jquery.countdown.js jquery.stopwatch.js membership_price_and_button.js rails_confirm_override_sweet_alert2.js strftime.js subscription_update_credit_card.js sweetalert2.min.js videos.js)
