# 蔬菜盲盒 API 架构速览

## 分层（别跨层写代码）

- **Controller** `app/controllers/`：接 HTTP、取参、鉴权、调 service。**不写业务逻辑**
- **Service** `app/services/`：事务/校验/去重/扣费，业务编排核心
- **Model** `app/models/`：关联关系/字段校验/作用域
- **Migration** `db/migrate/`：表结构变更

## 数据模型关系

User→Addresses / Wallet / Subscriptions / Orders / Reviews  
Subscription→SkipWeeks，Order→OrderItems→Reviews  
WeeklyBox↔WeeklyBoxItems↔Vegetables，Order→WeeklyBox

关键字段：Subscription.frequency+status+start_date，WeeklyBox.week_key(YYYY-WW)+is_locked+lock_at，Review 唯一索引(user_id, order_item_id, vegetable_id) 防重复。

## 关键流程

**周三20:00锁定**：Job 锁盲盒 → 扫 active 订阅 → 判该周送+没skip → 钱包扣费 → 生成 Order+菜品快照。

**锁定前换菜**：删旧 order_item 建新，差价钱包补退。

**评价**：签收后走 Service（行锁+唯一索引+异常兜底三层防重）。

## 鉴权 & 接口约定

**JWT**：登录返 token，放 `Authorization: Bearer <x>`，7 天过期。

**响应统一** `{code, message, data}`：
- code=0 成功；非0：400参数 / 401未登录 / 403无权限 / 404不存在 / 409重复 / 422校验
- HTTP 基本 200，鉴权才 401，判定看业务 code
