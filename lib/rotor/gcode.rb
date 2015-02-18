module Rotor
  class Gcode
    def initialize(stepper_x=nil,stepper_y=nil,stepper_z=nil,scale=1,servo=nil,fast_move=1)
      @stepper_x = stepper_x
      @stepper_y = stepper_y
      @stepper_z = stepper_z
      @fast_move = fast_move
      @scale = scale
      @servo = servo
    end

    def open(file)
      @file = File.open(file)
    end

    def simulate(accuracy=8,speed=1)
      @x = 0
      @y = 0
      @z = 0

      line_num = 0

      @file.each_line do |line|
        line[0..2] = @previous_command if line[0..2] == "   "
        parsed_line = parse_line(line)
        
        line_num += 1
        if parsed_line[:g]
          #Move to this origin point.
          if parsed_line[:g] == 0
            puts "Move Stepper (#{line_num})::#{parsed_line}"
            move_stepper(parsed_line,@fast_move)
          elsif parsed_line[:g] == 1
            puts "Move Stepper (#{line_num})::#{parsed_line}"
            move_stepper(parsed_line,speed)
          elsif parsed_line[:g] == 2 || parsed_line[:g] == 3
            # Get my ARC on
            ignore = false

            x_start = @x
            x_end = parsed_line[:x]

            y_start = @y
            y_end = parsed_line[:y]

            z_start = @z
            z_end = parsed_line[:z]

            if (parsed_line[:i] || parsed_line[:j] || parsed_line[:k]) && parsed_line[:r].nil?
              x_offset = parsed_line[:i]
              y_offset = parsed_line[:j]
              z_offset = parsed_line[:k]

              x_origin = x_offset + x_start
              y_origin = y_offset + y_start
              # z_origin = z_offset + z_start

              radius = Math.sqrt((x_start - x_origin) ** 2 + (y_start - y_origin) ** 2)
       
            elsif parsed_line[:i].nil? && parsed_line[:j].nil? && parsed_line[:k].nil? && parsed_line[:r]
              ignore = true
            end

            unless ignore
              distance = Math.sqrt((x_start - x_end) ** 2 + (y_start - y_end) ** 2)
              number_of_precision = [distance.to_i,8].max
              start_angle = Math.atan2((y_start - y_origin),(x_start - x_origin))
              end_angle = Math.atan2((y_end - y_origin),(x_end - x_origin))

              if start_angle - end_angle > Math::PI
                end_angle += Math::PI * 2
                # puts "Move Arc Stepper (#{line_num})::Insert Fix"
              elsif start_angle - end_angle < -Math::PI
                end_angle *= -1
                # puts "Move Arc Stepper (#{line_num})::Insert Fix 2"
              end

              steps = (end_angle - start_angle) / number_of_precision
              current_degrees = start_angle
            end

            number_of_precision.times do |i|
              current_degrees += steps
              arc_line = {}
              arc_line[:g] = parsed_line[:g]
              arc_line[:x] = radius * Math.cos(current_degrees) + x_origin
              arc_line[:y] = radius * Math.sin(current_degrees) + y_origin
              arc_line[:z] = nil
              # puts "Move Arc Stepper (#{line_num})::#{arc_line}::#{start_angle},#{end_angle}"
              move_stepper(arc_line,speed)
            end unless ignore

          else
            # puts "DEBUG::GLINE - Something else::#{parsed_line}"
          end
          @previous_command = line[0..2]
        elsif parsed_line[:m]
          if line[0..2] == "M03"
            puts "Lowering marker"
            @servo.rotate(:down) if @servo
          elsif line[0..2] == "M05"
            puts "Lifting marker"
            @servo.rotate(:up) if @servo
          else
            # puts "DEBUG::MLINE - Something else::#{parsed_line}"
          end
        else
          # puts "DEBUG::????? - Something else::#{parsed_line}"
        end        
      end
    end

    private

    def move_stepper(parsed_line,delay)
      threads = []
      comp_delay_calc = []

      @x_move = nil    
      if parsed_line[:x]
        @x_move = parsed_line[:x]        
        @x_move ||= 0
        @x_move *= @scale
        @x_movement = (@x_move - @x).abs
        comp_delay_calc << @x_movement
      end

      @y_move = nil    
      if parsed_line[:y]
        @y_move = parsed_line[:y]        
        @y_move ||= 0
        @y_move *= @scale
        @y_movement = (@y_move - @y).abs
        comp_delay_calc << @y_movement
      end

      @z_move = nil    
      if parsed_line[:z]
        @z_move = parsed_line[:z]        
        @z_move ||= 0
        @z_move *= @scale
        @z_movement = (@z_move - @z).abs
        comp_delay_calc << @z_movement
      end

      if parsed_line[:x]
        x_delay = comp_delay_calc.max * delay / @x_movement
        x_delay = delay if x_delay == 0.0
        if @x_move.to_f < @x #move to the right
          if @stepper_x # && @stepper_x.at_safe_area?
            threads << Thread.new { @stepper_x.forward(delay, @x_movement) }
          end
        elsif @x_move.to_f > @x #move to the left
          if @stepper_x # && @stepper_x.at_safe_area?
            threads << Thread.new { @stepper_x.backwards(delay, @x_movement) } 
          end
        end unless @x_movement == 0
        @x = @x_move
      end
      @x_move ||= @x

      if parsed_line[:y]
        y_delay = comp_delay_calc.max * delay / @y_movement
        y_delay = delay if y_delay == 0.0        
        if @y_move.to_f < @y #move to the right
          if @stepper_y # && @stepper_y.at_safe_area?
            threads << Thread.new { @stepper_y.forward(y_delay, @y_movement) }
          end
        elsif @y_move.to_f > @y #move to the left
          if @stepper_y # && @stepper_y.at_safe_area?
            threads << Thread.new { @stepper_y.backwards(y_delay, @y_movement) } 
          end
        end unless @y_movement == 0
        @y = @y_move
      end
      @y_move ||= @y

      if parsed_line[:z]
        z_delay = comp_delay_calc.max * delay / @z_movement
        z_delay = delay if z_delay == 0.0        
        if @z_move.to_f > @z #move to the right
          if @stepper_z # && @stepper_z.at_safe_area?
            threads << Thread.new { @stepper_z.forward(z_delay, @z_movement) }
          end
        elsif @z_move.to_f < @z #move to the left
          if @stepper_z # && @stepper_z.at_safe_area?
            threads << Thread.new { @stepper_z.backwards(z_delay, @z_movement) } 
          end
        end unless @z_movement == 0
        @z = @z_move
      end
      @z_move ||= @z
      threads.each { |thr| thr.join }
      File.open("output.txt", 'a') { |file| file.write("#{@x_move},#{@y_move},#{@z_move},#{@x_movement},#{@y_movement},#{@z_movement}\n") } if File.exists?("output.txt")
    end    

    def parse_line(line)
      returned_json = {}
      values = [:g,:x,:y,:z,:i,:j,:k, :r, :m,:f]
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
        when :x,:y,:z,:i,:j,:k,:r,:f
          return data[:data].to_f
        end
      else
        return nil
      end
    end
  end
end