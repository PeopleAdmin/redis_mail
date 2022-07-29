# RedisMail

A Redis-backed `delivery_method` for the Mail gem (and therefore, Rails'
ActionMailer).

If your tests run in the same process as the code you are testing, use the
:test delivery method (`Mail::TestMailer`) instead.

However, in acceptance test scenarios, your test code often runs in a separate
process from the code being tested. This makes the `Mail::TestMailer.deliveries`
in-memory array useless.

The :file delivery method (`Mail::FileDelivery`) is another option, however it
stores all messages to a recipient in a single file, with no easy way to parse
the messages individually.

RedisMail allows you to capture e-mails sent from one process (your application
under test) and make assertions in another (your test code). Each message
can be retrieived and parsed individually.

## Installation

Add this line to your application's Gemfile:

    gem 'redis_mail'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install redis_mail

## Configre your application

### Rails 3.x +

Configure ActionMailer to use RedisMail. In *config/environments/test.rb*:

    config.action_mailer.delivery_method = RedisMail::Deliverer

Set your connection to redis. In *config/initializers/redismail.rb*:

    RedisMail.redis = Redis.new(:host => myredis.host.com)

### Outside of Rails (using Mail gem)

Set the delivery method on the mail message:

    message = Mail.new(:to => "someone@example.com", :subject => "Hello")
    message.delivery_method(RedisMail::Deliverer, {})

## Retrieving message information

### RedisMail.clear_all

Clears all received messages for any recipient. Run this between each test!

### RedisMail.clear_mailbox(recipient)

Clears all recieved messages for a specific recipient.

### RedisMail.deliveries_count

Total number of messages delivered to any recipient.

Example usage:

    RedisMail.clear_all
    invoke_action_in_application_that_sends_two_emails
    raise "Expected emails missing" unless RedisMail.deliveries_count == 2

### RedisMail.deliveries_count_to(recipient)

Total number of messages delivered to a specific recipient.

### RedisMail.deliveries

An array of all messages delivered to any receipient. Each message can be
parsed using classes provided by the `Mail` gem, for finer grained assertions.

Example usage:

    RedisMail.clear_all
    invoke_action_that_sends_welcome_email
    sent_message = Mail.new(RedisMail.deliveries.first)
    raise "Unexpected subject" unless sent_message.subject == "Welcome!"

### RedisMail.deliveries_to

An array of messages delivered to a given recipient. Messages are ordered from
oldest to newest.

### RedisMail.mailboxes

An array of recipient addresses that can be used in calls to `deliveries_to`,
`deliveries_count_to`, or `clear_mailbox`.

## Contributing

1. [Fork it](https://github.com/PeopleAdmin/redis_mail/fork_select)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. [Create new Pull Request](https://github.com/PeopleAdmin/redis_mail/pull/new/master)
