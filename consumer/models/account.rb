require_relative 'application_record'

class Account < ApplicationRecord
  enum account_type: { bank: 'bank', user: 'user' }

  has_many :tranferrer_transactions, class_name: 'Transaction', foreign_key: 'transferrer_account_id'
  has_many :receiver_transactions, class_name: 'Transaction', foreign_key: 'receiver_account_id'

  def Account.bank_account
    self.where(account_type: :bank).first
  end
end
