# frozen_string_literal: true

class Video < ApplicationRecord
  # validates :title, :ytid, :duration, :video_file, :format, presence: true

  attr_accessor :actual_end_time

  has_many :converted_videos
  has_one  :tinyproxy_ip

  mount_uploader :video_file, VideoUploader

  extend FriendlyId
  friendly_id :title, use: :slugged, slug_column: :url_title

  scope :with_information, -> { where.not(url_title: nil) }

  ALLOWEDFORMATS = [
    ['Video',
     [
       %w[MP4 mp4],
       # ["3GP", "3gp"],
       %w[AVI avi],
       %w[FLV flv],
       %w[MKV mkv],
       # ["OGG", "ogg"],
       %w[WEBM webm]
     ]],
    ['Audio',
     [
       %w[MP3 mp3],
       %w[AAC aac],
       %w[M4A m4a],
       %w[WAV wav]
     ]]
  ].freeze

  def filename
    "#{title}.#{format}"
  end

  def check_incomplete_master_video
    title.blank? || video_file.file.blank?
  end

  def video_file_path
    video_file.url
  end

  def fetch_proxy
    Tinyproxy.new.get_proxy(true)
  end

  class << self
    def build_options
      request_options = {}

      youtube_options = {
        config_location: 'config/youtube-dl.conf',
        ffmpeg_location: FFMPEG.ffmpeg_binary
      }

      if Rails.application.credentials[Rails.env.to_sym][:TINYPROXY_ENABLED] == 'true'
        proxy = Tinyproxy.new.get_proxy(false, 'one', true)
        youtube_options.merge!(proxy: proxy['proxy']) unless proxy['proxy'].blank?
      else
        proxy = {
          'proxy' => '',
          'ip' => ''
        }
      end

      request_options.merge!(youtube_options: youtube_options, proxy: proxy)
    end

    def remove_leading_zero_hours(length)
      hours, minutes, seconds = length.split(':')
      if hours == '00'
        start_time = '00:00'
        end_time = "#{minutes}:#{seconds}"
      else
        start_time = '00:00:00'
        end_time = length
      end
      [start_time, end_time]
    end

    def format_url(search_url)
      if ['http://m.youtu', 'https://m.youtu'].any? { |url| search_url.include? url }
        search_url = search_url.gsub('m.youtube', 'www.youtube')
      end
      search_url
    end
  end
end
