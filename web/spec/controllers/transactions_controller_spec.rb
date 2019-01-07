require 'rails_helper'

RSpec.describe TransactionsController, type: :controller do
  before do
    # some problem with url_helper, skipping it for now
    allow_any_instance_of(::ActionController::Redirecting).to receive(:redirect_back).and_return(true)

    # create initial accounts and reset
    Account.create!(account_type: 'bank', balance: 0)
    3.times {Account.create!(account_type: 'user', balance: 0)}
    controller.send(:reset_all)
  end

  context 'reset_all' do
    it 'initializes 3 user accounts and 1 bank account' do
      post :reset_all

      all_accounts = Account.all
      all_account_balance_sum = all_accounts.map(&:balance).inject(0, &:+)
      all_transactions = Transaction.all

      expect(all_accounts.size).to eq(4)
      expect(all_account_balance_sum).to eq(0) # zero sum system

      expect(all_transactions.size).to eq(3)
      expect(all_transactions.pluck(:transferrer_account_id).uniq).to eq([Account.bank_account.id]) # all transferrers are from bank
      expect(all_transactions.pluck(:status).uniq).to eq(['success'])
      expect(all_transactions.pluck(:transaction_type).uniq).to eq(['topup'])
    end
  end

  context 'index' do
    it 'renders correct format' do
      get :index
      assigns(:accounts).as_json.each do |acc|
        expect(acc).to include_json(
                           {
                               'id' => an_instance_of(Integer),
                               'account_type' => be_in(['bank', 'user']),
                               'balance' => an_instance_of(String),
                               'is_on' => be_in([true, false])
                           }
                       )
      end
    end
  end

  context 'toggle_producer' do
    it 'toggles correctly' do
      $redis.setex("producer.100.is_on", 5.second, true)
      post :toggle_producer, params: {producer_id: 100}
      expect($redis.get("producer.100.is_on")).to eq('false')

      post :toggle_producer, params: {producer_id: 100}
      expect($redis.get("producer.100.is_on")).to eq('true')
    end
  end

  context 'start_all_producers, stop_all_producers' do
    let(:no_of_producers) {ENV['NO_OF_PRODUCERS']&.to_i || 3}

    it 'start/stop as expected' do
      # set all to false
      no_of_producers.times do |i|
        $redis.setex("producer.#{i + 2}.is_on", 7.days, false)
      end

      post :start_all_producers
      no_of_producers.times do |i|
        expect($redis.get("producer.#{i + 2}.is_on")).to eq('true')
      end

      post :stop_all_producers
      no_of_producers.times do |i|
        expect($redis.get("producer.#{i + 2}.is_on")).to eq('false')
      end
    end
  end
end
