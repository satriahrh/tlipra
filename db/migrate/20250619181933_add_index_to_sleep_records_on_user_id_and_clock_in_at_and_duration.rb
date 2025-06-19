class AddIndexToSleepRecordsOnUserIdAndClockInAtAndDuration < ActiveRecord::Migration[8.0]
  def change
    add_index :sleep_records, [ :user_id, :clock_in_at, :duration ]
  end
end
