require 'ostruct'
require 'logger'

module IPREDkoll
  module Configuration
    def load(configuration_file = nil)
      config = OpenStruct.new
      config.basedir         = File.join(ENV['HOME'], '.ipredkoll')
      config.db              = File.join(config.basedir, 'db.sqlite3')
      config.ipredkoll_se_db = File.join(config.basedir, 'ipredkoll_se.txt')
      config.logger          = Logger.new(File.join(config.basedir, 'ipredkoll.log'))
      config.config_file     = configuration_file || File.join(config.basedir, 'config.rb')

      unless File.readable?(config.config_file)
        STDERR.puts "~/.ipredkoll/config.rb doesn't exist or isn't readable!"
        exit 1
      end

      begin
        eval <<-END_EVAL
          #{File.read(config.config_file)}
        END_EVAL
      rescue SyntaxError => e
        STDERR.puts "Syntax error in configuration file: '#{config.config_file}'"
        exit 2
      end

      if config.notifier_conf[:logger][:log_level]
        config.logger.level = config.notifier_conf[:logger][:log_level]
      end

      return config
    end
    module_function :load
  end
end
