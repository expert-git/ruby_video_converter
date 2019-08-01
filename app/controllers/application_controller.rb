# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pundit
  # protect_from_forgery with: :exception
  protect_from_forgery prepend: true, with: :null_session, if: -> { request.format.json? }

  # saves the location before loading each page so we can return to the
  # right page. If we're on a devise page, we don't want to store that as the
  # place to return to (for example, we don't want to return to the sign in page
  # after signing in), which is what the :unless prevents
  before_action :store_current_location, unless: :devise_controller?
  before_action :invalidate_simultaneous_user_session, unless: proc { |c| (c.controller_name == 'sessions') && (c.action_name == 'create') }
  before_action :delete_session_values

  def payola_can_modify_subscription?(subscription)
    subscription.owner == current_member
  end

  def invalidate_simultaneous_user_session
    sign_out_and_redirect(current_member) if current_member && session[:sign_in_token] != current_member.current_sign_in_token
  end

  def sign_in(resource_or_scope, *args)
    super
    token = Devise.friendly_token
    current_member.update_attribute :current_sign_in_token, token
    session[:sign_in_token] = token
  end

  def pundit_user
    current_member
  end

  private

  # override the devise helper to store the current location so we can
  # redirect to it after loggin in or out. This override makes signing in
  # and signing up work automatically.
  def store_current_location
    store_location_for(:member, request.url)
  end

  def delete_session_values
    if request&.url&.include?('/signup')
      if request&.referrer && request.referrer.include?('/membership/new')
        session.delete(:after_sign_up_redirect_path) if session['after_sign_up_redirect_path']
      end
    end
  end

  # return member to the same page after signing in
  def after_sign_in_path_for(resource_or_scope)
    url = stored_location_for(resource_or_scope)
    if url.present? && url.include?('/videos') && !url.include?('/videos/search')
      store_location_for(:member, session['after_sign_in_redirect_path'])
      session.delete(:after_sign_in_redirect_path)
    else
      url || super
    end
  end

  # keep member on the same page after signing out
  def after_sign_out_path_for(resource_or_scope)
    stored_location_for(resource_or_scope) || request.referrer
  end

  def video_session_identifier
    session['video_identifier'] ||= SecureRandom.hex(8)
  end
  helper_method :video_session_identifier
end
