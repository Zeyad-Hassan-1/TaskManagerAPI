class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.text :name, null: false
      t.text :discription, null: false
      t.references :team, null: false, foreign_key: true

      t.timestamps
    end
  end
end
