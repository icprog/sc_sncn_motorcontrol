.. _app_test_hall:

=================================
Hall Sensor Demo
=================================

.. contents:: In this document
    :backlinks: none
    :depth: 3

The purpose of this app is showing the use of the :ref:`Hall Sensor Module <module_hall>` with :ref:`Position Feedback Module <module_position_feedback>`.
For that, it implements a simple app that reads the output of a Hall sensor and shows over **XScope** the read velocity and position.

* **Min. Nr. of cores**: 2
* **Min. Nr. of tiles**: 1

Quick How-to
============

1. :ref:`Assemble your SOMANET device <assembling_somanet_node>`.
2. Wire up your device. Check how at your specific :ref:`hardware documentation <hardware>`. Connect your sensor, power supply cable, and XTAG. Power up!
3. :ref:`Set up your XMOS development tools <getting_started_xmos_dev_tools>`.
4. Download and :ref:`import in your workspace <getting_started_importing_library>` the SOMANET Motor Control Library and its dependencies.
5. Open the **main.xc** within  the app. Include the :ref:`board-support file according to your device <somanet_board_support_module>`. Also set the :ref:`appropriate target in your Makefile <somanet_board_support_module>`.

.. important:: Make sure the SOMANET Motor Control Library supports your SOMANET device. For that, check the :ref:`Hardware compatibility <motor_control_hw_compatibility>` section of the library.

6. Again in your **main.xc**, set the configuration for the Position feedback Service and you sensor.

    .. code-block:: c

            on tile[IFM_TILE]:
            /* Position feedback service */
            {
                PositionFeedbackConfig position_feedback_config;
                position_feedback_config.sensor_type = HALL_SENSOR;
                position_feedback_config.resolution  = HALL_SENSOR_RESOLUTION;
                position_feedback_config.polarity    = NORMAL_POLARITY;
                position_feedback_config.velocity_compute_period = HALL_SENSOR_VELOCITY_COMPUTE_PERIOD;
                position_feedback_config.pole_pairs  = POLE_PAIRS;
                position_feedback_config.ifm_usec    = IFM_TILE_USEC;
                position_feedback_config.max_ticks   = SENSOR_MAX_TICKS;
                position_feedback_config.offset      = 0;
                position_feedback_config.sensor_function = SENSOR_FUNCTION_COMMUTATION_AND_MOTION_CONTROL;

                position_feedback_config.hall_config.port_number = HALL_SENSOR_PORT_NUMBER;

                position_feedback_service(qei_hall_port_1, qei_hall_port_2, null, null, null, null, null, null,
                        position_feedback_config, i_shared_memory[0], i_position_feedback,
                        null, null, null);
            }

7. In parallel, the position/velocity and others status info are displayed with XScope.

    .. code-block:: c
        
        on tile[APP_TILE]:
        {
            int angle = 0;
            int velocity = 0;
            int count = 0;

            while(1)
            {
                /* get position from Hall Sensor */
                { count, void, void } = i_position_feedback.get_position();
                angle = i_position_feedback.get_angle();

                /* get velocity from Hall Sensor */
                velocity = i_position_feedback.get_velocity();

                if (!isnull(i_shared_memory)) {
                    UpstreamControlData upstream_control_data = i_shared_memory.read();
                    angle = upstream_control_data.angle;
                    count = upstream_control_data.position;
                    velocity = upstream_control_data.velocity;
                }

                xscope_int(COUNT, count);
                xscope_int(VELOCITY, velocity);
                xscope_int(ANGLE, angle);
            }
        }


8. :ref:`Run the application enabling XScope <running_an_application>`.

.. seealso:: Did everything go well? If you need further support please check out our `forum <http://forum.synapticon.com/>`_.
