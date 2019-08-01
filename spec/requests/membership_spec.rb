# frozen_string_literal: true

describe 'Membership' do
  before { StripeMock.start }
  after { StripeMock.stop }

  specify 'should able to access membership plan page without login' do
    visit new_membership_path
    expect(current_path).to eq '/membership/new'
  end

  specify 'should able to access membership plan page after login' do
    login_as_member
    visit new_membership_path
    expect(current_path).to eq '/membership/new'
  end

  specify 'should not able to access the membership page without login' do
    visit subscriptions_path
    expect(current_path).to eq '/login'
    expect(page).to have_content 'You need to sign in or sign up before continuing.'
  end

  specify 'should able to access the membership page after login' do
    login_as_member
    visit subscriptions_path
    expect(current_path).to eq '/membership'
  end

  specify 'should goto membership plan page when clicked on guest button from subscription page' do
    login_as_member
    visit subscriptions_path
    click_on 'Guest'
    expect(current_path).to eq '/membership/new'
  end

  specify 'should show guest if member didn`t subscribe a membership plan' do
    login_as_member
    visit root_path
    expect(page).to have_content 'Guest'
  end

  specify 'should goto membership plan page when clicked on guest button from home page' do
    login_as_member
    visit root_path
    click_on 'Guest'
    expect(current_path).to eq '/membership/new'
  end

  specify 'should have annual plan active by default' do
    visit new_membership_path
    expect(page).to have_selector :css, 'label.annual-plan.active'
  end

  specify 'should have annual plan price as eight dollars per month' do
    visit new_membership_path
    expect(page).to have_content '$8 / month'
  end

  specify 'should change to monthly plan when clicked on monthly button', js: true do
    visit new_membership_path
    find('.monthly-plan').click
    expect(page).to have_selector :css, 'label.monthly-plan.active'
  end

  specify 'should have monthly plan price as ten dollars per month', js: true do
    visit new_membership_path
    find('.monthly-plan').click
    expect(page).to have_content '$10 / month'
  end

  specify 'should switch between annual and monthly plan', js: true do
    visit new_membership_path
    find('.monthly-plan').click
    expect(page).to have_content '$10 / month'
    find('.annual-plan').click
    expect(page).to have_content '$8 / month'
    expect(page).to have_content '(paid annually)'
  end

  specify 'should redirect to signup page when clicked on start free trial on membership plan page without login' do
    visit new_membership_path
    click_on 'Start free trial'
    expect(current_path).to eq '/membership/new'
    expect(page).to have_content 'Please create an account or login first.'
  end

  specify 'should display credit card form with annual plan amount', js: true do
    login_as_member
    create_membership
    visit new_membership_path
    click_on 'Start free trial'
    sleep(9)
    stripe_iframe = all('iframe[name=stripe_checkout_app]').last
    Capybara.within_frame stripe_iframe do
      expect(page).to have_content '$8 / month ($96 paid annually)'
      expect(page).to have_selector "input[placeholder='Card number']"
      expect(page).to have_selector "input[placeholder='MM / YY']"
      expect(page).to have_selector "input[placeholder='CVC']"
    end
  end

  specify 'should display credit card form with monthly plan amount', js: true do
    login_as_member
    create_membership
    visit new_membership_path
    find('.monthly-plan').click
    click_on 'Start free trial'
    sleep(9)
    stripe_iframe = all('iframe[name=stripe_checkout_app]').last
    Capybara.within_frame stripe_iframe do
      expect(page).to have_content '$10 / month'
      expect(page).to have_selector "input[placeholder='Card number']"
      expect(page).to have_selector "input[placeholder='MM / YY']"
      expect(page).to have_selector "input[placeholder='CVC']"
    end
  end

  specify 'should able to view the membership details' do
    create_membership
    subscription, member = create_subscription
    sign_in member
    visit root_path
    expect(page).to have_content 'Member'
    visit subscriptions_path
    expect(page).to have_content 'Monthly'
    expect(page).to have_content Time.at(subscription['current_period_start']).strftime('%b %d, %Y')
    expect(page).to have_content Time.at(subscription['current_period_end']).strftime('%b %d, %Y')
    expect(page).to have_content 'Upgrade plan to Annual plan ($96/year)'
  end

  specify 'should able to view update credit card form', js: true do
    create_membership
    subscription, member = create_subscription
    sign_in member
    visit subscriptions_path
    click_on 'Update credit card'
    sleep(9)
    stripe_iframe = all('iframe[name=stripe_checkout_app]').last
    Capybara.within_frame stripe_iframe do
      expect(page).to have_content 'Update credit card'
      expect(page).to have_selector "input[placeholder='Card number']"
      expect(page).to have_selector "input[placeholder='MM / YY']"
      expect(page).to have_selector "input[placeholder='CVC']"
    end
  end

  specify 'should show member if member as a active subscription' do
    create_membership
    subscription, member = create_subscription
    sign_in member
    visit root_path
    expect(page).to have_content 'Member'
  end

  specify 'should goto membership page when clicked on member button from home page' do
    create_membership
    subscription, member = create_subscription
    sign_in member
    visit root_path
    click_on 'Member'
    expect(current_path).to eq '/membership'
  end
end
