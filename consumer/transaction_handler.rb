require 'logger'
require 'json'
require_relative 'models/account'
require_relative 'models/transaction'

module TransactionHandler
  LOGGER = Logger.new(STDOUT)

  class << self
    def run(tx)
      event = tx['event']
      producer_id = tx['producer_id']
      amount = tx['amount'].to_d
      bank_account_id = Account.bank_account.id

      case event
      when Transaction.transaction_types[:topup]
        transaction = make_transaction(bank_account_id, producer_id, amount, event, Transaction.statuses[:success])

      when Transaction.transaction_types[:payment]
        producer_balance = Account.find(producer_id).balance
        if (producer_balance < amount)
          # handles not enough balance
          make_transaction(producer_id, bank_account_id, amount, event, Transaction.statuses[:fail])
          LOGGER.error("[consumer] TransactionHandler - producer #{producer_id} doesn't have enough balance (current: #{producer_balance}) to make payment, message: #{tx.to_json}")
          return
        end

        transaction = make_transaction(producer_id, bank_account_id, amount, event, Transaction.statuses[:success])
      else
        LOGGER.error("[consumer] error, unsupported event #{event}, message: #{tx.to_json}")
        return
      end

      LOGGER.info("[consumer] TransactionHandler - transactions made, transaction: #{transaction.to_json}")
    end

    private

    def make_transaction(transferrer_id, receiver_id, amount, transaction_type, status)
      transaction = nil
      Account.transaction(requires_new: true) do
        transferrer = Account.lock.find(transferrer_id)
        receiver = Account.lock.find(receiver_id)

        case status
        when Transaction.statuses[:success]
          transferrer_new_balance = transferrer.balance - amount
          receiver_new_balance = receiver.balance + amount

          transferrer.update!(balance: transferrer_new_balance)
          receiver.update!(balance: receiver_new_balance)
        when Transaction.statuses[:fail]
          transferrer_new_balance = transferrer.balance
          receiver_new_balance = receiver.balance
        end

        # create transactions and save
        transaction = Transaction.create!(
            transferrer_account: transferrer,
            receiver_account: receiver,
            amount: amount,
            transaction_type: transaction_type,
            status: status,
            transferrer_balance: transferrer_new_balance,
            receiver_balance: receiver_new_balance
        )
      end
      transaction
    end
  end
end
