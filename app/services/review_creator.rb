class ReviewCreator
  attr_reader :user, :order_item, :rating, :comment, :review, :error_message

  def initialize(user:, order_item:, rating:, comment: nil)
    @user = user
    @order_item = order_item
    @rating = rating.to_i
    @comment = comment&.truncate(200)
    @review = nil
    @error_message = nil
    @success = false
  end

  def self.create!(**kwargs)
    new(**kwargs).tap(&:create!)
  end

  def self.create(**kwargs)
    new(**kwargs).tap(&:create)
  end

  def create!
    create || raise(error_message || "评价创建失败")
  end

  def create
    validate_input!
    return false if @error_message

    Review.transaction do
      lock_order_item!
      return false if duplicate_exists?
      build_review
      save_review
    end

    success?
  rescue ActiveRecord::RecordNotUnique => e
    if e.message.include?("index_reviews_on_user_id_and_order_item_id") ||
       e.message.include?("index_reviews_on_user_order_item_vegetable")
      @error_message = "该菜品您已经评价过了"
      @success = false
    else
      raise
    end
    false
  rescue StandardError => e
    @error_message = e.message
    @success = false
    false
  end

  def success?
    @success
  end

  def error_code
    if @error_message&.include?("已经评价过了")
      409
    elsif @error_message&.include?("签收后才能评价")
      400
    elsif @error_message&.include?("评分必须在1到5星")
      422
    elsif @error_message&.include?("不存在")
      404
    else
      422
    end
  end

  private

  def validate_input!
    unless order_item.is_a?(OrderItem)
      @error_message = "订单项不存在"
      return
    end

    unless order_item.order.signed?
      @error_message = "订单签收后才能评价"
      return
    end

    unless rating.between?(1, 5)
      @error_message = "评分必须在1到5星之间"
      return
    end
  end

  def lock_order_item!
    order_item.lock!
  end

  def duplicate_exists?
    Review.where(user: user, order_item: order_item).exists?
  end

  def build_review
    @review = user.reviews.build(
      order_item: order_item,
      order: order_item.order,
      vegetable: order_item.vegetable,
      rating: rating,
      comment: comment
    )
  end

  def save_review
    if @review.save
      @success = true
    else
      @error_message = @review.errors.full_messages.join(", ")
      @success = false
      raise ActiveRecord::Rollback
    end
  end
end
