.. _module_motion_control:

=============================
Motion Control Module 
=============================

.. contents:: In this document
    :backlinks: none
    :depth: 3

This module provides a Service (motion_control_service) to perform Torque/Velocity/Position control. This Service is recommended to be running at **100MHz Reference Clock Frequency**. After running this service, the user can select the controlling mode (either torque, velocity, or position control mode). Depending on the selected mode, motion_control_service will call the corresponding function from module_controllers to calculate the proper reference value of the torque, and calculated values of reference torque will be sent to torque control service.

.. cssclass:: github

  `See Module on Public Repository <https://github.com/synapticon/sc_sncn_motorcontrol/tree/release/module_motion_control>`_

How to use
==========

.. important:: We assume that you are using :ref:`SOMANET Base <somanet_base>` and your app includes the required **board support** files for your SOMANET device.
          
.. seealso:: 
    You might find useful the **app_demo_motion_control** example apps, which illustrate the use of this module: 
    
    * :ref:`BLDC Motion Control Demo <app_demo_bldc_motion_control>`

1. First, add all the :ref:`SOMANET Motion Control <somanet_motion_control>` modules to your app Makefile.

    ::

        USED_MODULES = module_controllers lib_bldc_torque_control module_pwm module_adc module_hall_sensor module_utils module_profiles module_incremental_encoder module_gpio module_watchdog module_board-support

    .. note:: Not all modules will be required, but when using a library it is recommended to include always all the contained modules. 
              This will help solving internal dependency issues.

2. Properly instantiate a :ref:`Torque Control Service <lib_bldc_torque_control>`.

3. Include the Motion Control Service header **motion_control_service.h** in your app. 

4. Inside your main function, instantiate the interfaces array for the Service-Clients communication.

5. Outside your IF2 tile, instantiate the Service. For that, first you will have to fill up your Service configuration and provide interfaces to your position feedback sensor Service and Torque Control Service.

