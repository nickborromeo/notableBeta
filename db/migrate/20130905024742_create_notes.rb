class CreateNotes < ActiveRecord::Migration
  def change
    create_table :notes do |t|
      t.string :title
      t.string :subtitle

      t.timestamps
    end
  end
end
