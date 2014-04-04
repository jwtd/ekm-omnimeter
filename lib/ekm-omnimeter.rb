module EkmOmnimeter
  # Base Ekm exception class
  class EkmOmnimeterError < ::Exception; end
end

require "ekm-omnimeter/version"
require "ekm-omnimeter/logging"
require "ekm-omnimeter/crc16"
require "ekm-omnimeter/meter"