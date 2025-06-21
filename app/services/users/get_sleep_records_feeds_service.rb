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

      sleep_records_relation = SleepRecord
        .includes(:user)
        .where(clock_in_at: last_week, user_id: followed_user_ids)
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

    def last_week
      1.week.ago.beginning_of_week..1.week.ago.end_of_week
    end

    def empty_result
      { records: [], total: 0, page: @page, per_page: @per_page }
    end
  end
end
