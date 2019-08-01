class CreateVideos < ActiveRecord::Migration[5.1]
  def change
    create_table :videos do |t|
      t.string   :title
      t.string   :ytid
      t.string   :url_title # to make the url of the current video page
      t.integer  :duration
      t.string   :description
      t.datetime :published_on
      t.float    :rating
      t.string   :thumbnail
      t.integer  :views
      t.string   :related
      t.string   :category
      t.datetime :last_modified
      t.datetime :last_converted
      t.string   :video_file
      t.string   :format
      t.bigint   :file_size
      t.text     :keywords
      t.integer  :yt_download_time_sec
      t.timestamps
    end
    # add_index :videos, :title
    # add_index :videos, :ytid
  end
end
