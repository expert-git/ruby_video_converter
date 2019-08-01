class ChangeViewsCountToBigint < ActiveRecord::Migration[5.1]
  def change
    change_column :videos, :views, :bigint
  end
end
