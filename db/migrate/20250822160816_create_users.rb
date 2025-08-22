class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :username, null: false
      t.string :email
      t.string :password_digest, null: false
      t.string :bio
      t.boolean :admin, default: false, null: false
      t.string :reset_token
      t.datetime :reset_sent_at

      t.timestamps
    end

    add_index :users, :username, unique: true
    add_index :users, :admin
    add_index :users, :reset_token, unique: true
  end
end
