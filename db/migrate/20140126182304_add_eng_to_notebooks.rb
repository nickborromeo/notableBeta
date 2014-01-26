class AddEngToNotebooks < ActiveRecord::Migration
  def change
    add_column :notebooks, :eng, :string
  end
end
