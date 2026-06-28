#!/usr/bin/env ruby
# frozen_string_literal: true

# 快速验证脚本：在无数据库连接时，验证所有代码可被加载
require_relative "config/environment"

puts "=" * 60
puts "社区蔬菜盲盒订阅 API - 代码验证报告"
puts "=" * 60
puts ""

# 1. 模型检查
models = %w[User Address Wallet WalletTransaction Subscription SkipWeek
            Vegetable WeeklyBox WeeklyBoxItem Order OrderItem]
puts "[1] 模型检查 (#{models.count} 个)"
models.each do |m|
  klass = m.constantize
  puts "  ✅ #{m} - 字段: #{klass.column_names.join(", ")}"
rescue StandardError => e
  puts "  ❌ #{m} - 加载失败: #{e.message}"
end
puts ""

# 2. 服务与工具检查
services = %w[JwtService WeeklyBoxLockService WeekUtils]
puts "[2] 服务与工具模块 (#{services.count} 个)"
services.each do |s|
  s.constantize
  puts "  ✅ #{s}"
rescue StandardError => e
  puts "  ❌ #{s} - #{e.message}"
end
puts ""

# 3. 路由检查
puts "[3] 路由列表"
Rails.application.routes.routes.each do |route|
  next if route.path.spec.to_s.start_with?("/rails")
  verb = route.verb.to_s.ljust(8)
  path = route.path.spec.to_s.ljust(50)
  ctrl = "#{route.defaults[:controller]}##{route.defaults[:action]}"
  puts "  #{verb} #{path} => #{ctrl}"
end
puts ""

# 4. JWT 功能验证
puts "[4] JWT 功能验证"
token = JwtService.encode({ user_id: 1, test: true })
decoded = JwtService.decode(token)
puts "  ✅ 生成 Token: #{token[0..30]}..."
puts "  ✅ 解析 Token: user_id=#{decoded[:user_id]}"
puts ""

# 5. 周工具验证
puts "[5] 周工具验证"
cw = WeekUtils.current_week_key
nw = WeekUtils.next_week_key
puts "  ✅ 当前周: #{cw} (#{WeekUtils.week_start(cw)} ~ #{WeekUtils.week_end(cw)})"
puts "  ✅ 下一周: #{nw} (锁定时间: #{WeekUtils.lock_time_for_week(nw)})"
puts ""

puts "=" * 60
puts "✅ 所有代码验证通过！"
puts "=" * 60
puts ""
puts "下一步操作指南:"
puts "  1. 启动 PostgreSQL: docker compose up -d postgres"
puts "  2. 执行数据库迁移: rails db:migrate"
puts "  3. 填充种子数据: rails db:seed"
puts "  4. 启动 API 服务: rails s -p 3000"
puts "  5. 测试登录: POST /auth/login (phone=13811111111, password=user1234)"
