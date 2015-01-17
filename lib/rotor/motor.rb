require 'wiringpi'
require 'pi_piper'

module Rotor
  include PiPiper
  class Stepper
    def initialize(coil_A_1_pin, coil_A_2_pin, coil_B_1_pin, coil_B_2_pin, enable_pin=nil)
      @io = WiringPi::GPIO.new(WPI_MODE_GPIO)
      @coil_A_1_pin = coil_A_1_pin
      @coil_A_2_pin = coil_A_2_pin
      @coil_B_1_pin = coil_B_1_pin
      @coil_B_2_pin = coil_B_2_pin
      @enable_pin = enable_pin

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
    end

    def forward(delay=5,steps=100)
      delay_time = delay/1000.0
      (0..steps).each do |i|
        set_step(1, 0, 1, 0)
        sleep delay_time
        set_step(0, 1, 1, 0)
        sleep delay_time
        set_step(0, 1, 0, 1)
        sleep delay_time
        set_step(1, 0, 0, 1)
        sleep delay_time
      end
    end

    def backwards(delay=5,steps=100)
      delay_time = delay/1000.0
      (0..steps).each do |i|
        set_step(1, 0, 0, 1)
        sleep delay_time
        set_step(0, 1, 0, 1)
        sleep delay_time
        set_step(0, 1, 1, 0)
        sleep delay_time
        set_step(1, 0, 1, 0)
        sleep delay_time
      end
    end

    def set_step(w1, w2, w3, w4)
      @io.write(@coil_A_1_pin, w1)
      @io.write(@coil_A_2_pin, w2)
      @io.write(@coil_B_1_pin, w3)
      @io.write(@coil_B_2_pin, w4)
    end

    def set_home(x_coord=0, y_coord=0, x_homing_switch, y_homing_switch, x_homing_normally_open=true, y_homing_normally_open=true)
      x_homing_normally_open ? x_homing_logic = :high : x_homing_logic = :low
      y_homing_normally_open ? y_homing_logic = :high : y_homing_logic = :low

      @x_move = true
      @y_move = true

      while @x_move == true
        self.backwards(10,5)
      end

      while @y_move == true
        self.forward(10,5)
      end      
      
      after :pin => x_homing_switch, :goes => x_homing_logic do
        @x_move = false
      end

      after :pin => y_homing_switch, :goes => y_homing_logic do
        @y_move = false
      end      
    end
    
  end
end