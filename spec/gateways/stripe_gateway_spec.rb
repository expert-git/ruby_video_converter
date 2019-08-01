# frozen_string_literal: true

describe 'StripeGateway' do
  let(:stripe_helper) { StripeMock.create_test_helper }
  before { StripeMock.start }
  after { StripeMock.stop }

  it 'creates a stripe customer', live: true do
    customer = Stripe::Customer.create(
      email: 'testuser@getaudiofromvideorails.com',
      card: stripe_helper.generate_card_token
    )
    expect(customer.email).to eq('testuser@getaudiofromvideorails.com')
  end

  it 'creates a stripe plan', live: true do
    plan = stripe_helper.create_plan(id: 'test plan', amount: 1000)
    expect(plan.id).to eq('test plan')
    expect(plan.amount).to eq(1000)
  end

  it 'mocks a incorrect card number error', live: true do
    StripeMock.prepare_card_error(:incorrect_number)
    expect { Stripe::Charge.create(amount: 1, currency: 'usd') }.to raise_error { |e|
      expect(e).to be_a Stripe::CardError
      expect(e.http_status).to eq(402)
      expect(e.code).to eq('incorrect_number')
    }
  end

  it 'mocks a invalid card number error', live: true do
    StripeMock.prepare_card_error(:invalid_number)
    expect { Stripe::Charge.create(amount: 1, currency: 'usd') }.to raise_error { |e|
      expect(e).to be_a Stripe::CardError
      expect(e.http_status).to eq(402)
      expect(e.code).to eq('invalid_number')
    }
  end

  it 'mocks a card invalid expiry month error', live: true do
    StripeMock.prepare_card_error(:invalid_expiry_month)
    expect { Stripe::Charge.create(amount: 1, currency: 'usd') }.to raise_error { |e|
      expect(e).to be_a Stripe::CardError
      expect(e.http_status).to eq(402)
      expect(e.code).to eq('invalid_expiry_month')
    }
  end

  it 'mocks a card invalid expiry year error', live: true do
    StripeMock.prepare_card_error(:invalid_expiry_year)
    expect { Stripe::Charge.create(amount: 1, currency: 'usd') }.to raise_error { |e|
      expect(e).to be_a Stripe::CardError
      expect(e.http_status).to eq(402)
      expect(e.code).to eq('invalid_expiry_year')
    }
  end

  it 'mocks a card invalid cvc error', live: true do
    StripeMock.prepare_card_error(:invalid_cvc)
    expect { Stripe::Charge.create(amount: 1, currency: 'usd') }.to raise_error { |e|
      expect(e).to be_a Stripe::CardError
      expect(e.http_status).to eq(402)
      expect(e.code).to eq('invalid_cvc')
    }
  end

  it 'mocks a card expired error', live: true do
    StripeMock.prepare_card_error(:expired_card)
    expect { Stripe::Charge.create(amount: 1, currency: 'usd') }.to raise_error { |e|
      expect(e).to be_a Stripe::CardError
      expect(e.http_status).to eq(402)
      expect(e.code).to eq('expired_card')
    }
  end

  it 'mocks a card incorrect cvc error', live: true do
    StripeMock.prepare_card_error(:incorrect_cvc)
    expect { Stripe::Charge.create(amount: 1, currency: 'usd') }.to raise_error { |e|
      expect(e).to be_a Stripe::CardError
      expect(e.http_status).to eq(402)
      expect(e.code).to eq('incorrect_cvc')
    }
  end

  it 'mocks a card declined error', live: true do
    StripeMock.prepare_card_error(:card_declined)
    expect { Stripe::Charge.create(amount: 1, currency: 'usd') }.to raise_error { |e|
      expect(e).to be_a Stripe::CardError
      expect(e.http_status).to eq(402)
      expect(e.code).to eq('card_declined')
    }
  end

  it 'mocks a missing error', live: true do
    StripeMock.prepare_card_error(:missing)
    expect { Stripe::Charge.create(amount: 1, currency: 'usd') }.to raise_error { |e|
      expect(e).to be_a Stripe::CardError
      expect(e.http_status).to eq(402)
      expect(e.code).to eq('missing')
    }
  end

  it 'mocks a card processing error', live: true do
    StripeMock.prepare_card_error(:processing_error)
    expect { Stripe::Charge.create(amount: 1, currency: 'usd') }.to raise_error { |e|
      expect(e).to be_a Stripe::CardError
      expect(e.http_status).to eq(402)
      expect(e.code).to eq('processing_error')
    }
  end

  it 'mocks a stripe webhook', live: true do
    event = StripeMock.mock_webhook_event('customer.created')
    customer_object = event.data.object
    expect(customer_object.id).to_not be_nil
    expect(customer_object.default_card).to_not be_nil
  end

  it 'mocks stripe connect webhooks', live: true do
    event = StripeMock.mock_webhook_event('customer.created', account: 'acc_123456')
    expect(event.account).to eq('acc_123456')
  end

  it 'generates a stripe card token', live: true do
    card_token = StripeMock.generate_card_token(last4: '1414', exp_year: Time.now.year)
    cus = Stripe::Customer.create(source: card_token)
    card = cus.sources.data.first
    expect(card.last4).to eq('1414')
    expect(card.exp_year).to eq(Time.now.year)
  end

  it 'mock user subscribe to a annual plan', live: true do
    card_token = StripeMock.generate_card_token(
      last4: '1414',
      exp_month: 0o1,
      exp_year: Time.now.year + 1
    )
    plan = Stripe::Plan.create(
      amount: 96,
      interval: 'year',
      currency: 'usd',
      id: 'annual-plan',
      product: {
        name: 'Annual plan'
      }
    )
    customer = Stripe::Customer.create(
      email: 'test@getaudiofromvideorails.com',
      source: card_token,
      plan: 'annual-plan'
    )
    expect(customer.plan).to eq('annual-plan')
  end

  it 'mock user subscribe to a monthly plan', live: true do
    card_token = StripeMock.generate_card_token(
      last4: '0101',
      exp_month: 0o1,
      exp_year: Time.now.year + 1
    )
    plan = Stripe::Plan.create(
      amount: 10,
      interval: 'month',
      currency: 'usd',
      id: 'monthly',
      product: {
        name: 'Monthly plan'
      }
    )
    customer = Stripe::Customer.create(
      email: 'test@getaudiofromvideorails.com',
      source: card_token,
      plan: 'monthly'
    )
    expect(customer.plan).to eq('monthly')
  end

  it 'mock user upgrade plan form monthly plan to annual plan', live: true do
    card_token = StripeMock.generate_card_token(
      last4: '0202',
      exp_month: 0o1,
      exp_year: Time.now.year + 1
    )
    monthly_plan = Stripe::Plan.create(
      amount: 10,
      interval: 'month',
      currency: 'usd',
      id: 'monthly-plan',
      product: {
        name: 'Monthly plan'
      }
    )
    annual_plan = Stripe::Plan.create(
      amount: 96,
      interval: 'year',
      currency: 'usd',
      id: 'annual-plan',
      product: {
        name: 'Annual plan'
      }
    )
    customer = Stripe::Customer.create(
      email: 'test@getaudiofromvideorails.com',
      source: card_token,
      plan: 'monthly-plan'
    )
    expect(customer.plan).to eq('monthly-plan')
    subscription = customer.subscriptions.retrieve(customer.subscriptions.data[0].id)
    subscription.plan = 'annual-plan'
    subscription.save
    customer.plan = 'annual-plan'
    customer.save
    expect(customer.plan).to eq('annual-plan')
  end

  it 'mock user downgrade plan form annual plan to monthly plan', live: true do
    card_token = StripeMock.generate_card_token(
      last4: '0202',
      exp_month: 0o1,
      exp_year: Time.now.year + 1
    )
    monthly_plan = Stripe::Plan.create(
      amount: 10,
      interval: 'month',
      currency: 'usd',
      id: 'monthly-plan',
      product: {
        name: 'Monthly plan'
      }
    )
    annual_plan = Stripe::Plan.create(
      amount: 96,
      interval: 'year',
      name: 'Annual plan',
      currency: 'usd',
      id: 'annual-plan',
      product: {
        name: 'Annual plan'
      }
    )
    customer = Stripe::Customer.create(
      email: 'test@getaudiofromvideorails.com',
      source: card_token,
      plan: 'annual-plan'
    )
    expect(customer.plan).to eq('annual-plan')
    subscription = customer.subscriptions.retrieve(customer.subscriptions.data[0].id)
    subscription.plan = 'monthly-plan'
    subscription.save
    customer.plan = 'monthly-plan'
    customer.save
    expect(customer.plan).to eq('monthly-plan')
  end

  it 'mock user cancel subscribe for monthly plan', live: true do
    card_token = StripeMock.generate_card_token(
      last4: '0101',
      exp_month: 0o1,
      exp_year: Time.now.year + 1
    )
    plan = Stripe::Plan.create(
      amount: 10,
      interval: 'month',
      currency: 'usd',
      id: 'monthly-plan',
      product: {
        name: 'Monthly plan'
      }
    )
    customer = Stripe::Customer.create(
      email: 'test@getaudiofromvideorails.com',
      source: card_token,
      plan: 'monthly-plan'
    )
    subscription = customer.subscriptions.retrieve(customer.subscriptions.data[0].id)
    subscription = subscription.delete
    expect(subscription.status).to eq('canceled')
  end

  it 'mocks a stripe webhook for subscription created', live: true do
    event = StripeMock.mock_webhook_event('customer.subscription.created')
    subscription_object = event.data.object
    expect(subscription_object.id).to_not be_nil
    expect(subscription_object.status).to eq('active')
    expect(subscription_object.cancel_at_period_end).to eq(false)
  end

  it 'mocks a stripe webhook for subscription canceled', live: true do
    event = StripeMock.mock_webhook_event('customer.subscription.deleted')
    subscription_object = event.data.object
    expect(subscription_object.id).to_not be_nil
    expect(subscription_object.status).to eq('canceled')
  end

  it 'mocks a stripe webhook for charge succeeded', live: true do
    event = StripeMock.mock_webhook_event('charge.succeeded')
    charge_object = event.data.object
    expect(charge_object.id).to_not be_nil
    expect(charge_object.paid).to eq(true)
    expect(charge_object.amount).to_not be_nil
  end

  it 'mocks a stripe webhook for charge failed', live: true do
    event = StripeMock.mock_webhook_event('charge.failed')
    charge_object = event.data.object
    expect(charge_object.id).to_not be_nil
    expect(charge_object.paid).to eq(false)
    expect(charge_object.amount).to_not be_nil
  end

  it 'mocks a strip webhook for customer source created', live: true do
    event = StripeMock.mock_webhook_event('customer.source.created')
    source_object = event.data.object
    expect(source_object.id).to_not be_nil
    expect(source_object.funding).to eq('credit')
    expect(source_object.cvc_check).to eq('pass')
  end
end
