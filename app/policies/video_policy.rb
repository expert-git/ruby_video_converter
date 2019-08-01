# frozen_string_literal: true

class VideoPolicy < ApplicationPolicy
  def authorized_to_download?(ever_cookie)
    guest = GuestDownload.find_by_remote_ip_address(ApplicationHelper.remote_ip_address)
    if user.blank?
      guest_download_limit_reached?(guest, ever_cookie)
    else
      user.subscriptions.active.any? ? true : guest_download_limit_reached?(guest, ever_cookie)
    end
  end

  def show_guest_delay?(ever_cookie)
    guest = GuestDownload.find_by_remote_ip_address(ApplicationHelper.remote_ip_address)
    if user.blank?
      guest_already_skipped_delay?(guest, ever_cookie)
    else
      user.subscriptions.active.any? ? false : guest_already_skipped_delay?(guest, ever_cookie)
    end
  end

  private

  def guest_already_skipped_delay?(guest, ever_cookie)
    if guest.blank?
      return ever_cookie ? true : false
    end

    guest.download_count >= Rails.application.credentials[Rails.env.to_sym][:GUEST_SKIP_DELAY_COUNTDOWN_LIMIT].to_i
  end

  def guest_download_limit_reached?(guest, ever_cookie)
    if guest.blank?
      return ever_cookie ? false : true
    end

    guest.download_count < Rails.application.credentials[Rails.env.to_sym][:GUEST_VIDEO_CONVERSION_LIMIT].to_i
  end
end
