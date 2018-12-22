redis_url = ENV['REDISCLOUD_URL'] || 'redis://redis:6379'

$redis = Redis.new(url: redis_url)
