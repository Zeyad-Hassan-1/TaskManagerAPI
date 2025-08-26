class CreateTaggings < ActiveRecord::Migration[8.0]
  def change
    create_table :taggings do |t|
      t.timestamps
      t.references :tag, null: false, foreign_key: true
      t.references :taggable, polymorphic: true
    end
  end
end
