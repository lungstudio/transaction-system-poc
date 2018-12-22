module TransactionEventGenerator
  EVENTS = ['topup', 'payment']
  MAX_AMOUNT = ENV['MAX_TRANSACTION_AMOUNT'] || 100

  class << self
    def generate(producer_id)
      {
          producer_id: producer_id,
          amount: rand(MAX_AMOUNT),
          event: EVENTS.sample
      }
    end
  end
end
