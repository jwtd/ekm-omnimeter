require 'socket'
require 'ostruct'

# Convert byte array to string
# %w(01 52 31 02 30 30 31 31 28 29 03 13 16).map{|a| a.to_i(16).chr}.join

module EkmOmnimeter
  # EKM Omnimeter Pulse v.4 - Pulse Counting, Relay Controlling, Universal Smart Electric Meter
  # EKM Developer Portal http://www.ekmmetering.com/developer-portal
  # PHP Client http://forum.ekmmetering.com/viewtopic.php?f=4&t=3206
  class Meter

    VALID_POWER_CONFIGURATIONS = [:single_phase_2wire, :single_phase_3wire, :three_phase_3wire, :three_phase_4wire]

    # Initialization attributes
    attr_reader :meter_number, :remote_address, :remote_port, :power_configuration

    # Request A
    #attr_reader :meter_type, :meter_firmware, :address, :total_active_kwh, :total_kvarh, :total_rev_kwh, :three_phase_kwh, :three_phase_rev_kwh, :resettable_kwh, :resettable_reverse_kwh, :volts_l1, :volts_l2, :volts_l3, :amps_l1, :amps_l2, :amps_l3, :watts_l1, :watts_l2, :watts_l3, :watts_total, :cosϴ_l1, :cosϴ_l2, :cosϴ_l3, :var_l1, :var_l2, :var_l3, :var_total, :freq, :pulse_count_1, :pulse_count_2, :pulse_count_3, :pulse_input_hilo, :direction_of_current, :outputs_onoff, :kwh_data_decimal_places,

    # Request B
    #attr_reader :t1_t2_t3_t4_kwh, :t1_t2_t3_t4_rev_kwh, :maximum_demand, :maximum_demand_time, :pulse_ratio_1, :pulse_ratio_2, :pulse_ratio_3, :ct_ratio, :auto_reset_md, :settable_imp_per_kWh_constant

    # Mix in the ability to log
    include Logging

    def initialize(options)

      @logger = logger || options[:logger]

      # Test logging call
      @logger.info "Initializing Meter"

      # Prepend the meter number with the correct amount of leading zeros
      @meter_number   = options[:meter_number].to_s.rjust(12, '0')
      @remote_address = options[:remote_address] || '192.168.0.125'
      @remote_port    = options[:remote_port] || 50000
      @logger.debug  "meter_number: #{meter_number}"
      @logger.debug  "remote_address: #{remote_address}"
      @logger.debug  "remote_port: #{remote_port}"

      # Collect the power configurations
      if VALID_POWER_CONFIGURATIONS.index(options[:power_configuration])
        power_configuration = options[:power_configuration]
      else
        raise EkmOmnimeterError, "Invalid power configuration #{options[:power_configuration]}. Valid values are #{VALID_POWER_CONFIGURATIONS.join(', ')}"
      end

      # Collect pulse inputs
      #:ekm_gas_meter
      #:ekm_water_meter
      #@pulse_input_1_device = options[:pulse_input_1_device] || nil
      #@pulse_input_2_device = options[:pulse_input_3_device] || nil
      #@pulse_input_3_device = options[:pulse_input_2_device] || nil

      @values = {}
      @last_update = nil

      # Get values
      request_a()

    end

    # Alias request_a with read
    def read
      request_a()
    end

    # Formatted datetime reported by meter during last read
    def measurement_timestamp
      "20#{current_time[0,2]}-#{current_time[2,2]}-#{current_time[4,2]} #{current_time[6,2]}:#{current_time[ 8,2]}:#{current_time[10,2]}"
    end

    # Attribute handler that delegates attribute reads to the values hash
    def method_missing(method_sym, *arguments, &block)

      @logger.debug "method_missing #{method_sym.inspect}"

      # Only refresh data if its more than 0.25 seconds old
      et = @last_update.nil? ? 0 : (Time.now - @last_update)
      @logger.debug "Elapsed time since last read #{et}"
      if et > 250
        @logger.info "More than 250 milliseconds have passed, updating data"
        read()
      end

      if @values.include? method_sym
        @logger.debug "Found #{method_sym}"
        @values[method_sym]
      else
        @logger.debug "Didn't find #{method_sym}"
        super
      end
    end

    # Attribute responder that delegates check of attribute existence to the values hash
    def respond_to?(method_sym, include_private = false)
      if @values.include? method_sym
        true
      else
        super
      end
    end


    ## Request A
    #d[:meter_type]              # 2 Byte Meter Type
    #d[:meter_firmware]          # 1 Byte Meter Firmware
    #d[:address]                 # 12 Bytes Address
    #d[:total_active_kwh]        # 8 Bytes total Active kWh
    #d[:total_kvarh]             # 8 Bytes Total kVARh
    #d[:total_rev_kwh]           # 8 Bytes Total Rev.kWh
    #d[:three_phase_kwh]         # 24 Bytes 3 phase kWh
    #d[:three_phase_rev_kwh]     # 24 Bytes 3 phase Rev.kWh
    #d[:resettable_kwh]          # 8 Bytes Resettable kWh
    #d[:resettable_reverse_kwh]  # 8 bytes Resettable Reverse kWh
    #d[:volts_l1]                # 4 Bytes Volts L1
    #d[:volts_l2]                # 4 Bytes Volts L2
    #d[:volts_l3]                # 4 Bytes Volts L3
    #d[:amps_l1]                 # 5 Bytes Amps L1
    #d[:amps_l2]                 # 5 Bytes Amps L2
    #d[:amps_l3]                 # 5 Bytes Amps L3
    #d[:watts_l1]                # 7 Bytes Watts L1
    #d[:watts_l2]                # 7 Bytes Watts L2
    #d[:watts_l3]                # 7 Bytes Watts L3
    #d[:watts_total]             # 7 Bytes Watts Total
    #d[:cosϴ_l1]                 # 4 Bytes Cosϴ L1
    #d[:cosϴ_l2]                 # 4 Bytes Cosϴ L2
    #d[:cosϴ_l3]                 # 4 Bytes Cosϴ L3
    #d[:var_l1]                  # 7 Bytes VAR L1
    #d[:var_l2]                  # 7 Bytes VAR L2
    #d[:var_l3]                  # 7 Bytes VAR L3
    #d[:var_total]               # 7 Bytes VAR Total
    #d[:freq]                    # 4 Bytes Freq
    #d[:pulse_count_1]           # 8 Bytes Pulse Count 1
    #d[:pulse_count_2]           # 8 Bytes Pulse Count 2
    #d[:pulse_count_3]           # 8 Bytes Pulse Count 3
    #d[:pulse_input_hilo]        # 1 Byte Pulse Input Hi/Lo
    #d[:direction_of_current]    # 1 Bytes direction of current
    #d[:outputs_onoff]           # 1 Byte Outputs On/Off
    #d[:kwh_data_decimal_places] # 1 Byte kWh Data Decimal Places

    ## Request B
    #d[:t1_t2_t3_t4_kwh]               # 32 Bytes T1, T2, T3, T4 kwh
    #d[:t1_t2_t3_t4_rev_kwh]           # 32 Bytes T1, T2, T3, T4 Rev kWh
    #d[:maximum_demand]                # 8 Bytes Maximum Demand
    #d[:maximum_demand_time]           # 1 Byte Maximum Demand Time
    #d[:pulse_ratio_1]                 # 4 Bytes Pulse Ratio 1
    #d[:pulse_ratio_2]                 # 4 Bytes Pulse Ratio 2
    #d[:pulse_ratio_3]                 # 4 Bytes Pulse Ratio 3
    #d[:ct_ratio]                      # 4 Bytes CT Ratio
    #d[:auto_reset_md]                 # 1 Bytes Auto Reset MD
    #d[:settable_imp_per_kWh_constant] # 4 Bytes Settable Imp/kWh Constant


    # iSerial v4 Spec From http://documents.ekmmetering.com/Omnimeter-Pulse-v.4-Protocol.pdf
    # %w(01 52 31 02 30 30 31 31 28 29 03 13 16).map{|a| a.to_i(16).chr}.join

    # Returns the correct measurement for voltage, current, and power based on the corresponding power_configuration
    def calculate_measurement(m1, m2, m3)
      if power_configuration == :single_phase_2wire
        volts_l1
      elsif power_configuration == :single_phase_3wire
        (volts_l1 + volts_l2)
      elsif power_configuration == :three_phase_3wire
        (volts_l1 + :volts_l3)
      elsif power_configuration == :three_phase_4wire
        (volts_l1 + volts_l2 + volts_l3)
      end
    end

    #Request A:
    def request_a

      # 2F 3F 12 Bytes Address 30 30 21 0D 0A
      # /?00000000012300! then a CRLF
      request = "/?" + meter_number + "00!\r\n"
      read_bytes = 255
      logger.debug "Socket write #{request}" unless logger.nil?
      response = get_remote_meter_data(request, read_bytes)
      raise EkmError if response.nil?

      # Split the response string into an array and prepare a hash to store the values
      a = response.split('')
      d = {}

      # Return (255 Bytes total) :
      a.shift(1)                               # 02
      d[:meter_type] = a.shift(2)              # 2 Byte Meter Type
      d[:meter_firmware] = a.shift(1)          # 1 Byte Meter Firmware
      d[:address] = a.shift(12)                # 12 Bytes Address
      d[:total_active_kwh] = a.shift(8)        # 8 Bytes total Active kWh
      d[:total_kvarh] = a.shift(8)             # 8 Bytes Total kVARh
      d[:total_rev_kwh] = a.shift(8)           # 8 Bytes Total Rev.kWh
      d[:three_phase_kwh] = a.shift(24)        # 24 Bytes 3 phase kWh
      d[:three_phase_rev_kwh] = a.shift(24)    # 24 Bytes 3 phase Rev.kWh
      d[:resettable_kwh] = a.shift(8)          # 8 Bytes Resettable kWh
      d[:resettable_reverse_kwh] = a.shift(8)  # 8 bytes Resettable Reverse kWh
      d[:volts_l1] = a.shift(4)                # 4 Bytes Volts L1
      d[:volts_l2] = a.shift(4)                # 4 Bytes Volts L2
      d[:volts_l3] = a.shift(4)                # 4 Bytes Volts L3
      d[:amps_l1] = a.shift(5)                 # 5 Bytes Amps L1
      d[:amps_l2] = a.shift(5)                 # 5 Bytes Amps L2
      d[:amps_l3] = a.shift(5)                 # 5 Bytes Amps L3
      d[:watts_l1] = a.shift(7)                # 7 Bytes Watts L1
      d[:watts_l2] = a.shift(7)                # 7 Bytes Watts L2
      d[:watts_l3] = a.shift(7)                # 7 Bytes Watts L3
      d[:watts_total] = a.shift(7)             # 7 Bytes Watts Total
      d[:cosϴ_l1] = a.shift(4)                 # 4 Bytes Cosϴ L1
      d[:cosϴ_l2] = a.shift(4)                 # 4 Bytes Cosϴ L2
      d[:cosϴ_l3] = a.shift(4)                 # 4 Bytes Cosϴ L3
      d[:var_l1] = a.shift(7)                  # 7 Bytes VAR L1
      d[:var_l2] = a.shift(7)                  # 7 Bytes VAR L2
      d[:var_l3] = a.shift(7)                  # 7 Bytes VAR L3
      d[:var_total] = a.shift(7)               # 7 Bytes VAR Total
      d[:freq] = a.shift(4)                    # 4 Bytes Freq
      d[:pulse_count_1] = a.shift(8)           # 8 Bytes Pulse Count 1
      d[:pulse_count_2] = a.shift(8)           # 8 Bytes Pulse Count 2
      d[:pulse_count_3] = a.shift(8)           # 8 Bytes Pulse Count 3
      d[:pulse_input_hilo] = a.shift(1)        # 1 Byte Pulse Input Hi/Lo
      d[:direction_of_current] = a.shift(1)    # 1 Bytes direction of current
      d[:outputs_onoff] = a.shift(1)           # 1 Byte Outputs On/Off
      d[:kwh_data_decimal_places] = a.shift(1) # 1 Byte kWh Data Decimal Places
      a.shift(2)                               # 2 Bytes Reserved
      d[:current_time] = a.shift(14)           # 14 Bytes Current Time
      a.shift(6)                               # 30 30 21 0D 0A 03
      #d[] = a.shift(2)                         # 2 Bytes CRC16

      # Smash arrays into strungs
      d.each {|k,v| d[k] = v.join('')}

      # Merge to values and reset time
      @values.merge!(d)
      @last_update = Time.now

      # Calculate totals based on wiring configuration
      @values[:measurement_timestamp] = measurement_timestamp
      @values[:volts] = calculate_measurement(d[:volts_l1], d[:volts_l2], d[:volts_l3])
      @values[:amps]  = calculate_measurement(d[:amps_l1], d[:amps_l2], d[:amps_l3])
      @values[:watts] = calculate_measurement(d[:watts_l1], d[:watts_l2], d[:watts_l3])

      # Return the hash as an open struct
      return d

    end


    # Request B:
    def request_b

      # 2F 3F 12 Bytes Address 30 31 21 0D 0A
      # /?00000000012301! then a CRLF
      request = "/?" + meter_number + "01!\r\n"
      read_bytes = 255
      logger.debug "Socket write #{request}" unless logger.nil?
      response = get_remote_meter_data(request, read_bytes)
      raise EkmError if response.nil?

      # Split the response string into an array and prepare a hash to store the values
      a = s.split('')
      d = {}

      # Return (255 Bytes total) :
      a.shift(1)                               # 02
      d[:meter_type] = a.shift(2)              # 2 Byte Meter Type
      d[:meter_firmware] = a.shift(1)          # 1 Byte Meter Firmware
      d[:address] = a.shift(12)                # 12 Bytes Address
      # Diff from request A start
      d[:t1_t2_t3_t4_kwh] = a.shift(32)              # 32 Bytes T1, T2, T3, T4 kwh
      d[:t1_t2_t3_t4_rev_kwh] = a.shift(32)          # 32 Bytes T1, T2, T3, T4 Rev kWh
      # Diff from request A end
      d[:volts_l1] = a.shift(4)                # 4 Bytes Volts L1
      d[:volts_l2] = a.shift(4)                # 4 Bytes Volts L2
      d[:volts_l3] = a.shift(4)                # 4 Bytes Volts L3
      d[:amps_l1] = a.shift(5)                 # 5 Bytes Amps L1
      d[:amps_l2] = a.shift(5)                 # 5 Bytes Amps L2
      d[:amps_l3] = a.shift(5)                 # 5 Bytes Amps L3
      d[:watts_l1] = a.shift(7)                # 7 Bytes Watts L1
      d[:watts_l2] = a.shift(7)                # 7 Bytes Watts L2
      d[:watts_l3] = a.shift(7)                # 7 Bytes Watts L3
      d[:watts_total] = a.shift(7)             # 7 Bytes Watts Total
      d[:cosϴ_l1] = a.shift(4)                 # 4 Bytes Cosϴ L1
      d[:cosϴ_l2] = a.shift(4)                 # 4 Bytes Cosϴ L2
      d[:cosϴ_l3] = a.shift(4)                 # 4 Bytes Cosϴ L3
      # Diff from request A start
      d[:maximum_demand] = a.shift(8)                # 8 Bytes Maximum Demand
      d[:maximum_demand_time] = a.shift(1)           # 1 Byte Maximum Demand Time
      d[:pulse_ratio_1] = a.shift(4)                 # 4 Bytes Pulse Ratio 1
      d[:pulse_ratio_2] = a.shift(4)                 # 4 Bytes Pulse Ratio 2
      d[:pulse_ratio_3] = a.shift(4)                 # 4 Bytes Pulse Ratio 3
      d[:ct_ratio] = a.shift(4)                      # 4 Bytes CT Ratio
      d[:auto_reset_md] = a.shift(1)                 # 1 Bytes Auto Reset MD
      d[:settable_imp_per_kWh_constant] = a.shift(4) # 4 Bytes Settable Imp/kWh Constant
      # Diff from request A end
      a.shift(56)                               # 56 Bytes Reserved
      d[:current_time] = a.shift(14)           # 14 Bytes Current Time
      a.shift(6)                               # 30 30 21 0D 0A 03
      d[] = a.shift(2)                         # 2 Bytes CRC16

      # Smash arrays into strungs
      d.each {|k,v| d[k] = v.join('')}

      # Merge to values and reset time
      @values.merge!(d)
      @last_update = Time.now

      # Calculate totals based on wiring configuration
      @values[:measurement_timestamp] = measurement_timestamp
      @values[:volts] = calculate_measurement(d[:volts_l1], d[:volts_l2], d[:volts_l3])
      @values[:amps]  = calculate_measurement(d[:amps_l1], d[:amps_l2], d[:amps_l3])
      @values[:watts] = calculate_measurement(d[:watts_l1], d[:watts_l2], d[:watts_l3])

      # Return the hash as an open struct
      return d

    end



    # Gets remote EKM meter data using iSerial defaults
    #   meter_number is the meters serial number. leading 0s not required.
    #   remote_address is the IP address of the ethernet-RS485 converter
    #   remote_port is the TCP port number the converter is listening to (50000 in my case)
    # We do not check the checksum - I'm lazy.  Probably should. Running for 8 months, querying
    # once per minute..I've encountered one or two bad results from the meter.
    def get_remote_meter_data(request, read_bytes)

      logger.debug "get_remote_meter_data #{request} from meter# #{meter_number}" unless logger.nil?

      # connect to the meter and check to make sure we connected
      begin

        socket = TCPSocket.new(remote_address, remote_port)
        logger.debug "Socket open" unless logger.nil?

        # Send request to the meter
        logger.debug "Request: #{request}" unless logger.nil?
        socket.write(request)

        # Receive a response of 255 bytes
        response = socket.read(read_bytes)
        logger.debug "Socket response #{response.length}" unless logger.nil?
        logger.debug response unless logger.nil?

      rescue Exception => ex
        logger.error "Exception\n#{ex.message}\n#{ex.backtrace.join("\n")}" unless logger.nil?
      ensure
        # EKM Meter software sends this just before closing the connection, so we will too
        socket.write "\x0a\x03\x32\x3d"
        socket.close
        logger.debug "Socket closed" unless logger.nil?
      end

      return response

    end

  end
end
