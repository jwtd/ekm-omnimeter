require 'logging'

# Logging.init is required to avoid
#   unknown level was given 'info' (ArgumentError)
# or
#   uninitialized constant Logging::MAX_LEVEL_LENGTH (NameError)
# when an Appender or Layout is created BEFORE any Logger is instantiated:
#Logging.init :debug, :info, :warn, :error, :fatal
#
#layout = Logging::Layouts::Pattern.new :pattern => "[%d] [%-5l] %m\n"
#
## Default logfile, history kept for 10 days
#default_appender = Logging::Appenders::RollingFile.new 'default', \
#  :filename => 'log/default.log', :age => 'daily', :keep => 10, :safe => true, :layout => layout
#
## Audit logfile, history kept forever
#audit_appender = Logging::Appenders::RollingFile.new 'audit', \
#  :filename => 'log/audit.log', :age => 'daily', :safe => true, :layout => layout
#
## Production logfile, history kept forever
#prod_appender = Logging::Appenders::RollingFile.new 'prod', \
#  :filename => 'log/production.log', :age => 'daily', :safe => true, :layout => layout
#
#DEFAULT_LOGGER = returning Logging::Logger['server'] do |l|
#  l.add_appenders default_appender
#end

module EkmOmnimeter

  @@global_logger = nil

  # Returns true or false, reflecting whether a global logger is configured
  def self.global_logger_configured?
    (not @@global_logger.nil?)
  end

  # Returns true or false, reflecting whether a global logger is configured
  def self.configure_global_logger(options={})

    # Collect and validate log level
    log_level = options[:log_level] || configuration.log_level
    raise "Can not initialize global logger, because #{log_level.inspect} is an unrecognized log level." unless [:off, :all, :debug, :info, :warn, :error, :fatal].include?(log_level.to_sym)
    Logging.logger.root.level = log_level.to_sym

    # When set to true backtraces will be written to the logs
    trace_exceptions = options[:trace_exceptions] || configuration.trace_exceptions
    Logging.logger.root.trace = trace_exceptions

    # Check to see if we should log to stdout
    log_to_stdout = options[:log_to_stdout] || configuration.log_to_stdout
    if log_to_stdout

      # Setup colorized output for stdout (this scheme was setup for a terminal with a black background)
      # :black, :red, :green, :yellow, :blue, :magenta, :cyan, :white
      # :on_black, :on_red, :on_green, :on_yellow, :on_blue, :on_magenta, :on_cyan, :on_white
      # :blink, :bold, :underline, :underscore
      stdout_colors = options[:stdout_colors] || configuration.stdout_colors
      if stdout_colors == :for_dark_background
        Logging.color_scheme('stdout_colors',
                             {:levels => {
                                 :debug  => :white,
                                 :info  => [:white, :on_blue, :bold],
                                 :warn  => [:black, :on_yellow, :bold] ,
                                 :error => [:white, :on_red, :bold],
                                 :fatal => [:white, :on_red, :bold, :blink]
                             },
                              :date => :yellow,
                              :logger => :cyan,
                              :message => :white})
      elsif stdout_colors == :for_light_background
        Logging.color_scheme('stdout_colors',
                             {:levels => {
                                 :debug  => :black,
                                 :info  => [:black, :on_blue, :bold],
                                 :warn  => [:black, :on_yellow, :bold] ,
                                 :error => [:white, :on_red, :bold],
                                 :fatal => [:white, :on_red, :bold, :blink]
                             },
                              :date => :blue,
                              :logger => :magenta,
                              :message => :black})
      elsif stdout_colors.is_a?(Hash)
        Logging.color_scheme('stdout_colors', stdout_colors)
      end

      # Add the stdout appender
      Logging.logger.root.add_appenders Logging.appenders.stdout(
                          'stdout',
                          :layout => Logging.layouts.pattern(
                              #:pattern => '[%d] %-5l %c: %m\n',
                              :color_scheme => 'stdout_colors'
                          )
                      )
    end


    # Setup file logger
    log_file = options[:log_file] || configuration.log_file
    if log_file

      # Make sure log directory exists
      log_file = File.expand_path(log_file)
      log_dir  = File.dirname(log_file)

      raise "The log file can not be created, because its directory does not exist #{log_dir}" unless Dir.exists?(log_dir)

      # Determine layout. The available layouts are :basic, :json, :yaml, or a pattern such as '[%d] %-5l: %m\n'
      layout = options[:log_file_layout] || configuration.log_file_layout
      if layout == :basic
        use_layout = Logging::Layouts::Basic.new()
      elsif layout == :json
        use_layout = Logging::Layouts::JSON.new
      elsif layout == :yaml
        use_layout = Logging::Layouts::YAML.new
      else
        use_layout = Logging.layouts.pattern(:pattern => layout) # '[%d] %-5l -- %c -- %m\n'
      end

      # Make sure we're capturing milliseconds in date
      use_layout.date_pattern = '%Y-%m-%d %H:%M:%S:%L'

      # Determine if this should be a single or rolling log file
      rolling = options[:rolling_log_file_age] || configuration.rolling_log_file_age

      # Build the file appender
      if rolling
        rolling_limit = options[:rolling_log_limit] || configuration.rolling_log_limit
        Logging.logger.root.add_appenders Logging.appenders.rolling_file(
                            log_file,
                            :age  => rolling,
                            :keep => rolling_limit,
                            :safe => true,
                            :layout => use_layout
                        )
      else
        # Non-rolling log file
        Logging.logger.root.add_appenders Logging.appenders.file(log_file, :layout => use_layout)
      end

      # Growl on error
      growl_on_error = options[:growl_on_error] || configuration.growl_on_error
      if options[:growl_on_error]
        Logging.logger.root.add_appenders Logging.appenders.growl(
                            'growl',
                            :level  => :error,
                            :layout => use_layout #Logging.layouts.pattern(:pattern => '[%d] %-5l: %m\n')
                        )
      end

    end
    # Return the root logger
    Logging.logger.root
  end


  module Logger

    def logger
      @logger ||= EkmOmnimeter::Logger.logger
    end

    def self.logger
      @logger ||= self.configure_logger_for(self.class.name)
    end

    def self.configure_logger_for(classname)
      EkmOmnimeter.configure_global_logger() unless EkmOmnimeter.global_logger_configured?
      Logging.logger[classname]
    end

  end

end

