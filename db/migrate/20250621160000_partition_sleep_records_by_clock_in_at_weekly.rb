class PartitionSleepRecordsByClockInAtWeekly < ActiveRecord::Migration[8.0]
  def up
    # MySQL requires the partitioning key to be in the primary key.
    # We must drop the old primary key and create a new composite one.
    # Note: This will also drop the auto_increment property, which we'll add back.
    execute "ALTER TABLE sleep_records DROP PRIMARY KEY, ADD PRIMARY KEY (id, clock_in_at);"
    execute "ALTER TABLE sleep_records MODIFY id BIGINT NOT NULL AUTO_INCREMENT;"

    # Use a temporary, isolated model to safely query the table within the migration
    self.class.const_set(:SleepRecord, Class.new(ActiveRecord::Base) { self.table_name = 'sleep_records' })

    # Get the current min and max clock_in_at dates to create initial partitions
    if self.class::SleepRecord.unscoped.any?
      # minimum/maximum return Time objects, so convert to Date
      min_date = self.class::SleepRecord.unscoped.minimum(:clock_in_at).to_date
      max_date = self.class::SleepRecord.unscoped.maximum(:clock_in_at).to_date
    else
      # If there's no data, we'll just set up for the current week.
      min_date = Date.today
      max_date = Date.today
    end

    # Build the PARTITION BY statement using RANGE partitioning on clock_in_at
    partitions = build_weekly_partitions(min_date, max_date)

    execute <<-SQL
      ALTER TABLE sleep_records
      PARTITION BY RANGE (TO_DAYS(clock_in_at)) (
        #{partitions.join(",\n")}
      );
    SQL
  end

  def down
    # This will remove partitioning from the table, coalescing all data back into the main table.
    execute "ALTER TABLE sleep_records REMOVE PARTITIONING;"

    # Restore the original primary key
    execute "ALTER TABLE sleep_records DROP PRIMARY KEY, ADD PRIMARY KEY (id);"
  end

  private

  def build_weekly_partitions(start_date, end_date)
    partitions = []

    # Create partitions from the earliest record up to end date
    current_date = start_date.beginning_of_week
    end_of_partitions = end_date.end_of_week

    while current_date <= end_of_partitions
      partition_end_date = current_date.end_of_week + 1.day
      week_start = current_date.strftime('%Y%m%d')
      week_end = (partition_end_date - 1.day).strftime('%Y%m%d')
      partition_name = "p_#{week_start}_to_#{week_end}"

      # Use RANGE partitioning with TO_DAYS function
      partitions << "PARTITION #{partition_name} VALUES LESS THAN (TO_DAYS('#{partition_end_date}'))"

      current_date += 1.week
    end

    # Add a catch-all partition for any future data.
    # This is a good safety net in case the rake task fails to run.
    partitions << "PARTITION p_max VALUES LESS THAN MAXVALUE"

    partitions
  end
end
