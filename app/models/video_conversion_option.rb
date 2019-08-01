class VideoConversionOption
  include ActiveModel::Model

  attr_accessor :id, :session_identifier, :video_format,
                :start_time, :end_time, :actual_end_time, :retries
  validates :id, :session_identifier, :video_format,
             :start_time, :end_time, :retries, presence: true

  validates_each :start_time, :end_time do |record, attr, value|
    record.errors.add attr, :invalid if value !~ /\A[0-9:]+\z/
  end
end
