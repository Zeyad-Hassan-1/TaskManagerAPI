class AddUserToAttachment < ActiveRecord::Migration[8.0]
  def change
    add_reference :attachments, :user, null: false, foreign_key: true
    add_column :attachments, :name, :string, null: true
  end
end
