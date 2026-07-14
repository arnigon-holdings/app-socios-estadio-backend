# frozen_string_literal: true

# Deletes face records from Rekognition and S3 when a user is deleted.
# Called before destroying the user record in Postgres.
class FaceDeleter
  def self.delete_for_user(user)
    new(user).delete
  end

  def initialize(user)
    @user = user
  end

  def delete
    return if bucket.blank? || collection.blank?

    @user.face_records.each do |record|
      delete_from_rekognition(record.rekognition_face_id)
      delete_from_s3(record.s3_bucket, record.s3_key)
    end
  end

  private

  def delete_from_rekognition(face_id)
    return if face_id.blank?

    rekognition_client.delete_faces(
      collection_id: collection,
      face_ids: [face_id]
    )
  rescue StandardError => e
    Rails.logger.warn("[FaceDeleter] rekognition delete_faces face_id=#{face_id} error=#{e.class}: #{e.message}")
  end

  def delete_from_s3(bucket, key)
    return if bucket.blank? || key.blank?

    S3Uploader.delete(bucket: bucket, key: key)
  end

  def bucket
    ENV['AWS_S3_BUCKET_NAME']
  end

  def collection
    ENV['REKOGNITION_COLLECTION_ID']
  end

  def rekognition_client
    @rekognition_client ||= Aws::Rekognition::Client.new
  end
end
