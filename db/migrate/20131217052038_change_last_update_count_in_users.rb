class ChangeLastUpdateCountInUsers < ActiveRecord::Migration
  def change
		change_column :users, :last_update_count, :integer, :default => 0
  end
end
