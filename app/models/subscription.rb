class Subscription < ApplicationRecord
  belongs_to :user
  belongs_to :address
  has_many :skip_weeks, dependent: :destroy
  has_many :orders, dependent: :destroy

  enum :frequency, { weekly: 0, biweekly: 1 }
  enum :status, { active: 0, paused: 1, cancelled: 2 }

  validates :frequency, :status, :start_date, presence: true
  validates :box_size, numericality: { greater_than: 0 }

  scope :deliverable_in_week, ->(week_key) {
    where(status: :active)
      .where("start_date <= ?", WeekUtils.week_start(week_key))
      .where.not(id: SkipWeek.where(week_key: week_key).select(:subscription_id))
  }

  def should_deliver_week?(week_key)
    return false unless active?
    return false if start_date > WeekUtils.week_end(week_key)
    return false if skip_weeks.exists?(week_key: week_key)

    weeks_from_start = WeekUtils.weeks_between(start_date, WeekUtils.week_start(week_key))
    weekly? || (weeks_from_start.even?)
  end

  def skip_week!(week_key, reason: nil)
    raise "该周盲盒已锁定，无法跳过" if WeeklyBox.find_by(week_key: week_key)&.is_locked?

    skip_weeks.find_or_create_by!(week_key: week_key) do |sw|
      sw.reason = reason
    end
  end

  def unskip_week!(week_key)
    raise "该周盲盒已锁定，无法取消跳过" if WeeklyBox.find_by(week_key: week_key)&.is_locked?

    skip_weeks.find_by(week_key: week_key)&.destroy
  end
end
