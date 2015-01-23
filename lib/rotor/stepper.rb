require 'wiringpi'

module Rotor
  class Stepper
    def initialize(coil_A_1_pin, coil_A_2_pin, coil_B_1_pin, coil_B_2_pin, enable_pin=nil, homing_switch, homing_normally,steps_per_mm)
      @io = WiringPi::GPIO.new(WPI_MODE_GPIO)
      @coil_A_1_pin = coil_A_1_pin
      @coil_A_2_pin = coil_A_2_pin
      @coil_B_1_pin = coil_B_1_pin
      @coil_B_2_pin = coil_B_2_pin
      @enable_pin = enable_pin
      @steps_per_mm = steps_per_mm
      @homing_switch = homing_switch
      @homing_normally = homing_normally

      @step = 0
      @ps = [[1,0,1,0],[0,1,1,0],[0,1,0,1],[1,0,0,1]]

      [@coil_A_1_pin, @coil_A_2_pin, @coil_B_1_pin, @coil_B_2_pin].each do |pin|
        `echo #{pin} > /sys/class/gpio/unexport`
        @io.mode(pin,OUTPUT)
        @io.write(pin,LOW)
      end

      unless @enable_pin == nil
        `echo #{@enable_pin} > /sys/class/gpio/unexport`
        @io.mode(@enable_pin,OUTPUT)
        @io.write(@enable_pin,LOW)
        @io.write(@enable_pin,HIGH)
      end

      unless @homing_switch == nil
        `echo #{@homing_switch} > /sys/class/gpio/unexport`
        @io.mode(@homing_switch,INPUT)
      end
    end

    def forward(delay=5,steps=100)
      delay_time = delay/1000.0
      (0..(steps * @steps_per_mm)).each do |i|
        set_step(@ps[@step][0],@ps[@step][1],@ps[@step][2],@ps[@step][3])
        @step += 1
        @step = 0 if @step == 4
        sleep delay_time
      end
    end


    def backwards(delay=5,steps=100)
      delay_time = delay/1000.0
      (0..(steps * @steps_per_mm)).each do |i|
        set_step(@ps[@step][0],@ps[@step][1],@ps[@step][2],@ps[@step][3])
        @step -= 1
        @step = 3 if @step == -1
        sleep delay_time
      end
      
    end    

    def set_home(direction)
      puts "Setting #{direction} with Homing on GPIO #{@homing_switch}"
      @move = true
      while @move == true
        backwards(1,158) if direction == :backwards #&& @io.read(@homing_switch) == @homing_normally
        forward(1,158) if direction == :forward #&& @io.read(@homing_switch) == @homing_normally
        @move = false unless @io.read(@homing_switch) == @homing_normally
      end
    end

    def at_home?
      if @io.read(@homing_switch) == @homing_normally
        return true
      else
        return false
      end
    end

      def at_safe_area?
      if @io.read(@homing_switch) == @homing_normally
        return false
      else
        return true
      end
    end

    def power_down
      set_step(0, 0, 0, 0)
    end

    private

    def set_step(w1, w2, w3, w4)
      @io.write(@coil_A_1_pin, w1)
      @io.write(@coil_A_2_pin, w2)
      @io.write(@coil_B_1_pin, w3)
      @io.write(@coil_B_2_pin, w4)
    end
  end
end