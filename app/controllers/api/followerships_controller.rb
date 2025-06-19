class Api::FollowershipsController < ApplicationController
  before_action :set_other_user

  def create
    followership = @user.follow!(@other_user)
    render json: {
      action: "follow",
      message: "Successfully followed user",
      code: "SUCCESS"
    }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: {
      error: e.message,
      code: "RECORD_INVALID"
    }, status: :unprocessable_entity
  rescue => e
    render json: {
      error: e.message,
      code: "INTERNAL_ERROR"
    }, status: :internal_server_error
  end

  def destroy
    @user.unfollow!(@other_user)
    render json: {
      action: "unfollow",
      message: "Successfully unfollowed user",
      code: "SUCCESS"
    }, status: :ok
  rescue BusinessLogicError => e
    render json: {
      error: e.message,
      code: "BUSINESS_LOGIC_ERROR"
    }, status: :unprocessable_entity
  rescue => e
    render json: {
      error: e.message,
      code: "INTERNAL_ERROR"
    }, status: :internal_server_error
  end

  private

  def set_other_user
    @other_user = User.find(params[:other_user_id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      error: "User not found",
      code: "USER_NOT_FOUND"
    }, status: :not_found
  end
end
