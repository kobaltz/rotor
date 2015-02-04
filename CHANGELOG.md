Rotor (Ruby Motor)
==================

Version 0.1.7
-------------

Updated GCode Simulator to take into account various movement delays. For example, 

- X moves 10 steps
- Y moves 100 steps
- Delays are the same

X would have finished it's movement much faster than Y.

Now, the delay will be automatically adjusted for the maximum movement and will start
and now end at the same time (hopefully).

Updated GCode Simulator to add a small delay for Z Movement (500 * Delay) milliseconds to allow time for puncture.

Version 0.1.6
-------------

The GCode Module now has an option to specify the G0 Fast Move speed. 

    Rotor::Gcode.new(stepper_x=nil,stepper_y=nil,stepper_z=nil,scale=1,servo=nil,fast_move=1)

    gcode = Rotor::Gcode.new(stepper_x,stepper_y,stepper_z,1,servo,1)

Updated the README with new examples and updated documentation.