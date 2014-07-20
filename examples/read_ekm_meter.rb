# :stopdoc:
#
# This is the code I use to generatebundle  the property list in the readme.

$:.push File.expand_path("../../lib", __FILE__)
require 'ekm-omnimeter'

# Block style configuration
EkmOmnimeter.configure do |c|

  # Logging Configuration
  c.log_level            = :debug    # :off, :all, :debug, :info, :warn, :error, :fatal
  c.trace_exceptions     = true       # Default is true
  c.log_to_stdout        = false      # Default is true
  c.stdout_colors        = :for_dark_background
  c.log_file             = 'ekm.log'  # Default is nil
  c.log_file_layout      = '[%d] %-5l -- %c -- %m\n'     # :basic, :json, :yaml, or a pattern such as '[%d] %-5l: %m\n'
  c.rolling_log_file_age = :daily     # Default is false
  c.rolling_log_limit    = 11         # Default is false, but any positive integer can be passed
  c.growl_on_error       = false      # Default is false

end


# Connect to a meter
m = EkmOmnimeter::Meter.new(
    :power_configuration => :single_phase_3wire,
    :meter_number=>300000234,
    :remote_address=>'192.168.0.125',
    :remote_port => 50000)

# Read some parameters
puts "m.meter_number\t\t\t# #{m.meter_number}"
puts "m.remote_address\t\t# #{m.remote_address}"
puts "m.remote_port\t\t\t# #{m.remote_port}"
puts "m.volts\t\t\t\t# #{m.volts}"
puts "m.amps\t\t\t\t# #{m.amps}"
puts "m.watts\t\t\t\t# #{m.watts}"
puts "m.meter_timestamp\t\t# #{m.meter_timestamp}"
puts "m.last_read_timestamp\t\t# #{m.last_read_timestamp}"
puts "m.meter_type\t\t\t# #{m.meter_type}"
puts "m.meter_firmware\t\t# #{m.meter_firmware}"
puts "m.address\t\t\t# #{m.address}"
puts "m.total_kwh\t\t\t# #{m.total_kwh}"
puts "m.total_forward_kwh\t\t# #{m.total_forward_kwh}"
puts "m.total_reverse_kwh\t\t# #{m.total_reverse_kwh}"
puts "m.net_kwh\t\t\t# #{m.net_kwh}"
puts "m.total_kwh_t1\t\t\t# #{m.total_kwh_t1}"
puts "m.total_kwh_t2\t\t\t# #{m.total_kwh_t2}"
puts "m.total_kwh_t3\t\t\t# #{m.total_kwh_t3}"
puts "m.total_kwh_t4\t\t\t# #{m.total_kwh_t4}"
puts "m.reverse_kwh_t1\t\t# #{m.reverse_kwh_t1}"
puts "m.reverse_kwh_t2\t\t# #{m.reverse_kwh_t2}"
puts "m.reverse_kwh_t3\t\t# #{m.reverse_kwh_t3}"
puts "m.reverse_kwh_t4\t\t# #{m.reverse_kwh_t4}"
puts "m.volts_l1\t\t\t# #{m.volts_l1}"
puts "m.volts_l2\t\t\t# #{m.volts_l2}"
puts "m.volts_l3\t\t\t# #{m.volts_l3}"
puts "m.amps_l1\t\t\t# #{m.amps_l1}"
puts "m.amps_l2\t\t\t# #{m.amps_l2}"
puts "m.amps_l3\t\t\t# #{m.amps_l3}"
puts "m.watts_l1\t\t\t# #{m.watts_l1}"
puts "m.watts_l2\t\t\t# #{m.watts_l2}"
puts "m.watts_l3\t\t\t# #{m.watts_l3}"
puts "m.watts_total\t\t\t# #{m.watts_total}"
puts "m.power_factor_1\t\t# #{m.power_factor_1}"
puts "m.power_factor_2\t\t# #{m.power_factor_2}"
puts "m.power_factor_3\t\t# #{m.power_factor_3}"
puts "m.maximum_demand\t\t# #{m.maximum_demand}"
puts "m.maximum_demand_period\t\t# #{m.maximum_demand_period}"
puts "m.ct_ratio\t\t\t# #{m.ct_ratio}"
puts "m.pulse_1_count\t\t\t# #{m.pulse_1_count}"
puts "m.pulse_1_ratio\t\t\t# #{m.pulse_1_ratio}"
puts "m.pulse_2_count\t\t\t# #{m.pulse_2_count}"
puts "m.pulse_2_ratio\t\t\t# #{m.pulse_2_ratio}"
puts "m.pulse_3_count\t\t\t# #{m.pulse_3_count}"
puts "m.pulse_3_ratio\t\t\t# #{m.pulse_3_ratio}"
puts "m.reactive_kwh_kvarh\t\t# #{m.reactive_kwh_kvarh}"
puts "m.total_kwh_l1\t\t\t# #{m.total_kwh_l1}"
puts "m.total_kwh_l2\t\t\t# #{m.total_kwh_l2}"
puts "m.total_kwh_l3\t\t\t# #{m.total_kwh_l3}"
puts "m.reverse_kwh_l1\t\t# #{m.reverse_kwh_l1}"
puts "m.reverse_kwh_l2\t\t# #{m.reverse_kwh_l2}"
puts "m.reverse_kwh_l3\t\t# #{m.reverse_kwh_l3}"
puts "m.resettable_total_kwh\t\t# #{m.resettable_total_kwh}"
puts "m.resettable_reverse_kwh\t# #{m.resettable_reverse_kwh}"
puts "m.reactive_power_1\t\t# #{m.reactive_power_1}"
puts "m.reactive_power_2\t\t# #{m.reactive_power_2}"
puts "m.reactive_power_3\t\t# #{m.reactive_power_3}"
puts "m.total_reactive_power\t\t# #{m.total_reactive_power}"
puts "m.frequency\t\t\t# #{m.frequency}"
#  puts "m.pulse_input_hilo\t# #{m.pulse_input_hilo}" # Pulse input state 1 ????
puts "m.pulse_1_input\t\t\t# #{m.pulse_1_input}"  # Open / Closed
puts "m.pulse_2_input\t\t\t# #{m.pulse_2_input}"  # Open / Closed
puts "m.pulse_3_input\t\t\t# #{m.pulse_3_input}"  # Open / Closed
#  puts "m.direction_of_current\t# #{m.direction_of_current}"   # 1 = Forward
puts "m.current_direction_l1\t\t# #{m.current_direction_l1}"
puts "m.current_direction_l2\t\t# #{m.current_direction_l2}"
puts "m.current_direction_l3\t\t# #{m.current_direction_l3}"
#  puts "m.outputs_onoff\t# #{m.outputs_onoff}"
puts "m.output_1\t\t\t# #{m.output_1}"
puts "m.output_2\t\t\t# #{m.output_2}"
puts "m.kwh_data_decimal_places\t# #{m.kwh_data_decimal_places}"
puts "m.auto_reset_max_demand\t\t# #{m.auto_reset_max_demand}"
puts "m.settable_pulse_per_kwh_ratio\t# #{m.settable_pulse_per_kwh_ratio}"
  puts "m.checksum\t\t\t# #{m.checksum}"
#puts "m.checksum_calculated\t# #{m.checksum_calculated}"



# :startdoc: