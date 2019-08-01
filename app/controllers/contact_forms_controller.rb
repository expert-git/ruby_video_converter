class ContactFormsController < ApplicationController
  # before_action :check_for_yahoo_email, only: [:create]

  def new
    @contact_form = ContactForm.new
  end

  def create
    @contact_form = ContactForm.new(contact_form_params)
    @contact_form.request = request
    if !verify_recaptcha
      # flash.now[:error] = nil
      # flash.now[:error] = "Error: #{@captcha_error}"
      render :new
    elsif @contact_form.deliver
      flash.now[:error] = nil
      flash[:success] = "Success: We have received your message and will reply within 24 hours!"
      redirect_back(fallback_location: (request.referer || root_path))
    end
  end

  private
  def contact_form_params
    params.require(:contact_form).permit(:nickname, :name, :email, :message)
  end

  def check_for_yahoo_email
    if ["yahoo"].any? { |slug| contact_form_params[:email].include? slug }
      contact_form_params[:email] = "yahoo@getaudiofromvideo.com"
      contact_form_params[:name] = "YAHOO EMAIL ADDRESS"
    end
  end

end
