class Team < ApplicationRecord
  has_many :users

  validates :name, presence: true, uniqueness: true
  validates :short_name, presence: true, uniqueness: true, allow_blank: true

  scope :active, -> { where(active: true) }
end
