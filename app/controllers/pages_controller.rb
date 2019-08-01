class PagesController < ApplicationController

  def robots
    respond_to :text
    expires_in 6.hours, public: true
  end

  def homepage
    videos = Video.with_information.order('created_at DESC').limit(4)
    @videos_collection = videos.map { |v| YtVideo.new(v) }
  end

  def about
  end

  # def blog
  # end

  def faq
  end

  def terms
  end

  def privacy
  end

  def dmca
  end

end
