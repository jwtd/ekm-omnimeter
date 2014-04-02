require 'rubygems'
require 'bundler/setup'
Bundler.setup

require 'rspec'
require 'time'

# figure out where we are being loaded from
if $LOADED_FEATURES.grep(/spec\/spec_helper\.rb/).any?
  begin
    raise "foo"
  rescue => e
    puts <<-MSG
  ===================================================
  It looks like spec_helper.rb has been loaded
  multiple times. Normalize the require to:

    require "spec/spec_helper"

  Things like File.join and File.expand_path will
  cause it to be loaded multiple times.

  Loaded this time from:

    #{e.backtrace.join("\n    ")}
  ===================================================
    MSG
  end
end

$:.push File.expand_path("../lib", __FILE__)
require 'ekm-omnimeter'

RSpec.configure do |config|
  config.color_enabled = true
  config.formatter     = 'documentation'
end





