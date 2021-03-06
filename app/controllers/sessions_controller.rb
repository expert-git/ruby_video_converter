class SessionsController < Devise::SessionsController
  prepend_before_action :check_captcha, only: [:create] # Change this to be any actions you want to protect.

  private
    def check_captcha
      unless verify_recaptcha
        self.resource = warden.authenticate!(auth_options)
        resource.validate # Look for any other validation errors besides Recaptcha
        respond_with_navigational(resource) { render :new }
      end
    end

end
