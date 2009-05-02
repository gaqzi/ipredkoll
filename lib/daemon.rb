require 'observer'

module IPREDkoll
  class Daemon
    include Observable

    def initialize
      Config.notifiers.each do |notifier|
        IPREDkoll::Notifiers.const_get(notifier).new(self)
      end

      loop do
        check()
        sleep(15 * 60)
      end
    end

    def check
      DB.new do |db|
        db.mark_ip(IPLookup.my_ip)
        db.any_ip_under_inspection?.each do |row|
          changed
          notify_observers(row)
        end
      end
    end
  end # End Daemon
end # End IPREDkoll
