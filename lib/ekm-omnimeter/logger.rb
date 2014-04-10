require 'logging'

module EkmOmnimeter

  @@global_logger = nil

  # Returns true or false, reflecting whether a global logger is configured
  def self.global_logger_configured?
    (not @@global_logger.nil?)
  end

  # Returns true or false, reflecting whether a global logger is configured
  def self.configure_global_logger(options={})

    # Collect and validate log level
    log_level = options[:log_level] || :debug
    raise "Can not initialize global logger, because #{log_level.inspect} is an unrecognized log level." unless [:off, :all, :debug, :info, :warn, :error, :fatal].include?(log_level)
    Logging.logger.root.level = log_level

    # When set to true backtraces will be written to the logs
    trace_exceptions = options[:trace_exceptions] || true
    Logging.logger.root.trace = trace_exceptions

    # Setup colorized output for stdout (this scheme was setup for a terminal with a black background)
    # :black, :red, :green, :yellow, :blue, :magenta, :cyan, :white
    # :on_black, :on_red, :on_green, :on_yellow, :on_blue, :on_magenta, :on_cyan, :on_white
    # :blink, :bold, :underline, :underscore
    stdout_colors = options[:stdout_colors] || {:levels => {
        :debug  => :white,
        :info  => [:white, :on_blue, :bold],
        :warn  => [:black, :on_yellow, :bold] ,
        :error => [:white, :on_red, :bold],
        :fatal => [:white, :on_red, :bold, :blink]
    },
                                                :date => :yellow,
                                                :logger => :cyan,
                                                :message => :white}
    Logging.color_scheme('stdout_colors', stdout_colors)

    # Always log info to stdout
    log_to_stdout = options[:log_to_stdout] || true
    if log_to_stdout
      Logging.logger.root.add_appenders Logging.appenders.stdout(
                          'stdout',
                          :layout => Logging.layouts.pattern(
                              #:pattern => '[%d] %-5l %c: %m\n',
                              :color_scheme => 'stdout_colors'
                          )
                      )
    end

    if options[:log_file]

      # Make sure log directory exists
      log_file = File.expand_path(options[:log_file])
      log_dir  = File.dirname(log_file)
      raise "The log file can not be created, because its directory does not exist #{log_dir}" if Dir.exists?(log_dir)

      # Determine layout. The available layouts are :basic, :json, :yaml, or a pattern such as '[%d] %-5l: %m\n'
      layout = options[:log_file_layout] || :basic
      if options[:log_file_layout]
        if layout == :basic
          use_layout = Logging.layouts.basic
        elsif layout == :json
          use_layout = Logging.layouts.json
        elsif layout == :yaml
          use_layout = Logging.layouts.yaml
        else
          use_layout = Logging.layouts.pattern(:pattern => layout) # '[%d] %-5l: %m\n'
        end
      end

      # Determine if this should be a single or rolling log file
      rolling = options[:rolling_log_file_age] || false

      # Build the file appender
      if rolling
        Logging.logger.root.add_appenders Logging.appenders.rolling_file(
                            'development.log',
                            :age    => rolling,
                            :layout => use_layout
                        )
      else
        # Non-rolling log file
        Logging.logger.root.add_appenders Logging.appenders.file(log_file, :layout => use_layout)
      end

      # Growl on error
      growl_on_error = options[:growl_on_error] || false
      if options[:growl_on_error]
        Logging.logger.root.add_appenders Logging.appenders.growl(
                            'growl',
                            :level  => :error,
                            :layout => Logging.layouts.pattern(:pattern => '[%d] %-5l: %m\n')
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
      l = Logging.logger[classname]
    end

    #def self.configure_logger_for(classname, options={})
    #
    #  # Create the logger
    #  l = Logging.logger[classname]
    #
    #  # Collect and validate log level
    #  log_level = options[:log_level] || :debug
    #  raise "Can not initalize global logger, because #{log_level.inspect} is an unrecognized log level." unless [:off, :all, :debug, :info, :warn, :error, :fatal].include?(log_level)
    #  Logging.logger.root.level = log_level
    #
    #  # When set to true backtraces will be written to the logs
    #  trace_exceptions = options[:trace_exceptions] || true
    #  l.trace = trace_exceptions
    #
    #  # Setup colorized output for stdout (this scheme was setup for a terminal with a black background)
    #  # :black, :red, :green, :yellow, :blue, :magenta, :cyan, :white
    #  # :on_black, :on_red, :on_green, :on_yellow, :on_blue, :on_magenta, :on_cyan, :on_white
    #  # :blink, :bold, :underline, :underscore
    #  stdout_colors = options[:stdout_colors] || {:levels => {
    #                                                  :debug  => :white,
    #                                                  :info  => [:white, :on_blue, :bold],
    #                                                  :warn  => [:black, :on_yellow, :bold] ,
    #                                                  :error => [:white, :on_red, :bold],
    #                                                  :fatal => [:white, :on_red, :bold, :blink]
    #                                              },
    #                                            :date => :yellow,
    #                                            :logger => :cyan,
    #                                            :message => :white}
    #  Logging.color_scheme('stdout_colors', stdout_colors)
    #
    #  # Always log info to stdout
    #  log_to_stdout = options[:log_to_stdout] || true
    #  if log_to_stdout
    #    l.add_appenders Logging.appenders.stdout(
    #        'stdout',
    #        :layout => Logging.layouts.pattern(
    #            #:pattern => '[%d] %-5l %c: %m\n',
    #            :color_scheme => 'stdout_colors'
    #        )
    #    )
    #  end
    #
    #  if options[:log_file]
    #
    #    # Make sure log directory exists
    #    log_file = File.expand_path(options[:log_file])
    #    log_dir  = File.dirname(log_file)
    #    raise "The log file can not be created, because its directory does not exist #{log_dir}" if Dir.exists?(log_dir)
    #
    #    # Determine layout. The available layouts are :basic, :json, :yaml, or a pattern such as '[%d] %-5l: %m\n'
    #    layout = options[:log_file_layout] || :basic
    #    if options[:log_file_layout]
    #      if layout == :basic
    #        use_layout = Logging.layouts.basic
    #      elsif layout == :json
    #        use_layout = Logging.layouts.json
    #      elsif layout == :yaml
    #        use_layout = Logging.layouts.yaml
    #      else
    #        use_layout = Logging.layouts.pattern(:pattern => layout) # '[%d] %-5l: %m\n'
    #      end
    #    end
    #
    #    # Determine if this should be a single or rolling log file
    #    rolling = options[:rolling_log_file_age] || false
    #
    #    # Build the file appender
    #    if rolling
    #      l.add_appenders Logging.appenders.rolling_file(
    #          'development.log',
    #          :age    => rolling,
    #          :layout => use_layout
    #      )
    #    else
    #      # Non-rolling log file
    #      l.add_appenders Logging.appenders.file(log_file, :layout => use_layout)
    #    end
    #
    #    # Growl on error
    #    growl_on_error = options[:growl_on_error] || false
    #    if options[:growl_on_error]
    #      l.add_appenders Logging.appenders.growl(
    #          'growl',
    #          :level  => :error,
    #          :layout => Logging.layouts.pattern(:pattern => '[%d] %-5l: %m\n')
    #      )
    #    end
    #
    #  end
    #
    #  l
    #
  end

end