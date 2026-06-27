class JwtService
  SECRET_KEY = ENV.fetch("JWT_SECRET_KEY") do
    fallback = Rails.application.credentials.secret_key_base
    if Rails.env.development? || Rails.env.test?
      fallback ||= "dev_jwt_secret_key_change_in_production_min_32_chars"
    end
    fallback || raise("JWT_SECRET_KEY not set")
  end

  def self.encode(payload, exp: 1.hour.from_now)
    payload[:exp] = exp.to_i

    JWT.encode(payload, SECRET_KEY, "HS256")
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY, true, algorithm: "HS256")[0]

    if decoded["exp"] && Time.at(decoded["exp"]) < Time.current
      return nil
    end

    decoded.with_indifferent_access
  rescue JWT::DecodeError
    nil
  end
end
