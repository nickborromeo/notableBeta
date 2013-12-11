class CreateNotebooks < ActiveRecord::Migration
  def change
    create_table :notebooks do |t|
      t.string :title
      t.string :modview
      t.integer :user_id

      t.timestamps
    end
  end
end
