class WeeklyBoxLockJob < ApplicationJob
  queue_as :default

  def perform
    WeeklyBoxLockService.check_and_lock_expired
  end
end
