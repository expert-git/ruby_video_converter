# frozen_string_literal: true

module SubscriptionHelper
  def create_subscription
    member = Member.first.blank? ? create_member : Member.first
    payola_subscription = Payola::Subscription.first
    # return [payola_subscription, member] unless payola_subscription.blank?
    membership = Membership.where(stripe_id: 'monthly').last
    begin
      Stripe::Plan.create(
        amount: 10,
        interval: 'month',
        currency: 'usd',
        id: 'monthly',
        product: {
          name: 'Monthly plan'
        }
      )
    rescue Stripe::InvalidRequestError
    end
    membership = FactoryBot.create(:membership) if membership.blank?
    card_token = StripeMock.generate_card_token(
      last4: '0101',
      exp_month: 0o1,
      exp_year: Time.now.year + 1
    )
    customer = Stripe::Customer.create(
      email: member.email,
      source: card_token,
      plan: membership.stripe_id
    )
    subscription = customer.subscriptions.data[0]
    card = customer.sources.data[0]
    response = {
      plan_type: 'Membership',
      plan_id: membership.id,
      owner_type: 'Member',
      owner_id: member.id,
      stripe_customer_id: customer.id,
      cancel_at_period_end: 0,
      current_period_start: Time.at(subscription['current_period_start']).to_s(:db),
      current_period_end: Time.at(subscription['current_period_end']).to_s(:db),
      quantity: 1,
      stripe_id: subscription['id'],
      card_last4: card['last4'],
      card_expiration: (Time.now + 1.year).to_s(:db),
      card_type: card['type'],
      state: 'active',
      email: member.email,
      currency: membership.currency,
      amount: membership.amount,
      guid: SecureRandom.random_number(1_000_000_000).to_s(32),
      stripe_status: 'active'
    }
    [Payola::Subscription.create!(response), member]
  end
end
