class RemoveRedundantUserIdIndexFromSleepRecords < ActiveRecord::Migration[8.0]
  def change
    remove_index :sleep_records, :user_id
  end
end
