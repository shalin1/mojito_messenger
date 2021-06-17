class AddAdminToUser < ActiveRecord::Migration[6.1]
  def change
    change_table :users do |t|
      t.boolean :admin
    end
  end
end
