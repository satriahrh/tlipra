class SleepRecord < ApplicationRecord
  belongs_to :user

  validates :clock_in_at, presence: true
  validate :clock_out_after_clock_in, if: :both_times_present?

  before_update :prevent_duration_update, unless: :clock_out_at_changed?

  def clock_out_at=(value)
    super(value)
    calculate_duration if clock_in_at && value
  end

  private

  def both_times_present?
    clock_in_at.present? && clock_out_at.present?
  end

  def calculate_duration
    if clock_in_at && clock_out_at
      write_attribute(:duration, (clock_out_at - clock_in_at).to_i)
    end
  end

  def prevent_duration_update
    if duration_changed?
      errors.add(:duration, "can only be set when clocking out")
      throw(:abort)
    end
  end

  def clock_out_after_clock_in
    if clock_in_at && clock_out_at
      if clock_out_at <= clock_in_at
        errors.add(:clock_out_at, "must be after clock in time")
      end
    end
  end
end
