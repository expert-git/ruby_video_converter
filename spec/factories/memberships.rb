# frozen_string_literal: true

FactoryBot.define do
  factory :membership do
    name { 'Monthly plan' }
    stripe_id { 'monthly' }
    interval { 'month' }
    amount { 1000 }

    trait :annual_plan do
      name { 'Annual plan' }
    end
    trait :annual do
      stripe_id { 'yearly' }
    end
    trait :year do
      interval { 'year' }
    end
    trait :year_amount do
      amount { 9600 }
    end

    interval_count { 1 }
    currency { 'usd' }
    trial_period_days { 1 }
  end
end
