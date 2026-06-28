class AuthController < ApplicationController
  skip_before_action :authenticate_request!, only: [:register, :login]

  def register
    user = User.new(register_params)
    if user.save
      token = JwtService.encode(user_id: user.id)
      success({ user: user.as_json(except: [:password_digest]), token: token }, message: "注册成功")
    else
      error(message: user.errors.full_messages.join(", "), code: 422, status: :unprocessable_entity)
    end
  end

  def login
    user = User.find_by(phone: login_params[:phone])
    if user&.authenticate(login_params[:password])
      token = JwtService.encode(user_id: user.id)
      success({ user: user.as_json(except: [:password_digest]), token: token }, message: "登录成功")
    else
      error(message: "手机号或密码错误", code: 401, status: :unauthorized)
    end
  end

  def me
    success(current_user.as_json(except: [:password_digest]), message: "获取成功")
  end

  def update_profile
    if current_user.update(profile_params)
      success(current_user.as_json(except: [:password_digest]), message: "更新成功")
    else
      error(message: current_user.errors.full_messages.join(", "), code: 422, status: :unprocessable_entity)
    end
  end

  private

  def register_params
    params.require(:auth).permit(:phone, :password, :password_confirmation, :nickname)
  end

  def login_params
    params.require(:auth).permit(:phone, :password)
  end

  def profile_params
    params.require(:user).permit(:nickname, :avatar)
  end
end
