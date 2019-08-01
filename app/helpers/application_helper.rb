# frozen_string_literal: true

module ApplicationHelper
  def bootstrap_class_for(flash_type)
    { success: 'alert-success', error: 'alert-danger', alert: 'alert-danger', notice: 'alert-warning', recaptcha_error: 'alert-danger' }[flash_type.to_sym] || flash_type.to_s
  end

  def flash_messages_helper(_options = {})
    content_tag(:div, class: 'alert-fixed-right') do
      flash.each do |msg_type, message|
        alert_msg = concat(content_tag(:div, message, class: "alert #{bootstrap_class_for(msg_type)} alert-dismissible fade show", role: 'alert') do
          content_tag(:p, '<br>'.html_safe) if flash.count >= 2
          concat(content_tag(:button, class: 'close', data: { dismiss: 'alert' }, 'aria-label' => 'Close') do
            concat content_tag(:span, '&times;'.html_safe, 'aria-hidden' => true, class: 'cursor-pointer')
          end)
          if bootstrap_class_for(msg_type) == 'alert-success'
            concat content_tag(:span, '<i class="fa fa-check-circle"></i>'.html_safe, 'aria-hidden' => true)
          elsif bootstrap_class_for(msg_type) == ('alert-danger' || 'alert-warning')
            concat content_tag(:span, '<i class="fa fa-times-circle"></i>'.html_safe, 'aria-hidden' => true)
          else
            concat content_tag(:span, '<i class="fa fa-info-circle"></i>'.html_safe, 'aria-hidden' => true)
          end
          concat '  ' + message
          concat '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'.html_safe
        end)
      end
      nil
    end
  end

  def title(text)
    content_for :title, text
  end

  def meta_tag(tag, text)
    content_for :"meta_#{tag}", text
  end

  def yield_meta_tag(tag, default_text)
    content_for?(:"meta_#{tag}") ? content_for(:"meta_#{tag}") : default_text
  end

  def access_denied_message_helper
    if current_page?(new_member_registration_path) && request.referrer.present? && URI(request.referrer).path == '/membership/new'
      flash.now[:error] = 'Please login or create an account first.'
    end
  end

  def resource_name
    :member
  end

  def resource
    @resource ||= Member.new
  end

  def resource_class
    Member
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:member]
  end

  def remote_ip_address
    if Rails.env.production?
      request.remote_ip
    elsif Rails.env.test?
      '24.29.18.175'
    else
      Net::HTTP.get(URI.parse('http://checkip.amazonaws.com/')).squish
    end
  end
  module_function :remote_ip_address
end
