.. _app_control_tuning:

====================================================
Commutation angle offset and PID gains tuning helper
====================================================

.. contents:: In this document
    :backlinks: none
    :depth: 3

The purpose of this application is finding the commutation angle offset to be able to turn the motor, and the the PID setting for position and velocity controllers.

This is a console app which use simple command of 1, 2 or 3 characters and an optional value.

The app also displays various data in real time with `XScope`

* **Minimum Number of Cores**: 7
* **Minimum Number of Tiles**: 3

Console commands
================

The app uses commands up to 3 characters with an optional value. The command are executed by pressing enter. If no value is entered the default is `0`:

- ``ao``: start the auto offset tuning. It automatically update the offset field display. If the offset detection fails the offset will be -1. If it displays "WRONG POSITION SENSOR POLARITY" you need to change the sensor polarity of ``position_feedback_service()`` and recompile the app. After the offset is found you need to make sure that a positive torque command result in a positive velocity/position increment. Otherwise the position and velocity controller will not work.
- ``av``: starts the automatic tuning of velocity controller. By default, the motor will start to rotate at a speed close to 1000 rpm for 1.5 second, and after that the PID parameters of velocity controller will be updated. These parameters will also be printed on the screen.
- ``ap2``: starts the automatic tuning of position controller with cascaded structure. Once this command is sent, the motor starts to move forward and backward, and the PID parameters of position controller with cascaded structure will be optimized. This procedure could last up to 4 minutes, and by the end of this procedure the optimized parameters of PID controllers for inner loop (velocity controller) and outer loop (position controller) will be updated in the software (and printed on the console). Depending on load type further fine tuning might be required by the user. 
- ``ap3``: starts the automatic tuning of position controller with limited-torque structure. Once this command is sent, the motor starts to move forward and backward, and the PID parameters of position controller with limited torque structure will be optimized. This procedure could last up to 4 minutes, and by the end of this procedure the optimized parameters of PID controller will be updated in the software (and printed on the console). Depending on load type further fine tuning might be required by the user. In this case increase all PID constants with the same ratio to sharpen the control, or reduce them all with the same ratio to make the controller smoother.
- ``kp``: print the position PID parameters
- ``kpp [number]``: set the P coefficient of the Position controller.
- ``kpi [number]``: set the I coefficient of the Position controller.
- ``kpd [number]``: set the D coefficient of the Position controller.
- ``kpl [number]``: set the Integral part limit the Position controller.
- ``kpj [number]``: set the Moment of inertia of the Position controller.
- ``kv``: print the velocity PID parameters
- ``kvp [number]``: set the P coefficient of the Velocity controller.
- ``kvi [number]``: set the I coefficient of the Velocity controller.
- ``kvd [number]``: set the D coefficient of the Velocity controller.
- ``kpl [number]``: set the Integral part limit the Velocity controller.
- ``L``: print the limits
- ``Lp [number]``:  set both the maximum and minimum position limit to [number] and -[number]. The motorcontrol will be automatically disable when the position limit is reached. You can use this feature if your axis has a limited movement. If you are past the limits move the axis manually (use b and tss to unlock the motor) or restart position/velocity/torque controller in the right direction (the position limiter has a threshold to allow to restart if the motor is right after the limit).
- ``Lpu [number]``: set the maximum position limit.
- ``Lpl [number]``: set the minimum position limit.
- ``Lt [number]``: set the torque limit. The unit in in 1/1000 of rated torque. This command stops the motorcontrol.
- ``Lv [number]``: set the velocity limit. Used in velocity control and in cascaded and limited-torque position control modes.
- ``ep1``: enable position control with simple PID controller
- ``ep2``: enable position control with velocity cascaded controller
- ``ep3``: enable position control with limited-torque controller
- ``ev1``: enable velocity control 
- ``et1``: enable torque control 
- ``p``: set a position command (the position controller need to be started first)
- ``pp``: set a position command with profiler
- ``ps``: do a position step command
- ``psp``: do a position step command with profiler
- ``v``: set a velocity command (the velocity controller need to be started first)
- ``vs``: do a velocity step command
- ``vsp``: do a velocity step command with profiler
- ``t``: set a torque command (the torque controller need to be started first)
- ``ts``: do a torque step command
- ``tp``: set a torque command with profiler
- ``tsp``: do a torque step command with profiler
- ``tss``: activate the torque safe mode. in this mode all the phases are disconnected and the motor can turn freely (usefull if you want to turn it by hand).
- ``r``: reverse the current torque or velocity command
- ``d``: toggle the motion polarity. It reverse the position/velocity/torque commands and feedback in the motion controller. Which will make you motor turn the other direction.
- ``j``: print profilers parameters
- ``ja``: set profiler acceleration
- ``jd``: set profiler deceleration
- ``jv``: set profiler speed
- ``jt``: set profiler maximum torque
- ``b``: toggle the brake state between blocking and released.
- ``bs``: set the brake release strategy parameter. 0 is to disable the brake. 1 to enable normal release. and 2 to 100
- ``bvn``: set the nominal voltage of dc-bus in Volts
- ``bvp``: set the pull voltage for releasing the brake at startup in millivolts
- ``bvh``: set the hold voltage for holding the brake after it is pulled in millivolts
- ``bt``: set the pull time of the brake
- ``o``: print the commutation offset
- ``os``: set the commutation offset
- ``op``: set the offset detection torque percentage. increase it you motor is loaded or has a lot of friction (it will also increase the current consumption).
- ``f``: reset the motorcontrol fault. If the motor stops because of over/under current. Try adjusting you power supply
- ``h``: print some help
- ``[enter]``: disable the motorcontrol (can be use as an emergency stop)

