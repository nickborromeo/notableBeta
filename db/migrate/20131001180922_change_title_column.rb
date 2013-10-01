class ChangeTitleColumn < ActiveRecord::Migration
  def change
  	change_column :notes, :title, :text
  end
end

