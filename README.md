Rotor (Ruby Motor)
==================

Tested on RaspberryPi Model B+ but should work for any Raspberry Pi.

This Ruby gem allows you to control different kinds of stepper motors. You can
use this gem to run both Bipolar and Unipolar motors with either L293D or
ULN2800 Integrated Controllers.

Installation
------------

### WiringPi

Make sure that you have WiringPi installed first

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
gem install wiringpi
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If you are using GPIO Pins from a A+/B+, you may need to update your WiringPi
libraries. You can pull from my repo
[https://github.com/kobaltz/WiringPi-Ruby][1]

[1]: <https://github.com/kobaltz/WiringPi-Ruby >

I did not write any of the WiringPi-Ruby platform. I simply pulled the latest C
libraries and recompiled the gem.

### Rotor

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
gem install rotor
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Notes
=====

This gem has been built for my personal project. I do not and cannot know if
this will work with your setup. However, put in an issue if you're having
troubles with this gem and I will try to help you as best as I can.

I am using two stepper motors (NEMA17 Bipolar 20Ncm 12V) and two L293D motor
drivers. This gem has also been tested with a small 5V Unipolar Stepper Motor
and 12V Unipolar Stepper Motor.

My Steps Per MM is based on a 200 step per revolution motor and a threaded rod
with 20 threads per inch. This means that I will have to step 4000 times to move
the coupler one inch.

Usage
=====

Class Stepper
-------------

MAKE SURE THAT YOU HAVE CONFIGURED THE Rotor::Stepper WITH THE CORRECT GPIO PIN
NUMBERS. CHECK AND DOUBLE CHECK THESE BEFORE RUNNING YOUR CODE. This has been
tested with both Bipolar and Unipolar Stepper Motors

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
stepper = Rotor::Stepper.new(coil_A_1_pin, coil_A_2_pin, coil_B_1_pin, coil_B_2_pin, enable_pin=nil, homing_switch, homing_normally, steps_per_mm)
stepper.forward(delay=5,steps=100) # stepper.forward(5,100)
stepper.backwards(delay=5,steps=100)# stepper.backwards(5,100)
stepper.set_home(direction) #:forward or :backwards
stepper.at_home?
stepper.at_safe_area? # opposite of at_home?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

After running your GCode, you may want to consider to power down the motor by
sending a LOW to each step.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
stepper.power_down
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Class Servo
-----------

You can use a servo to control the marker (or leave blank if you're using a Z
Axis Stepper) This will be built out so that the strength control of the servo
(for laser power) can be adjusted and inputs sent in. However, for development
purposes, I recommend not playing with lasers, but rather get the machine and
code working properly first.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
servo = Rotor::Servo.new(pin=18)# Rotor::Servo.new(18)
servo.rotate(direction) # :up or :down
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Class GCode
-----------

The plot points are streamed to output.txt file on your computer.

You can test the outputs of your GCODE and the XY plots it creates by Rotor.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
File.open("output.txt", 'wb') { |file| file.write("x,y,xm,ym\n") }
gcode = Rotor::Gcode.new(nil,nil,nil,1,nil)
gcode.open('output.nc')
gcode.simulate
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The goal of this gem is to make controlling your robotics easier than other
solutions.

Added Homing Switch options where you can add the GPIO of the switch and
indicate if it is normally open or normally closed. I have my homing switches on
each axis configured in parallel since I know the direction that the panel is
moving in and therefore know which side it has hit. This was to reduce the
number of GPIO pins required.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
stepper_x = Rotor::Stepper.new(23,12,17,24,nil,13,0,157.48)
stepper_y = Rotor::Stepper.new(25, 4,21,22,nil,19,0,157.48)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

You can send the stepper motor to the outter edges of the board. You will want
to play with the :backwards and :forward options to make sure that they’re
moving in the correct direction for your stepper motor.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
stepper_x = Rotor::Stepper.new(23,12,17,24,nil,13,LOW,157.48)
stepper_y = Rotor::Stepper.new(25, 4,21,22,nil,19,LOW,157.48)

stepper_x.set_home(:backwards)
stepper_y.set_home(:forward)

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
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

GCode Simulation
================

GCode can be simulated (this is my latest part of the project) where a file can
be read in and the movements interpreted. Right now, G02 and G03 will work with
I and J offsets. Radius is not currently supported.

Enter each stepper motor (or nil if you do not have that particular axis) along
with the scale (multiplies all coordinates by this. Typically you will keep this
at 1).

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#gcode = Rotor::Gcode.new(stepper_x,stepper_y,stepper_z,1,servo)
gcode = Rotor::Gcode.new(nil,nil,nil,1,nil)
gcode.open('sample.nc')
gcode.simulate
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

By passing nil into each stepper motor and servo, you can simulate the GCode
execution.

Asynchronous Movement
=====================

By default, if you run the first motor and then the second motor commands, the
first command will execute first and the second one will execute afterwards.
This may not always be the desired result as your plot/laser/mill may get ruined
by having nonsynchronous movements.

Since Ruby by default will not asynchronously execute commands, you can combine
the X/Y/Z movements into their own threads.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
threads = []
threads << Thread.new { stepper_x.forward(5,text.to_i) }
threads << Thread.new { stepper_y.forward(5,text.to_i) }
threads.each { |thr| thr.join }
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Sample Code
===========

Production (Moving Stepper and Servo)
-------------------------------------

Here is the real world sample code that I am using to plot

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
require 'rotor'
begin
  stepper_x = Rotor::Stepper.new(23,12,17,24,nil,13,0,157.48)
  stepper_y = Rotor::Stepper.new(25, 4,21,22,nil,19,0,157.48)
  servo = Rotor::Servo.new(18)

  stepper_x.set_home(:backwards)
  stepper_y.set_home(:backwards)

  #My threaded rods move 1 inch per 4000 steps (Stepper Motor has 200 steps/rev and    the rod has 20 threads per inch)

  stepper_x.forward(1,4000)
  stepper_y.forward(1,4000)

  gcode = Rotor::Gcode.new(stepper_x,stepper_y,nil,1,servo)
  gcode.open('output.nc')
  gcode.simulate

ensure
  servo.rotate(:up)

  stepper_x.set_home(:backwards)
  stepper_y.set_home(:backwards)
  stepper_x.forward(1,4000)
  stepper_y.forward(1,4000)

  stepper_x.power_down
  stepper_y.power_down

  [23,12,17,24,13,25,4,21,22,19,13].each do |pin|
   `echo #{pin} > /sys/class/gpio/unexport`
  end
end
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Based on the code above, my origin (0,0) is one inch from the backwards X and
one inch from the backwards Y

Development (Exporting Plot Points for Graphing)
------------------------------------------------

Before wasting more materials, I try to plot my points to a file and view them
in Excel. Within the root of this repository, there is an Excel file, called
Visual.xlsx, and you can import the output.txt into the first four columns. By
doing so, you can see the plot points and the scatter of movements. Go to the
data tab and click Refresh Data. Select the output.txt file that you generated
and it will show the plot points. If you see some crazy stray points, you can
put in a issue and I will look at it. Please include the GCode that you’re using
that is causing problems.

Keep in mind that this keeps track of the coordinates, so you will see the entry
and exit points as lines. This is expected behavior since I like to see where my
marker is entering into an object.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
File.open("output.txt", 'wb') { |file| file.write("x,y,xm,ym\n") }
gcode = Rotor::Gcode.new(nil,nil,nil,1,nil)
gcode.open('output.nc')
gcode.simulate
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

License
=======

Copyright (c) 2015 kobaltz

MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
