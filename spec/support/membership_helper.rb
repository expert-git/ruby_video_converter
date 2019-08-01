# frozen_string_literal: true

module MembershipHelper
  def create_membership
    monthly_plan = Stripe::Plan.create(
      amount: 10,
      interval: 'month',
      currency: 'usd',
      id: 'monthly',
      product: {
        name: 'Monthly plan'
      }
    )
    membership_monthly = FactoryBot.create(:membership)
    annual_plan = Stripe::Plan.create(
      amount: 96,
      interval: 'year',
      name: 'Annual plan',
      currency: 'usd',
      id: 'yearly',
      product: {
        name: 'Annual plan'
      }
    )
    membership_annual = FactoryBot.create(:membership, :annual_plan, :annual, :year, :year_amount)
  end
end
