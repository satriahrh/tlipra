class CreateFollowerships < ActiveRecord::Migration[8.0]
  def change
    create_table :followerships do |t|
      t.references :follower, null: false, foreign_key: { to_table: :users }
      t.references :followed, null: false, foreign_key: { to_table: :users }
      t.string :status, default: 'active'
      t.datetime :unfollowed_at

      t.timestamps
    end

    add_index :followerships, [ :follower_id, :followed_id ], unique: true
  end
end
