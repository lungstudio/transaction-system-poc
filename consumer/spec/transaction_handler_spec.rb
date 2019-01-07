require 'spec_helper'
require_relative '../transaction_handler'
require_relative '../models/account'
require_relative '../models/transaction'

RSpec.describe TransactionHandler do
  let!(:bank_account) {Account.create!(account_type: 'bank', balance: 0)}
  let!(:user_account) {Account.create!(account_type: 'user', balance: 0)}

  context 'make_transaction' do
    it 'should create transaction successfully' do
      result = subject.send(:make_transaction, bank_account.id, user_account.id, 100, 'topup', 'success')

      expect(result.as_json.with_indifferent_access).to include_json(
                                                            {
                                                                transferrer_account_id: bank_account.id,
                                                                receiver_account_id: user_account.id,
                                                                amount: 100,
                                                                transaction_type: 'topup',
                                                                status: 'success',
                                                                transferrer_balance: -100,
                                                                receiver_balance: 100
                                                            }
                                                        )

      expect(bank_account.reload.balance).to eq(-100)
      expect(user_account.reload.balance).to eq(100)
    end

    it 'should roll back if any error occurs' do
      allow(Transaction).to receive(:create!).and_raise(::ActiveRecord::ActiveRecordError.new('unexpected error'))

      expect do
        subject.send(:make_transaction, bank_account.id, user_account.id, 100, 'topup', 'success')
      end.to raise_error(::ActiveRecord::ActiveRecordError)

      expect(
          Transaction
              .where(transferrer_account_id: bank_account.id, receiver_account_id: user_account.id)
              .all
      ).to be_empty

      expect(user_account.reload.balance).to eq(0)
      expect(bank_account.reload.balance).to eq(0)
    end
  end

  context 'run' do
    let(:topup_message) do
      {event: 'topup', producer_id: user_account.id, amount: 150.to_d}.with_indifferent_access
    end

    let(:payment_message) do
      {event: 'payment', producer_id: user_account.id, amount: 100.to_d}.with_indifferent_access
    end

    let(:unsupported_message) do
      {event: 'hacked', producer_id: user_account.id, amount: 999.to_d}.with_indifferent_access
    end

    it 'processes topup and payment correctly' do
      expect(described_class).to receive(:make_transaction)
                                     .with(bank_account.id, user_account.id, topup_message[:amount], 'topup', 'success')
                                     .and_call_original
      subject.run(topup_message)
      expect(bank_account.reload.balance).to eq(-150)
      expect(user_account.reload.balance).to eq(150)

      expect(described_class).to receive(:make_transaction)
                                     .with(user_account.id, bank_account.id, payment_message[:amount], 'payment', 'success')
                                     .and_call_original
      subject.run(payment_message)
      expect(bank_account.reload.balance).to eq(-50)
      expect(user_account.reload.balance).to eq(50)
    end

    it 'does not accept payment if user account is not enough' do
      subject.run(topup_message)
      subject.run(payment_message)
      subject.run(payment_message)

      # balance hasn't changed
      expect(bank_account.reload.balance).to eq(-50)
      expect(user_account.reload.balance).to eq(50)
    end

    it 'does not make any transaction if the event is unsupported' do
      subject.run(unsupported_message)

      expect(described_class).not_to receive(:make_transaction)
      expect(bank_account.reload.balance).to eq(0)
      expect(user_account.reload.balance).to eq(0)
    end
  end
end
