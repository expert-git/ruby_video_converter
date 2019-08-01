class AddIndexesToVideos < ActiveRecord::Migration[5.1]
  def change
    change_table :videos do |t|
      t.index :url_title
      t.index :ytid
    end
  end
end
