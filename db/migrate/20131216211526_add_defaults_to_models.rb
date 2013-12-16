class AddDefaultsToModels < ActiveRecord::Migration
	def change
		change_column :users, :admin, :boolean, :default => false
		change_column :notes, :fresh, :boolean, :default => true
		change_column :notes, :collapsed, :boolean, :default => false
	end
end
