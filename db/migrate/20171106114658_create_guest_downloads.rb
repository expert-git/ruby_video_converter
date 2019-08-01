class CreateGuestDownloads < ActiveRecord::Migration[5.1]
  def change
    create_table :guest_downloads do |t|
      t.inet     :remote_ip_address
      t.integer  :download_count, default: 0
      t.string   :evercookie_id
      t.timestamps
    end
  end
end