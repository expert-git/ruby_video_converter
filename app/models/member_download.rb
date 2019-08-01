class MemberDownload < ApplicationRecord
  validates :member_id, :converted_video_id, presence: true

  belongs_to :member
  belongs_to :converted_video

end
