class CreatePublishers < ActiveRecord::Migration[7.0]
  def change
    create_table :publishers do |t|
      t.string :name
      t.timestamps
    end
    add_reference :books, :publisher, index: true
  end
end
