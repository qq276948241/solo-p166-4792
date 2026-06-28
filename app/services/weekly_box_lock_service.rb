class WeeklyBoxLockService
  def self.lock_week(week_key)
    weekly_box = WeeklyBox.find_by(week_key: week_key)
    return unless weekly_box && !weekly_box.is_locked?

    ActiveRecord::Base.transaction do
      weekly_box.lock!
      generate_orders_for_week(weekly_box)
    end
  end

  def self.generate_orders_for_week(weekly_box)
    week_key = weekly_box.week_key
    subscriptions = Subscription.deliverable_in_week(week_key)
      .select { |s| s.should_deliver_week?(week_key) }

    subscriptions.each do |subscription|
      create_order_for_subscription(subscription, weekly_box)
    end
  end

  def self.create_order_for_subscription(subscription, weekly_box)
    return if Order.exists?(subscription: subscription, weekly_box: weekly_box)

    raise "盲盒库存不足" if weekly_box.remaining_stock <= 0

    ActiveRecord::Base.transaction do
      address = subscription.address
      box_price = weekly_box.price * subscription.box_size

      subscription.user.wallet.consume!(
        box_price,
        source: "蔬菜盲盒订阅扣费",
        remark: "#{weekly_box.week_key} 盲盒配送"
      )

      order = subscription.orders.create!(
        user: subscription.user,
        weekly_box: weekly_box,
        week_key: weekly_box.week_key,
        address_snapshot: address.to_snapshot.to_json,
        total_amount: box_price,
        status: :locked
      )

      weekly_box.weekly_box_items.each do |item|
        order.order_items.create!(
          vegetable: item.vegetable,
          vegetable_name_snapshot: item.vegetable.name,
          vegetable_unit_snapshot: item.vegetable.unit,
          quantity: item.quantity * subscription.box_size,
          unit_price: item.vegetable.price
        )
      end

      weekly_box.increment!(:sold_count)
      order
    end
  end

  def self.check_and_lock_expired
    WeeklyBox.unlocked.where("lock_at <= ?", Time.current).find_each do |box|
      lock_week(box.week_key)
    end
  end
end
