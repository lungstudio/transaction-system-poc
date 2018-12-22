class CreateAccounts < ActiveRecord::Migration[5.2]
  def change
    create_table :accounts do |t|
      t.string :account_type, null: false, index: true
      t.numeric :balance, null: false, default: 0
      t.timestamps
    end
  end
end
