class Youtube::ProcessVideo

  attr_reader :youtube_video

  def initialize(video_id)
    @youtube_video = Yt::Video.new(id: video_id)
  end

  def fetch_video
    @youtube_video.select(:snippet, :content_details, :statistics, :status)
    @youtube_video
  end

end
