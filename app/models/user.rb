class User < ApplicationRecord
  has_secure_password

  has_many :point_transactions, dependent: :destroy
  has_many :point_actions, through: :point_transactions

  validates :rut, presence: true, uniqueness: true
  validates :phone, presence: true
  validates :birth_month, presence: true, inclusion: { in: 1..12 }
  validates :birth_year, presence: true
  validates :photo_url, presence: true
  validates :teams_ids, length: { maximum: 5 }, allow_blank: true

  validate :validate_rut_format
  validate :validate_rut_checksum
  validate :validate_birth_year

  before_validation :normalize_rut

  def points_balance
    point_transactions.sum(:amount)
  end

  def phone_verified?
    phone_verified
  end

  private

  def normalize_rut
    return unless rut.present?

    self.rut = rut.gsub(/[.\-]/, "").upcase
  end

  def validate_rut_format
    return unless rut.present?

    unless rut =~ /^\d{7,8}[0-9K]$/i
      errors.add(:rut, "formato inválido")
    end
  end

  def validate_rut_checksum
    return unless rut.present?
    return unless rut =~ /^\d{7,8}[0-9K]$/i

    body = rut[0..-2].to_i
    dv = rut[-1].upcase

    sum = body.to_s.chars.reverse.each_with_index.sum do |digit, i|
      digit.to_i * (i + 2)
    end

    remainder = sum % 11
    expected = case 11 - remainder
               when 10 then "K"
               when 11 then "0"
               else (11 - remainder).to_s
               end

    unless dv == expected
      errors.add(:rut, "inválido")
    end
  end

  def validate_birth_year
    return unless birth_year.present?

    if birth_year < 1900 || birth_year > Date.current.year
      errors.add(:birth_year, "año inválido")
    end
  end
end
