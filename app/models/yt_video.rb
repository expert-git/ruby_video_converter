# Unified interface to Youtube video
# either accessed from db or yt api
class YtVideo
  def initialize(video)
    @video = video
  end

  def title
    video.title
  end

  def description
    video.description
  end

  def keywords
    if db?
      video.keywords
    else
      video.tags.join(", ")
    end
  end

  def ytid
    if db?
      video.ytid
    else
      video.id
    end
  end

  def views
    if db?
      video.views
    else
      video.view_count
    end
  end

  def published_on
    if db?
      video.published_on
    else
      video.published_at
    end
  end

  def duration
    if video.respond_to?(:seconds)
      video.seconds
    else
      video.duration
    end
  end

  def thumbnail_url(size)
     if db?
      video.thumbnail.gsub(/maxresdefault|hqdefault/, 'mqdefault')
     else
       video.thumbnail_url(size)
     end
  end

  def humanize_duration
    Time.at(duration).utc.strftime("%H:%M:%S")
  end

  def lengthy_video?
    duration > Rails.application.credentials[Rails.env.to_sym][:VIDEO_MAX_DURATION_EVERYONE_SECONDS].to_i
  end

  def live?
    if db?
      duration.zero?
    else
      video.live_broadcast_content != "none"
    end
  end

  private

  attr_reader :video

  def db?
    video.is_a?(Video)
  end
end
