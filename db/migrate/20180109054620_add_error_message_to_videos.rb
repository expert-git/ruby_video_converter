class AddErrorMessageToVideos < ActiveRecord::Migration[5.1]
  def change
  	add_column :videos, :status, :string
  	add_column :videos, :status_error, :text
  end
end