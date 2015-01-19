module Rotor
  class Gcode
    def initialize(stepper_x=nil,stepper_y=nil,scale=1,servo=nil)
      @stepper_x = stepper_x
      @stepper_y = stepper_y
      @scale = scale
      @servo = servo
    end

    def open(file)
      @file = File.open(file)
    end

    def simulate
      @x = 0
      @y = 0

      @file.each_line do |line|
        parsed_line = parse_line(line)
        puts parsed_line
        case line[0]
        when "G"
          #Move to this origin point.
          if line[0..3] == "G1 F"
            
          elsif line[0..2] == "G0 "
            x_move = parsed_line[:x]
            x_move ||= 0
            x_move *= @scale

            y_move = parsed_line[:y]
            y_move ||= 0
            y_move *= @scale
            x_movement = (x_move - @x).abs
            y_movement = (y_move - @y).abs

            threads = []

            if x_move.to_f > @x #move to the right
              threads << Thread.new { @stepper_x.forward(2, x_movement) } if @stepper_x && @stepper_x.at_safe_area?
            elsif x_move.to_f < @x #move to the left
              threads << Thread.new { @stepper_x.backwards(2, x_movement) } if @stepper_x && @stepper_x.at_safe_area?
            end
            @x = x_move

            if y_move.to_f > @y #move to the right
              threads << Thread.new { @stepper_y.forward(2, y_movement) } if @stepper_y && @stepper_x.at_safe_area?
            elsif y_move.to_f < @y #move to the left
              threads << Thread.new { @stepper_y.backwards(2, y_movement) } if @stepper_y && @stepper_x.at_safe_area?
            end
            @y = y_move

            puts "Moving Fast to G0 #{x_move}, #{y_move}"
            threads.each { |thr| thr.join }            
          elsif line[0..2] == "G1 "
            x_move = find_value(:x,line)
            x_move ||= 0
            x_move *= @scale

            y_move = find_value(:y,line)
            y_move ||= 0
            y_move *= @scale

            x_movement = (x_move - @x).abs
            y_movement = (y_move - @y).abs

            threads = []

            if x_move.to_f > @x #move to the right
              threads << Thread.new { @stepper_x.forward(2, x_movement) } if @stepper_x && @stepper_x.at_safe_area?
            elsif x_move.to_f < @x #move to the left
              threads << Thread.new { @stepper_x.backwards(2, x_movement) } if @stepper_x && @stepper_x.at_safe_area?
            end
            @x = x_move

            if y_move.to_f > @y #move to the right
              threads << Thread.new { @stepper_y.forward(2, y_movement) } if @stepper_y && @stepper_y.at_safe_area?
            elsif y_move.to_f < @y #move to the left
              threads << Thread.new { @stepper_y.backwards(2, y_movement) } if @stepper_y && @stepper_y.at_safe_area?
            end
            @y = y_move

            puts "Moving to G1 #{x_move}, #{y_move}"
            threads.each { |thr| thr.join }
          else
            puts "GLINE - Something else"
          end
        when "M"
          if line[0..2] == "M03"
            puts "Lowering marker"
            @servo.rotate(:down) if @servo
          elsif line[0..2] == "M05"
            puts "Lifting marker"
            @servo.rotate(:up) if @servo
          else
            puts "MLINE - Something else"
          end
        else
          # puts "Something else"
        end
      end
    end

    private

    def parse_line(line)
      returned_json = {}
      values = [:g,:x,:y,:i,:j,:m,:f]
      values.each do |element|
        returned_json[element] = find_value(element,line)
      end
      return returned_json
    end

    def find_value(element,line)
      node = element.to_s.upcase
      data = line.match /#{node}(?<data>\d+[,.]\d+)/
      if data
        return data[:data].to_f
      else
        return nil
      end
    end
  end
end