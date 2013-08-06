module RedisMail
  class Railtie < Rails::Railtie
    config.before_configuration do
      ActionMailer::Base.add_delivery_method :redis_mail, RedisMail::Deliverer
    end
  end
end
