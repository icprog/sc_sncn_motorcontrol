/* INCLUDE BOARD SUPPORT FILES FROM module_board-support */
#include <CORE_C22-rev-a.inc>
#include <IFM_DC100-rev-b.inc>

/**
 * @file test_velocity-ctrl.xc
 * @brief Test illustrates usage of profile velocity control
 * @author Synapticon GmbH (www.synapticon.com)
 */

//BLDC Motor drive libs
#include <qei_service.h>
#include <hall_service.h>
#include <pwm_service.h>
#include <watchdog_service.h>
#include <motorcontrol_service.h>

//Position control + profiler libs
#include <velocity_ctrl_service.h>
#include <profile_control.h>

//Configuration
#include <user_config.h>
#include <control_config.h>

PwmPorts pwm_ports = SOMANET_IFM_PWM_PORTS;
WatchdogPorts wd_ports = SOMANET_IFM_WATCHDOG_PORTS;
FetDriverPorts fet_driver_ports = SOMANET_IFM_FET_DRIVER_PORTS;
HallPorts hall_ports = SOMANET_IFM_HALL_PORTS;
QEIPorts qei_ports = SOMANET_IFM_QEI_PORTS;

/* Test Profile Velocity function */
void profile_velocity_test(interface VelocityControlInterface client i_velocity_control)
{
	int target_velocity = 30;	 		// rpm
	int acceleration 	= 1000;			// rpm/s
	int deceleration 	= 1000;			// rpm/s

	ProfileVelocityConfig profile_velocity_config;
	profile_velocity_config.max_profile_velocity = MAX_PROFILE_VELOCITY;
	profile_velocity_config.max_acceleration = MAX_ACCELERATION;
	profile_velocity_config.quick_stop_deceleration = MAX_ACCELERATION;

	/* Initialise the velocity profile generator */
	init_velocity_profiler(profile_velocity_config, i_velocity_control);

	/* Set new target velocity for profile velocity control */
	set_profile_velocity(target_velocity, acceleration, deceleration, i_velocity_control);
}

int main(void)
{
	chan c_pwm_ctrl;     // pwm channel

	interface WatchdogInterface i_watchdog[2];
    interface HallInterface i_hall[5];
    interface QEIInterface i_qei[5];
    interface MotorcontrolInterface i_motorcontrol[5];

    interface VelocityControlInterface i_velocity_control[3];

	par
	{

		/* Test Profile Velocity function */
		on tile[APP_TILE]: profile_velocity_test(i_velocity_control[0]);            // test PVM on node

		/* XScope monitoring */
		on tile[APP_TILE]:
		{
		    int target_velocity, actual_velocity;

		    while(1) {

		        actual_velocity = i_velocity_control[1].get_velocity();
		        target_velocity = i_velocity_control[1].get_set_velocity();

		        xscope_int(TARGET_VELOCITY, target_velocity);
		        xscope_int(ACTUAL_VELOCITY, actual_velocity);

		        delay_microseconds(1);
		    }
		}

		on tile[APP_TILE]:
		{

            /* Velocity Control Loop */
            {
                ControlConfig velocity_ctrl_params;
                /* Initialize PID parameters for Velocity Control (defined in config/motor/bldc_motor_config.h) */
                init_velocity_control_config(velocity_ctrl_params);

                /* Control Loop */
                velocity_control_service(velocity_ctrl_params, i_hall[1], i_qei[1], i_motorcontrol[0],
                                            i_velocity_control);
            }
		}

		/************************************************************
		 * IFM_CORE
		 ************************************************************/
		on tile[IFM_TILE]:
		{
		    par
            {
                /* PWM Loop */
                pwm_service(pwm_ports, c_pwm_ctrl);

                /* Watchdog Server */
                watchdog_service(wd_ports, i_watchdog);

                /* Hall sensor Service */
                {
                    HallConfig hall_config;
                        hall_config.pole_pairs = POLE_PAIRS;

                    hall_service(hall_ports, hall_config, i_hall);
                }

                /* Quadrature encoder sensor Service */
                 {
                     QEIConfig qei_config;
                         qei_config.signal_type = QEI_SIGNAL_TYPE;               // Encoder signal type (just if applicable)
                         qei_config.index_type = QEI_INDEX_TYPE;                 // Indexed encoder?
                         qei_config.ticks_resolution = ENCODER_RESOLUTION;       // Encoder resolution
                         qei_config.sensor_polarity = QEI_SENSOR_POLARITY;       // CW

                     qei_service(qei_ports, qei_config, i_qei);
                 }

                 /* Motor Commutation Service */
                 {
                     MotorcontrolConfig motorcontrol_config;
                         motorcontrol_config.motor_type = BLDC_MOTOR;
                         motorcontrol_config.bldc_winding_type = BLDC_WINDING_TYPE;
                         motorcontrol_config.hall_offset_clk =  COMMUTATION_OFFSET_CLK;
                         motorcontrol_config.hall_offset_cclk = COMMUTATION_OFFSET_CCLK;
                         motorcontrol_config.commutation_loop_period =  COMMUTATION_LOOP_PERIOD;

                     motorcontrol_service(fet_driver_ports, motorcontrol_config,
                                             c_pwm_ctrl, i_hall[0], i_qei[0], i_watchdog[0], i_motorcontrol);
                 }
            }
		}
	}

	return 0;
}
