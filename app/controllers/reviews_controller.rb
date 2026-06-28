class ReviewsController < ApplicationController
  def create
    order_item = current_user.orders.flat_map(&:order_items).find_by(id: review_params[:order_item_id])
    unless order_item
      return error(message: "订单项不存在", code: 404, status: :not_found)
    end

    creator = ReviewCreator.create(
      user: current_user,
      order_item: order_item,
      rating: review_params[:rating],
      comment: review_params[:comment]
    )

    if creator.success?
      success(creator.review, message: "评价成功")
    else
      error(message: creator.error_message, code: creator.error_code, status: :unprocessable_entity)
    end
  end

  def batch_create
    items = params[:items] || []
    return error(message: "评价内容不能为空", code: 400, status: :bad_request) if items.blank?

    order = current_user.orders.find(params[:order_id])
    unless order.signed?
      return error(message: "订单签收后才能评价", code: 400, status: :bad_request)
    end

    results = []
    errors = []

    ActiveRecord::Base.transaction do
      items.each do |item|
        order_item = order.order_items.find_by(id: item[:order_item_id])
        unless order_item
          errors << "订单项##{item[:order_item_id]}不存在"
          next
        end

        creator = ReviewCreator.create(
          user: current_user,
          order_item: order_item,
          rating: item[:rating],
          comment: item[:comment]
        )

        if creator.success?
          results << creator.review
        else
          errors << "#{order_item.vegetable_name_snapshot}: #{creator.error_message}"
        end
      end
    end

    if errors.empty?
      success(results, message: "批量评价成功")
    else
      error(message: errors.join("; "), code: 422, data: { saved: results, errors: errors }, status: :unprocessable_entity)
    end
  end

  def my_reviews
    scope = current_user.reviews.includes(:order, :vegetable, order_item: []).recent
    scope = scope.where(rating: params[:rating]) if params[:rating].present?
    scope = scope.where(order_id: params[:order_id]) if params[:order_id].present?

    success(paginate(scope, page: params[:page], per_page: params[:per_page]), message: "获取成功")
  end

  def admin_all
    admin_required!
    scope = Review.includes(:user, :order, :vegetable, order_item: []).recent
    scope = scope.where(rating: params[:rating]) if params[:rating].present?
    scope = scope.low_rating if params[:low_only] == "1" || params[:low_only] == true
    scope = scope.high_rating if params[:high_only] == "1" || params[:high_only] == true
    scope = scope.where(user_id: params[:user_id]) if params[:user_id].present?
    scope = scope.where(order_id: params[:order_id]) if params[:order_id].present?
    scope = scope.where("created_at >= ?", params[:start_date]) if params[:start_date].present?
    scope = scope.where("created_at <= ?", params[:end_date]) if params[:end_date].present?

    data = paginate(scope, page: params[:page], per_page: params[:per_page])
    stats = {
      total: scope.count,
      avg_rating: scope.average(:rating).to_f.round(2),
      distribution: {
        "5星" => scope.where(rating: 5).count,
        "4星" => scope.where(rating: 4).count,
        "3星" => scope.where(rating: 3).count,
        "2星" => scope.where(rating: 2).count,
        "1星" => scope.where(rating: 1).count
      }
    }
    success(data.merge(stats: stats), message: "获取成功")
  end

  def destroy
    review = if current_user.admin?
      Review.find(params[:id])
    else
      current_user.reviews.find(params[:id])
    end
    review.destroy
    success(nil, message: "删除成功")
  end

  private

  def review_params
    params.require(:review).permit(:order_item_id, :rating, :comment)
  end
end
