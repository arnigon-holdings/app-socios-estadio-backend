class AuditLog < ApplicationRecord
  belongs_to :admin, optional: true

  validates :action, presence: true
  validates :resource_type, presence: true

  scope :recent, -> { order(created_at: :desc).limit(100) }
  scope :for_resource, ->(type, id) { where(resource_type: type, resource_id: id) }
end
