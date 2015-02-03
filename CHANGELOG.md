Rotor (Ruby Motor)
==================

Version 0.1.6
-------------

The GCode Module now has an option to specify the G0 Fast Move speed. 

    Rotor::Gcode.new(stepper_x=nil,stepper_y=nil,stepper_z=nil,scale=1,servo=nil,fast_move=1)

    gcode = Rotor::Gcode.new(stepper_x,stepper_y,stepper_z,1,servo,1)

Updated the README with new examples and updated documentation.