XScope display
==============
The data displayed with XScope is:

- Position
- Velocity
- Torque
- secondary position (if you have a second sensor)
- secondary velocity (if you have a second sensor)
- position command
- velocity command
- torque command
- fault code: motorcontrol fault code (the value is multiplied by 1000 for better display)
- sensor error: the sensor error code (the value is multiplied by 100 for better display)
- V DC: the DC bus voltage
- I DC: the DC bus current
- temperature


You can use trigger on position/velocity/torque value and step command to test the reaction of the controller and tune the PID settings.


Quick How-to
============

#. :ref:`Assemble your SOMANET device <assembling_somanet_node>`.
#. Wire up your device. Check how at your specific :ref:`hardware documentation <hardware>`. Connect your position sensor, motor phases, power supply cable, and XTAG. Power up!

   .. important:: For safety please use a current limited power supply and always monitor the current consumption during the tuning procedure.

#. :ref:`Set up your XMOS development tools <getting_started_xmos_dev_tools>`.
#. Download and :ref:`import in your workspace <getting_started_importing_library>` the SOMANET Motor Control Library and its dependencies.
#. Edit **user_config.h** in **configuration_parameters** to set the motor and sensor parameters. The motor parameters are in **motor_config.h** and the sensor parameters in **sensor_config.h**.

  In  **user_config.h** you need to specify the sensors you want to use for commutation and motion control using by setting `SENSOR_x_FUNCTION`. You can use up to 2 sensors.

  For each sensor you need to set:

  - `SENSOR_x_TYPE`
  - `SENSOR_x_FUNCTION`
  - `SENSOR_x_RESOLUTION`
  - `SENSOR_x_VELOCITY_COMPUTE_PERIOD`
  - `SENSOR_x_POLARITY`

  For exemple here we set the `Sensor 1` as `REM 16MT`. We set the sensor function to both commutation and motion control. We set the resolution. We set the velocity compute period to the default value for this sensor (can be found in **sensor_config.h**). And we set the polarity to normal. We don't need a second sensor so we set the second sensor function to disabled.

   .. code-block:: C
                
                // SENSOR 1 TYPE [HALL_SENSOR, REM_14_SENSOR, REM_16MT_SENSOR, BISS_SENSOR]
                #define SENSOR_1_TYPE                     REM_16MT_SENSOR//HALL_SENSOR

                // FUNCTION OF SENSOR_1 [ SENSOR_FUNCTION_DISABLED, SENSOR_FUNCTION_COMMUTATION_AND_MOTION_CONTROL,
                //                        SENSOR_FUNCTION_COMMUTATION_AND_FEEDBACK_DISPLAY_ONLY,
                //                        SENSOR_FUNCTION_MOTION_CONTROL, SENSOR_FUNCTION_FEEDBACK_DISPLAY_ONLY
                //                        SENSOR_FUNCTION_COMMUTATION_ONLY]
                // Only one sensor can be selected for commutation, motion control or feedback display only
                #define SENSOR_1_FUNCTION                 SENSOR_FUNCTION_COMMUTATION_AND_MOTION_CONTROL

                // RESOLUTION (TICKS PER TURN) OF SENSOR_1
                #define SENSOR_1_RESOLUTION               REM_16MT_SENSOR_RESOLUTION

                // VELOCITY COMPUTE PERIOD (ALSO POLLING RATE) OF SENSOR_1 (in microseconds)
                #define SENSOR_1_VELOCITY_COMPUTE_PERIOD  REM_16MT_SENSOR_VELOCITY_COMPUTE_PERIOD

                // POLARITY OF SENSOR_1 SENSOR [1,-1]
                #define SENSOR_1_POLARITY                 SENSOR_POLARITY_NORMAL

                // SENSOR 2 TYPE [HALL_SENSOR, REM_14_SENSOR, REM_16MT_SENSOR, BISS_SENSOR]
                #define SENSOR_2_TYPE                     REM_16MT_SENSOR//HALL_SENSOR

                // FUNCTION OF SENSOR_2 [ SENSOR_FUNCTION_DISABLED, SENSOR_FUNCTION_COMMUTATION_AND_MOTION_CONTROL,
                //                        SENSOR_FUNCTION_COMMUTATION_AND_FEEDBACK_DISPLAY_ONLY,
                //                        SENSOR_FUNCTION_MOTION_CONTROL, SENSOR_FUNCTION_FEEDBACK_DISPLAY_ONLY
                //                        SENSOR_FUNCTION_COMMUTATION_ONLY]
                // Only one sensor can be selected for commutation, motion control or feedback display only
                #define SENSOR_2_FUNCTION                 SENSOR_FUNCTION_DISABLED

                // RESOLUTION (TICKS PER TURN) OF SENSOR_2
                #define SENSOR_2_RESOLUTION               HALL_SENSOR_RESOLUTION

                // VELOCITY COMPUTE PERIOD (ALSO POLLING RATE) OF SENSOR_2 (in microseconds)
                #define SENSOR_2_VELOCITY_COMPUTE_PERIOD  HALL_SENSOR_VELOCITY_COMPUTE_PERIOD

                // POLARITY OF SENSOR_2 SENSOR [1,-1]
                #define SENSOR_2_POLARITY                 SENSOR_POLARITY_NORMAL



