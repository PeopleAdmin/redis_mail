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

    it "returns true when messages are cleared" do
      RedisMail.clear_mailbox("someone@example.com").should be_true
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

    it "returns true when messages are cleared" do
      RedisMail.clear_all.should be_true
    end
  end

  describe ".deliveries_to" do
    before do
      send "someone@example.com", "Beta"
      send "another@example.com", "Gamma"
      send "someone@example.com", "Alpha"
    end

    it "returns the messages for a given recipient, in chronological order" do
      deliveries = RedisMail.deliveries_to "someone@example.com"
      deliveries.should have(2).items
      deliveries[0].should include("Beta")
      deliveries[1].should include("Alpha")
    end
  end

  describe ".deliveries" do
    before do
      send "someone@example.com", "Beta"
      send "another@example.com", "Gamma"
      send "someone@example.com", "Alpha"
    end

    it "returns all messages received" do
      deliveries = RedisMail.deliveries
      deliveries.should have(3).items
      deliveries.any?{|d| d.include?("Alpha")}.should be_true
      deliveries.any?{|d| d.include?("Beta")}.should be_true
      deliveries.any?{|d| d.include?("Gamma")}.should be_true
    end
  end

  describe ".deliveries_count" do
    before do
      send "someone@example.com", "Beta"
      send "another@example.com", "Gamma"
      send "someone@example.com", "Alpha"
    end

    it "returns the number of messages received" do
      RedisMail.deliveries_count.should == 3
    end
  end

  describe ".deliveries_count_to" do
    before do
      send "someone@example.com", "Beta"
      send "another@example.com", "Gamma"
      send "someone@example.com", "Alpha"
    end

    it "returns the number of messages sent to a given address" do
      RedisMail.deliveries_count_to("someone@example.com").should == 2
    end
  end

  describe ".mailboxes" do
    before do
      send "someone@example.com", "Beta"
      send "another@example.com", "Gamma"
      send "someone@example.com", "Alpha"
    end

    it "returns a list of email address which have received messages" do
      mailboxes = RedisMail.mailboxes
      mailboxes.should have(2).recipients
      mailboxes.should include("someone@example.com")
      mailboxes.should include("another@example.com")
    end
  end

  context "when no messages have been sent" do
    it "returns an empty array for .mailboxes" do
      RedisMail.mailboxes.should == []
    end

    it "returns an empty array for .deliveries" do
      RedisMail.deliveries.should == []
    end

    it "returns an empty array for .deliveries_to" do
      RedisMail.deliveries_to("someone@example.com").should == []
    end

    it "returns 0 for .deliveries_count" do
      RedisMail.deliveries_count.should == 0
    end

    it "returns 0 for .deliveries_count_to" do
      RedisMail.deliveries_count_to("someone@example.com").should == 0
    end

    it "returns false for .clear_mailbox" do
      RedisMail.clear_mailbox("someone@example.com").should be_false
    end

    it "returns false for .clear_all" do
      RedisMail.clear_all.should be_false
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
