# frozen_string_literal: true

class ConvertedVideoPolicy < ApplicationPolicy
  def allow_download?
    return true if user.present?

    guest_download_count = GuestDownload.find_by(
      remote_ip_address: ApplicationHelper.remote_ip_address
    ).try(:download_count).to_i
    guest_download_count < Rails.application.credentials[Rails.env.to_sym][:GUEST_SKIP_SIGNUP_REQUIRED_MODAL_LIMIT].to_i
  end
end
