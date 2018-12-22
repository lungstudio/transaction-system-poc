require 'bunny'
require 'logger'
require 'json'
require 'erb'
require 'active_record'
require_relative 'transaction_handler'

RABBITMQ_URL = ENV['CLOUDAMQP_URL'] || 'amqp://guest:guest@rabbitmq'
TRANSACTION_MQ_ROUTE_KEY = ENV['TRANSACTION_MQ_ROUTE_KEY'] || 'transaction_handler'
TRANSACTION_EXCHANGE_NAME = ENV['TRANSACTION_EXCHANGE_NAME'] || 'transaction_system'

# connect to DB
connection_configs = YAML.load(ERB.new(File.read('config/database.yml')).result)
ActiveRecord::Base.establish_connection(connection_configs['default'])

# logger
logger = Logger.new(STDOUT)

# setup bunny connection
connection = Bunny.new(RABBITMQ_URL)
connection.start

begin
  logger.info("[consumer] START")
  channel = connection.create_channel
  exchange = channel.direct(TRANSACTION_EXCHANGE_NAME)
  queue = channel.queue('consumer_queue', druable: true, auto_delete: false)
  queue.bind(exchange, routing_key: TRANSACTION_MQ_ROUTE_KEY)

  begin
    queue.subscribe(manual_ack: true, block: true) do |delivery_info, _, payload|
      TransactionHandler.run(JSON.parse(payload))
      channel.ack(delivery_info.delivery_tag)
    end
  rescue Interrupt
    logger.info("[consumer] interrupted, stopping...")
  end

ensure
  connection.close
  logger.info("[consumer] END")
end
