class AddMaterializedRankToNotes < ActiveRecord::Migration
  def change
    add_column :notes, :parent_id, :string
    add_column :notes, :rank, :integer
    add_column :notes, :depth, :integer
  end
end
