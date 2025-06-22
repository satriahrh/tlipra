class Api::SleepRecordsController < ApplicationController
  DEFAULT_PAGE = 1
  DEFAULT_PER_PAGE = 20

  rescue_from ArgumentError do |e|
    render json: { error: e.message, code: "INVALID_PARAMS" }, status: :bad_request
  end

  def clock_in
    sleep_record = @user.sleep_clock_in!

    render json: {
      action: "clock_in",
      data: SleepRecordSerializer.new(sleep_record).as_json,
      message: "Successfully clocked in",
      code: "SUCCESS"
    }, status: :created
  rescue BusinessLogicError => e
    render json: {
      error: e.message,
      code: "ALREADY_CLOCKED_IN"
    }, status: :unprocessable_entity
  rescue StandardError => e
    render json: {
      error: e.message,
      code: "INTERNAL_ERROR"
    }, status: :internal_server_error
  end

  def clock_out
    sleep_record = @user.sleep_clock_out!

    render json: {
      action: "clock_out",
      data: SleepRecordSerializer.new(sleep_record).as_json,
      message: "Successfully clocked out",
      code: "SUCCESS"
    }, status: :ok
  rescue BusinessLogicError => e
    render json: {
      error: e.message,
      code: "NO_ACTIVE_SLEEP_RECORD"
    }, status: :unprocessable_entity
  rescue StandardError => e
    render json: {
      error: e.message,
      code: "INTERNAL_ERROR"
    }, status: :internal_server_error
  end

  def clock_in_history
    page = params[:page].present? ? params[:page].to_i : DEFAULT_PAGE
    per_page = params[:per_page].present? ? params[:per_page].to_i : DEFAULT_PER_PAGE

    relation = @user.sleep_records.
      order(created_at: :desc)

    records = relation.limit(per_page).offset((page - 1) * per_page)

    render json: {
      data: records.map(&:clock_in_at),
      code: "SUCCESS",
      total: relation.count,
      page: page,
      per_page: per_page
    }
  end

  def feeds
    page = validate_and_convert_to_int(params[:page], Users::GetSleepRecordsFeedsService::DEFAULT_PAGE, "page")
    per_page = validate_and_convert_to_int(params[:per_page], Users::GetSleepRecordsFeedsService::DEFAULT_PER_PAGE, "per_page")

    service_result = Users::GetSleepRecordsFeedsService.new(@user, page: page, per_page: per_page).call

    render json: {
      data: ActiveModelSerializers::SerializableResource.new(service_result[:records], each_serializer: SleepRecordSerializer),
      code: "SUCCESS",
      total: service_result[:total],
      page: service_result[:page],
      per_page: service_result[:per_page]
    }
  end

  private

  def validate_and_convert_to_int(value, default, param_name)
    return default if value.blank?

    # Check if the string represents a valid positive integer
    unless value.to_s.match?(/^[1-9]\d*$/)
      raise ArgumentError, "#{param_name} must be a positive integer"
    end

    value.to_i
  end
end
