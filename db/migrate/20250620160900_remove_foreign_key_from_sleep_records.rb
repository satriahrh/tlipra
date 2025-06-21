class RemoveForeignKeyFromSleepRecords < ActiveRecord::Migration[8.0]
  def up
    # MySQL partitioning does not support foreign keys on this version.
    # We remove the constraint to allow the sleep_records table to be partitioned.
    # The application layer (belongs_to :user) will still maintain referential integrity.
    remove_foreign_key :sleep_records, :users
  end

  def down
    # If we roll back the partitioning, we can add the foreign key back.
    add_foreign_key :sleep_records, :users
  end
end
