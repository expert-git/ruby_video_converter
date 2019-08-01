class CreateConvertedVideos < ActiveRecord::Migration[5.1]
  def change
    create_table :converted_videos do |t|
      t.references :video, index: true
      t.string     :start_time
      t.string     :end_time
      t.integer    :duration
      t.string     :format
      t.bigint     :file_size
      t.string     :video_file
      t.string     :conversion_status
      t.integer    :download_count, default: 0
      t.string     :from
      t.integer    :conversion_time_sec
      t.timestamps
    end
    add_index :converted_videos, :download_count
  end
end