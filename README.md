# Rotor (Ruby Motor)

Tested on RaspberryPi Model B+ but should work for any Raspberry Pi.

This Ruby gem allows you to control different kinds of stepper motors. You
can use this gem to run both Bipolar and Unipolar motors with either L293D
or ULN2800 Integrated Controllers.

## Installation

  Make sure that you have WiringPi installed first

    gem install wiringpi

  Install Rotor

    gem install rotor

# Notes

  Class Stepper

    stepper = Rotor::Stepper.new(coil_A_1_pin, coil_A_2_pin, coil_B_1_pin, coil_B_2_pin, enable_pin=nil, homing_switch, homing_normally,steps_per_mm)
    stepper.forward(delay=5,steps=100)
    stepper.backwards(delay=5,steps=100)
    stepper.set_home(direction) #:forward or :backwards
    stepper.at_home?
    stepper.at_safe_area? #opposite of at_home?

  Class Servo

    servo = Rotor::Servo.new(pin=18)
    servo.rotate(direction) # :up or :down

  Class GCode

    gcode = Rotor::Gcode.new(stepper_x=nil,stepper_y=nil,stepper_z=nil,scale=1,servo=nil)
    gcode.open(file)
    gcode.simulate

# Usage

  The goal of this gem is to make controlling your robotics easier than
  other solutions.

  Added Homing Switch options where you can add the GPIO of the switch
  and indicate if it is normally open or normally closed. I have my homing
  switches on each axis configured in parallel since I know the direction
  that the panel is moving in and therefore know which side it has hit. This
  was to reduce the number of GPIO pins required.

    stepper_x = Rotor::Stepper.new(23,12,17,24,nil,13,LOW,6.74)
    stepper_y = Rotor::Stepper.new(25, 4,21,22,nil,19,LOW,8.602)

  You can use a servo to control the marker (or leave blank if you're using a Z Axis Stepper)
  This will be built out so that the strength control of the servo (for laser power) can be
  adjusted and inputs sent in. However, for development purposes, I recommend not playing with
  lasers, but rather get the machine and code working properly first.

    servo = Rotor::Servo.new(18)

  You can send the stepper motor to the outter edges of the board.

    # stepper_x.set_home(:backwards)
    # stepper_x.forward(1,100)
    # stepper_y.set_home(:forward)

    stepper_x = Rotor::Stepper.new(23,12,17,24,nil,13,LOW,6.74)
    stepper_y = Rotor::Stepper.new(25, 4,21,22,nil,19,LOW,8.602)
    
    loop do
      puts "Enter steps forward::"
      text = gets.chomp
      
      threads = []
      threads << Thread.new { stepper_x.forward(5,text.to_i) }
      threads << Thread.new { stepper_y.forward(5,text.to_i) }
      threads.each { |thr| thr.join }

      puts "Enter steps backward::"
      text = gets.chomp

      stepper_x.backwards(5,text.to_i)
      stepper_y.backwards(5,text.to_i)
    end

# GCode Simulation

GCode can be simulated (this is my latest part of the project) where
a file can be read in and the movements interpreted. I'm still working
on the ARC movement on G02 and G03, but have gotten G0 and G1 working.

Enter each stepper motor (or nil if you do not have that particular axis)
along with the scale (multiplies all coordinates by this. Typically you will
keep this at 1).

    #gcode = Rotor::Gcode.new(stepper_x,stepper_y,stepper_z,1,servo)
    gcode = Rotor::Gcode.new(nil,nil,nil,1,nil)
    gcode.open('sample.nc')
    gcode.simulate

# Asynchronous Movement

  By default, if you run the first motor and then the second motor commands,
  the first command will execute first and the second one will execute afterwards.
  This may not always be the desired result as your plot/laser/mill may get ruined
  by having nonsynchronous movements.

  Since Ruby by default will not asynchronously execute commands, you can combine
  the X/Y/Z movements into their own threads.

    threads = []
    threads << Thread.new { stepper_x.forward(5,text.to_i) }
    threads << Thread.new { stepper_y.forward(5,text.to_i) }
    threads.each { |thr| thr.join }

# License

Copyright (c) 2015 kobaltz

MIT License

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
