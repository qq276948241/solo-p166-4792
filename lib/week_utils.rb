module WeekUtils
  WEEK_KEY_FORMAT = "%G-W%V"

  def self.current_week_key(date = Date.today)
    date.strftime(WEEK_KEY_FORMAT)
  end

  def self.next_week_key(date = Date.today)
    (date + 7.days).strftime(WEEK_KEY_FORMAT)
  end

  def self.week_start(week_key)
    year, week = week_key.split("-W").map(&:to_i)
    Date.commercial(year, week, 1)
  end

  def self.week_end(week_key)
    week_start(week_key) + 6.days
  end

  def self.weeks_between(start_date, end_date)
    ((end_date.beginning_of_week - start_date.beginning_of_week).to_i / 7).to_i
  end

  def self.lock_time_for_week(week_key)
    week_start = week_start(week_key)
    lock_date = week_start - 4.days
    Time.zone.local(lock_date.year, lock_date.month, lock_date.day, 20, 0, 0)
  end

  def self.generate_week_key_for_date(date)
    date.strftime(WEEK_KEY_FORMAT)
  end
end
