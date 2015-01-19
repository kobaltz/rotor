module Rotor
  class Gcode
    def initialize(stepper_x=nil,stepper_y=nil,stepper_z=nil,scale=1,servo=nil)
      @stepper_x = stepper_x
      @stepper_y = stepper_y
      @stepper_z = stepper_z
      @scale = scale
      @servo = servo
    end

    def open(file)
      @file = File.open(file)
    end

    def simulate
      @x = 0
      @y = 0
      @z = 0

      @file.each_line do |line|
        parsed_line = parse_line(line)
        if parsed_line[:g]
          #Move to this origin point.
          if parsed_line[:g] == 0
            move_stepper(parsed_line,1)
          elsif parsed_line[:g] == 1
            move_stepper(parsed_line,10)
          else
            # puts "GLINE - Something else"
          end
        elsif parsed_line[:m]
          if line[0..2] == "M03"
            puts "Lowering marker"
            @servo.rotate(:down) if @servo
          elsif line[0..2] == "M05"
            puts "Lifting marker"
            @servo.rotate(:up) if @servo
          else
            # puts "MLINE - Something else"
          end
        else
          # puts "Something else"
        end
      end
    end

    def move_stepper(parsed_line,delay)
      threads = []
      [:x,:y,:z].each do |element|
        ets = element.to_s
        instance_variable_set(:"@#{ets}_move",nil)    
        if parsed_line[element]
          instance_variable_set(:"@#{ets}_move",parsed_line[element])          
          instance_variable_set(:"@#{ets}_move",0) unless instance_variable_get(:"@#{ets}_move")
          instance_variable_set(:"@#{ets}_move",instance_variable_get(:"@#{ets}_move") * @scale)

          instance_variable_set(:"@#{ets}_movement", (instance_variable_get(:"@#{ets}_move") - instance_variable_get(:"@#{ets}")).abs)

          if instance_variable_get(:"@#{ets}_move").to_f > instance_variable_get(:"@#{ets}") #move to the right
            if instance_variable_get(:"@stepper_#{ets}") && instance_variable_get(:"@stepper_#{ets}").at_safe_area?
              threads << Thread.new { instance_variable_get(:"@stepper_#{ets}").forward(1, instance_variable_get(:"@#{ets}_movement")) }
            end
          elsif instance_variable_get(:"@#{ets}_move").to_f < instance_variable_get(:"@#{ets}") #move to the left
            if instance_variable_get(:"@stepper_#{ets}") && instance_variable_get(:"@stepper_#{ets}").at_safe_area?
              threads << Thread.new { instance_variable_get(:"@stepper_#{ets}").backwards(1, instance_variable_get(:"@#{ets}_movement")) } 
            end
          end
          instance_variable_set(:"@#{ets}",instance_variable_get(:"@#{ets}_move"))
        end
      end

      puts "Moving to G#{parsed_line[:g]} #{instance_variable_get(:"@x_move")}, #{instance_variable_get(:"@y_move")}, #{instance_variable_get(:"@z_move")}"
      threads.each { |thr| thr.join }
    end

    def parse_line(line)
      returned_json = {}
      values = [:g,:x,:y,:z,:i,:j,:m,:f]
      values.each do |element|
        returned_json[element] = find_value(element,line)
      end
      return returned_json
    end

    def find_value(element,line)
      node = element.to_s.upcase
      data = line.match /#{node}(?<data>\d+[,.]\d+)/
      data ||= line.match /#{node}(?<data>\d+)/
      if data
        case element
        when :g, :m
          return data[:data].to_i
        when :x,:y,:z,:i,:k,:f
          return data[:data].to_f
        end
      else
        return nil
      end
    end
  end
end