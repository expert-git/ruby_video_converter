# frozen_string_literal: true

describe 'Sessions' do
  specify 'should sign member in and out' do
    member = create_member

    sign_in member
    visit download_history_path
    expect(current_path).to eq '/videos/download_history'
    expect(page).to have_content 'Download history'

    sign_out member
    visit download_history_path
    expect(current_path).to eq '/login'
    expect(page).not_to have_content 'Download history'
  end

  specify 'should able to access login page when clicked on login button' do
    visit '/'
    click_on('Login', match: :first)
    within('#loginModalCenter') do
      expect(page).to have_content 'Login'
    end
    expect(current_path).to eq '/'
  end

  specify 'should able to access membership plan page when clicked on create account button' do
    visit '/'
    click_on 'Create Account'
    expect(page).to have_content '1 day free trial'
    expect(current_path).to eq new_membership_path
  end

  specify 'should able to access signup page' do
    visit '/signup'
    expect(page).to have_content 'Create account'
  end

  specify 'should display error messages on signup' do
    visit '/signup'
    click_on('Sign up', match: :first)
    expect(page).to have_content '2 errors must be fixed'
    expect(page).to have_content "Email can't be blank"
    expect(page).to have_content "Password can't be blank"
  end

  specify 'should able to signup' do
    visit '/signup'
    within('form', id: 'modal_signup_member') do
      fill_in 'member_email', with: 'testmember@getaudiofromvideo.com'
      fill_in 'member_password', with: 'secert01'
      fill_in 'member_password_confirmation', with: 'secert01'
      click_on 'Sign up'
    end
    expect(current_path).to eq '/'
    expect(page).to have_content 'Please check your inbox for our email and click the link to activate your account.'
  end

  specify 'shoudl able to confirm account after signup' do
    visit '/signup'
    within('form', id: 'modal_signup_member') do
      fill_in 'member_email', with: 'testmember@getaudiofromvideo.com'
      fill_in 'member_password', with: 'secert01'
      fill_in 'member_password_confirmation', with: 'secert01'
      expect do
        click_on 'Sign up'
      end.to change(ActionMailer::Base.deliveries, :count).by(1)
    end
    expect(unread_emails_for('testmember@getaudiofromvideo.com')).to be_present
    open_email('testmember@getaudiofromvideo.com', with_subject: 'Confirmation instructions')
    visit_in_email('Confirm my email')
    expect(page).to have_content 'Your email address has been successfully confirmed.'
    within('form', id: 'new_member') do
      fill_in 'member_email', with: 'testmember@getaudiofromvideo.com'
      fill_in 'member_password', with: 'secert01'
      click_button 'Login', match: :one
    end
    expect(page).to have_content 'Signed in successfully.'
  end

  specify 'should able to access login page' do
    visit '/login'
    expect(page).to have_content 'Login'
  end

  specify 'should display invalid email or password' do
    visit '/login'
    within('form', id: 'new_member') do
      click_button 'Login'
    end
    expect(page).to have_content 'Invalid Email or password.'
  end

  specify 'should able to login' do
    login_as_member
    expect(current_path).to eq '/'
    expect(page).to have_content 'Signed in successfully.'
  end

  specify 'should able to logout when clicked ok button on confirmation alert', js: true do
    member = create_member
    sign_in member
    visit root_path
    click_link member.email
    click_link 'Logout'
    click_button 'Ok'
    expect(page).to have_content 'Signed out successfully.'
    visit '/login'
    expect(page).to have_content 'Login'
  end

  specify 'should not logout when clicked cancel button on confirmation alert', js: true do
    member = create_member
    sign_in member
    visit root_path
    click_link member.email
    click_link 'Logout'
    click_button 'Cancel'
    expect(current_path).to eq '/'
  end

  specify 'should able to access forgot password page' do
    visit '/login'
    click_link 'Forgot password?'
    expect(page).to have_content 'Forgot your password?'
    expect(current_path).to eq '/password/new'
  end

  specify 'should able to submit the forgot password' do
    member = create_member
    visit '/login'
    click_link 'Forgot password?'
    within('form', id: 'new_member') do
      fill_in 'Email', with: member.email
      click_button 'Send me reset password instructions'
    end
    expect(page).to have_content 'You will receive an email with instructions on how to reset your password in a few minutes.'
  end

  specify 'should able to reset the password using forgot password option', js: true do
    member = create_member
    visit '/login'
    click_link 'Forgot password?'
    fill_in 'Email', with: member.email
    expect do
      click_button 'Send me reset password instructions'
    end.to change(ActionMailer::Base.deliveries, :count).by(1)
    expect(unread_emails_for(member.email)).to be_present
    open_email(member.email, with_subject: 'Reset password instructions')
    visit_in_email('Change my password')
    fill_in 'New password', with: 'verysecert'
    fill_in 'Confirm new password', with: 'verysecert'
    click_button 'Change my password'
    expect(page).to have_content 'Your password has been changed successfully. You are now signed in.'
    click_link member.email
    click_link 'Logout'
    click_button 'Ok'
    visit '/login'
    within('form', id: 'new_member') do
      fill_in 'member_email', with: member.email
      fill_in 'member_password', with: 'verysecert'
      click_button 'Login'
    end
    expect(page).to have_content 'Signed in successfully.'
  end
end
