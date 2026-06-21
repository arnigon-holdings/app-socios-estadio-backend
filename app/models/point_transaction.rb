class PointTransaction < ApplicationRecord
  belongs_to :user
  belongs_to :point_action

  validates :amount, presence: true, numericality: { only_integer: true }
  validates :user_id, presence: true
  validates :point_action_id, presence: true

  after_create :update_user_balance_cache if Rails.env.production?

  private

  def update_user_balance_cache
    Rails.cache.write(
      "user:#{user_id}:points_balance",
      user.points_balance,
      expires_in: 1.hour
    )
  end
end
