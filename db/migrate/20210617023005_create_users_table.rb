class CreateUsersTable < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.string :name
      t.string :phone
      t.boolean :subscribed
      t.datetime :created_at
      t.datetime :updated_at
    end
  end
end