6. Now you can perform calls to the Motion Control Service through the interfaces connected to it. You can do this at whichever other core. 

    .. code-block:: c

       #include <CoreC2X.bsp>   	    //Board Support file for SOMANET Core C22 device 
       #include <Drive1000-rev-c4.bsp>  //Board Support file for SOMANET IFM DC100 device 
                                        //(select your board support files according to your device)

        #include <pwm_service.h>
        #include <hall_service.h>
        #include <watchdog_service.h>
        #include <motorcontrol_service.h>
        #include <motion_control_service.h> // step 3
    
        PwmPortsGeneral pwm_ports = SOMANET_DRIVE_PWM_PORTS_GENERAL;
		WatchdogPorts wd_ports = SOMANET_DRIVE_WATCHDOG_PORTS;
		FetDriverPorts fet_driver_ports = SOMANET_DRIVE_FET_DRIVER_PORTS;
		ADCPorts adc_ports = SOMANET_DRIVE_ADC_PORTS;
		SPIPorts spi_ports = SOMANET_DRIVE_SPI_PORTS;
		HallEncSelectPort hall_enc_select_port = SOMANET_DRIVE_ENCODER_PORTS_INPUT_MODE_SELECTION;
		port ? qei_hall_port_1 = SOMANET_DRIVE_ENCODER_1_PORT;
		port ? qei_hall_port_2 = SOMANET_DRIVE_ENCODER_2_PORT;
		port ?gpio_port_0 = SOMANET_DRIVE_GPIO_D0;
		port ?gpio_port_1 = SOMANET_DRIVE_GPIO_D1;
		port ?gpio_port_2 = SOMANET_DRIVE_GPIO_D2;
		port ?gpio_port_3 = SOMANET_DRIVE_GPIO_D3;  

       int main(void)
        {

		    // Motor control interfaces
		    interface WatchdogInterface i_watchdog[2];
		    interface UpdatePWMGeneral i_update_pwm;
		    interface UpdateBrake i_update_brake;
		    interface ADCInterface i_adc[2];
		    interface TorqueControlInterface i_torque_control[2];
		    interface MotionControlInterface i_motion_control[3];
		    interface PositionFeedbackInterface i_position_feedback_1[3];
		    interface PositionFeedbackInterface i_position_feedback_2[3];
		    interface shared_memory_interface i_shared_memory[3]; 		//step 4

            par
            {
                on tile[APP_TILE]:
                {
                     demo_motion_control(i_motion_control[0]); // step 6
                }
                on tile[APP_TILE_2]:
                {
                    //step 5
                    MotionControlConfig motion_ctrl_config;
		
		            motion_ctrl_config.min_pos_range_limit =                  MIN_POSITION_RANGE_LIMIT;
		            motion_ctrl_config.max_pos_range_limit =                  MAX_POSITION_RANGE_LIMIT;
		            motion_ctrl_config.max_motor_speed =                      MOTOR_MAX_SPEED;
		            motion_ctrl_config.polarity =                             POLARITY;
		
		            motion_ctrl_config.enable_profiler =                      ENABLE_PROFILER;
		            motion_ctrl_config.max_acceleration_profiler =            MAX_ACCELERATION_PROFILER;
		            motion_ctrl_config.max_deceleration_profiler =            MAX_DECELERATION_PROFILER;
		            motion_ctrl_config.max_speed_profiler =                   MAX_SPEED_PROFILER;
		
		            motion_ctrl_config.position_control_strategy =            POSITION_CONTROL_STRATEGY;
		
		            motion_ctrl_config.filter =                               FILTER_CUT_OFF_FREQ;
		
		            motion_ctrl_config.position_kp =                          POSITION_Kp;
		            motion_ctrl_config.position_ki =                          POSITION_Ki;
		            motion_ctrl_config.position_kd =                          POSITION_Kd;
		            motion_ctrl_config.position_integral_limit =              POSITION_INTEGRAL_LIMIT;
		            motion_ctrl_config.moment_of_inertia =                    MOMENT_OF_INERTIA;
		
		            motion_ctrl_config.velocity_kp =                          VELOCITY_Kp;
		            motion_ctrl_config.velocity_ki =                          VELOCITY_Ki;
		            motion_ctrl_config.velocity_kd =                          VELOCITY_Kd;
		            motion_ctrl_config.velocity_integral_limit =              VELOCITY_INTEGRAL_LIMIT;
		            motion_ctrl_config.enable_velocity_auto_tuner =           ENABLE_VELOCITY_AUTO_TUNER;
		            motion_ctrl_config.enable_compensation_recording =        ENABLE_COMPENSATION_RECORDING;
		            motion_ctrl_config.enable_open_phase_detection =          ENABLE_OPEN_PHASE_DETECTION;
		
		            motion_ctrl_config.position_kp_l =                        GAIN_SCHEDULING_POSITION_Kp_0;
		            motion_ctrl_config.position_ki_l =                        GAIN_SCHEDULING_POSITION_Ki_0;
		            motion_ctrl_config.position_kd_l =                        GAIN_SCHEDULING_POSITION_Kd_0;
		            motion_ctrl_config.position_kp_h =                        GAIN_SCHEDULING_POSITION_Kp_1;
		            motion_ctrl_config.position_ki_h =                        GAIN_SCHEDULING_POSITION_Ki_1;
		            motion_ctrl_config.position_kd_h =                        GAIN_SCHEDULING_POSITION_Kd_1;
		            motion_ctrl_config.velocity_kp_l =                        GAIN_SCHEDULING_VELOCITY_Kp_0;
		            motion_ctrl_config.velocity_ki_l =                        GAIN_SCHEDULING_VELOCITY_Ki_0;
		            motion_ctrl_config.velocity_kd_l =                        GAIN_SCHEDULING_VELOCITY_Kd_0;
		            motion_ctrl_config.velocity_kp_h =                        GAIN_SCHEDULING_VELOCITY_Kp_1;
		            motion_ctrl_config.velocity_ki_h =                        GAIN_SCHEDULING_VELOCITY_Ki_1;
		            motion_ctrl_config.velocity_kd_h =                        GAIN_SCHEDULING_VELOCITY_Kd_1;
		            motion_ctrl_config.velocity_lo_l =                        GAIN_SCHEDULING_VELOCITY_THRESHOLD_0;
		            motion_ctrl_config.velocity_hi_l =                        GAIN_SCHEDULING_VELOCITY_THRESHOLD_1;
		
		
		            motion_ctrl_config.brake_release_strategy =               BRAKE_RELEASE_STRATEGY;
		            motion_ctrl_config.brake_release_delay =                  BRAKE_RELEASE_DELAY;
		
		            //select resolution of sensor used for motion control
		            if (SENSOR_2_FUNCTION == SENSOR_FUNCTION_COMMUTATION_AND_MOTION_CONTROL || SENSOR_2_FUNCTION == SENSOR_FUNCTION_MOTION_CONTROL) {
		                motion_ctrl_config.resolution  =                          SENSOR_2_RESOLUTION;
		            } else {
		                motion_ctrl_config.resolution  =                          SENSOR_1_RESOLUTION;
		            }
		
		            motion_ctrl_config.dc_bus_voltage=                        DC_BUS_VOLTAGE;
		            motion_ctrl_config.pull_brake_voltage=                    PULL_BRAKE_VOLTAGE;
		            motion_ctrl_config.pull_brake_time =                      PULL_BRAKE_TIME;
		            motion_ctrl_config.hold_brake_voltage =                   HOLD_BRAKE_VOLTAGE;
		
		            motion_control_service(motion_ctrl_config, i_torque_control[0], i_motion_control, i_update_brake); //5
        		}

        on tile[IF2_TILE]:
        {
            par
            {
                /* PWM Service */
                {
                    pwm_config_general(pwm_ports);

                    if (!isnull(fet_driver_ports.p_esf_rst_pwml_pwmh) && !isnull(fet_driver_ports.p_coast))
                        predriver(fet_driver_ports);

                    pwm_service_general(pwm_ports, i_update_pwm, GPWM_FRQ_15, DEADTIME_NS);

                }

                 /* ADC Service */
                {
                    adc_service(adc_ports, i_adc /*ADCInterface*/, i_watchdog[1], IF2_TILE_USEC, SINGLE_ENDED);
                }

                /* Watchdog Service */
                {
                    watchdog_service(wd_ports, i_watchdog, IF2_TILE_USEC);
                }

                /* Motor Control Service */
                {
                    MotorcontrolConfig motorcontrol_config;

                    motorcontrol_config.dc_bus_voltage =  DC_BUS_VOLTAGE;
                    motorcontrol_config.phases_inverted = MOTOR_PHASES_CONFIGURATION;
                    motorcontrol_config.torque_P_gain =  TORQUE_Kp;
                    motorcontrol_config.torque_I_gain =  TORQUE_Ki;
                    motorcontrol_config.torque_D_gain =  TORQUE_Kd;
                    motorcontrol_config.pole_pairs =  MOTOR_POLE_PAIRS;
                    motorcontrol_config.commutation_sensor=SENSOR_1_TYPE;
                    motorcontrol_config.commutation_angle_offset=COMMUTATION_ANGLE_OFFSET;
                    motorcontrol_config.max_torque =  MOTOR_MAXIMUM_TORQUE;
                    motorcontrol_config.phase_resistance =  MOTOR_PHASE_RESISTANCE;
                    motorcontrol_config.phase_inductance =  MOTOR_PHASE_INDUCTANCE;
                    motorcontrol_config.torque_constant =  MOTOR_TORQUE_CONSTANT;
                    motorcontrol_config.current_ratio =  CURRENT_RATIO;
                    motorcontrol_config.voltage_ratio =  VOLTAGE_RATIO;
                    motorcontrol_config.temperature_ratio =  TEMPERATURE_RATIO;
                    motorcontrol_config.rated_current =  MOTOR_RATED_CURRENT;
                    motorcontrol_config.rated_torque  =  MOTOR_RATED_TORQUE;
                    motorcontrol_config.percent_offset_torque =  APPLIED_TUNING_TORQUE_PERCENT;
                    motorcontrol_config.protection_limit_over_current =  PROTECTION_MAXIMUM_CURRENT;
                    motorcontrol_config.protection_limit_over_voltage =  PROTECTION_MAXIMUM_VOLTAGE;
                    motorcontrol_config.protection_limit_under_voltage = PROTECTION_MINIMUM_VOLTAGE;
                    motorcontrol_config.protection_limit_over_temperature = TEMP_BOARD_MAX;
                    for (int i = 0; i < 1024; i++)
                    {
                        motorcontrol_config.torque_offset[i] = 0;
                    }
                    torque_control_service(motorcontrol_config, i_adc[0], i_shared_memory[2],
                            i_watchdog[0], i_torque_control, i_update_pwm, IF2_TILE_USEC, /*gpio_port_0*/null);
                }

                /* Shared memory Service */
                [[distribute]] shared_memory_service(i_shared_memory, 3);

                 /* Position feedback service */
                {
                    PositionFeedbackConfig position_feedback_config;
                    position_feedback_config.sensor_type = SENSOR_1_TYPE;
                    position_feedback_config.resolution  = SENSOR_1_RESOLUTION;
                    position_feedback_config.polarity    = SENSOR_1_POLARITY;
                    position_feedback_config.velocity_compute_period = SENSOR_1_VELOCITY_COMPUTE_PERIOD;
                    position_feedback_config.pole_pairs  = MOTOR_POLE_PAIRS;
                    position_feedback_config.ifm_usec    = IF2_TILE_USEC;
                    position_feedback_config.max_ticks   = SENSOR_MAX_TICKS;
                    position_feedback_config.offset      = HOME_OFFSET;
                    position_feedback_config.sensor_function = SENSOR_1_FUNCTION;

                    position_feedback_config.biss_config.multiturn_resolution = BISS_MULTITURN_RESOLUTION;
                    position_feedback_config.biss_config.filling_bits = BISS_FILLING_BITS;
                    position_feedback_config.biss_config.crc_poly = BISS_CRC_POLY;
                    position_feedback_config.biss_config.clock_frequency = BISS_CLOCK_FREQUENCY;
                    position_feedback_config.biss_config.timeout = BISS_TIMEOUT;
                    position_feedback_config.biss_config.busy = BISS_BUSY;
                    position_feedback_config.biss_config.clock_port_config = BISS_CLOCK_PORT;
                    position_feedback_config.biss_config.data_port_number = BISS_DATA_PORT_NUMBER;
                    position_feedback_config.biss_config.data_port_signal_type = BISS_DATA_PORT_SIGNAL_TYPE;

                    position_feedback_config.rem_16mt_config.filter = REM_16MT_FILTER;

                    position_feedback_config.rem_14_config.hysteresis              = REM_14_SENSOR_HYSTERESIS;
                    position_feedback_config.rem_14_config.noise_settings          = REM_14_SENSOR_NOISE_SETTINGS;
                    position_feedback_config.rem_14_config.dyn_angle_error_comp    = REM_14_DYN_ANGLE_ERROR_COMPENSATION;
                    position_feedback_config.rem_14_config.abi_resolution_settings = REM_14_ABI_RESOLUTION_SETTINGS;

                    position_feedback_config.qei_config.number_of_channels = QEI_SENSOR_NUMBER_OF_CHANNELS;
                    position_feedback_config.qei_config.signal_type        = QEI_SENSOR_SIGNAL_TYPE;
                    position_feedback_config.qei_config.port_number        = QEI_SENSOR_PORT_NUMBER;
                    position_feedback_config.qei_config.ticks_lost_threshold = QEI_SENSOR_TICKS_LOST;

                    position_feedback_config.hall_config.port_number = HALL_SENSOR_PORT_NUMBER;
                    position_feedback_config.hall_config.hall_state_angle[0]=HALL_STATE_1_ANGLE;
                    position_feedback_config.hall_config.hall_state_angle[1]=HALL_STATE_2_ANGLE;
                    position_feedback_config.hall_config.hall_state_angle[2]=HALL_STATE_3_ANGLE;
                    position_feedback_config.hall_config.hall_state_angle[3]=HALL_STATE_4_ANGLE;
                    position_feedback_config.hall_config.hall_state_angle[4]=HALL_STATE_5_ANGLE;
                    position_feedback_config.hall_config.hall_state_angle[5]=HALL_STATE_6_ANGLE;

                    position_feedback_config.gpio_config[0] = GPIO_CONFIG_1;
                    position_feedback_config.gpio_config[1] = GPIO_CONFIG_2;
                    position_feedback_config.gpio_config[2] = GPIO_CONFIG_3;
                    position_feedback_config.gpio_config[3] = GPIO_CONFIG_4;

                    //setting second sensor
                    PositionFeedbackConfig position_feedback_config_2 = position_feedback_config;
                    position_feedback_config_2.sensor_type = 0;
                    if (SENSOR_2_FUNCTION != SENSOR_FUNCTION_DISABLED) //enable second sensor
                    {
                        position_feedback_config_2.sensor_type = SENSOR_2_TYPE;
                        position_feedback_config_2.polarity    = SENSOR_2_POLARITY;
                        position_feedback_config_2.resolution  = SENSOR_2_RESOLUTION;
                        position_feedback_config_2.velocity_compute_period = SENSOR_2_VELOCITY_COMPUTE_PERIOD;
                        position_feedback_config_2.sensor_function = SENSOR_2_FUNCTION;
                    }

                    position_feedback_service(qei_hall_port_1, qei_hall_port_2, hall_enc_select_port, spi_ports, gpio_port_0, gpio_port_1, gpio_port_2, gpio_port_3,
                            position_feedback_config, i_shared_memory[0], i_position_feedback_1,
                            position_feedback_config_2, i_shared_memory[1], i_position_feedback_2);
                }
            }
        }
    }

    return 0;
}

