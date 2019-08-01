class RegistrationsController < Devise::RegistrationsController
  prepend_before_action :check_captcha, only: [:create] # Change this to be any actions you want to protect.

  private
    def check_captcha
      unless verify_recaptcha
        self.resource = resource_class.new sign_up_params
        resource.validate # Look for any other validation errors besides Recaptcha
        respond_with_navigational(resource) { render :new }
      end
    end

    def after_inactive_sign_up_path_for(resource_or_scope)
      if session["after_sign_up_redirect_path"]
        store_location_for(:member, session["after_sign_up_redirect_path"])
        session.delete(:after_sign_up_redirect_path)
      end
      stored_location_for(resource_or_scope) || super
    end
    
end