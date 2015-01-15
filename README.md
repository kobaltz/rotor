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

# Usage

  The goal of this gem is to make controlling your robotics easier than
  other solutions.

    stepper_x = Rotor::Stepper.new(4,17,23,24,18)
    stepper_y = Rotor::Stepper.new(25,12,16,21,18)
    
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
