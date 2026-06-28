class Address < ApplicationRecord
  belongs_to :user

  validates :name, :phone, :province, :city, :district, :detail, presence: true
  validates :phone, format: { with: /\A1[3-9]\d{9}\z/, message: "手机号格式不正确" }

  before_save :ensure_single_default

  def full_address
    "#{province}#{city}#{district}#{detail}"
  end

  def to_snapshot
    {
      name: name,
      phone: phone,
      province: province,
      city: city,
      district: district,
      detail: detail,
      full_address: full_address
    }
  end

  private

  def ensure_single_default
    return unless is_default?
    user.addresses.where.not(id: id).update_all(is_default: false)
  end
end
