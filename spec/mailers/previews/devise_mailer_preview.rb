# Preview all emails at http://localhost:3000/rails/mailers/devise/mailer
class Devise::MailerPreview < ActionMailer::Preview

  def confirmation_instructions
    Devise::Mailer.confirmation_instructions(Member.first, "faketoken", {})
  end

  def reset_password_instructions
    Devise::Mailer.reset_password_instructions(Member.first, "faketoken", {})
  end

end