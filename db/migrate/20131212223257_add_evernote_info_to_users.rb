class AddEvernoteInfoToUsers < ActiveRecord::Migration
  def change
    add_column :users, :lastUpdateCount, :integer
    add_column :users, :lastFullSync, :timestamp
  end
end
