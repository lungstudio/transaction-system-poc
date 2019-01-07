redis_url = if Rails.env == 'test'
              'redis://localhost:6379'
            else
              ENV['REDISCLOUD_URL'] || 'redis://redis:6379'
            end

$redis = Redis.new(url: redis_url)
