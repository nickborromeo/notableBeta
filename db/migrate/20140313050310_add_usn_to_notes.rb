class AddUsnToNotes < ActiveRecord::Migration
  def change
    add_column :notes, :usn, :integer
  end
end
