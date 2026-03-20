class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :name_ciphertext
      t.string :email_ciphertext
      t.string :phone_ciphertext
      t.timestamps
    end
  end
end
