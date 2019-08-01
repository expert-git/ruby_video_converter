describe 'Profile' do
  specify 'should not able to access profile page before login' do
  	visit '/profile'
  	expect(page).to have_content 'You need to sign in or sign up before continuing.'
  end

  specify 'should able to access profile page' do
  	login_as_member
  	visit '/profile'
    expect(current_path).to eq '/profile'
    expect(page).to have_content 'Edit profile'
  end

  specify "should display error current password can't be blank" do
    login_as_member
  	visit '/profile'
  	click_on 'Update'
    expect(page).to have_content '1 error must be fixed'
    expect(page).to have_content "Current password can't be blank"
  end

  specify "should display message profile updated succesfully message" do
    login_as_member
  	visit '/profile'
  	fill_in "member_current_password", with: "secert01"
  	click_on 'Update'
  	expect(page).to have_content 'Your account has been updated successfully.'
  end

  specify "should able to change the password", js: true do
    member = create_member
    sign_in member
  	visit '/profile'
  	fill_in "member_password", with: "verysecert"
  	fill_in "member_password_confirmation", with: "verysecert"
  	fill_in "member_current_password", with: member.password
  	click_on 'Update'
    expect(page).to have_content 'Your account has been updated successfully.'
    click_link member.email
    click_link 'Logout'
    click_button 'Ok'
    expect(page).to have_content 'Signed out successfully.'
    login_as_member({email: member.email, password: 'verysecert', create_member: 'false'})
    expect(page).to have_content 'Signed in successfully.'
  end

  specify "should receive an email after password change" do
    login_as_member
    visit '/profile'
    fill_in "member_password", with: "verysecert"
    fill_in "member_password_confirmation", with: "verysecert"
    fill_in "member_current_password", with: "secert01"
    expect do
      click_button 'Update'
    end.to change(ActionMailer::Base.deliveries, :count).by(1)
    expect(unread_emails_for('testmember@getaudiofromvideo.com')).to be_present
    open_email('testmember@getaudiofromvideo.com', with_subject: 'Password change')
  end

end