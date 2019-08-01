namespace :retry_failed_stripe_webhooks do
  desc "Retrieve failed events and update GAFV webhook endpoint"
  task retrieve: :environment do
    # Get all events
    # Stripe.api_key = Rails.application.credentials[Rails.env.to_sym][:STRIPE_SECRET_KEY]
    # events = Stripe::Event.list(limit: 100).data
    # (1..50).each do |i|
    #   next_events = Stripe::Event.list(starting_after: events.last.id, limit: 100).data
    #   events += next_events
    # end

    # Get one event
    Stripe.api_key = 'sk_live_TR7EKdCpLnPMSZHhpVzyeG9F'
    events = Stripe::Event.retrieve('evt_1E2657HTCe9wwd9iNOgj0cj1')
    last = JSON.parse(events.to_json)
    # conn = Faraday.new(:url => 'http://stripe.gafv.ultrahook.com') do |f|
    conn = Faraday.new(:url => "https://webhook.site") do |f|
      f.request :url_encoded
      f.response :logger
      f.headers['Content-Type'] = 'application/json'
      f.adapter Faraday.default_adapter
    end
    conn.post '/10b27df3-5cc3-4f45-9ba7-30d166be6d83', last.to_json
    # conn.post '/', last.to_json
  end
end
