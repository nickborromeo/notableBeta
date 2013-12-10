class AddEngToNotes < ActiveRecord::Migration
  def change
    add_column :notes, :eng, :string
  end
end
