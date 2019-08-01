# frozen_string_literal: true

class ConvertedVideo < ApplicationRecord
  belongs_to :video
  has_many :member_downloads
  has_many :members, through: :member_downloads

  mount_uploader :video_file, ConvertedVideoUploader

  def filename
    video_file.file.filename
  end

  def video_file_path
    video_file.url
  end

  def initiate_download(user, converted_video, ip_address, guest_uid_value)
    if user.present?
      MemberDownload.create(member_id: user.id, converted_video_id: converted_video.id, evercookie_id: guest_uid_value)
      track_guest_downloads(ip_address, guest_uid_value) unless user.subscriptions.active.any?
    else
      track_guest_downloads(ip_address, guest_uid_value)
    end
    ConvertedVideo.increment_counter(:download_count, converted_video.id)
    data = open(converted_video.video_file_path)
    data
  end

  def track_guest_downloads(ip_address, guest_uid_value)
    guest_download = GuestDownload.find_or_create_by(remote_ip_address: ip_address)
    guest_download.download_count += 1 unless guest_download.blank?
    guest_download.evercookie_id = guest_uid_value
    guest_download.save
  end

  def self.validate_start_end_time(start_time, end_time)
    (!(start_time =~ /([0-1]?[0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]/).blank? || !(start_time =~ /([0-1]?[0-9]|2[0-3]):[0-5][0-9]/).blank?) &&
      !(start_time =~ /[0-5][0-9]:[0-5][0-9]/).blank? &&
      (!(end_time =~ /([0-1]?[0-9]|2[0-3]):[0-5][0-9]/).blank? || !(end_time =~ /([0-1]?[0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]/).blank?) &&
      !(end_time =~ /[0-5][0-9]:[0-5][0-9]/).blank?
  end
end
