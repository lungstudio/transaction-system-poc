min_initial_balance = ENV['MIN_INITIAL_BALANCE']&.to_i || 0
max_initial_balance = ENV['MAX_INITIAL_BALANCE']&.to_i || 100

# create an account for the bank
bank_account = Account.create!(account_type: Account.account_types[:bank])

# create accounts for the producers
no_of_producers = ENV['NO_OF_PRODUCERS']&.to_i || 3
no_of_producers.times do
  initial_balance = rand(min_initial_balance..max_initial_balance)

  bank_new_balance = bank_account.balance - initial_balance
  bank_account.update!(balance: bank_new_balance)
  acc = Account.create!(account_type: Account.account_types[:user], balance: initial_balance)

  Transaction.create!(
      transferrer_account: bank_account,
      receiver_account: acc,
      transaction_type: Transaction.transaction_types[:topup],
      amount: initial_balance,
      status: Transaction.statuses[:success],
      transferrer_balance: bank_new_balance,
      receiver_balance: initial_balance
  )
end
