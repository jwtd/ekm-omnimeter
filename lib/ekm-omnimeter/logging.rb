require 'log4r'
include Log4r
module EkmOmnimeter

  module Logging

    def logger
      @logger ||= EkmOmnimeter::Logging.logger
    end

    def self.logger
      @logger ||= self.configure_logger_for(self.class.name)
    end

    def self.configure_logger_for(classname)
      l = Logger.new(classname)
      l.level = ERROR
      l.trace = false
      l.add Log4r::Outputter.stderr
      l
    end

  end

end