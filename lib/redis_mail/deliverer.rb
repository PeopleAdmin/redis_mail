require 'redis-namespace'
module RedisMail
  class Deliverer
    attr :settings

    def initialize(values)
      @settings = values
    end

    def deliver!(mail)
      mail.destinations.uniq.each do |to|
        RedisMail.deliver to, mail.to_s
      end
    end
  end
end
