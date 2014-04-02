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
m.address                   # 000300000001
m.measurement_timestamp     # 2014-04-03 05:03:01
m.total_active_kwh          # 00450609
m.total_kvarh               # 00080417
m.total_rev_kwh             # 00007590
m.three_phase_kwh           # 002115660023898000000000
m.three_phase_rev_kwh       # 000000000000759000000000
m.resettable_kwh            # 00450609
m.resettable_reverse_kwh    # 00007590
m.volts_l1                  # 1245
m.volts_l2                  # 1254
m.volts_l3                  # 0000
m.amps_l1                   # 00200
m.amps_l2                   # 00056
m.amps_l3                   # 00000
m.watts_l1                  # 0002504
m.watts_l2                  # 0000664
m.watts_l3                  # 0000000
m.watts_total               # 0003172
m.cosϴ_l1                   # 100
m.cosϴ_l2                   # 100
m.cosϴ_l3                   # C000
m.var_l1                    # 0000052
m.var_l2                    # 0000000
m.var_l3                    # 0000000
m.var_total                 # 0000052
m.freq                      # 6006
m.pulse_count_1             # 00000003
m.pulse_count_2             # 00000006
m.pulse_count_3             # 00000000
m.pulse_input_hilo          # 4
m.direction_of_current      # 1
m.outputs_onoff             # 1
m.kwh_data_decimal_places   # 2


```

## Special Thanks

* EKM Metering - for an awesome piece of hardware
* Ian Duggan - for introducing me to ruby

