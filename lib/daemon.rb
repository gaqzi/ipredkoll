require 'observer'

module IPREDkoll
  class Daemon
    include Observable

    def initialize
      Config.logger.debug "Entering initialize"

      Config.notifiers.each do |notifier|
        Config.logger.debug "Trying to add notifier: #{notifier}"
        IPREDkoll::Notifiers.const_get(notifier).new(self)
      end

      Config.logger.debug "Notifiers has been added and main loop is starting..."

      if block_given?
        yield self
      else
        loop do
          Config.logger.debug "In main loop"
          check()
          sleep()
        end
      end
    end

    def sleep
      Kernel.sleep(15 * 60)
    end

    def check
      ip = IPLookup.my_ip

      if ip.nil?
        Config.logger.info "Not connected to the Internet. Will retry later..."
        return false
      end

      DB.new do |db|
        Config.logger.debug "Marking IP: #{ip}"
        db.mark_ip(ip)
        db.any_ip_under_inspection?.each do |data|
          Config.logger.debug "IP: #{data['ip']} is under inspection! #{data.inspect}"

          changed
          notify_observers(data)
        end
      end
    end
  end # End Daemon
end # End IPREDkoll
