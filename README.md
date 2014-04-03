ekm-omnimeter
=============

This ruby gem provides an interface to [EKM Omnimeter Pulse meters](http://www.ekmmetering.com/ekm-metering-products/electric-meters-kwh-meters/smart-meters-read-meter-remotely-automatically/omnimeter-pulse.html)
that are connected to a [EKM iSerial TCP/IP Ethernet to RS-485 Serial Converter](http://www.ekmmetering.com/ekm-metering-products/remote-meter-reading-solutions/ekm-iserial-v-2-tcp-ip-to-serial-converter-ethernet-connection.html).

[EKM Metering](http://www.ekmmetering.com) offers a range of digital utility metering and control devices, including the
Omnimeter Pulse Meter line of smart meters. The
[Omnimeter Pulse Meter](http://www.ekmmetering.com/ekm-metering-products/electric-meters-kwh-meters/smart-meters-read-meter-remotely-automatically/omnimeter-pulse.html)
contains a revenue-grade universal kWh power meter, three pulse counting inputs for
[water](http://www.ekmmetering.com/ekm-metering-products/water-meters.html) and/or
[gas](http://www.ekmmetering.com/ekm-metering-products/gas-meters/pulse-output-gas-meter-pgm-1-read-gas-consumption-remotely.html) metering,
and 2 controllable 50 mA at 12 volts relay outputs that can toggle 120v circuits when connected to their [EKM Switch120 power cord](http://www.ekmmetering.com/ekm-metering-products/accessories/switch120.html).

TODO:
* Cast values to their proper type and precision
* Add specs
* Add daemon to monitor meter's output at regular intervals

## Requirements

* Ruby 2.0.0 or higher
* A [EKM Omnimeter Pulse meters](http://www.ekmmetering.com/ekm-metering-products/electric-meters-kwh-meters/smart-meters-read-meter-remotely-automatically/omnimeter-pulse.html)
* A [EKM iSerial TCP/IP Ethernet to RS-485 Serial Converter](http://www.ekmmetering.com/ekm-metering-products/remote-meter-reading-solutions/ekm-iserial-v-2-tcp-ip-to-serial-converter-ethernet-connection.html)


## Contact, feedback and bugs

This interface was not developed or reviewed by EKM Metering. They bare no responsibility for its quality, performance, or results. Use at your own risk.

Please file bugs / issues and feature requests on the [issue tracker](https://github.com/jwtd/ekm-omnimeter/issues)

## Install

```
gem install ekm-omnimeter
```

## Examples

```ruby

require 'ekm-omnimeter'

# Connect to the meter
m = EkmOmnimeter::Meter.new(
  :power_configuration => :single_phase_3wire,  # Valid values are  :single_phase_2wire, :single_phase_3wire, :three_phase_3wire, :three_phase_4wire
  :meter_number=>300000001,                     # Your nine digit meter id
  :remote_address=>'192.168.1.125',             # The IP address of your iSerial device
  :remote_port => 50000)                        # The port on which your iSerial device is listening

# Read some values
m.remote_address            # 192.168.1.125
m.remote_port               # 50000
m.meter_number              # 000300000001

m.meter_timestamp			# 2014-04-04 06:02:48
m.computer_timestamp		# 2014-04-03 14:54:10 -0400
m.address					# 000300000001
m.total_kwh					# 4583.51
m.total_forward_kwh			# 4507.610000000001
m.total_reverse_kwh			# 75.9
m.net_kwh					# 4431.710000000001
m.total_kwh_t1				# 2826.64
m.total_kwh_t2				# 1756.87
m.total_kwh_t3				# 0.0
m.total_kwh_t4				# 0.0
m.reverse_kwh_t1			# 47.93
m.reverse_kwh_t2			# 27.97
m.reverse_kwh_t3			# 0.0
m.reverse_kwh_t4			# 0.0
m.volts_l1					# 123.9
m.volts_l2					# 124.8
m.volts_l3					# 0.0
m.m.amps_l1					# 18.4
m.amps_l2					# 3.2
m.amps_l3					# 0.0
m.watts_l1					# 2276
m.watts_l2					# 384
m.watts_l3					# 0
m.watts_total				# 2664
m.power_factor_1			# 1.0
m.power_factor_2			# 0.0
m.power_factor_3			# 0.0
m.maximum_demand			# 226400
m.maximum_demand_period		# 1
m.ct_ratio					# 400
m.pulse_1_count				# 3
m.pulse_1_ratio				# 1000
m.pulse_2_count				# 6
m.pulse_2_ratio				# 3
m.pulse_3_count				# 0
m.pulse_3_ratio				# 1000
m.reactive_kwh_kvarh		# 812.63
m.total_kwh_l1				# 2165.46
m.total_kwh_l2				# 2417.42
m.total_kwh_l3				# 0.0
m.reverse_kwh_l1			# 0.0
m.reverse_kwh_l2			# 75.9
m.reverse_kwh_l3			# 0.0
m.resettable_total_kwh		# 4583.51
m.resettable_reverse_kwh	# 75.9
m.reactive_power_1			# 24
m.reactive_power_2			# 60
m.reactive_power_3			# 0
m.total_reactive_power		# 84
m.frequency					# 60.04
m.pulse_input_hilo			# 0
m.direction_of_current		# 1
m.outputs_onoff				# 1
m.kwh_data_decimal_places	# 2
m.auto_reset_max_demand		# 0
m.settable_pulse_per_kwh_ratio	# 800


```

## Special Thanks

* EKM Metering - for an awesome piece of hardware
* Ian Duggan - for introducing me to ruby

