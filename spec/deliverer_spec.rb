require 'mail'
require 'redis_mail'

describe RedisMail::Deliverer do
  it "delivers the message to each recipient" do
    mail = Mail.new to: "someone@example.com", from: "author@example.com",
      subject: "Hello world", body: "This is the test email"
    mail.delivery_method(RedisMail::Deliverer, {})
    mail.deliver!
  end
end
