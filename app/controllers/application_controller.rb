class ApplicationController < ActionController::API
  before_action :set_user

  private

  def set_user
    user_id = request.headers["Authorization"]

    if user_id.blank?
      render json: { error: "User ID required", code: "UNAUTHORIZED" }, status: :unauthorized
      return
    end

    @user = User.find_by(id: user_id)

    if @user.nil?
      render json: { error: "User not found", code: "UNAUTHORIZED" }, status: :unauthorized
    end
  end
end
