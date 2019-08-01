class VideoConversionJob < ApplicationJob
  include ::NewRelic::Agent::MethodTracer

  queue_as (Rails.application.credentials[Rails.env.to_sym][:VIDEO_CONVERSION_JOB_QUEUE] || :video_conversion_job).to_sym

  def perform(options, video)
    @fetch_start_time = Time.now
    # Fetch video from DB using id of an video object
    @video = Video.find_by_id(video.id)
    @options = options
    @request_options = Video.build_options()
    @proxy = @request_options[:proxy]


    validator = VideoConversionOption.new(options)
    unless validator.valid?
      logger.error "Job enqueued with invalid options, #{validator.errors.to_hash.inspect}"
      Rollbar.warning("Job [#{job_id}] enqueued with invalid options", options: options, video: video, errors: validator.errors.to_hash)

      return
    end
    # Convert video start time and end time in required format
    @start_time = pad_leading_zero_hours(@options[:start_time])
    @end_time = pad_leading_zero_hours(@options[:end_time])

    # Calculate user request duration of the video, using user inputted start time and end time
    @requested_duration = (@start_time.to_time - @end_time.to_time).to_i.abs

    # Analyzing conversion options
    update_status(@video, 0)
    @youtube_video = initialize_youtube_video_object()

    begin
      # Check if master video is available
      if master_video_available_and_complete?() # returns true or false
        @video_source = "master_file"
        puts "[YTID: #{@options[:id]}] '#{@video_source}' file available, skipping 'youtube_dl'"
      else
        @video_source = "youtube_dl"
        puts "[YTID: #{@options[:id]}][#{@proxy["instance_name"]}: #{@proxy["proxy"]}] Downloading with '#{@video_source}'"
        fetch_master_video()
      end

      # Check if converted video is available
      @conversion_start_time = Time.now
      if converted_video_available?()
        puts "[YTID: #{@options[:id]}] Using identical video from 'converted_videos' DB"
      else
        # check if master copy & converted video are same
        if check_converted_video_and_master_copy_same?()
          puts "[YTID: #{@options[:id]}] Copying from '#{@video_source}' to 'converted_video' DB"
          copy_master_video_to_convert_video()
        else
          puts "[YTID: #{@options[:id]}] FFMPEG from '#{@video_source}' to 'converted_video' DB"
          convert_video_from_master()
        end
      end

      # Display status message and update progress bar
      update_status(@video, 9, {requested_extension: @requested_extension})
      total_conversion_time = calculate_process_time_in_seconds(@fetch_start_time, Time.now)
      puts "[YTID: #{@options[:id]}] Success, video converted to #{@requested_extension.upcase} in #{total_conversion_time} seconds"

    # Proxy IP error exception
    rescue StandardError => e
      status = handle_exception(e)

      unless status
        logger.error e.message
        e.backtrace.each { |line| logger.info line }
        Rollbar.error(e, video_id: @options[:id])
      end

      status ||= 11

      @tinyproxy_ip.update_attribute(:download_status, 'failed') if @video.check_incomplete_master_video() && !@tinyproxy_ip.blank?
      # update error message for video & converted_video
      if @video.check_incomplete_master_video()
        @video.update_attributes({status: "Failed", status_error: full_error_message(e)})
      else
        if @converted_video.blank?
          ConvertedVideo.create!(
            video_id: @video.id,
            start_time: @start_time,
            end_time: @end_time,
            duration: @requested_duration,
            format: @requested_extension,
            status: "Failed",
            from: @video_source,
            status_error: full_error_message(e)
          )
        else
          @converted_video.update_attribute(:status_error, full_error_message(e))
        end
      end

      update_status(@video, status, {requested_extension: @requested_extension})


      # destroy the incomplete video record
      #@video.destroy if @video.check_incomplete_master_video()
      puts "[YTID: #{@options[:id]}][#{@proxy["instance_name"]}: #{@proxy["proxy"]}] Youtube-dl failed error: #{e.message.truncate(500)}"
    end
  end

  # Initialize youtube video object
  def initialize_youtube_video_object
    # Find user requested file format and master copy extension
    @requested_extension = @options[:video_format]
    @master_extension = "mp4"

    # Build the Youtube video url
    url = "https://www.youtube.com/watch?v=" + @options[:id]

    # Initialise YoutubeDL video object
    YoutubeDL::Video.new(url, @request_options[:youtube_options])
  end

  def fetch_video_information
    @youtube_video.information
  end
  add_method_tracer :fetch_video_information

  def download_video
    @youtube_video.download
  end
  add_method_tracer :download_video

  # Check if master MP4 is in DB already
  def master_video_available_and_complete?
    @video.title.present? && !@video.check_incomplete_master_video()
  end

  # Fetching MP4 master video details from Youtube
  def fetch_master_video

    # Create a record in tinyproxy_ips
    note_tinyproxy_request_details()

    # Fetch information of the video from Youtube
    video_information = fetch_video_information

    @tinyproxy_ip.update_attribute(:download_status, 'success') unless @tinyproxy_ip.blank?

    published_on = video_information[:upload_date].blank? ? nil : Date.strptime(video_information[:upload_date], "%Y%m%d").to_s(:db)
    video_details = {
      title: video_information[:fulltitle],
      duration: video_information[:duration],
      description: video_information[:description],
      published_on: published_on,
      rating: video_information[:average_rating].to_f.round(2),
      thumbnail: video_information[:thumbnails].first[:url],
      views: video_information[:view_count],
      format: @master_extension,
      keywords: video_information[:tags].empty? ? nil : video_information[:tags].join(", ")
    }
    @video.update_attributes(video_details)

    # Download video to /lib/assets/<title>.mp4 folder
    update_status(@video, 1)
    download_video

    update_status(@video, 2)
    store_master_video(video_information)

    calculate_process_time_in_seconds(@fetch_start_time, Time.now, @video, "yt_download_time_sec")
  end

  def check_converted_video_and_master_copy_same?
    update_status(@video, 3)
    # Convert video actual end time in required format
    actual_end_time = pad_leading_zero_hours(@options[:end_time])

    @start_time == "00:00:00" && actual_end_time == @end_time && @requested_extension == "mp4"
  end

  def copy_master_video_to_convert_video
    update_status(@video, 4)

    update_status(@video, 5)

    video_location = @video.video_file_path
    update_status(@video, 6)
    video_file_data = open(video_location)

    @converted_video = ConvertedVideo.create!(
      video_id: @video.id,
      start_time: @start_time,
      end_time: @end_time,
      duration: @video.duration,
      format: @requested_extension,
      video_file: video_file_data,
      file_size: File.size(video_file_data),
      status: "Success",
      from: @video_source
    )
    update_status(@video, 7)

    calculate_process_time_in_seconds(@conversion_start_time, Time.now, @converted_video, "conversion_time_sec")
    update_status(@video, 8)
  end
  add_method_tracer :copy_master_video_to_convert_video

  def converted_video_available?
    update_status(@video, 3)

    # Check whether the requested video is present in converted_videos table
    @converted_video = @video.converted_videos.where(start_time: @start_time, end_time: @end_time, format: @requested_extension, status: "Success").last
    @converted_video.present?
  end

  def convert_video_from_master
    update_status(@video, 4)

    requested_file_name = "#{@video.video_file.file.filename.rpartition('.').first}.#{@requested_extension}"

    # If master video incomplete fetch master video
    fetch_master_video if @video.check_incomplete_master_video()

    video_location = "lib/assets/#{requested_file_name}"

    transcode(video_location)

    # Saving converted/cropped video or audio file
    update_status(@video, 7)
    @converted_video = ConvertedVideo.create!(
      video_id: @video.id,
      start_time: @start_time,
      end_time: @end_time,
      duration: @requested_duration,
      format: @requested_extension,
      video_file: Rails.root.join(video_location).open,
      file_size: File.size(video_location),
      status: "Success",
      from: @video_source
    )
    update_status(@video, 8)
    File.delete(video_location)

    calculate_process_time_in_seconds(@conversion_start_time, Time.now, @converted_video, "conversion_time_sec")
  end

    # Fetch the video location path and format the path name. The downloaded video will be saved to /tmp/video location.
  def store_master_video(info)
    downloaded_file_path = info[:_filename].rpartition(".").first + ".mp4"
    @video.update_attributes({video_file: open(downloaded_file_path), status: "Success"})

    # Delete video from /lib/assets/ folder
    File.delete(downloaded_file_path)
  end
  add_method_tracer :store_master_video

  def transcode(location)
    # Build options to crop the file
    opts = {}
    if @requested_duration < @video.duration
      opts.merge!(
        seek_time: time_in_seconds(@start_time),
        duration: @requested_duration
      )
    end

    if location.include?('mp3')
      opts.merge!(
        write_xing: 0
      )
    end

    # Initialise FFMPEG Movie object
    original_video = FFMPEG::Movie.new(@video.video_file_path)

    # Convert/Crop the file, can be a audio or video format
    update_status(@video, 5)

    original_video.transcode(location, opts)
    update_status(@video, 6)
  end
  add_method_tracer :transcode

  def calculate_process_time_in_seconds(start_time, end_time, object = nil, column_name = nil)
    seconds = (end_time - start_time).round
    object.update_attribute(column_name.to_sym, seconds) unless object.blank?
    seconds
  end

  def display_flash_message(message_type, message)
    ApplicationController.renderer.new.render(partial: 'layouts/flash_message', locals: {message_type: message_type, message: message})
  end

  # flash message after conversion complete/failed
  def update_status(video, status, opts = {})
    stream = "status_#{video.ytid}_#{@options[:session_identifier]}"
    options = fetch_status_percentage(status)
    options[:status_code] = status
    options[:conversion_time_in_sec] = opts[:conversion_time_in_sec]
    options[:retries] = @options[:retries]
    options[:proxy_retry_limit] = Rails.application.credentials[Rails.env.to_sym][:TINYPROXY_RETRY_LIMIT].to_i

    # Conversion successful
    case status
    when 9
      message_type = "success"
      message = "Success: Video converted to #{opts[:requested_extension].upcase}"
      options.merge!(converted_video_id: @converted_video.id) unless @converted_video.blank?

    # Conversion failed, retrying with new proxy
    when 10
      @converted_video.update_attributes(status: "Failed") unless @converted_video.blank?
      message_type = "notice"
      message = "We experienced a hiccup, automatically trying conversion again..."

    # Conversion failed after 3 proxy tries
    when 11
      @converted_video.update_attributes(status: "Failed") unless @converted_video.blank?
      message_type = "error"
      message = "Error: Convert to 'MP4' format first, then try converting to your format again."
    # Conversion failed due to video being blocked
    when 12
      @converted_video.update_attributes(status: "Failed") unless @converted_video.blank?
      message_type = "error"
      message = "Error: Unable to convert video, please try another"
    end

    options.merge!(display_flash_message: display_flash_message(message_type, message)) unless message.blank?
    ActionCable.server.broadcast(stream, options)
  end

  def fetch_status_percentage(status)
    statuses = {
      0 => {
        conversion_status: "Analyzing your conversion options...",
        percentage: 10
      },
      1 => {
        conversion_status: "Fetching video...",
        percentage: 20
      },
      2 => {
        conversion_status: "Transferring video...",
        percentage: 30
      },
      3 => {
        conversion_status: "Analyzing video...",
        percentage: 40
      },
      4 => {
        conversion_status: "Preparing video for conversion...",
        percentage: 50
      },
      5 => {
        conversion_status: "Converting video to your format...",
        percentage: 60
      },
      6 => {
        conversion_status: "Finalizing video conversion...",
        percentage: 70
      },
      7 => {
        conversion_status: "Preparing video for download...",
        percentage: 80
      },
      8 => {
        conversion_status: "Finalizing video for download...",
        percentage: 90
      },
      9 => {
        conversion_status: "Finished, video ready to download",
        percentage: 100
      },
      10 => {
        conversion_status: "Request failed, automatically trying conversion again...",
        percentage: 0
      },
      11 => {
        conversion_status: "Request failed, please try converting to 'MP4' format first.",
        percentage: 0
      },
      12 => {
        conversion_status: "Unable to convert video, please try another",
        percentage: 0
      }
    }
    statuses[status]
  end

  def time_in_seconds(time)
    time = Time.parse(time)
    time.hour * 60 * 60 + time.min * 60 + time.sec
  end

  def pad_leading_zero_hours(time)
    if time.split(":").length == 2
      time = "00:#{time}"
    end
    time
  end

  def note_tinyproxy_request_details
    unless @proxy["proxy"].blank?
      tinyproxy_ip = TinyproxyIp.where("ip_address = ?", @proxy["ip"]).order('last_used_at ASC').last
      request_count = tinyproxy_ip.blank? ? 1 : tinyproxy_ip.total_requests + 1
      @tinyproxy_ip = TinyproxyIp.create(video_id: @video.id, ip_address: @proxy["ip"], last_used_at: Time.now.utc, total_requests: request_count, download_status: "in_progress")
    end
  end

  def full_error_message(error)
    error.message + "/n" + error.backtrace.join("/n")
  end

  def handle_exception(exception)
    handlers = [:handle_blocked_video_exception].map do |handler|
      status = send(handler, exception)

      status if status
    end

    handlers.compact.first
  end

  # should return status if handled exception
  # or false if it doesn't handle this exception
  def handle_blocked_video_exception(exception)
    return false unless exception.is_a?(Cocaine::ExitStatusError)
    return false unless exception.message.match(/ERROR: .*: YouTube said/)

    yt_video = Yt::Video.new(id: @options[:id])

    yt_video.duration

    region_restriction = yt_video.data.dig(:content_details, "regionRestriction")
    blocked = region_restriction["blocked"]
    allowed = region_restriction["allowed"]

    return false unless blocked.present? || allowed.present?

    puts "[YTID: #{@options[:id]}] blocked in #{blocked} countries" if blocked.present?
    puts "[YTID: #{@options[:id]}] allowed only in #{allowed} countries" if allowed.present?

    12
  rescue => e
    logger.error e.message
    e.backtrace.each { |line| logger.info line }
    Rollbar.error(e, video_id: @options[:id])

    false
  end
end
