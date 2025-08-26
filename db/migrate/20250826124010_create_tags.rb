class CreateTags < ActiveRecord::Migration[8.0]
  def change
    create_table :tags do |t|
      t.text :name
      t.references :taggable, polymorphic: true

      t.timestamps
    end
  end
end
