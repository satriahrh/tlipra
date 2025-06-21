namespace :partitions do
  desc "Maintain weekly partitions for sleep_records table on MySQL (clock_in_at based RANGE partitioning)"
  task maintain_sleep_records_partitions: :environment do
    # We want to ensure partitions exist for the next 4 weeks
    (0..4).each do |week_offset|
      target_date = Date.today + week_offset.weeks
      start_of_week = target_date.beginning_of_week

      # Generate partition name
      week_start = start_of_week.strftime("%Y-%m-%d")
      week_end = start_of_week.end_of_week.strftime("%Y-%m-%d")
      partition_name = "p_#{week_start}_to_#{week_end}"

      # Check if the partition already exists in the information schema
      exists_query = "SELECT COUNT(1) FROM information_schema.partitions WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sleep_records' AND PARTITION_NAME = '#{partition_name}';"
      partition_exists = ActiveRecord::Base.connection.select_value(exists_query) > 0

      if !partition_exists
        puts "Creating partition #{partition_name} for week #{week_start} to #{week_end}..."

        # In MySQL RANGE partitioning, we add a new partition by splitting the p_max partition
        partition_end_date = start_of_week.end_of_week + 1.day
        reorganize_query = <<-SQL
          ALTER TABLE sleep_records REORGANIZE PARTITION p_max INTO (
            PARTITION #{partition_name} VALUES LESS THAN (TO_DAYS('#{partition_end_date.to_s(:db)}')),
            PARTITION p_max VALUES LESS THAN MAXVALUE
          );
        SQL

        ActiveRecord::Base.connection.execute(reorganize_query)
        puts "✓ Partition #{partition_name} created successfully"
      else
        puts "Partition #{partition_name} already exists"
      end
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

  desc "Add a specific weekly partition for a given date"
  task :add_partition_for_date, [ :date ] => :environment do |task, args|
    target_date = args[:date] ? Date.parse(args[:date]) : Date.today
    start_of_week = target_date.beginning_of_week

    week_start = start_of_week.strftime("%Y%m%d")
    week_end = start_of_week.end_of_week.strftime("%Y%m%d")
    partition_name = "p_#{week_start}_to_#{week_end}"

    puts "Adding partition: #{partition_name} for week #{week_start} to #{week_end}"
    add_weekly_partition(partition_name, start_of_week)
  end

  private

  def add_weekly_partition(partition_name, start_date)
    partition_end_date = start_date.end_of_week + 1.day
    reorganize_query = <<-SQL
      ALTER TABLE sleep_records REORGANIZE PARTITION p_max INTO (
        PARTITION #{partition_name} VALUES LESS THAN (TO_DAYS('#{partition_end_date}')),
        PARTITION p_max VALUES LESS THAN MAXVALUE
      );
    SQL

    ActiveRecord::Base.connection.execute(reorganize_query)
    puts "  ✓ Partition #{partition_name} created successfully"
  rescue => e
    puts "  ✗ Failed to create partition #{partition_name}: #{e.message}"
  end
end
