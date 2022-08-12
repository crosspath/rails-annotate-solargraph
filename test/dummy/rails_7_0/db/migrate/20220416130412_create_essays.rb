class CreateEssays < ActiveRecord::Migration[7.0]
  def change
    create_table :essays do |t|
      t.text :content
      t.string :title
      t.references :author
      t.timestamps
    end
  end
end
