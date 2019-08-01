if Rails.env.production?
  FFMPEG.ffmpeg_binary = "/opt/ffmpeg-static/ffmpeg"
  FFMPEG.ffprobe_binary = "/opt/ffmpeg-static/ffprobe"
end
