require 'wiringpi'

module Rotor
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

    def set_home(coord=0, direction, homing_switch, homing_normally)
      `echo #{homing_switch} > /sys/class/gpio/unexport`
      @io.mode(homing_switch,INPUT)
      @move = true
      while @move == true
        backwards(2,1) if direction == :backwards #&& @io.read(homing_switch) == homing_normally
        forward(2,1) if direction == :forward #&& @io.read(homing_switch) == homing_normally
        @move = false unless @io.read(homing_switch) == homing_normally
      end
    end

  end
end