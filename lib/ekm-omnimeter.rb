module EkmOmnimeter
  # Base Ekm exception class
  class EkmOmnimeterError < ::Exception; end
end

require "ekm-omnimeter/version"
require "ekm-omnimeter/logger"
require "ekm-omnimeter/configuration"
require "ekm-omnimeter/crc16"
require "ekm-omnimeter/meter"