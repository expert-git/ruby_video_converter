class Youtube::VideosCollection

  attr_reader :search_term

  def initialize(search_term, max_results = nil)
    @search_term = search_term
    @max_results = max_results
  end

  def search_by_terms
    # Youtube API => values must be within the range: [0, 50]
    max_search_results = @max_results || 50

    # searches matching videos and returns video ids
    @videos ||= Yt::Collections::Videos.new.where(
      part: "id",
      q: search_term,
      max_results: max_search_results,
      order: "relevance"
    )
    begin
      # needed to initiate the YT API call and load the data.
      @videos.first
      # direct to fetch_videos_by_ids action
      fetch_videos_by_ids()
    rescue => e
      Rails.logger.error e.message
      return nil
    end
  end

  def fetch_videos_by_ids
    @videos = Yt::Collections::Videos.new.where(
      id: video_ids(),
      part: "id, snippet, content_details, statistics, status".freeze
    )
    # needed to initiate the YT API call and load the data.
    @videos.first

    # return all videos
    @videos
  end

  def video_ids
    unless @videos.blank?
      @videos.map { |video| video.id }.compact.join(",".freeze)
    else
      @search_term
    end
  end

  def fetch_videos_by_title
    videos = Yt::Collections::Videos.new.where(
      q: @search_term,
      max_results: @max_results,
      order: "relevance"
    )
    videos
  end


end
