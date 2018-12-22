class CreateTransactions < ActiveRecord::Migration[5.2]
  def change
    create_table :transactions do |t|
      t.references :transferrer_account, index: true, foreign_key: {to_table: :accounts}
      t.references :receiver_account, index: true, foreign_key: {to_table: :accounts}
      t.string :transaction_type, index: true
      t.string :status
      t.numeric :amount
      t.numeric :transferrer_balance
      t.numeric :receiver_balance
      t.timestamps
    end
  end
end
