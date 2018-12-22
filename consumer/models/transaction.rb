require_relative 'application_record'

class Transaction < ApplicationRecord
  enum transaction_type: { topup: 'topup', payment: 'payment' }
  enum status: { success: 'success', fail: 'fail' }

  belongs_to :transferrer_account, class_name: 'Account', foreign_key: 'transferrer_account_id'
  belongs_to :receiver_account, class_name: 'Account', foreign_key: 'receiver_account_id'
end
