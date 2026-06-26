# frozen_string_literal: true

class S3Uploader
  SUPPORTED_TYPES = {
    'image/jpeg' => 'jpg',
    'image/png' => 'png'
  }.freeze
  MAX_BYTES = 5 * 1024 * 1024

  def self.put_object(bucket:, key:, bytes:, content_type:)
    raise ArgumentError, 'bucket required' if bucket.blank?
    raise ArgumentError, 'key required' if key.blank?
    raise ArgumentError, 'bytes required' if bytes.blank?
    raise ArgumentError, "unsupported content_type: #{content_type}" unless SUPPORTED_TYPES.key?(content_type)
    raise ArgumentError, 'bytes exceed MAX_BYTES' if bytes.bytesize > MAX_BYTES

    client = Aws::S3::Client.new
    client.put_object(
      bucket: bucket,
      key: key,
      body: bytes,
      content_type: content_type,
      server_side_encryption: 'AES256'
    )

    "s3://#{bucket}/#{key}"
  end

  def self.upload_base64(bucket:, key_prefix:, base64_data:)
    bytes, content_type = decode(base64_data)
    return nil unless bytes

    ext = SUPPORTED_TYPES[content_type]
    key = "#{key_prefix}/#{SecureRandom.uuid}.#{ext}"
    put_object(bucket: bucket, key: key, bytes: bytes, content_type: content_type)

    { s3_key: key, s3_uri: "s3://#{bucket}/#{key}", content_type: content_type }
  end

  def self.decode(data)
    return nil if data.blank?

    payload = data.start_with?('data:') ? data.split(',', 2).last : data
    bytes = Base64.decode64(payload)

    content_type = detect_content_type(bytes)
    return nil unless SUPPORTED_TYPES.key?(content_type)

    [bytes, content_type]
  rescue ArgumentError
    nil
  end

  def self.detect_content_type(bytes)
    b = bytes[0..3].bytes
    return 'image/jpeg' if b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF && (0xE0..0xEF).cover?(b[3])
    return 'image/png' if b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47

    nil
  end
end
