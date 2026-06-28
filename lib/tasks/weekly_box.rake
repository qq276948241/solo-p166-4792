namespace :weekly_box do
  desc "检查并锁定已到锁定时间的盲盒，生成配送订单（每周三晚8点后调用）"
  task lock_expired: :environment do
    puts "[#{Time.current}] 开始执行盲盒锁定检查..."
    WeeklyBoxLockService.check_and_lock_expired
    puts "[#{Time.current}] 执行完成"
  end

  desc "手动锁定指定周盲盒并生成订单（传 WEEK_KEY=2026-W26）"
  task lock: :environment do
    week_key = ENV["WEEK_KEY"]
    if week_key.blank?
      puts "错误: 请指定 WEEK_KEY，例如: rails weekly_box:lock WEEK_KEY=#{WeekUtils.current_week_key}"
      exit 1
    end

    puts "[#{Time.current}] 锁定 #{week_key} 盲盒..."
    WeeklyBoxLockService.lock_week(week_key)
    puts "[#{Time.current}] 执行完成"
  end

  desc "为当前周生成示例盲盒（运营快速创建）"
  task generate_sample: :environment do
    week_key = ENV["WEEK_KEY"] || WeekUtils.next_week_key
    week_start = WeekUtils.week_start(week_key)
    week_end = WeekUtils.week_end(week_key)
    lock_at = WeekUtils.lock_time_for_week(week_key)

    box = WeeklyBox.create!(
      week_key: week_key,
      name: "新鲜蔬菜盲盒 - #{week_key}",
      description: "当周精选时令蔬菜，新鲜直达",
      week_start_date: week_start,
      week_end_date: week_end,
      lock_at: lock_at,
      price: 59.0,
      stock: 200,
      sold_count: 0,
      is_locked: false
    )

    veggies = Vegetable.active.limit(6)
    veggies.each do |veg|
      box.weekly_box_items.create!(vegetable: veg, quantity: [1, 2].sample)
    end

    puts "已创建 #{week_key} 盲盒 (ID: #{box.id})"
    puts "价格: ¥#{box.price}, 库存: #{box.stock}"
    puts "菜品数量: #{box.weekly_box_items.count}"
  end
end
