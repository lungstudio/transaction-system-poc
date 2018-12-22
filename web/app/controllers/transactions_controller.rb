class TransactionsController < ApplicationController
  NO_OF_PRODUCERS = ENV['NO_OF_PRODUCERS']&.to_i || 3
  MIN_INITIAL_BALANCE = ENV['MIN_INITIAL_BALANCE']&.to_i || 0
  MAX_INITIAL_BALANCE = ENV['MAX_INITIAL_BALANCE']&.to_i || 100

  def index
    @accounts = Account.order('id asc').all&.map do |acc|
      {
          id: acc.id,
          account_type: acc.account_type,
          balance: acc.balance,
          is_on: ($redis.get("producer.#{acc.id}.is_on") == "true")
      }.with_indifferent_access
    end
    @transactions = Transaction.order('id desc').limit(50)
  end

  def toggle_producer
    producer_id = params['producer_id']

    original = $redis.get("producer.#{producer_id}.is_on")
    $redis.setex("producer.#{producer_id}.is_on", 7.days, original == "true" ? false : true)

    redirect_back fallback_location: :index
  end

  def start_all_producers
    NO_OF_PRODUCERS.times do |i|
      $redis.setex("producer.#{i + 2}.is_on", 7.days, true)
    end

    redirect_back fallback_location: :index
  end

  def stop_all_producers
    NO_OF_PRODUCERS.times do |i|
      $redis.setex("producer.#{i + 2}.is_on", 7.days, false)
    end

    redirect_back fallback_location: :index
  end

  def reset_all
    Transaction.delete_all
    ActiveRecord::Base.connection.reset_pk_sequence!(Transaction.table_name)

    bank_account = Account.bank_account
    bank_account.update!(balance: 0)

    Account.all.each do |acc|
      next if acc.bank?

      initial_balance = rand(MIN_INITIAL_BALANCE..MAX_INITIAL_BALANCE)

      bank_new_balance = bank_account.balance - initial_balance
      bank_account.update!(balance: bank_new_balance)
      acc.update!(balance: initial_balance)

      Transaction.create!(
          transferrer_account: Account.bank_account,
          receiver_account: acc,
          transaction_type: Transaction.transaction_types[:topup],
          amount: initial_balance,
          status: Transaction.statuses[:success],
          transferrer_balance: bank_new_balance,
          receiver_balance: initial_balance
      )
    end

    redirect_back fallback_location: :index
  end
end