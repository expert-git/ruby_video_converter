module MemberHelper

  def login_as_member(options = {})
    email = options[:email].blank? ? 'testmember@getaudiofromvideo.com' : options[:email]
    password = options[:password].blank? ? "secert01" : options[:password]
    form_id = options[:form_id] ||  'new_member'
    member_create = options[:create_member].blank? ? true : false
    create_member({email: email, password: password}) if member_create
    visit '/login'
    within("form", id: form_id) do
      fill_in 'member_email', with: email
      fill_in 'member_password', with: password
      click_button 'Login', match: :one
    end
  end

  def create_member(options = {})
    if options.blank?
      member = FactoryBot.create(:member)
    else
      member = FactoryBot.create(:member, email: options[:email], password: options[:password], password_confirmation: options[:password])
    end
    member.confirm
    member
  end

end