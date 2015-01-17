module Rotor
  class Gcode
    def initialize(stepper_x=nil,stepper_y=nil)
      @stepper_x = stepper_x
      @stepper_y = stepper_y
    end

    def open(file)
      @file = File.open(file)
    end

    def simulate
      @file.each_line do |line|
        case line[0]
        when "G"
          puts "GLINE"
        when "M"
          puts "MLINE"
        else
          puts "something else"
        end
      end
    end
  end
end

gcode = Rotor::Gcode.new
gcode.open('sample.nc')
gcode.simulate