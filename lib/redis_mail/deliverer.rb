module RedisMail
  class Deliverer
    attr :settings

    def initialize(values)
      @settings = values
    end

    def deliver!(mail)
      mail.destinations.uniq.each do |to|
        puts "sending mail to #{to}"
      end
    end
  end
end
