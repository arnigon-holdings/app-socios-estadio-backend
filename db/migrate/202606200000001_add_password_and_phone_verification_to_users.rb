class AddPasswordAndPhoneVerificationToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :password_digest, :string
    add_column :users, :phone_verified, :boolean, default: false
    add_column :users, :phone_verification_token, :string
    add_column :users, :phone_verified_at, :datetime
  end
end
