require_relative "../lib/week_utils"

puts "=== 开始创建种子数据 ==="

ActiveRecord::Base.transaction do
  puts "1. 创建管理员账号..."
  admin = User.find_or_initialize_by(phone: "13800000000")
  admin.update!(
    password: "admin123",
    password_confirmation: "admin123",
    nickname: "运营管理员",
    role: :admin
  )
  puts "   管理员手机号: 13800000000 / 密码: admin123"

  puts "2. 创建测试用户..."
  user1 = User.find_or_initialize_by(phone: "13811111111")
  user1.update!(
    password: "user1234",
    password_confirmation: "user1234",
    nickname: "张小明"
  )
  puts "   用户1手机号: 13811111111 / 密码: user1234"

  user2 = User.find_or_initialize_by(phone: "13822222222")
  user2.update!(
    password: "user1234",
    password_confirmation: "user1234",
    nickname: "李小红"
  )
  puts "   用户2手机号: 13822222222 / 密码: user1234"

  puts "3. 创建收货地址..."
  [user1, user2].each_with_index do |user, idx|
    user.addresses.find_or_create_by!(name: "#{user.nickname}家") do |addr|
      addr.phone = user.phone
      addr.province = "上海市"
      addr.city = "上海市"
      addr.district = idx == 0 ? "浦东新区" : "徐汇区"
      addr.detail = idx == 0 ? "陆家嘴环路1000号1栋101室" : "漕河泾开发区888弄5栋501室"
      addr.is_default = true
    end
  end

  puts "4. 给用户充值虚拟余额..."
  user1.wallet.recharge!(500.00, source: "种子数据赠送", remark: "初始赠送500元")
  user2.wallet.recharge!(300.00, source: "种子数据赠送", remark: "初始赠送300元")
  puts "   用户1余额: ¥#{user1.wallet.balance}"
  puts "   用户2余额: ¥#{user2.wallet.balance}"

  puts "5. 创建菜品基础库..."
  veggies_data = [
    { name: "西红柿", unit: "500g", price: 5.0, stock: 200, description: "自然成熟，酸甜可口" },
    { name: "黄瓜", unit: "500g", price: 4.5, stock: 300, description: "新鲜脆嫩，清香爽口" },
    { name: "土豆", unit: "1kg", price: 6.0, stock: 500, description: "黄心土豆，粉糯香甜" },
    { name: "青椒", unit: "500g", price: 8.0, stock: 180, description: "果肉厚实，微辣带甜" },
    { name: "胡萝卜", unit: "500g", price: 4.0, stock: 400, description: "富含胡萝卜素，营养丰富" },
    { name: "上海青", unit: "500g", price: 5.5, stock: 250, description: "叶质柔软，清香美味" },
    { name: "西兰花", unit: "1颗(约400g)", price: 9.0, stock: 150, description: "花球紧实，翠绿色美" },
    { name: "茄子", unit: "500g", price: 6.5, stock: 220, description: "紫黑油亮，肉质细嫩" },
    { name: "生菜", unit: "1颗(约300g)", price: 4.0, stock: 200, description: "叶色翠绿，口感清爽" },
    { name: "玉米", unit: "2根", price: 8.0, stock: 160, description: "甜糯可口，颗粒饱满" }
  ]

  veggies = {}
  veggies_data.each do |v|
    veggies[v[:name]] = Vegetable.find_or_create_by!(name: v[:name]) do |veg|
      veg.update!(v)
    end
  end
  puts "   共创建 #{veggies.count} 种菜品"

  puts "6. 创建本周和下周盲盒..."
  current_week_key = WeekUtils.current_week_key
  next_week_key = WeekUtils.next_week_key

  [
    {
      week_key: current_week_key,
      name: "夏日清爽盲盒",
      description: "精选夏日清凉菜品，消暑解热",
      price: 59.0,
      stock: 200,
      items: [
        { veg: "西红柿", qty: 2 },
        { veg: "黄瓜", qty: 2 },
        { veg: "生菜", qty: 2 },
        { veg: "青椒", qty: 1 },
        { veg: "玉米", qty: 1 }
      ]
    },
    {
      week_key: next_week_key,
      name: "营养均衡盲盒",
      description: "营养搭配均衡，一家大小都爱吃",
      price: 68.0,
      stock: 200,
      items: [
        { veg: "土豆", qty: 1 },
        { veg: "胡萝卜", qty: 2 },
        { veg: "西兰花", qty: 2 },
        { veg: "茄子", qty: 1 },
        { veg: "上海青", qty: 2 },
        { veg: "玉米", qty: 1 }
      ]
    }
  ].each do |box_data|
    week_start = WeekUtils.week_start(box_data[:week_key])
    week_end = WeekUtils.week_end(box_data[:week_key])
    lock_at = WeekUtils.lock_time_for_week(box_data[:week_key])

    box = WeeklyBox.find_or_create_by!(week_key: box_data[:week_key]) do |b|
      b.assign_attributes(
        name: box_data[:name],
        description: box_data[:description],
        week_start_date: week_start,
        week_end_date: week_end,
        lock_at: lock_at,
        price: box_data[:price],
        stock: box_data[:stock],
        sold_count: 0,
        is_locked: false
      )
    end

    box_data[:items].each do |item|
      veg = veggies[item[:veg]]
      box.weekly_box_items.find_or_create_by!(vegetable: veg) do |bi|
        bi.quantity = item[:qty]
      end
    end
    puts "   #{box_data[:week_key]} - #{box_data[:name]} (¥#{box_data[:price]})"
  end

  puts "7. 创建测试用户订阅..."
  user1.subscriptions.find_or_create_by!(
    address: user1.default_address,
    frequency: :weekly,
    status: :active,
    start_date: Date.today - 14,
    box_size: 1
  )

  user2.subscriptions.find_or_create_by!(
    address: user2.default_address,
    frequency: :biweekly,
    status: :active,
    start_date: Date.today - 7,
    box_size: 1
  )
  puts "   用户1订阅: 周配（每周配送）"
  puts "   用户2订阅: 双周配（隔周配送）"

  puts ""
  puts "=== 种子数据创建完成 ==="
  puts ""
  puts "提示: 如需生成本周订单，可调用 POST /weekly_boxes/check_lock 或 POST /weekly_boxes/:id/lock"
  puts ""
end
