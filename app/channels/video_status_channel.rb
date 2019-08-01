class VideoStatusChannel < ApplicationCable::Channel

  def subscribed
    stream_from "status_#{params[:video_id]}_#{params[:session_identifier]}"
  end

  def unsubcribed
    Rails.logger.debug('VideoStatusChannel#unsubscribed')
  end

end
