class AddIndexForClockInHistoryOrdering < ActiveRecord::Migration[8.0]
  def up
    remove_index :sleep_records, :user_id

    # Add a composite index for user_id and created_at to optimize clock_in_history queries
    # that filter by user_id and order by created_at desc
    add_index :sleep_records, [ :user_id, :created_at ], name: "index_sleep_records_on_user_id_and_created_at"
  end

  def down
    remove_index :sleep_records, name: "index_sleep_records_on_user_id_and_created_at"
    add_index :sleep_records, :user_id
  end
end
