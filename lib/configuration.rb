require 'ostruct'
require 'logger'

module IPREDkoll
  module Configuration
    module_function

    # Takes these arguments:
    # :data_dir:: An absolute path to where you store configuration files and
    #             application data as log files, database etc.
    #             Default value on Windows is app_path\etc
    #             Default value on a Unix system is ~/.ipredkoll/
    # :app_dir::  The absolute path to the running directory of this script
    def load(args = {})
      config = OpenStruct.new

      config.app_dir         = args[:app_dir]
      config.data_dir        = if args[:data_dir]
                                 args[:data_dir]
                               elsif RUBY_PLATFORM.match(/win32/)
                                 File.join(config.app_dir, 'etc')
                               else
                                 File.join(ENV['HOME'], '.ipredkoll')
                               end
      config.config_file     = File.join(config.data_dir, 'config.rb')
      config.logger          = Logger.new(File.join(config.data_dir, 'ipredkoll.log'))

      unless File.readable?(config.config_file)
        config.logger.error "#{config.config_file} doesn't exist or isn't readable!"
        exit 1
      end

      begin
        eval <<-END_EVAL
          #{File.read(config.config_file)}
        END_EVAL
      rescue SyntaxError => e
        IPREDkoll::Config.logger.error "Syntax error in configuration file: '#{config.config_file}'"
        exit 2
      end

      config.db              = File.join(config.data_dir, 'db.sqlite3')
      config.ipredkoll_se_db = File.join(config.data_dir, 'ipredkoll_se.txt')

      if config.notifier_conf[:logger][:log_level]
        config.logger.level = config.notifier_conf[:logger][:log_level]
      end

      return config
    end
  end
end
