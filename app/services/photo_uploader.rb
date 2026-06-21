class PhotoUploader
  SUPPORTED_TYPES = ["image/jpeg", "image/png"].freeze
  MAX_SIZE = 5 * 1024 * 1024 # 5MB

  def self.upload(base64_data)
    return nil if base64_data.blank?

    image = decode_base64(base64_data)
    return nil unless image

    content_type = detect_content_type(image)
    return nil unless SUPPORTED_TYPES.include?(content_type)
    return nil if image.size > MAX_SIZE

    ext = content_type == "image/png" ? "png" : "jpg"
    filename = "#{SecureRandom.uuid}.#{ext}"
    filepath = Rails.root.join("storage", "uploads", filename)

    FileUtils.mkdir_p(filepath.parent)
    File.binwrite(filepath, image)

    "/uploads/#{filename}"
  end

  def self.decode_base64(data)
    return nil unless data.starts_with?("data:")

    uri = data.split(",", 2).last
    Base64.decode64(uri)
  rescue ArgumentError
    nil
  end

  def self.detect_content_type(image)
    bytes = image[0..3].bytes
    if bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF && (0xE0..0xEF).cover?(bytes[3])
      "image/jpeg"
    elsif bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47
      "image/png"
    else
      nil
    end
  end
end
