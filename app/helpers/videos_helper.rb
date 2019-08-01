module VideosHelper

  def seconds_to_time_helper(seconds)
    if seconds < 3600
      format = '%M:%S'
    else
      format = '%H:%M:%S'
    end
    Time.at(seconds).utc.strftime(format)
  end

  def number_with_delimiter_helper(number)
    number_with_delimiter(number.to_s, delimiter: ",")
  end

  def published_at_helper(date)
    return nil if date.blank?
    date.strftime("%b %d, %Y")
  end

  def download_at_helper(datetime)
    datetime.strftime("%m/%d/%Y")
  end

  def serial_number_helper(page, per_page, row)
    count = ((page || 1).to_i - 1) * per_page
    count + row + 1
  end

end
