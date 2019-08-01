Payola.configure do |config|
  config.secret_key = Rails.application.credentials[Rails.env.to_sym][:STRIPE_SECRET_KEY]
  config.publishable_key = Rails.application.credentials[Rails.env.to_sym][:STRIPE_PUBLISHABLE_KEY]
  StripeEvent.signing_secret = Rails.application.credentials[Rails.env.to_sym][:STRIPE_SIGNING_SECRET]

  config.background_worker = lambda do |klass, *args|
    klass.call(*args)
  end
  # config.default_currency = "usd"

  # Prevent more than one active subscription for a given member
  config.charge_verifier = lambda do |event|
    member = Member.find_by(email: event.email)
    if event.is_a?(Payola::Subscription) && member.subscriptions.active.any?
      raise "<strong>Error:</strong> You already have <br>an <a href=#{subscriptions_path} class='alert-link'>active membership.</a>".html_safe
      # raise "<strong>Error:</strong> You already have <br>an <a href=#{Rails.application.credentials[Rails.env.to_sym][:HTTP_HOST]}/membership class='alert-link'>active membership.</a>".html_safe
    end
    event.owner = member
    event.save!
  end

  # Send invoice payment succeeded email
  config.subscribe("invoice.payment_succeeded") do |event|
    amount = event.as_json.dig("data", "object").fetch("total")
    date = Time.at(event.as_json.dig("data", "object").fetch("date"))
    subscription = Payola::Subscription.find_by(stripe_id: event.data.object.subscription)
    # MembershipMailer.payment_succeeded_email(amount, date, subscription.id).deliver
    Member.change_mailchimp_member_tag(subscription.email, "Member")
  end

  # Send invoice payment failed email
  config.subscribe("invoice.payment_failed") do |event|
    amount = event.as_json.dig("data", "object").fetch("total")
    date = Time.at(event.as_json.dig("data", "object").fetch("date"))
    subscription = Payola::Subscription.find_by(stripe_id: event.data.object.subscription)
    # MembershipMailer.payment_failed_email(amount, date, subscription.id).deliver
  end

  # Send create membership email
  config.subscribe("customer.subscription.created") do |event|
    subscription = Payola::Subscription.find_by(stripe_id: event.data.object.id)
    MembershipMailer.new_membership_email(subscription.id).deliver
  end

  config.subscribe("customer.subscription.updated") do |event|
    subscription = Payola::Subscription.find_by(stripe_id: event.data.object.id)
    if event.as_json.dig("data", "previous_attributes").key?("items")
      # Send upgrade membership email
      old_amount = event.as_json.dig("data", "previous_attributes", "items", "data").first.dig("plan").fetch("amount")
      MembershipMailer.upgrade_membership_email(old_amount, subscription.id).deliver
    elsif (!event.as_json.dig("data", "object").fetch("canceled_at").nil? && event.as_json.dig("data", "object").fetch("cancel_at_period_end")==true)
      # Send cancel membership email
      MembershipMailer.cancel_membership_email(subscription.id).deliver
      Member.change_mailchimp_member_tag(subscription.email, "Former member")
    end
  end

  # Send cancel membership email
  # config.subscribe("customer.subscription.deleted") do |event|
  #   subscription = Payola::Subscription.find_by(stripe_id: event.data.object.id)
  #   MembershipMailer.cancel_membership_email(subscription.id).deliver
  # end

end
