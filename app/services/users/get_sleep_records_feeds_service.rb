module Users
  class GetSleepRecordsFeedsService
    DEFAULT_PAGE = 1
    DEFAULT_PER_PAGE = 20

    def initialize(user, page: DEFAULT_PAGE, per_page: DEFAULT_PER_PAGE)
      @user = user
      @page = page.to_i
      @per_page = per_page.to_i
      validate_params!
    end

    def call
      followed_user_ids = @user.following.pluck(:id)
      return empty_result if followed_user_ids.empty?

      target_date = DateTime.now.last_week
      clock_in_at_range = (target_date.beginning_of_week.to_time)..(target_date.end_of_week.to_time)

      sleep_records_relation = SleepRecord
        .includes(:user)
        .where(clock_in_at: clock_in_at_range, user_id: followed_user_ids)
        .where.not(duration: nil)

      paginated_records = sleep_records_relation
        .order(duration: :desc)
        .limit(@per_page)
        .offset((@page - 1) * @per_page)

      {
        records: paginated_records,
        total: sleep_records_relation.count,
        page: @page,
        per_page: @per_page
      }
    end

    private

    def validate_params!
      raise ArgumentError, "page must be a positive integer" if @page <= 0
      raise ArgumentError, "per_page must be a positive integer" if @per_page <= 0
    end

    def empty_result
      { records: [], total: 0, page: @page, per_page: @per_page }
    end
  end
end
