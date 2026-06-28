class JwtService
  SECRET = Rails.application.config.jwt_secret
  ALGORITHM = "HS256"
  EXPIRATION = 7.days

  def self.encode(payload, exp: EXPIRATION.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET, ALGORITHM)
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET, true, algorithm: ALGORITHM).first
    decoded.with_indifferent_access
  rescue JWT::ExpiredSignature, JWT::VerificationError, JWT::DecodeError
    nil
  end
end
