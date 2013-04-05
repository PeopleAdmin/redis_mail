require "redis_mail/version"
require "redis_mail/deliverer"

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
    redis.del "mailbox:#{recipient}"
    redis.srem :mailboxes, recipient
  end
end
