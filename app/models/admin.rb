class Admin < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, presence: true, inclusion: { in: %w[admin superadmin] }

  before_validation :downcase_email

  def last_login_update!
    update!(last_login_at: Time.current)
  end

  private

  def downcase_email
    self.email = email.downcase.strip if email.present?
  end
end
