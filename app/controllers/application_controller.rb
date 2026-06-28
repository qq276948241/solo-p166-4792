class ApplicationController < ActionController::API
  include ActionController::Cookies

  before_action :authenticate_request!

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid
  rescue_from ActionController::ParameterMissing, with: :parameter_missing
  rescue_from StandardError, with: :handle_standard_error

  protected

  def success(data = nil, message: "操作成功", code: 0)
    render json: { code: code, message: message, data: data }, status: :ok
  end

  def error(message: "操作失败", code: 1, data: nil, status: :ok)
    render json: { code: code, message: message, data: data }, status: status
  end

  def paginate(collection, page: 1, per_page: 10)
    page = [page.to_i, 1].max
    per_page = [per_page.to_i, 100].min
    total = collection.count
    items = collection.offset((page - 1) * per_page).limit(per_page)
    {
      items: items,
      pagination: {
        page: page,
        per_page: per_page,
        total: total,
        total_pages: (total.to_f / per_page).ceil
      }
    }
  end

  def current_user
    @current_user
  end

  def admin_required!
    unless current_user&.admin?
      error(message: "无权访问", code: 403, status: :forbidden)
    end
  end

  private

  def authenticate_request!
    return if skip_auth?

    token = extract_token
    decoded = token ? JwtService.decode(token) : nil

    unless decoded && decoded[:user_id]
      error(message: "请先登录", code: 401, status: :unauthorized)
      return
    end

    @current_user = User.find_by(id: decoded[:user_id])
    unless @current_user
      error(message: "用户不存在", code: 401, status: :unauthorized)
    end
  end

  def extract_token
    header = request.headers["Authorization"]
    header&.start_with?("Bearer ") ? header.split(" ").last : nil
  end

  def skip_auth?
    controller_name == "auth" && action_name.in?(%w[register login])
  end

  def record_not_found(exception)
    error(message: "记录不存在: #{exception.model}", code: 404, status: :not_found)
  end

  def record_invalid(exception)
    error(message: exception.record.errors.full_messages.join(", "), code: 422, data: exception.record.errors.messages, status: :unprocessable_entity)
  end

  def parameter_missing(exception)
    error(message: "缺少参数: #{exception.param}", code: 400, status: :bad_request)
  end

  def handle_standard_error(exception)
    Rails.logger.error "#{exception.class}: #{exception.message}"
    Rails.logger.error exception.backtrace&.first(10)&.join("\n")
    error(message: exception.message, code: 500, status: :internal_server_error)
  end
end
