require 'mail'
require 'redis'
require 'redis_mail'

describe RedisMail do
  let(:redis) { RedisMail.redis = Redis.new.tap {|r| r.select 15} }
  before { redis.flushdb }

  describe ".clear_mailbox" do
    before do
      send "someone@example.com", "First"
      send "someone@example.com", "Second"
      send "someone@example.com", "Third"
    end

    it "removes all messages from the given mailbox" do
      redis.llen("redis_mail:mailbox:someone@example.com").should == 3
      RedisMail.clear_mailbox "someone@example.com"
      redis.llen("redis_mail:mailbox:someone@example.com").should == 0
    end

    it "removes the mailbox" do
      redis.smembers("redis_mail:mailboxes").should include("someone@example.com")
      RedisMail.clear_mailbox "someone@example.com"
      redis.smembers("redis_mail:mailboxes").should_not include("someone@example.com")
    end
  end

  describe ".clear_all" do
    before do
      send "someone@example.com", "First"
      send "another@example.com", "Second"
      send "different@example.com", "Third"
    end

    it "removes all messages from all given mailboxes" do
      redis.llen("redis_mail:mailbox:someone@example.com").should == 1
      redis.llen("redis_mail:mailbox:another@example.com").should == 1
      redis.llen("redis_mail:mailbox:different@example.com").should == 1
      RedisMail.clear_all
      redis.llen("redis_mail:mailbox:someone@example.com").should == 0
      redis.llen("redis_mail:mailbox:another@example.com").should == 0
      redis.llen("redis_mail:mailbox:different@example.com").should == 0
    end

    it "removes the mailboxes" do
      redis.scard("redis_mail:mailboxes").should == 3
      RedisMail.clear_all
      redis.scard("redis_mail:mailboxes").should == 0
    end
  end

  def send(recipient, subject)
    message = Mail.new {
        to recipient
        from "author@example.com"
        subject subject
    }
    message.delivery_method(RedisMail::Deliverer, {redis: redis})
    message.deliver!
  end
end
