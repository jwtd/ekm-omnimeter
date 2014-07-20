# Reference: http://brandonhilkert.com/blog/ruby-gem-configuration-patterns/


module EkmOmnimeter

  # Module level access to configuration
  class << self
    attr_writer :configuration
  end


  # Allow block style configuration
  def self.configure
    yield(configuration)
  end

  # Lazy initialization of default config
  def self.configuration
    @configuration ||= Configuration.new
  end

  # Allow configuration from hash
  def self.configure_from_hash(h)
    @configuration = Configuration.from_hash(h)
  end

  # Allow configuration from yaml file
  def self.configure_from_yaml_file(f)
    @configuration = Configuration.from_yaml_file(f)
  end

  # Reset configuration
  def self.reset_configuration
    @configuration = Configuration.new
  end


  # Define the configuration options
  class Configuration

    attr_accessor :log_level            # :off, :all, :debug, :info, :warn, :error, :fatal
    attr_accessor :trace_exceptions     # Default is true
    attr_accessor :log_to_stdout        # Default is true
    attr_accessor :stdout_colors        # Default is :for_dark_backgrounds, :for_light_background, or custom by passing a hash that conforms to https://github.com/TwP/logging/blob/master/examples/colorization.rb
    attr_accessor :log_file             # Default is nil
    attr_accessor :log_file_layout      # :basic, :json, :yaml, or a pattern such as '[%d] %-5l: %m\n'
    attr_accessor :rolling_log_file_age # Default is false, options are false or 'daily', 'weekly', 'monthly' or an integer
    attr_accessor :rolling_log_limit    # Default is false, but any positive integer can be passed
    attr_accessor :growl_on_error       # Default is false

    # Specify the configuration defaults and support configuration via hash .configuration.new(config_hash)
    def initialize(options={})

      @log_level            = options[:log_level]            || :warn
      @trace_exceptions     = options[:trace_exceptions]     || true
      @log_to_stdout        = options[:log_to_stdout]        || true
      @stdout_colors        = options[:stdout_colors]        || :for_dark_background
      @log_file             = options[:log_file]             || nil
      @log_file_layout      = options[:log_file_layout]      || :basic
      @rolling_log_file_age = options[:rolling_log_file_age] || false
      @rolling_log_limit    = options[:rolling_log_limit]    || false
      @growl_on_error       = options[:growl_on_error]       || false

    end

    # Hash constructor
    def self.from_hash(h)
      self.new(h)
    end

    # File constructor
    def self.from_yaml_file(f)
      # Make sure configuration file exists
      c = File.join(pwd, f)
      unless File.exist?(c)
        raise "Configuration file does not exist #{f}"
      else
        self.new(YAML::load_file(c))
      end
    end


  end

end


