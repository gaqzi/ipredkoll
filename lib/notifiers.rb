module IPREDkoll
  # The notifiers has to follow these two rules which are set by the built-in
  # +Observable+ module:
  # * The +initialize+ method can only take one argument which is the object
  #   that we're going to add our self as an observer to by: +obj.add_observer(self)+
  # * An +update+ method which takes one argument, which is the hash described below.
  #   Apart from that you are free to make as many methods as you want.
  #
  # The hash passed into the +update+ method contains these keys:
  # ip::
  # start_time::  The first time that IP was seen
  # end_time::    The time we got a new IP
  # last_seen::   Last time we had an active report of that IP
  # time_active:: The date/time that IP was in use in an IPRED-case
  # case_number::
  # url::         An URL with more information at ipredkoll.se
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

    # --
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
