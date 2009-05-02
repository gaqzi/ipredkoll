require 'socket'
require 'open-uri'

module IPREDkoll
  module IPLookup
    # Creating an UDP-connection to Google to find out what IP I would use
    # to do the connection from the machine being run. So if NAT:ed it shows
    # the NAT IP.
    # Note: We temporarily turn of DNS-lookups while doing this.
    #
    # http://coderrr.wordpress.com/2008/05/28/get-your-local-ip-address/
    def self.local_ip
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
    # The external IP is looked up through http://myip.dk/
    #
    # TODO: Look whether there's a way to do this without an external site
    def self.external_ip
      open('http://myip.dk') do |f|
        f.read.match(/(\d{1,3}\.){3}\d{1,3}/)[0]
      end
    end

    # A simple check whether the IP is a RFC1918 IP
    # aka Private Address Space IP
    def self.is_private_ip?(ip)
      case ip
      when /10.\d{1,3}.\d{1,3}.\d{1,3}/
        true
      when /192.168.\d{1,3}.\d{1,3}/
        true
      when /172.(1[6-9]|2\d|3[0-1]).\d{1,3}.\d{1,3}/
        true
      when '127.0.0.1'
        true
      else
        false
      end
    end

    # Find out what IP the computer calling this method uses
    # to connect to the internet.
    def self.my_ip
      ip = self.local_ip
      if is_private_ip?(ip)
        self.external_ip
      else
        ip
      end
    end
  end
end
