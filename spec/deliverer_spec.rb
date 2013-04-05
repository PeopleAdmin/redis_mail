require 'mail'
require 'redis'
require 'redis_mail'

describe RedisMail::Deliverer do
  let(:redis) { RedisMail.redis = Redis.new.tap {|r| r.select 15} }

  before { redis.flushdb }

  context "delivering a message" do
    let(:sent_message) {
      Mail.new {
        to "someone@example.com"
        to << "another@example.com"
        from "author@example.com"
        subject "Hello world"
        body "This is the test email"
        cc "interested@example.com"
      }
    }

    before do
      sent_message.delivery_method(RedisMail::Deliverer, {})
      sent_message.deliver!
    end

    it "creates a mailbox for tracking messages to each recipient" do
      mailboxes = redis.smembers "redis_mail:mailboxes"
      mailboxes.should have(3).items
      mailboxes.should include "someone@example.com"
      mailboxes.should include "another@example.com"
      mailboxes.should include "interested@example.com"
    end

    it "stores the entire message for each recipient" do
      sent = redis.lpop "redis_mail:mailbox:someone@example.com"
      sent.should_not be_nil
      sent.should == sent_message.to_s

      sent = redis.lpop "redis_mail:mailbox:another@example.com"
      sent.should_not be_nil
      sent.should == sent_message.to_s

      sent = redis.lpop "redis_mail:mailbox:interested@example.com"
      sent.should_not be_nil
      sent.should == sent_message.to_s
    end

    context "delivering multiple message to same recipient" do
      let(:second_message) { Mail.new to: "someone@example.com", subject: "second"  }
      let(:third_message) { Mail.new to: "someone@example.com", subject: "third"  }

      before do
        [second_message, third_message].each do |message|
          message.delivery_method(RedisMail::Deliverer, {redis: redis})
          message.deliver!
        end
      end

      it "stores the messages in chronological order" do
        sent = redis.lpop "redis_mail:mailbox:someone@example.com"
        Mail.new(sent).should == sent_message

        sent = redis.lpop "redis_mail:mailbox:someone@example.com"
        Mail.new(sent).should == second_message

        sent = redis.lpop "redis_mail:mailbox:someone@example.com"
        Mail.new(sent).should == third_message

        sent = redis.lpop "redis_mail:mailbox:someone@example.com"
        sent.should be_nil
      end
    end
  end
end
