class PointAction < ApplicationRecord
  has_many :point_transactions

  validates :action_key, presence: true, uniqueness: true
  validates :points, presence: true, numericality: { only_integer: true }
  validates :description, presence: true

  scope :active, -> { where(active: true) }
end
