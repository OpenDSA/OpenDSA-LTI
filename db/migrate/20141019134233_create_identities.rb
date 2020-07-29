class CreateIdentities < ActiveRecord::Migration[5.1]
  def change
    create_table :identities do |t|
      t.references :user, index: true
      t.string :provider
      t.string :uid

      t.timestamps
    end
  end
end
