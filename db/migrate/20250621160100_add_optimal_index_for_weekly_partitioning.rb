class AddOptimalIndexForWeeklyPartitioning < ActiveRecord::Migration[8.0]
  def up
    # Add a composite index optimized for feed queries with clock_in_at partitioning
    # clock_in_at first for partition pruning, then user_id for filtering, then duration for ordering
    add_index :sleep_records, [ :clock_in_at, :user_id, :duration ], name: "index_sleep_records_on_clock_user_duration"

    # Keep the standalone user_id index for general user lookups
    # (This should already exist from previous migrations)
  end

  def down
    # Remove the new index
    remove_index :sleep_records, name: "index_sleep_records_on_clock_user_duration"
  end
end
