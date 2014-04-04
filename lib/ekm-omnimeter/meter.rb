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
    attr_reader :meter_number, :remote_address, :remote_port, :verify_checksums, :power_configuration, :last_read_timestamp

    # Request A
    #attr_reader :meter_type, :meter_firmware, :address, :total_active_kwh, :total_kvarh, :total_rev_kwh, :three_phase_kwh, :three_phase_rev_kwh, :resettable_kwh, :resettable_reverse_kwh, :volts_l1, :volts_l2, :volts_l3, :amps_l1, :amps_l2, :amps_l3, :watts_l1, :watts_l2, :watts_l3, :watts_total, :cosϴ_l1, :cosϴ_l2, :cosϴ_l3, :var_l1, :var_l2, :var_l3, :var_total, :freq, :pulse_count_1, :pulse_count_2, :pulse_count_3, :pulse_input_hilo, :direction_of_current, :outputs_onoff, :kwh_data_decimal_places,

    # Request B
    #attr_reader :t1_t2_t3_t4_kwh, :t1_t2_t3_t4_rev_kwh, :maximum_demand, :maximum_demand_time, :pulse_ratio_1, :pulse_ratio_2, :pulse_ratio_3, :ct_ratio, :auto_reset_md, :settable_imp_per_kWh_constant

    # iSerial v4 Spec From http://documents.ekmmetering.com/Omnimeter-Pulse-v.4-Protocol.pdf
    # %w(01 52 31 02 30 30 31 31 28 29 03 13 16).map{|a| a.to_i(16).chr}.join

    # Mix in the ability to log
    include Logging

    def initialize(options)

      @logger = logger || options[:logger]

      # Test logging call
      @logger.info "Initializing Meter"

      # Prepend the meter number with the correct amount of leading zeros
      @meter_number     = options[:meter_number].to_s.rjust(12, '0')
      @remote_address   = options[:remote_address] || '192.168.0.125'
      @remote_port      = options[:remote_port] || 50000
      @verify_checksums = options[:verify_checksums] || false
      @logger.debug  "meter_number: #{meter_number}"
      @logger.debug  "remote_address: #{remote_address}"
      @logger.debug  "remote_port: #{remote_port}"
      @logger.debug  "verify_checksums: #{verify_checksums}"

      # Collect the power configurations
      if VALID_POWER_CONFIGURATIONS.index(options[:power_configuration])
        @power_configuration = options[:power_configuration]
        @logger.debug  "power_configuration: #{@power_configuration}"
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
      @last_read_timestamp = nil

      # Get values
      read()

    end

    # A complete read spans two protocol requests
    def read
      request_a()
      request_b()
      @values
    end


    # Attribute handler that delegates attribute reads to the values hash
    def method_missing(method_sym, *arguments, &block)
      # Only refresh data if its more than 0.25 seconds old
      et = @last_read_timestamp.nil? ? 0 : (Time.now - @last_read_timestamp)
      @logger.debug "Elapsed time since last read #{et}"
      if et > 250
        @logger.info "More than 250 milliseconds have passed since last read. Triggering refresh."
        read()
      end

      if @values.include? method_sym
        @values[method_sym]
      else
        @logger.debug "method_missing failed to find #{method_sym} in the Meter.values cache"
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


    # Returns the correct measurement for voltage, current, and power based on the corresponding power_configuration
    def calculate_measurement(m1, m2, m3)
      if power_configuration == :single_phase_2wire
        m1
      elsif power_configuration == :single_phase_3wire
        (m1 + m2)
      elsif power_configuration == :three_phase_3wire
        (m1 + m3)
      elsif power_configuration == :three_phase_4wire
        (m1 + m2 + m3)
      end
    end

    def to_kwh_float(s)
      to_f_with_decimal_places(s, @values[:kwh_data_decimal_places])
    end

    def to_f_with_decimal_places(s, p=1)
      unless s.nil?
        v = (s.to_f / (10 ** p))
        logger.debug "Casting #{s.inspect}  ->  #{v.inspect}"
        v
      else
        logger.error "Could not cast #{s} to #{p} decimal places"
      end
    end

    # Power factor values come back as C099 which need to be cast to C0.99
    def cast_power_factor(s)
      "#{s[0]}#{s[1,3].to_f / 100.0}"
    end

    # Formatted datetime reported by meter during last read.
    # Raw string is formatted as YYMMDDWWHHMMSS where YY is year without century, and WW is week day with Sunday as the first day of the week
    #"20#{current_time[0,2]}-#{current_time[2,2]}-#{current_time[4,2]} #{current_time[8,2]}:#{current_time[ 10,2]}:#{current_time[12,2]}"
    def as_datetime(s)
      DateTime.new("20#{s[0,2]}".to_i, s[2,2].to_i, s[4,2].to_i, s[8,2].to_i, s[10,2].to_i, s[12,2].to_i, '-4')
    end

    # All values are returned without decimals. This method loops over all
    # the values and sets them to the correct precision
    def cast_response_to_correct_types(d)

      # Integers
      [:kwh_data_decimal_places,
       :watts_l1,
       :watts_l2,
       :watts_l3,
       :watts_total,
       :ct_ratio,
       :pulse_1_count,
       :pulse_1_ratio,
       :pulse_2_count,
       :pulse_2_ratio,
       :pulse_3_count,
       :pulse_3_ratio,
       :reactive_power_1,
       :reactive_power_2,
       :reactive_power_3,
       :total_reactive_power,
       :settable_pulse_per_kwh_ratio
      ].each do |k|
        logger.debug "Casting #{k} = #{d[k].inspect}  ->  #{d[k].to_i}"
        d[k] = d[k].to_i if d.has_key?(k)
      end

      # Floats with precision 1
      [:volts_l1,
       :volts_l2,
       :volts_l3,
       :amps_l1,
       :amps_l2,
       :amps_l3,
       :maximum_demand
      ].each do |k|
        logger.debug "Casting #{k}"
        d[k] = to_f_with_decimal_places(d[k], 1) if d.has_key?(k)
      end

      # Floats with precision 2
      [:frequency
      ].each do |k|
        logger.debug "Casting #{k}"
        d[k] = to_f_with_decimal_places(d[k], 2) if d.has_key?(k)
      end

      # Floats with precision set by kwh_data_decimal_places
      [:total_kwh,
       :reactive_kwh_kvarh,
       :total_forward_kwh,
       :total_reverse_kwh,
       :net_kwh,
       :total_kwh_l1,
       :total_kwh_l2,
       :total_kwh_l3,
       :reverse_kwh_l1,
       :reverse_kwh_l2,
       :reverse_kwh_l3,
       :resettable_total_kwh,
       :resettable_reverse_kwh,
       :total_kwh_t1,
       :total_kwh_t2,
       :total_kwh_t3,
       :total_kwh_t4,
       :reverse_kwh_t1,
       :reverse_kwh_t2,
       :reverse_kwh_t3,
       :reverse_kwh_t4
      ].each do |k|
        logger.debug "Casting #{k}"
        d[k] = to_kwh_float(d[k]) if d.has_key?(k)
      end

    end


    # Request A
    # TODO: Instead of pre-parsing and casting everything, refactor this so that only the response string gets saved, and  parse out values that are accessed.
    def request_a

      # 2F 3F 12 Bytes Address 30 30 21 0D 0A
      # /?00000000012300! then a CRLF
      request = "/?" + meter_number + "00!\r\n"
      read_bytes = 255
      logger.debug "Socket write #{request}" unless logger.nil?
      response = get_remote_meter_data(request, read_bytes)

      if response.nil?
        logger.error "No response to request_a from meter #{meter_number}"
        raise EkmOmnimeter, "No response from meter."
      end

      # Split the response string into an array and prepare a hash to store the values
      a = response.split('')
      d = {}

      # Return (255 Bytes total) :
      a.shift(1)                               # 02
      d[:meter_type] = a.shift(2)              # 2 Byte Meter Type
      d[:meter_firmware] = a.shift(1)          # 1 Byte Meter Firmware
      d[:address] = a.shift(12)                # 12 Bytes Address
      d[:total_kwh] = a.shift(8)               # 8 Bytes total Active kWh
      d[:reactive_kwh_kvarh] = a.shift(8)      # 8 Bytes Total kVARh
      d[:total_reverse_kwh] = a.shift(8)       # 8 Bytes Total Rev.kWh

      # 24 Bytes 3 phase kWh
      d[:total_kwh_l1] = a.shift(8)
      d[:total_kwh_l2] = a.shift(8)
      d[:total_kwh_l3] = a.shift(8)
      # 24 Bytes 3 phase Rev.kWh
      d[:reverse_kwh_l1] = a.shift(8)
      d[:reverse_kwh_l2] = a.shift(8)
      d[:reverse_kwh_l3] = a.shift(8)

      d[:resettable_total_kwh] = a.shift(8)    # 8 Bytes Resettable kWh
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
      d[:power_factor_1] = a.shift(4)          # 4 Bytes Cosϴ L1
      d[:power_factor_2] = a.shift(4)          # 4 Bytes Cosϴ L2
      d[:power_factor_3] = a.shift(4)          # 4 Bytes Cosϴ L3
      d[:reactive_power_1] = a.shift(7)        # 7 Bytes VAR L1
      d[:reactive_power_2] = a.shift(7)        # 7 Bytes VAR L2
      d[:reactive_power_3] = a.shift(7)        # 7 Bytes VAR L3
      d[:total_reactive_power] = a.shift(7)    # 7 Bytes VAR Total
      d[:frequency] = a.shift(4)               # 4 Bytes Freq
      d[:pulse_1_count] = a.shift(8)           # 8 Bytes Pulse Count 1
      d[:pulse_2_count] = a.shift(8)           # 8 Bytes Pulse Count 2
      d[:pulse_3_count] = a.shift(8)           # 8 Bytes Pulse Count 3
      d[:pulse_input_hilo] = a.shift(1)        # 1 Byte Pulse Input Hi/Lo
      d[:direction_of_current] = a.shift(1)    # 1 Bytes direction of current
      d[:outputs_onoff] = a.shift(1)           # 1 Byte Outputs On/Off
      d[:kwh_data_decimal_places] = a.shift(1) # 1 Byte kWh Data Decimal Places
      a.shift(2)                               # 2 Bytes Reserved
      meter_timestamp = a.shift(14).join('')   # 14 Bytes Current Time
      a.shift(6)                               # 30 30 21 0D 0A 03
      d[:checksum] = a.shift(2)                # 2 Bytes CRC16

      # Smash arrays into strungs
      d.each {|k,v| d[k] = v.join('')}

      if verify_checksums
        if Crc16.check_crc16(response, d[:checksum])
          @logger.debug "Checksum matches"
        else
          @logger.error "CRC16 Checksum doesn't match. Expecting #{d[:checksum]} but was #{Crc16.crc16(response)}"
          #raise EkmOmnimeterError, "Checksum doesn't match"
        end
      end

      # Cast types
      @values[:kwh_data_decimal_places] = d[:kwh_data_decimal_places].to_i
      d[:power_factor_1] = cast_power_factor(d[:power_factor_1])
      d[:power_factor_2] = cast_power_factor(d[:power_factor_2])
      d[:power_factor_3] = cast_power_factor(d[:power_factor_3])
      d[:meter_timestamp] = as_datetime(meter_timestamp)
      cast_response_to_correct_types(d)

      # Lookup mapped values
      d[:pulse_1_input], d[:pulse_2_input], d[:pulse_3_input] = lookup_pulse_input_states(d[:pulse_input_hilo])
      d[:current_direction_l1], d[:current_direction_l2], d[:current_direction_l3] = lookup_direction_of_current(d[:direction_of_current])
      d[:output_1], d[:output_2] = lookup_output_states(d[:outputs_onoff])

      # Merge to values and reset time
      @values.merge!(d)
      @last_read_timestamp = Time.now

      # Calculate totals based on wiring configuration
      @values[:volts] = calculate_measurement(volts_l1, volts_l2, volts_l3)
      @values[:amps]  = calculate_measurement(amps_l1, amps_l2, amps_l3)
      @values[:watts] = calculate_measurement(watts_l1, watts_l2, watts_l3)
      @values[:total_forward_kwh] = total_kwh - total_reverse_kwh
      @values[:net_kwh] = total_forward_kwh - total_reverse_kwh

      # Return the hash as an open struct
      return d

    end

    # Request B
    # TODO: Instead of pre-parsing and casting everything, refactor this so that only the response string gets saved, and  parse out values that are accessed.
    def request_b

      # 2F 3F 12 Bytes Address 30 31 21 0D 0A
      # /?00000000012301! then a CRLF
      request = "/?" + meter_number + "01!\r\n"
      read_bytes = 255
      logger.debug "Socket write #{request}" unless logger.nil?
      response = get_remote_meter_data(request, read_bytes)
      if response.nil?
        logger.error "No response to request_a from meter #{meter_number}"
        raise EkmOmnimeter, "No response from meter."
      end

      # Split the response string into an array and prepare a hash to store the values
      a = response.split('')
      d = {}

      # Return (255 Bytes total) :
      a.shift(1)                               # 02
      d[:meter_type] = a.shift(2)              # 2 Byte Meter Type
      d[:meter_firmware] = a.shift(1)          # 1 Byte Meter Firmware
      d[:address] = a.shift(12)                # 12 Bytes Address

      # Diff from request A start
      #d[:t1_t2_t3_t4_kwh] = a.shift(32)        # 32 Bytes T1, T2, T3, T4 kwh
      d[:total_kwh_t1] = a.shift(8)
      d[:total_kwh_t2] = a.shift(8)
      d[:total_kwh_t3] = a.shift(8)
      d[:total_kwh_t4] = a.shift(8)

      #d[:t1_t2_t3_t4_rev_kwh] = a.shift(32)    # 32 Bytes T1, T2, T3, T4 Rev kWh
      d[:reverse_kwh_t1] = a.shift(8)
      d[:reverse_kwh_t2] = a.shift(8)
      d[:reverse_kwh_t3] = a.shift(8)
      d[:reverse_kwh_t4] = a.shift(8)

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
      d[:power_factor_1] = a.shift(4)          # 4 Bytes Cosϴ L1
      d[:power_factor_2] = a.shift(4)          # 4 Bytes Cosϴ L2
      d[:power_factor_3] = a.shift(4)          # 4 Bytes Cosϴ L3
      # Diff from request A start
      d[:maximum_demand] = a.shift(8)                # 8 Bytes Maximum Demand
      d[:maximum_demand_period] = a.shift(1)         # 1 Byte Maximum Demand Time
      d[:pulse_1_ratio] = a.shift(4)                 # 4 Bytes Pulse Ratio 1
      d[:pulse_2_ratio] = a.shift(4)                 # 4 Bytes Pulse Ratio 2
      d[:pulse_3_ratio] = a.shift(4)                 # 4 Bytes Pulse Ratio 3
      d[:ct_ratio] = a.shift(4)                      # 4 Bytes CT Ratio
      d[:auto_reset_max_demand] = a.shift(1)         # 1 Bytes Auto Reset MD
      d[:settable_pulse_per_kwh_ratio] = a.shift(4)  # 4 Bytes Settable Imp/kWh Constant
      # Diff from request A end
      a.shift(56)                              # 56 Bytes Reserved
      meter_timestamp = a.shift(14).join('')   # 14 Bytes Current Time
      a.shift(6)                               # 30 30 21 0D 0A 03
      d[:checksum] = a.shift(2)                   # 2 Bytes CRC16

      # Smash arrays into strungs
      d.each {|k,v| d[k] = v.join('')}

      if verify_checksums
        if Crc16.check_crc16(response, d[:checksum])
          @logger.debug "Checksum matches"
        else
          @logger.error "CRC16 Checksum doesn't match. Expecting #{d[:checksum]} but was #{Crc16.crc16(response)}"
          #raise EkmOmnimeterError, "Checksum doesn't match"
        end
      end

      # Cast types
      d[:power_factor_1] = cast_power_factor(d[:power_factor_1])
      d[:power_factor_2] = cast_power_factor(d[:power_factor_2])
      d[:power_factor_3] = cast_power_factor(d[:power_factor_3])
      d[:meter_timestamp] = as_datetime(meter_timestamp)
      cast_response_to_correct_types(d)

      # Lookup mapped values
      d[:maximum_demand_period] = lookup_demand_period_time(d[:maximum_demand_period])
      d[:auto_reset_max_demand] = lookup_auto_reset_max_demand_period(d[:auto_reset_max_demand])

      # Merge to values and reset time
      @values.merge!(d)
      @last_read_timestamp = Time.now

      # Calculate totals based on wiring configuration
      @values[:volts] = calculate_measurement(volts_l1, volts_l2, volts_l3)
      @values[:amps]  = calculate_measurement(amps_l1, amps_l2, amps_l3)
      @values[:watts] = calculate_measurement(watts_l1, watts_l2, watts_l3)

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
        @logger.debug "Socket open"

        # Send request to the meter
        @logger.debug "Request: #{request}"
        socket.write(request)

        # Receive a response of 255 bytes
        response = socket.read(read_bytes)
        @logger.debug "Socket response #{response.length}"
        @logger.debug response

      rescue Exception => ex
        @logger.error "Exception\n#{ex.message}\n#{ex.backtrace.join("\n")}"
      ensure
        # EKM Meter software sends this just before closing the connection, so we will too
        socket.write "\x0a\x03\x32\x3d"
        socket.close
        @logger.debug "Socket closed"
      end

      return response

    end



    PULSE_INPUT_STATE_MAP = {
      0 => [:high,:high,:high], # High/High/High = 0 (30)
      1 => [:high,:high,:low],  # High/High/Low  = 1 (31)
      2 => [:high,:low,:high],  # High/Low/High  = 2 (32)
      3 => [:high,:low,:low],   # High Low/Low   = 3 (33)
      4 => [:low,:high,:high],  # Low/High/High  = 4 (34)
      5 => [:low,:high,:low],   # Low/High/Low   = 5 (35)
      6 => [:low,:low,:high],   # Low/Low/High   = 6 (36)
      7 => [:low,:low,:low]     # Low/Low/Low    = 7 (37)
    }
    def lookup_pulse_input_states(v)
      PULSE_INPUT_STATE_MAP[v.to_i]
    end


    DIRECTION_OF_CURRENT_MAP = {
      #Line1/Line2/Line3
      1 => [:forward,:forward,:forward],  #Forward/Forward/Forward = 1 (31)
      2 => [:forward,:forward,:reverse],  #Forward/Forward/Reverse = 2 (32)
      3 => [:forward,:reverse,:forward],  #Forward/Reverse/Forward = 3 (33)
      4 => [:reverse,:forward,:forward],  #Reverse/Forward/Forward = 4 (34)
      5 => [:forward,:reverse,:reverse],  #Forward/Reverse/Reverse = 5 (35)
      6 => [:reverse,:forward,:reverse],  #Reverse/Forward/Reverse = 6 (36)
      7 => [:reverse,:reverse,:forward],  #Reverse/Reverse/Forward = 7 (37)
      8 => [:reverse,:reverse,:reverse]   #Reverse/Reverse/Reverse = 8 (38)
    }
    def lookup_direction_of_current(v)
      DIRECTION_OF_CURRENT_MAP[v.to_i]
    end


    OUTPUT_INDICATOR_MAP = {
      1 => [:off,:off], # OFF/OFF = 1 (31)
      2 => [:off,:on],  # OFF/ON  = 2 (32)
      3 => [:on,:off],  # ON/OFF  = 3 (33)
      4 => [:on,:on]    # ON/ON   = 4 (34)
    }
    def lookup_output_states(v)
      OUTPUT_INDICATOR_MAP[v.to_i]
    end


    DEMAND_PERIOD_TIME_MAP = {
      1 => 15,  # 15 min = 1 (31)
      2 => 30,  # 30 min = 2 (31)
      3 => 60   # Hour   = 3 (31)
    }
    def lookup_demand_period_time(v)
      DEMAND_PERIOD_TIME_MAP[v.to_i]
    end


    AUTO_RESET_MAX_DEMAND_MAP = {
      0 => :off,     # OFF = 0 (30)
      1 => :monthly, # Monthly = 1 (31)
      2 => :weekly,  # Weekly = 2 (32)
      3 => :daily,   # Daily = 3 (33)
      4 => :hourly   # Hourly = 4 (34)
    }
    def lookup_auto_reset_max_demand_period(v)
      AUTO_RESET_MAX_DEMAND_MAP[v.to_i]
    end

  end
end
