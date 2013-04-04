require 'redis-namespace'
module RedisMail
  class Deliverer
    attr :settings

    def initialize(values)
      @settings = values
    end

    def redis
      @redis ||= Redis::Namespace.new(:redis_mail, redis: settings[:redis])
    end

    def deliver!(mail)
      mail.destinations.uniq.each do |to|
        redis.sadd :mailboxes, to
        redis.rpush "mailbox:#{to}", mail.to_s
      end
    end
  end
end
