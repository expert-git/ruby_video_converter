class AddErrorMessageToConvertedVideos < ActiveRecord::Migration[5.1]
  def change
  	rename_column :converted_videos, :conversion_status, :status
    add_column :converted_videos, :status_error, :text
  end
end