# frozen_string_literal: true

require 'will_paginate/array'
class VideosController < ApplicationController
  include Evercookie::ControllerHelpers

  before_action :authenticate_member!, only: [:download_history]
  before_action :load_converted_video, :set_evercookie_value, only: %i[download dispatch_download_file]
  before_action :remove_blocked_videos, only: :video

  def search
    if search_params[:terms].present?
      if ['http://youtu', 'http://www.youtu', 'https://youtu', 'https://www.youtu', 'http://m.youtu', 'https://m.youtu'].any? { |url| search_params[:terms].include? url }

        # fetch info from video URL
        video = Yt::URL.new(Video.format_url(search_params[:terms]))
        if video.kind.to_s == 'video'
          redirect_to action: 'video', id: video.id
        else
          flash[:error] = 'Error: Video not found. Check the URL you entered.'
          redirect_back(fallback_location: (request.referer || root_path))
        end
      else
        videos = Youtube::VideosCollection.new(search_params[:terms]).search_by_terms
        if videos.is_a?(Yt::Collections::Videos)
          @videos = videos.send(:list).to_a.paginate(page: params[:page], per_page: 12)
        else
          flash[:error] = 'Error: Sorry, no videos found.'
          redirect_back(fallback_location: (request.referer || root_path))
        end
      end
    else
      flash[:error] = 'Error: Please enter a search term.'
      redirect_back(fallback_location: (request.referer || root_path))
    end
  end

  def video
    if params[:id].present?
      # fetch info from video ID
      video = Video.with_information.find_by_ytid(params[:id])
      video ||= Yt::Video.new(id: params[:id])
    elsif params[:title].present?
      max_results = 1
      video = Video.find_by_url_title(params[:title])
      # Fetching video from youtube by performing search using the title present in the pretty url
      unless video
        found = Youtube::VideosCollection.new(params[:title], max_results).fetch_videos_by_title.first
        video = Video.with_information.find_by_ytid(found.id) if found
        video ||= found
      end
    end
    if video.blank?
      flash[:error] = 'Error: Video not found. Check the search terms you entered.'
      redirect_back(fallback_location: (request.referer || root_path))
    else
      @video = YtVideo.new(video)
      begin
        if @video.live?
          flash[:error] = 'Error: Live videos not supported'
          redirect_back(fallback_location: (request.referer || root_path))
        else
          if @video.lengthy_video?
            flash[:error] = 'Sorry, video too long. Please try another video.'
            redirect_back(fallback_location: (request.referer || root_path))
          else
            session['after_sign_up_redirect_path'] = request.original_url
            session['after_sign_in_redirect_path'] = request.original_url
            @start_time, @end_time = Video.remove_leading_zero_hours(@video.humanize_duration)
            @has_active_subscription = current_member.blank? ? false : current_member.subscriptions.active.any?
            load_gon_variables
          end
        end
      # This is to handle OpenTimeout error, this error is raised if a connection cannot be created within the open_timeout.
      rescue Net::OpenTimeout
        flash[:error] = 'Error: Network connection!'
        redirect_back(fallback_location: (request.referer || root_path))
      rescue Yt::NoItemsError
        flash[:error] = 'Error: Video not found. Check the search terms you entered.'
        redirect_back(fallback_location: (request.referer || root_path))
      end
    end
  end

  def convert
    redirect_back(fallback_location: (request.referer || root_path)) unless request.xhr?
    # evercookie_is_set? method is used to check whether evercookie is set or not
    if policy(Video).authorized_to_download?(evercookie_is_set?(:guest_uid))
      options = {
        id: params[:id],
        session_identifier: video_session_identifier,
        video_format: params[:video_format],
        start_time: params[:start_time],
        end_time: params[:end_time],
        actual_end_time: params[:actual_end_time],
        retries: 0
      }
      @video = Video.find_or_create_by!(ytid: params[:id])
      conversion_delay = Rails.application.credentials[Rails.env.to_sym][:VIDEO_WAIT_START_CONVERSION_SECONDS].to_i
      if ConvertedVideo.validate_start_end_time(params[:start_time], params[:end_time])
        VideoConversionJob.set(wait: conversion_delay).perform_later(options, @video)
      else
        @message = 'Error: Please check start time and end time values!'
      end
    else
      download_limit = Rails.application.credentials[Rails.env.to_sym][:GUEST_VIDEO_CONVERSION_LIMIT]
      @message = "Download limit of #{download_limit} videos reached. Join as member for unlimited downloads!"
    end
  end

  def download
    redirect_back(fallback_location: (request.referer || root_path)) unless request.xhr?

    if policy(@converted_video).allow_download?
      if @converted_video.video_file.file.exists?
        respond_to do |format|
          @url = "/videos/#{params[:converted_video_id]}/dispatch_download_file"
          format.js { render partial: 'download_file' }
        end
      else
        @message = 'Error: file missing.'
      end
    end
  end

  def dispatch_download_file
    @file = @converted_video.initiate_download(current_member, @converted_video, ApplicationHelper.remote_ip_address, evercookie_get_value(:guest_uid))
    send_file(
      @file,
      filename: @converted_video.filename,
      type: @converted_video.video_file.content_type,
      disposition: 'attachment'
    )
  end

  def download_history
    @download_history = ConvertedVideo.joins(:member_downloads).where('member_downloads.member_id = ?', current_member.id).paginate(page: params[:page], per_page: 8).order('created_at DESC')
  end

  def delay_download
    # evercookie_is_set? method is used to check whether evercookie is set or not
    display_guest_delay = policy(Video).show_guest_delay?(evercookie_is_set?(:guest_uid))
    data = { status: display_guest_delay, delay_seconds: Rails.application.credentials[Rails.env.to_sym][:GUEST_DELAY_COUNTDOWN_SECONDS].to_i }.to_json
    respond_to do |format|
      format.json { render json: data }
    end
  end

  private

  def search_params
    params.permit(
      :terms
    )
  end

  def load_converted_video
    @converted_video = ConvertedVideo.find_by_id(params[:converted_video_id])
  end

  # set evercookie
  def set_evercookie_value
    set_evercookie(:guest_uid, Digest::SHA1.hexdigest([Time.now, rand].join))
  end

  def load_gon_variables
    gon.video_start_time = @start_time
    gon.video_end_time = @end_time
    gon.guest_video_duration_limit_minutes = Rails.application.credentials[Rails.env.to_sym][:GUEST_VIDEO_DURATION_LIMIT_MINUTES].to_i
    gon.has_active_subscription = @has_active_subscription
    gon.video_converting_modal_showafter_seconds = Rails.application.credentials[Rails.env.to_sym][:VIDEO_CONVERTING_MODAL_SHOWAFTER_SECONDS].to_i
    gon.host_url = Rails.application.credentials[Rails.env.to_sym][:WEB_HOST] || 'http://localhost:3000'
  end

  def remove_blocked_videos
    blocked_videos = %w[calvin-harris-sam-smith-promises-official-lyric-video dTQMd2I3drE]
    blocked_videos.each do |title|
      if (params[:title].present? && params[:title].include?(title)) || (params[:id].present? && params[:id].include?(title))
        flash[:error] = 'Error: Video not found.'
        redirect_back(fallback_location: (request.referer || root_path))
      end
    end
  end
end
