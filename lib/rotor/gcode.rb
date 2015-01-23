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

      line_num = 0
      last_parsed_line = nil

      @file.each_line do |line|
        # puts "last_parsed_line::#{last_parsed_line}"
        # line = line.gsub("J-0.000000","J-0.000001") if last_parsed_line && last_parsed_line[:j] && last_parsed_line[:j] > 0.0
        # line = line.gsub("J-0.000000","J0.000001") if last_parsed_line && last_parsed_line[:j] && last_parsed_line[:j] < 0.0

        parsed_line = parse_line(line)
        
        line_num += 1
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
              move_stepper(parsed_line,1)
            end
          elsif parsed_line[:g] == 2 || parsed_line[:g] == 3
            # Get my ARC on
            # puts "DEBUG::#{parsed_line}"
            ignore = false

            x_start = @x
            x_end = parsed_line[:x]

            y_start = @y
            y_end = parsed_line[:y]

            if parsed_line[:i] && parsed_line[:j] && parsed_line[:r].nil?
              x_offset = parsed_line[:i]
              # x_offset = 0.0001 if x_offset == 0.0
              # x_offset = -0.0001 if x_offset == -0.0
              y_offset = parsed_line[:j]
              # y_offset = 0.0001 if y_offset == 0.0
              # y_offset = -0.0001 if y_offset == -0.0

              x_origin = x_offset + x_start
              y_origin = y_offset + y_start

              radius = Math.sqrt((x_start - x_origin) ** 2 + (y_start - y_origin) ** 2)
       
            elsif parsed_line[:i].nil? && parsed_line[:j].nil? && parsed_line[:r]
              ignore = true
            end

            unless ignore
              distance = Math.sqrt((x_start - x_end) ** 2 + (y_start - y_end) ** 2)
              number_of_precision = [distance.to_i,4].max
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
              puts "Move Arc Stepper (#{line_num})::#{arc_line}::#{start_angle},#{end_angle}"
              move_stepper(arc_line,1)
            end unless ignore

          else
            # puts "GLINE - Something else"
            puts "DEBUG::GLINE - Something else::#{parsed_line}"
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
            puts "DEBUG::MLINE - Something else::#{parsed_line}"
          end
        else
          # puts "Something else"
          puts "DEBUG::????? - Something else::#{parsed_line}"
        end
        last_parsed_line = parsed_line
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

        if @x_move.to_f < @x #move to the right
          if @stepper_x # && @stepper_x.at_safe_area?
            threads << Thread.new { @stepper_x.forward(delay, @x_movement) }
          end
        elsif @x_move.to_f > @x #move to the left
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

        if @y_move.to_f < @y #move to the right
          if @stepper_y # && @stepper_y.at_safe_area?
            threads << Thread.new { @stepper_y.forward(delay, @y_movement) }
          end
        elsif @y_move.to_f > @y #move to the left
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

        if @z_move.to_f < @z #move to the right
          if @stepper_z # && @stepper_z.at_safe_area?
            threads << Thread.new { @stepper_z.forward(delay, @z_movement) }
          end
        elsif @z_move.to_f > @z #move to the left
          if @stepper_z # && @stepper_z.at_safe_area?
            threads << Thread.new { @stepper_z.backwards(delay, @z_movement) } 
          end
        end
        @z = @z_move
      end      
      # puts "Moving to G#{parsed_line[:g]} #{@x_move}(#{@x_movement}), #{@y_move}(#{@y_movement}), #{@z_move}(#{@z_movement})"
      threads.each { |thr| thr.join }
      File.open("output.txt", 'a') { |file| file.write("#{@x_move},#{@y_move},#{@x_movement},#{@y_movement}\n") } if File.exists?("output.txt")
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