require 'bunny'
require 'logger'
require 'json'
require 'redis'
require_relative 'transaction_event_generator'

MAX_SLEEP_SEC = ENV['MAX_SLEEP_SEC']&.to_i || 5
RABBITMQ_URL = ENV['CLOUDAMQP_URL'] || 'amqp://guest:guest@rabbitmq'
REDIS_URL = ENV['REDISCLOUD_URL'] || 'redis://redis:6379'
TRANSACTION_MQ_ROUTE_KEY = ENV['TRANSACTION_MQ_ROUTE_KEY'] || 'transaction_handler'
TRANSACTION_EXCHANGE_NAME = ENV['TRANSACTION_EXCHANGE_NAME'] || 'transaction_system'
NO_OF_PRODUCERS = ENV['NO_OF_PRODUCERS']&.to_i || 3

# logger
logger = Logger.new(STDOUT)

# setup bunny connection
connection = Bunny.new(RABBITMQ_URL)
connection.start

# setup up redis connection
redis = Redis.new(url: REDIS_URL)

# get producer ID from redis list
# 'producer.available_accounts' stores a list of available account IDs
# if it's null, set self to ID 2 and push other IDs to the list
# (note: ID 1 is reserved for the bank)
redis_list_key = 'producer.available_accounts'
producer_id = redis.lpop(redis_list_key)
unless producer_id
  redis.lpush(redis_list_key, Array("3"..(NO_OF_PRODUCERS + 1).to_s)) if (NO_OF_PRODUCERS > 1)
  producer_id = "2"
end

begin
  logger.info("[producer #{producer_id}] START")
  channel = connection.create_channel
  exchange = channel.direct(TRANSACTION_EXCHANGE_NAME)
  routing_key = TRANSACTION_MQ_ROUTE_KEY

  # keep sending message in a random interval
  loop do
    if (redis.get("producer.#{producer_id}.is_on") == 'true')
      message = TransactionEventGenerator.generate(producer_id).to_json
      exchange.publish(message, routing_key: routing_key)

      logger.info("[producer #{producer_id}] message published to route #{routing_key}, messgae: #{message}")
    end

    sleep(rand(MAX_SLEEP_SEC))
  end
ensure
  redis.lpush(redis_list_key, producer_id) # mark the id as available
  redis.close
  connection.close
  logger.info("[producer #{producer_id}] END")
end
