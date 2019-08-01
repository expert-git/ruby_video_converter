class ContactForm < MailForm::Base
  append :remote_ip, :user_agent
  attribute :name,      validate: true
  attribute :email,     validate: /\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})\z/i
  attribute :message
  validates :message,   length: { in: 4..2000 }
  attribute :nickname,  :captcha  => true

  # Declare the e-mail headers. It accepts anything the mail method in ActionMailer accepts.
  def headers
    {
      subject: "New message from 'Contact Form'",
      to: Rails.application.credentials[Rails.env.to_sym][:EMAIL_SUPPORT],
      from: "contact-form@getaudiofromvideo.com"
      # from: %("#{name}" <#{email}>)
    }
  end

end
