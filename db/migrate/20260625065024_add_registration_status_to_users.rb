class AddRegistrationStatusToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :registration_status, :string
  end
end