API
===

Definitions
-------------

.. doxygendefine:: PID_DENOMINATOR
.. doxygendefine:: POSITION_LIMIT_THRESHOLD
.. doxygendefine:: POSITION_CONTROL_LOOP_PERIOD
.. doxygendefine:: PID_DENOMINATOR
.. doxygendefine:: PID_DENOMINATOR
.. doxygendefine:: PID_DENOMINATOR

Global Types
-------------

.. doxygenstruct:: MotionControlStrategies

.. _Motion Control Config :
.. doxygenstruct:: MotionControlConfig
.. doxygenstruct:: MotionPolarity
.. doxygenstruct:: ControlConfig

Motion Control Service
````````````````````````

.. doxygenfunction:: motion_control_service
.. doxygenfunction:: init_motion_control

Position Control Interface
``````````````````````````

.. doxygeninterface:: MotionControlInterface

.. _Cogging-Torque-Feature :

Cogging Torque Feature
======================

Introduction
------------

This software also includes a cogging torque compensation feature, which enables you to remove the magnetic disturbances between the motor shaft and the stator. 
Those disturbances are in the form of a periodic load applied to the rotor (the cogging torque). This load is positive when the magnets are reppelled by the stator, and negative when they are attracted to it.
The disturbances are most present at low speed and can induce a jitter in the control of the motor.

