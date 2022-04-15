class CreateBooks < ActiveRecord::Migration[7.0]
  def change
    create_table :books do |t|
      t.text :hash
      t.text :array
      t.text :openstruct
      t.integer :integer
      t.decimal :price, precision: 12, scale: 4
      t.boolean :hard_cover
      t.string :title
      t.timestamps
    end
  end
end
