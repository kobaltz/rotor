require 'wiringpi'

module Rotor
  class Servo
    def initialize(pin=18)
      @io = WiringPi::GPIO.new(WPI_MODE_GPIO)
      @pin = pin
      @io.mode @pin, OUTPUT
    end

    def rotate(direction)
        if direction == :up
          freq = 1.0
        elsif direction == :down
          freq = 2.0
        else
          freq = 0.0
        end
        25.times do;pulser(freq,20.0);end
    end

    private

    def pulser(freq,dur)
      @io.write @pin, HIGH
      sleep (freq/1000)
      @io.write @pin, LOW
      sleep ((dur-freq)/1000)
    end    
  end
end