The compensation can be done in two steps : 

-	First the controller must perform a calibration process, in which the torque necessary to remove is measured. This part needs a good velocity control of the motor at low speed (10 RPM) to work properly.
	During this process, the motor will run for two rotations in each direction.
- 	Then, if the compensation is enabled, the controller will add an offset to the torque command given to the torque control service. Since the cogging torque is periodic, the offset is equal to the one measured at the same angle of the rotor.

How to use
----------
1-  The calibration process uses the velocity controller. The first step is to enable the velocity controller with the interface **enable_velocity_ctrl()**

2-	Start the recording of the cogging torque of your motor by setting the variable  **enable_compensation_recording** to 1 in the structure `Motion Control Config`_.

3-	At the end of the measurement process, the variable **enable_compensation_recording** is automatically set to 0. You can then enable/disable the compensation of the cogging torque with the interface enable_cogging_compensation()

.. warning ::

	Warning
	-------
	Before the calibration process, make sure that the velocity PID parameters are set for a stable control at 10 RPM
	To tune the controller, feel free to use the :ref:`Tuning application <app_control_tuning>`. (Bad tuning means the motor turns visibly step by step, stopping from time to time)

	Once the cogging torque is calibrated for a motor, the calibration table is saved into the falsh memory. It is possible to enable/disable the compensation without doing the calibration another time. 

	Before doing the calibration, be sure that the compensation is disabled, otherwise the measures will be altered.

