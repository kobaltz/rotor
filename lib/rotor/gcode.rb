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
        # puts "DEBUG::#{parsed_line}"
        if parsed_line[:g]
          #Move to this origin point.
          if parsed_line[:g] == 0
            if parsed_line[:z] && parsed_line[:f] && parsed_line[:x].nil? && parsed_line[:y].nil? 
              puts "Lowering marker"
              @servo.rotate(:down) if @servo
            elsif parsed_line[:z] && parsed_line[:f].nil? && parsed_line[:x].nil? && parsed_line[:y].nil? 
              puts "Raising marker::#{parsed_line}"
              @servo.rotate(:up) if @servo
            else
              puts "Move Stepper::#{parsed_line}"
              move_stepper(parsed_line,1)
            end
          elsif parsed_line[:g] == 1
            if parsed_line[:z] && parsed_line[:f] && parsed_line[:x].nil? && parsed_line[:y].nil? 
              puts "Lowering marker"
              @servo.rotate(:down) if @servo
            elsif parsed_line[:z] && parsed_line[:f].nil? && parsed_line[:x].nil? && parsed_line[:y].nil? 
              puts "Raising marker::#{parsed_line}"
              @servo.rotate(:up) if @servo
            elsif parsed_line[:z].nil? && parsed_line[:f] && parsed_line[:x].nil? && parsed_line[:y].nil? 
              # Set feed/spin rate
            else
              puts "Move Stepper::#{parsed_line}"
              move_stepper(parsed_line,25)
            end
          elsif parsed_line[:g] == 2 || parsed_line[:g] == 3
            # Get my ARC on
            # puts "DEBUG::#{parsed_line}"
            x_start = @x
            x_end = parsed_line[:x]

            y_start = @y
            y_end = parsed_line[:y]

            x_offset = parsed_line[:i]
            y_offset = parsed_line[:j]

            x_origin = x_offset + x_start
            y_origin = y_offset + y_start

            radius = Math.sqrt((x_start - x_origin) ** 2 + (y_start - y_origin) ** 2)

            start_angle = Math.atan2((y_start - y_origin),(x_start - x_origin))
            end_angle = Math.atan2((y_end - y_origin),(x_end - x_origin))

            steps = (end_angle - start_angle) / 1

            current_degrees = start_angle

            1.times do
              current_degrees += steps
              #puts "CURRENT_RADIAN:#{current_degrees}"
              arc_line = {}
              arc_line[:x] = x_origin + radius * Math.cos(current_degrees)
              arc_line[:y] = y_origin + radius * Math.sin(current_degrees)
              arc_line[:z] = nil
              puts "Move Arc Stepper::#{arc_line}"
              move_stepper(arc_line,25)
            end


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

    private

    def move_stepper(parsed_line,delay)
      threads = []
      @x_move = nil    
      if parsed_line[:x]
        @x_move = parsed_line[:x]        
        @x_move ||= 0
        @x_move *= @scale

        @x_movement = (@x_move - @x).abs

        if @x_move.to_f > @x #move to the right
          if @stepper_x # && @stepper_x.at_safe_area?
            threads << Thread.new { @stepper_x.forward(delay, @x_movement) }
          end
        elsif @x_move.to_f < @x #move to the left
          if @stepper_x # && @stepper_x.at_safe_area?
            threads << Thread.new { @stepper_x.backwards(delay, @x_movement) } 
          end
        end
        @x = @x_move
      end

      @y_move = nil    
      if parsed_line[:y]
        @y_move = parsed_line[:y]        
        @y_move ||= 0
        @y_move *= @scale

        @y_movement = (@y_move - @y).abs

        if @y_move.to_f > @y #move to the right
          if @stepper_y # && @stepper_y.at_safe_area?
            threads << Thread.new { @stepper_y.forward(delay, @y_movement) }
          end
        elsif @y_move.to_f < @y #move to the left
          if @stepper_y # && @stepper_y.at_safe_area?
            threads << Thread.new { @stepper_y.backwards(delay, @y_movement) } 
          end
        end
        @y = @y_move
      end

      @z_move = nil    
      if parsed_line[:z]
        @z_move = parsed_line[:z]        
        @z_move ||= 0
        @z_move *= @scale

        @z_movement = (@z_move - @z).abs

        if @z_move.to_f > @z #move to the right
          if @stepper_z # && @stepper_z.at_safe_area?
            threads << Thread.new { @stepper_z.forward(delay, @z_movement) }
          end
        elsif @z_move.to_f < @z #move to the left
          if @stepper_z # && @stepper_z.at_safe_area?
            threads << Thread.new { @stepper_z.backwards(delay, @z_movement) } 
          end
        end
        @z = @z_move
      end      
      # puts "Moving to G#{parsed_line[:g]} #{@x_move}(#{@x_movement}), #{@y_move}(#{@y_movement}), #{@z_move}(#{@z_movement})"
      threads.each { |thr| thr.join }
      File.open("output.txt", 'a') { |file| file.write("#{@x_move},#{@y_move},#{@x_movement},#{@y_movement}\n") }
    end    

    def parse_line(line)
      returned_json = {}
      values = [:g,:x,:y,:z,:i,:j,:k,:m,:f]
      values.each do |element|
        returned_json[element] = find_value(element,line)
      end
      return returned_json
    end

    def find_value(element,line)
      node = element.to_s.upcase
      data = line.match /#{node}(?<data>\d+[,.]\d+)/
      data ||= line.match /#{node}(?<data>\d+)/
      data ||= line.match /#{node}(?<data>-\d+[,.]\d+)/
      data ||= line.match /#{node}(?<data>\d+[,.])/
      data ||= line.match /#{node}(?<data>-\d+[,.])/
      if data
        case element
        when :g, :m
          return data[:data].to_i
        when :x,:y,:z,:i,:j,:k,:f
          return data[:data].to_f
        end
      else
        return nil
      end
    end
  end
end