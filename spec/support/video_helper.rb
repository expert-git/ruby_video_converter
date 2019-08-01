# frozen_string_literal: true

module VideoHelper
  TIMEOUT = 30
  def navigate_to_video_page(duration_limit = false)
    visit root_path
    fill_in 'terms', with: 'nope.avi'
    click_on 'Search'
    if duration_limit
      link_position = nil
      page.all('.duration-position').each_with_index do |duration, index|
        split_duration = duration.text.split(':')
        if split_duration.length == 2
          hours = 0
          minutes, seconds = split_duration.map(&:to_i)
        elsif split_duration.length == 3
          hours, minutes, seconds = split_duration.map(&:to_i)
        end
        if (hours == 0 && minutes < Rails.application.credentials[Rails.env.to_sym][:GUEST_VIDEO_DURATION_LIMIT_MINUTES].to_i && seconds > 0) || (hours == 0 && minutes == Rails.application.credentials[Rails.env.to_sym][:GUEST_VIDEO_DURATION_LIMIT_MINUTES].to_i && seconds == 0)
          link_position = index
          break
        end
      end
      page.all('.card-title a')[link_position].click
    else
      first('.card-title a').click
    end
  end

  def navigate_to_video_page_longer_than_6_minutes(duration_limit = false)
    visit root_path
    fill_in 'terms', with: '6 mins'
    click_on 'Search'
    if duration_limit
      link_position = nil
      page.all('.duration-position').each_with_index do |duration, index|
        split_duration = duration.text.split(':')
        duration_in_seconds = 0
        if split_duration.length == 2
          minutes, seconds = split_duration.map(&:to_i)
          duration_in_seconds = minutes * 60 + seconds
        elsif split_duration.length == 3
          duration_in_seconds = hours * 3600 + minutes * 60 + seconds
        end

        minutes_limit = Rails.application.credentials[Rails.env.to_sym][:GUEST_VIDEO_DURATION_LIMIT_MINUTES].to_i
        if duration_in_seconds > minutes_limit * 60
          link_position = index
          break
        end
      end
      page.all('.card-title a')[link_position].click
    else
      first('.card-title a').click
    end
  end

  def get_input_time(format_length, start_time_field = true)
    if format_length == 2
      if start_time_field
        time = '0000'
        compare_time = '00:00'
      else
        time = '0002'
        compare_time = '00:02'
      end
    else
      if start_time_field
        time = '000000'
        compare_time = '00:00:00'
      else
        time = '000002'
        compare_time = '00:00:02'
      end
    end
    [time, compare_time]
  end

  def start_end_times(format_length, start_time_greater = false, end_time_greater = false)
    if format_length == 2
      if start_time_greater
        start_time = '00:10'
        end_time = '00:02'
      elsif end_time_greater
        start_time = '00:02'
        end_time = '00:10'
      else
        start_time = '00:02'
        end_time = '00:02'
      end
    else
      if start_time_greater
        start_time = '00:00:10'
        end_time = '00:00:02'
      elsif end_time_greater
        start_time = '00:00:02'
        end_time = '00:00:10'
      else
        start_time = '00:00:02'
        end_time = '00:00:02'
      end
    end
    [start_time, end_time]
  end

  def elapse_sleep_time(object, video = nil, video_format = nil, record_from = nil)
    object_state = object.class.name == 'Video' ? object.title.blank? : object.blank?
    if object_state
      loop do
        sleep 1
        video.blank? ? object.reload : video.reload
        if object.class.name == 'Video'
          object = object.blank? ? Video.first : object
          break unless object.title.blank?
        else
          converted_videos = video.converted_videos
          record_from = converted_videos.count == 1 ? 'youtube_dl' : 'master_file'
          record = converted_videos.where('format = ?', video_format).last
          object = record.blank? ? nil : record
          break unless object.blank?
        end
      end
    end
    if object.class.name == 'Video'
      return object
    else
      return [object, record_from]
    end
  end

  def wait_to_download(video_id)
    Timeout.timeout(TIMEOUT) do
      sleep 0.5 until Video.find_by_ytid(video_id).video_file.present?
    end
  end
end
