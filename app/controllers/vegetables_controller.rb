class VegetablesController < ApplicationController
  before_action :set_vegetable, only: [:show, :update, :destroy]

  def index
    scope = Vegetable.all
    scope = scope.active unless current_user&.admin?
    success(scope.order(created_at: :desc), message: "获取成功")
  end

  def show
    success(@vegetable, message: "获取成功")
  end

  def create
    admin_required!
    vegetable = Vegetable.new(vegetable_params)
    if vegetable.save
      success(vegetable, message: "创建成功")
    else
      error(message: vegetable.errors.full_messages.join(", "), code: 422, status: :unprocessable_entity)
    end
  end

  def update
    admin_required!
    if @vegetable.update(vegetable_params)
      success(@vegetable, message: "更新成功")
    else
      error(message: @vegetable.errors.full_messages.join(", "), code: 422, status: :unprocessable_entity)
    end
  end

  def destroy
    admin_required!
    @vegetable.update!(active: false)
    success(nil, message: "已下架")
  end

  private

  def set_vegetable
    @vegetable = Vegetable.find(params[:id])
  end

  def vegetable_params
    params.require(:vegetable).permit(:name, :unit, :price, :description, :image, :stock, :active)
  end
end
