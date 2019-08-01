class CreateMembershipService

  def create
    monthly = Membership.where(stripe_id: "monthly").first_or_initialize do |x|
      x.name = "Monthly"
      x.interval = "month"
      x.interval_count = 1
      x.amount = 1000 # $10/month
      x.currency = "usd"
      x.trial_period_days = 1
    end
    monthly.save!(validate: false)

    annual = Membership.where(stripe_id: "yearly").first_or_initialize do |x|
      x.name = "Annual"
      x.interval = "year"
      x.interval_count = 1
      x.amount = 9600 # $8/month
      x.currency = "usd"
      x.trial_period_days = 1
    end
    annual.save!(validate: false)

    annual_oto = Membership.where(stripe_id: "yearly_oto").first_or_initialize do |x|
      x.name = "Annual (one time offer)"
      x.interval = "year"
      x.interval_count = 1
      x.amount = 7200 # $6/month
      x.currency = "usd"
      x.trial_period_days = 0
    end
    annual_oto.save!(validate: false)

    monthly_special = Membership.where(stripe_id: "monthly_special").first_or_initialize do |x|
      x.name = "Monthly (special offer)"
      x.interval = "month"
      x.interval_count = 1
      x.amount = 500 # $5/month
      x.currency = "usd"
      x.trial_period_days = 1
    end
    monthly_special.save!(validate: false)

    annual_special = Membership.where(stripe_id: "annual_special").first_or_initialize do |x|
      x.name = "Annual (special offer)"
      x.interval = "year"
      x.interval_count = 1
      x.amount = 4800 # $4/month
      x.currency = "usd"
      x.trial_period_days = 0
    end
    annual_special.save!(validate: false)

  end
end
