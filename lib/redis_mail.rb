require "redis_mail/version"
require "redis_mail/deliverer"
require "redis_mail/railtie" if defined?(Rails::Railtie)

module RedisMail
  extend self

  def redis=(server)
    @redis = Redis::Namespace.new(:redis_mail, redis: server)
  end

  def redis
    raise "RedisMail.redis must be set to a Redis connection" unless @redis
    @redis
  end

  def clear_mailbox(recipient)
    redis.del mailbox_key(recipient)
    redis.srem :mailboxes, recipient
  end

  def clear_all
    mailboxes.reduce(false) do |cleared,mailbox|
      clear_mailbox(mailbox) || cleared
    end
  end

  def mailboxes
    redis.smembers :mailboxes
  end

  def deliveries_to(recipient)
    redis.lrange mailbox_key(recipient), 0, -1
  end

  def deliveries
    mailboxes.map{|recipient| deliveries_to(recipient)}.flatten
  end

  def deliveries_count
    mailboxes.reduce(0){|sum, recipient|
      sum + redis.llen(mailbox_key(recipient))
    }
  end

  def deliveries_count_to(recipient)
    redis.llen(mailbox_key(recipient))
  end

  def deliver(recipient, message)
    redis.sadd? :mailboxes, recipient
    redis.rpush mailbox_key(recipient), message
  end

  private

  def mailbox_key(recipient)
    "mailbox:#{recipient}"
  end
end
