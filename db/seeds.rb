# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

#admin = CreateAdminService.new.create
#puts "Created admin with email: #{admin.email}"

if Rails.env.test?
  CreateVideoService.new.create
end

if !Rails.env.test? && (Rails.env.production? || Rails.env.development?)
  CreateMembershipService.new.create
  memberships = Membership.all
  memberships.each do |membership|
    puts "Created ##{membership.id}: '#{membership.name}' membership"
    puts "- Stripe ID: #{membership.stripe_id}"
    puts "- #{membership.currency} $#{membership.price_in_dollars} / #{membership.interval} #{'($' if membership.interval == 'year'}#{(membership.price_in_dollars/12) if membership.interval == 'year'} #{'per month)' if membership.interval == 'year'}"
    if membership.trial_period_days.present?
      puts "- #{membership.trial_period_days} day#{'s' unless membership.trial_period_days == 1} free trial"
    end
    puts ""
  end
end

if !Rails.env.test? && Rails.env.development?
  temp_password = "12345678"

  member1 = Member.new(email: "monthly@getaudiofromvideo.com", password: temp_password, password_confirmation: temp_password)
  member1.skip_confirmation!
  member1.save!

  member2 = Member.new(email: "annual@getaudiofromvideo.com", password: temp_password, password_confirmation: temp_password)
  member2.skip_confirmation!
  member2.save!

  member3 = Member.new(email: "annual-oto@getaudiofromvideo.com", password: temp_password, password_confirmation: temp_password)
  member3.skip_confirmation!
  member3.save!

  members = Member.all
  members.each do |member|
    puts "Created member ##{member.id}: #{member.email}"
  end

  # subscription = Payola::Subscription.create!(
  #   plan_type: "Membership",
  #   plan_id: Membership.first.id,
  #   # start: ,
  #   status: "active",
  #   owner_type: "Member",
  #   owner_id: member1.id,
  #   stripe_customer_id: stripe_customer_id,
  #   cancel_at_period_end: canceled_at_period_end,
  #   current_period_start: DateTime.now,
  #   current_period_end: current_period_end,
  #   # ended_at: ,
  #   # trial_start: ,
  #   trial_end: ,
  #   # canceled_at: canceled_at,
  #   quantity: quantity,
  #   stripe_id: stripe_id,
  #   # stripe_token: ,
  #   # card_last4: ,
  #   # card_expiration: ,
  #   # card_type: ,
  #   # error: ,
  #   state: "active",
  #   email: email,
  #   created_at: created_at,
  #   updated_at: created_at,
  #   currency: "usd",
  #   amount: amount,
  #   # guid: ,
  #   stripe_status: "active",
  #   # affiliate_id: ,
  #   # coupon: ,
  #   # signed_custom_fields: ,
  #   # customer_address: ,
  #   # business_address: ,
  #   # setup_fee: ,
  #   tax_percent: 0.00
  # )

  # subscriptions = Payola::Subscription.all
  # subscriptions.each do |subcription|
  #   member = Member.where(id: subscription.owner_id).first
  #   puts "Created subscription ##{subscription.id} for #{member.email}: '#{subscription.stripe_id}' expiring #{subscription.current_period_end}"
  # end

end

# Seed database with real Stripe subscriptions (first created in Stripe dashboard)
if !Rails.env.test? && Rails.env.production?
  require 'csv'
  count = 1
  begin
    CSV.foreach(Rails.root.join('db/subscriptions.csv'), headers: true) do |row|
      stripe_id = row[0]
      stripe_customer_id = row[1]
      customer_description = row[2]
      email = row[3]
      plan = row[4]
      quantity = row[5]
      interval = row [6]
      amount = row [7]
      status = row[8]
      created_at = row[9]
      start = row[10]
      current_period_start = row[11]
      current_period_end = row[12]
      trial_start = row[13]
      trial_end = row[14]
      application_fee_percent = row[15]
      coupon = row[16]
      tax_percent = row[17]
      canceled_at = row[18]
      canceled_at_period_end = row[19]
      ended_at = row[20]

      next if Member.exists?(email: email)

      combination =  [('A'..'Z'),(1..9)].map{ |i| i.to_a }.flatten
      temp_password = (0..10).map{ combination[rand(combination.length)]  }.join
      member = Member.new(email: email, password: temp_password, password_confirmation: temp_password)
      member.skip_confirmation!
      member.save!
      puts "Created member ##{count}: #{member.email}"

      subscription = Payola::Subscription.create!(
        plan_type: "Membership",
        plan_id: 6,
        # start: ,
        status: status,
        owner_type: "Member",
        owner_id: member.id,
        stripe_customer_id: stripe_customer_id,
        cancel_at_period_end: canceled_at_period_end,
        current_period_start: current_period_start,
        current_period_end: current_period_end,
        # ended_at: ,
        # trial_start: ,
        # trial_end: ,
        # canceled_at: canceled_at,
        quantity: quantity,
        stripe_id: stripe_id,
        # stripe_token: ,
        # card_last4: ,
        # card_expiration: ,
        # card_type: ,
        # error: ,
        state: "active",
        email: email,
        created_at: created_at,
        updated_at: created_at,
        currency: "usd",
        amount: amount,
        # guid: ,
        stripe_status: "active",
        # affiliate_id: ,
        coupon: "legacy-members-free",
        # signed_custom_fields: ,
        # customer_address: ,
        # business_address: ,
        # setup_fee: ,
        tax_percent: 0.00
      )
      puts "Created subscription ##{count} for #{member.email}: '#{subscription.stripe_id}' expiring #{subscription.current_period_end}"
      count += 1
    end
  rescue => e
    puts "Caught exception: #{e.inspect}"
  end
end