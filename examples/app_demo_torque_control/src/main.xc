/* PLEASE REPLACE "CORE_BOARD_REQUIRED" AND "DRIVE_BOARD_REQUIRED" WITH AN APPROPRIATE BOARD SUPPORT FILE FROM module_board-support */
#include <CORE_BOARD_REQUIRED>
#include <DRIVE_BOARD_REQUIRED>

/**
 * @file main.xc
 * @brief Demo application illustrates usage of lib_bldc_torque_control
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <user_interface_service.h>
#include <pwm_server.h>
#include <pwm_ports.h>
#include <adc_service.h>
#include <user_config.h>
#include <motor_control_interfaces.h>
#include <advanced_motor_control.h>
#include <position_feedback_service.h>

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

#define POSITION_LIMIT 5000000 //+/- 4095

int main(void) {

    // Motor control interfaces
    interface WatchdogInterface i_watchdog[2];
    interface UpdateBrake i_update_brake;
    interface ADCInterface i_adc[2];
    interface TorqueControlInterface i_torque_control[2];
    interface shared_memory_interface i_shared_memory[3];
    interface PositionFeedbackInterface i_position_feedback_1[3];
    interface PositionFeedbackInterface i_position_feedback_2[3];
    interface UpdatePWMGeneral i_update_pwm;

    par
    {
        /* WARNING: only one blocking task is possible per tile. */
        /* Waiting for a user input blocks other tasks on the same tile from execution. */
        on tile[APP_TILE]: demo_torque_control(i_torque_control[0], i_update_brake);

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
