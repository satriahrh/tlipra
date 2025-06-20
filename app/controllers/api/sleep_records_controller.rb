class Api::SleepRecordsController < ApplicationController
  before_action :validate_action, only: [ :create ]

  DEFAULT_PAGE = 1
  DEFAULT_PER_PAGE = 20

  rescue_from ArgumentError do |e|
    render json: { error: e.message, code: "INVALID_PARAMS" }, status: :bad_request
  end

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

  def feeds
    options = { user: @user }
    options[:page] = params[:page] if params[:page].present?
    options[:per_page] = params[:per_page] if params[:per_page].present?

    service_result = Users::GetSleepRecordsFeedsService.new(**options).call

    render json: {
      data: ActiveModelSerializers::SerializableResource.new(service_result[:records], each_serializer: SleepRecordSerializer),
      code: "SUCCESS",
      total: service_result[:total],
      page: service_result[:page],
      per_page: service_result[:per_page]
    }
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
