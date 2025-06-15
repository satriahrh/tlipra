class Api::SleepRecordsController < ApplicationController
  before_action :validate_action

  def create
    case params[:action_type]
    when "clock_in"
      sleep_record = @user.sleep_clock_in!

      render json: {
        action: "clock_in",
        data: sleep_record_json(sleep_record),
        message: "Successfully clocked in"
      }, status: :created
    when "clock_out"
      sleep_record = @user.sleep_clock_out!

      render json: {
        action: "clock_out",
        data: sleep_record_json(sleep_record),
        message: "Successfully clocked out"
      }, status: :ok
    end
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def validate_action
    unless %w[clock_in clock_out].include?(params[:action_type])
      render json: { error: "action_type must be either 'clock_in' or 'clock_out'" },
             status: :bad_request
    end
  end

  def sleep_record_json(sleep_record)
    {
      id: sleep_record.id,
      user_id: sleep_record.user_id,
      clock_in_at: sleep_record.clock_in_at,
      clock_out_at: sleep_record.clock_out_at,
      duration: sleep_record.duration,
      created_at: sleep_record.created_at,
      updated_at: sleep_record.updated_at
    }
  end
end
