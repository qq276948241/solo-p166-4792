class AddressesController < ApplicationController
  before_action :set_address, only: [:show, :update, :destroy, :set_default]

  def index
    success(current_user.addresses.order(is_default: :desc, created_at: :desc), message: "获取成功")
  end

  def show
    success(@address, message: "获取成功")
  end

  def create
    address = current_user.addresses.build(address_params)
    if address.save
      success(address, message: "创建成功")
    else
      error(message: address.errors.full_messages.join(", "), code: 422, status: :unprocessable_entity)
    end
  end

  def update
    if @address.update(address_params)
      success(@address, message: "更新成功")
    else
      error(message: @address.errors.full_messages.join(", "), code: 422, status: :unprocessable_entity)
    end
  end

  def destroy
    @address.destroy
    success(nil, message: "删除成功")
  end

  def set_default
    @address.update!(is_default: true)
    success(@address, message: "设置成功")
  end

  private

  def set_address
    @address = current_user.addresses.find(params[:id])
  end

  def address_params
    params.require(:address).permit(:name, :phone, :province, :city, :district, :detail, :is_default)
  end
end
