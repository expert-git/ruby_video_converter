class AddConfirmableToDevise < ActiveRecord::Migration[5.1]
  def change
    ## Confirmable
    add_column :members, :confirmation_token, :string
    add_column :members, :confirmed_at, :datetime
    add_column :members, :confirmation_sent_at, :datetime
    add_column :members, :unconfirmed_email, :string
    add_index :members, :confirmation_token,   unique: true
  end


end