Example
-------
    .. code-block:: c
    

        void cogging_torque_compensation(client interface MotionControlInterface i_motion_control)
        {
            DownstreamControlData downstream_control_data = {0};

            MotionControlConfig motion_ctrl_config = i_motion_control.get_motion_control_config();

            //*****************************//
            // 1) First step : Calibration //
            //*****************************//
            i_motion_control.enable_velocity_ctrl();                            //the calibration process uses the velocity controller 

            motion_ctrl_config = i_motion_control.get_motion_control_config(); 
            motion_ctrl_config.enable_compensation_recording = 1;               //set the flag to 'enable'
            i_motion_control.set_motion_control_config(motion_ctrl_config);

            while (motion_ctrl_config.enable_compensation_recording)            //check regularly if the flag is set to '0', which indicates the end of the process
            {                                                                   //do not give other commands to the motor that would risk to influence the measurement
                motion_ctrl_config = i_motion_control.get_motion_control_config();
                delay_milliseconds(1);
            }

            //*******************************//
            // 2) Second step : Compensation //
            //*******************************//
            i_motion_control.enable_cogging_compensation(1);                    //use the previous calibration to compensate the cogging torque
            i_motion_control.enable_torque_ctrl();
            downstream_control_data.torque_cmd = 0;

        }