#. Open the **main.xc** within  the **app_control_tuning**. Include the :ref:`board-support file according to your device <somanet_board_support_module>`. Also set the :ref:`appropiate target in your Makefile <somanet_board_support_module>`.

   .. important:: Make sure the SOMANET Motor Control Library supports your SOMANET device. For that, check the :ref:`Hardware compatibility <motor_control_hw_compatibility>` section of the library.


#. :ref:`Run the application enabling XScope <running_an_application>`.

#. When the app start you can check if the motor control and sensor error are `0` and maybe turn the motor manually to see if the position and velocity feedback are working

   Use the ``a`` command to start the offset detection. This should make the motor turn slowly in both direction for maximum one minute. When it is finished the 
   offset is printed. If the motor does not move or with difficulty try increasing the offset detection torque with the ``op`` command. If it displays "WRONG 
   POSITION SENSOR POLARITY" you need to change the sensor polarity of ``position_feedback_service()`` and recompile the app. You can try to run the offset 
   detection several time to see if you get similar result. After the offset is found you need to make sure that a positive torque command result in a positive 
   velocity/position increment. Otherwise the position and velocity controller will not work. You can tune the offset manually with the ``os`` command.

   Then you can use the command starting with `k` to tune the position and velocity controllers. There are tutorials on the `documentation <https://doc.synapticon.com/tutorials/index.html>`_

   .. important:: When you have found the offset and PID parameters save them in your **user_config.h** file for your app

.. seealso:: Did everything go well? If you need further support please check out our `forum <http://forum.synapticon.com/>`_.
