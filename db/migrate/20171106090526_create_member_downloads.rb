class CreateMemberDownloads < ActiveRecord::Migration[5.1]
  def change
    create_table :member_downloads do |t|
      t.belongs_to :member, index: true
      t.belongs_to :converted_video, index: true
      t.string     :evercookie_id
      t.timestamps
    end
  end
end
