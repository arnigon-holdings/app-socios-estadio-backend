# frozen_string_literal: true

class FaceRecord < ApplicationRecord
  belongs_to :user

  validates :rekognition_face_id, presence: true, uniqueness: true
  validates :s3_bucket, presence: true
  validates :s3_key, presence: true
  validates :indexed_at, presence: true
end
