class PartitionSleepRecordsByClockInAtWeekly < ActiveRecord::Migration[8.0]
  def up
    # MySQL requires the partitioning key to be in the primary key.
    # We must drop the old primary key and create a new composite one.
    # Note: This will also drop the auto_increment property, which we'll add back.
    execute "ALTER TABLE sleep_records DROP PRIMARY KEY, ADD PRIMARY KEY (id, clock_in_at);"
    execute "ALTER TABLE sleep_records MODIFY id BIGINT NOT NULL AUTO_INCREMENT;"

    # Create partitioning with only p_max initially
    execute <<-SQL
      ALTER TABLE sleep_records
      PARTITION BY RANGE (TO_DAYS(clock_in_at)) (
        PARTITION p_max VALUES LESS THAN MAXVALUE
      );
    SQL
  end

  def down
    # This will remove partitioning from the table, coalescing all data back into the main table.
    execute "ALTER TABLE sleep_records REMOVE PARTITIONING;"

    # Restore the original primary key
    execute "ALTER TABLE sleep_records DROP PRIMARY KEY, ADD PRIMARY KEY (id);"
  end
end
