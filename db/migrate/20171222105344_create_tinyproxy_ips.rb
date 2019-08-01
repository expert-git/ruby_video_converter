class CreateTinyproxyIps < ActiveRecord::Migration[5.1]
  def change
    create_table   :tinyproxy_ips do |t|
      t.references :video, index: true
      t.inet       :ip_address
	    t.datetime   :last_used_at
	    t.integer    :total_requests, default: 0
	    t.string     :download_status
      t.timestamps
    end
  end
end
