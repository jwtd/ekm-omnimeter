# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ekm-omnimeter/version'

Gem::Specification.new do |spec|
  spec.name          = "ekm-omnimeter"
  spec.version       = EkmOmnimeter::VERSION::STRING
  spec.authors       = ["Jordan Duggan"]
  spec.email         = ["Jordan.Duggan@gmail.com"]
  spec.description   = %q{Ruby interface to the EKM Omnimeter Pulse}
  spec.summary       = %q{This ruby gem provides an interface to EKM Omnimeter Pulse meters that are connected to a EKM iSerial TCP/IP Ethernet to RS-485 Serial Converter. Omnimeter Pulse meters contain a revenue-grade universal kWh power meter, three pulse counting inputs for water and/or gas metering, and 2 controllable 50 mA at 12 volts relay outputs.}
  spec.homepage      = "https://github.com/jwtd/ekm-omnimeter"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake", "~> 10.2"
  spec.add_development_dependency "rspec", "~> 2.14"

  # Runtime dependencies
  spec.add_runtime_dependency "log4r", "~> 1.1"
  spec.add_runtime_dependency "xively-rb-connector", "~> 0.1"


end
