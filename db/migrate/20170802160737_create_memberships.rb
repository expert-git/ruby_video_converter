class CreateMemberships < ActiveRecord::Migration[5.1]
  def change
    create_table :memberships do |t|
      t.string :name
      t.string :stripe_id
      t.string :interval
      t.integer :interval_count
      t.integer :amount
      t.string :currency
      t.integer :trial_period_days

      t.timestamps
    end
  end
end
