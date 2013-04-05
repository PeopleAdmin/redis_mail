require 'redis-namespace'
module RedisMail
  class Deliverer
    attr :settings

    def initialize(values)
      @settings = values
    end

    def deliver!(mail)
      mail.destinations.uniq.each do |to|
        redis.sadd :mailboxes, to
        redis.rpush "mailbox:#{to}", mail.to_s
      end
    end

    private

    def redis
      RedisMail.redis
    end
  end
end
