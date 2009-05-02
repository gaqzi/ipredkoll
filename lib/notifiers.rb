module IPREDkoll
  # The hash passed into the +update+ method contains these keys:
  # ip, start_time, end_time, last_seen, time_active, case_number, url
  #
  module Notifiers
    class Logger
      def initialize(obj)
        obj.add_observer(self)
      end

      def update(data)
        message = "#{data['ip']} undersöks enligt IPRED. Du har haft det IP:et "
        message += if data['end_time']
                     "mellan #{data['start_time']} och #{data['end_time']}. "
                   else
                     "sedan #{data['start_time']}. "
                   end
        message += "URL hos ipredkoll.se: #{data['url']}"

        Config.logger.warn(message)
      end
    end # End Logger

    # To be implemented
    #
    # class Email
    #   def initialize(obj)
    #     @host  = Config.notifiers[:email][:host]
    #     @port  = Config.notifiers[:email][:port]
    #     @user  = Config.notifiers[:email][:user]
    #     @pass  = Config.notifiers[:email][:pass]
    #     @email = Config.notifiers[:email][:email_address]
    #     @auth  = Config.notifiers[:email][:auth] || :plain
    #
    #     obj.add_observer(self)
    #   end
    #
    #   def update(data)
    #     Net::SMTP.start(@host, @user, @pass, @auth) do |smtp|
    #       smtp.send_message()
    #     end
    #   end
    # end
  end # End Notifiers
end
