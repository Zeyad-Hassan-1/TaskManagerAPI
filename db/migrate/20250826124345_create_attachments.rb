class CreateAttachments < ActiveRecord::Migration[8.0]
  def change
    create_table :attachments do |t|
      t.text :link
      t.references :attachable, polymorphic: true

      t.timestamps
    end
  end
end
