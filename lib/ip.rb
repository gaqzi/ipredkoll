require 'socket'
require 'open-uri'
require 'ipaddr'

module IPREDkoll
  module IPLookup
    # These are some services that can give you your remote IP when visited.
    # We choose one at random when checking for the remote IP.
    #
    # Any site that gives the IP can be added as long as the first IP that
    # can be found by a regexp is the external one.
    LOOKUP_SERVICES = ['http://jackson.io/ip/', 'http://myip.dk/',
                       'http://myip.se/', 'http://www.ventrilo.com/myip.php',
                       'http://www.knowmyip.com/', 'http://myipinfo.net/',
                       'http://www.showipaddress.com/']

    module_function

    # Creating an UDP-connection to Google to find out what IP I would use
    # to do the connection from the machine being run. So if NAT:ed it shows
    # the NAT IP.
    # Note: We temporarily turn of DNS-lookups while doing this.
    #
    # http://coderrr.wordpress.com/2008/05/28/get-your-local-ip-address/
    def local_ip
      orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true

      UDPSocket.open do |s|
        s.connect '64.233.187.99', 1
        s.addr.last
      end
    ensure
      Socket.do_not_reverse_lookup = orig
    end

    # Discovers the IP you report when you surf the Internet (most likely used
    # whenever you connect to another Internet connected host).
    #
    # The external IP is looked up through a random site from
    # +LOOKUP_SERVICES+ and if there's a +SocketError+ (should account
    # for all kinds of connection errors here) it will retry 10 times
    # and then give up.
    #
    # TODO: Look whether there's a way to do this without an external site
    def external_ip
      counter = 0
      begin
        open(LOOKUP_SERVICES[rand(LOOKUP_SERVICES.size)]) do |f|
          f.read.match(/(\d{1,3}\.){3}\d{1,3}/)[0]
        end
      rescue SocketError
        counter += 1
        return nil if counter == 10

        retry
      end
    end

    # A simple check whether the IP is a RFC1918 IP
    # aka Private Address Space IP.
    #
    # The matching done is simple since if anything of the static pattern
    # is found then it's local and we should check through an external service.
    def is_private_ip?(ip)
      case ip
      when /^10\.\d{1,3}\.\d{1,3}\.\d{1,3}/
        true
      when /^192\.168\.\d{1,3}\.\d{1,3}/
        true
      when /^172\.(1[6-9]|2\d|3[0-1])\.\d{1,3}\.\d{1,3}/
        true
      when /^127\.\d{1,3}\.\d{1,3}\.\d{1,3}/
        true
      else
        false
      end
    end

    # Find out what IP the computer calling this method uses
    # to connect to the internet.
    #
    # Returns +nil+ when no valid IP or no connections made to an external
    # service.
    #
    # TODO: Have test this out with all interfaces down
    def my_ip
      ip = IPAddr.new(local_ip).to_s # Raises ArgumentError if it's an invalid IP

      if ip == '0.0.0.0'
        return nil
      elsif is_private_ip?(ip)
        external_ip
      else
        ip
      end
    end
  end
end
