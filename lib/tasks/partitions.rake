namespace :partitions do
  desc "Maintain weekly partitions for sleep_records table on MySQL (clock_in_at based RANGE partitioning) - run weekly on Sunday"
  task maintain_sleep_records_partitions: :environment do
    # We want to ensure partitions exist
    if self.class::SleepRecord.unscoped.any?
      # minimum/maximum return Time objects, so convert to Date
      min_date = self.class::SleepRecord.unscoped.minimum(:clock_in_at).to_date
    else
      # If there's no data, we'll just set up for the current week.
      min_date = Date.today
    end

    current_date = min_date.beginning_of_week
    end_of_partitions = Date.today.end_of_week + 1.week
    while current_date <= end_of_partitions
      partition_end_date = current_date.end_of_week + 1.day
      week_start = current_date.strftime("%Y%m%d")
      week_end = (partition_end_date - 1.day).strftime("%Y%m%d")
      partition_name = "p_#{week_start}_to_#{week_end}"

      # Check if the partition already exists in the information schema
      exists_query = "SELECT COUNT(1) FROM information_schema.partitions WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sleep_records' AND PARTITION_NAME = '#{partition_name}';"
      partition_exists = ActiveRecord::Base.connection.select_value(exists_query) > 0

      if !partition_exists
        puts "Creating partition #{partition_name} for week #{week_start} to #{week_end}..."

        # In MySQL RANGE partitioning, we add a new partition by splitting the p_max partition
        reorganize_query = <<-SQL
          ALTER TABLE sleep_records REORGANIZE PARTITION p_max INTO (
            PARTITION #{partition_name} VALUES LESS THAN (TO_DAYS('#{partition_end_date}')),
            PARTITION p_max VALUES LESS THAN MAXVALUE
          );
        SQL

        ActiveRecord::Base.connection.execute(reorganize_query)
        puts "✓ Partition #{partition_name} created successfully"
      else
        puts "Partition #{partition_name} already exists"
      end

      current_date += 1.week
    end

    puts "Weekly partition maintenance completed!"
  end

  desc "Show current weekly partition information for sleep_records table"
  task show_sleep_records_partitions: :environment do
    puts "Current weekly partitions for sleep_records table:"
    puts "=" * 50

    query = <<-SQL
      SELECT
        PARTITION_NAME,
        PARTITION_DESCRIPTION,
        TABLE_ROWS
      FROM information_schema.partitions
      WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'sleep_records'
      ORDER BY PARTITION_ORDINAL_POSITION;
    SQL

    results = ActiveRecord::Base.connection.execute(query)

    results.each do |row|
      partition_name = row[0]
      description = row[1] == "MAXVALUE" ? "MAXVALUE" : "TO_DAYS('#{row[1]}')"
      table_rows = row[2]

      puts "#{partition_name.ljust(30)} | #{description.ljust(25)} | #{table_rows} rows"
    end
  end
end
