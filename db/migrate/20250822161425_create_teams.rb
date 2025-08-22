class CreateTeams < ActiveRecord::Migration[8.0]
  def change
    create_table :teams do |t|
      t.text :name, null: false
      t.text :discription, null: false

      t.timestamps
    end
  end
end
