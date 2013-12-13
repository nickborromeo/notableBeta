class AddEvernoteInfoToUsers < ActiveRecord::Migration
  def change
    add_column :users, :last_update_count, :integer
    add_column :users, :last_full_sync, :timestamp
  end
end
