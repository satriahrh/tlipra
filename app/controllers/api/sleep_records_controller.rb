class Api::SleepRecordsController < ApplicationController
  before_action :validate_action, only: [ :create ]
  before_action :validate_feeds_params, only: [ :feeds ]

  DEFAULT_PAGE = 1
  DEFAULT_PER_PAGE = 20

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
    page = params[:page].present? ? params[:page].to_i : DEFAULT_PAGE
    per_page = params[:per_page].present? ? params[:per_page].to_i : DEFAULT_PER_PAGE

    following_user_ids = @user.following.pluck(:id)
    last_week = 1.week.ago.beginning_of_week..1.week.ago.end_of_week

    sleep_records = SleepRecord
      .includes(:user)
      .where(user_id: following_user_ids, clock_in_at: last_week)
      .where.not(duration: nil)
      .order(duration: :desc)
      .limit(per_page)
      .offset((page - 1) * per_page)

    render json: {
      data: sleep_records.map { |record| SleepRecordSerializer.new(record).as_json },
      code: "SUCCESS",
      total: sleep_records.count,
      page: page,
      per_page: per_page
    }
  end

  private

  def validate_feeds_params
    if params[:page].present? && (params[:page].to_s !~ /\A\d+\z/ || params[:page].to_i <= 0)
      render json: {
        error: "page must be a positive integer",
        code: "INVALID_PARAMS"
      }, status: :bad_request and return
    end
    if params[:per_page].present? && (params[:per_page].to_s !~ /\A\d+\z/ || params[:per_page].to_i <= 0)
      render json: {
        error: "per_page must be a positive integer",
        code: "INVALID_PARAMS"
      }, status: :bad_request and return
    end
  end

  def validate_action
    unless %w[clock_in clock_out].include?(params[:action_type])
      render json: {
        error: "action_type must be either 'clock_in' or 'clock_out'",
        code: "INVALID_ACTION_TYPE"
      }, status: :bad_request
    end
  end
end
