# frozen_string_literal: true

class FaceIndexer
  Result = Struct.new(:status, :face_record, :error, keyword_init: true)

  def self.index(user:, reference_photo_base64:, audit_images: [])
    new(user, reference_photo_base64, audit_images).index
  end

  def initialize(user, reference_photo_base64, audit_images)
    @user = user
    @reference_photo_base64 = reference_photo_base64
    @audit_images = Array(audit_images)
  end

  def index
    return Result.new(status: :skipped, error: 'AWS_S3_BUCKET_NAME not configured') if bucket.blank?
    return Result.new(status: :skipped, error: 'REKOGNITION_COLLECTION_ID not configured') if collection.blank?

    reference = S3Uploader.upload_base64(
      bucket: bucket,
      key_prefix: "users/#{@user.id}/reference",
      base64_data: @reference_photo_base64
    )
    return Result.new(status: :invalid_photo, error: 'reference photo missing or invalid') if reference.nil?

    upload_audit_images

    response = rekognition_client.index_faces(
      collection_id: collection,
      image: { s3_object: { bucket: bucket, name: reference[:s3_key] } },
      external_image_id: @user.id.to_s,
      detection_attributes: ['DEFAULT'],
      max_faces: 1,
      quality_filter: 'AUTO'
    )

    face = response.face_records.first
    return Result.new(status: :no_face_detected, error: 'Rekognition detected no face in reference photo') if face.nil?

    face_record = persist(face.face.face_id, reference[:s3_key])

    Result.new(status: :indexed, face_record: face_record)
  rescue Aws::Errors::ServiceError, StandardError => e
    Rails.logger.error("[FaceIndexer] user=#{@user.id} error=#{e.class}: #{e.message}")
    Result.new(status: :error, error: "#{e.class}: #{e.message}")
  end

  private

  def persist(face_id, s3_key)
    FaceRecord.transaction do
      record = FaceRecord.create!(
        user: @user,
        rekognition_face_id: face_id,
        s3_bucket: bucket,
        s3_key: s3_key,
        indexed_at: Time.current
      )
      @user.update!(indexed_at: record.indexed_at)
      record
    end
  end

  def upload_audit_images
    @audit_images.each_with_index do |img, idx|
      S3Uploader.upload_base64(
        bucket: bucket,
        key_prefix: "users/#{@user.id}/audit",
        base64_data: img
      )
    rescue StandardError => e
      Rails.logger.warn("[FaceIndexer] audit image upload failed user=#{@user.id} idx=#{idx} error=#{e.class}: #{e.message}")
    end
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
