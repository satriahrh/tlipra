class Api::SleepRecordsController < ApplicationController
  before_action :validate_action

  def create
    case params[:action_type]
    when "clock_in"
      sleep_record = @user.sleep_clock_in!

      render json: {
        action: "clock_in",
        data: SleepRecordSerializer.new(sleep_record).as_json,
        message: "Successfully clocked in",
        code: "SUCCESS"
      }, status: :created
    when "clock_out"
      sleep_record = @user.sleep_clock_out!

      render json: {
        action: "clock_out",
        data: SleepRecordSerializer.new(sleep_record).as_json,
        message: "Successfully clocked out",
        code: "SUCCESS"
      }, status: :ok
    end
  rescue BusinessLogicError => e
    error_code = case e.message
    when /already has an active sleep record/
      "ALREADY_CLOCKED_IN"
    when /No active sleep record found/
      "NO_ACTIVE_SLEEP_RECORD"
    else
      "BUSINESS_LOGIC_ERROR"
    end

    render json: {
      error: e.message,
      code: error_code
    }, status: :unprocessable_entity
  rescue StandardError => e
    render json: {
      error: e.message,
      code: "INTERNAL_ERROR"
    }, status: :internal_server_error
  end

  private

  def validate_action
    unless %w[clock_in clock_out].include?(params[:action_type])
      render json: {
        error: "action_type must be either 'clock_in' or 'clock_out'",
        code: "INVALID_ACTION_TYPE"
      }, status: :bad_request
    end
  end
end
