/**
 * @file  position_ctrl_server.xc
 * @brief Position Control Loop Server Implementation
 * @author Synapticon GmbH <support@synapticon.com>
*/
#include <xs1.h>
#include <xscope.h>
#include <print.h>
#include <stdlib.h>

#include <controllers_lib.h>

#include <position_ctrl_service.h>
#include <a4935.h>
#include <mc_internal_constants.h>
#include <filters_lib.h>
#include <stdio.h>



void init_position_control(interface PositionControlInterface client i_position_control)
{
    int ctrl_state;

    while (1) {
        ctrl_state = i_position_control.check_busy();
        if (ctrl_state == INIT_BUSY) {
            i_position_control.enable_position_ctrl();
        }

        if (ctrl_state == INIT) {
#ifdef debug_print
            printstrln("position_ctrl_service: position control initialized");
#endif
            break;
        }
    }
}

int position_limit(int position, int max_position_limit, int min_position_limit)
{
    if (position > max_position_limit) {
        position = max_position_limit;
    } else if (position < min_position_limit) {
        position = min_position_limit;
    }
    return position;
}

void position_control_service(ControlConfig &position_control_config,
                              interface MotorcontrolInterface client i_motorcontrol,
                              interface PositionControlInterface server i_position_control[3])
{
    int actual_position = 0;
    int target_position = 0;
    int error_position = 0;
    int error_position_D = 0;
    int error_position_I = 0;
    int previous_error = 0;
    int position_control_out = 0;

    unsigned T_s_desired = 1000; //us


    //Joint Torque Control
//    int i1_torque_j_ref = 0;
    int f1_torque_j_lim = 50000;
//    float f1_torque_j_sens_measured = 0;
    int i1_torque_j_sens_offset = 0;
    int i1_torque_j_sens_offset_accumulator = 0;

    PIDparam velocity_control_pid_param;
    int int16_velocity_k = 0;
    int int16_velocity_ref_k = 0;
    int int16_velocity_cmd_k = 0;

    int int16_position_k = 0;
    int int16_position_ref_k = 0;

    timer t;
    unsigned int ts;

    int activate = 0;

    int config_update_flag = 1;

//    int i=0;
//    int offset=0;

//    MotorcontrolConfig motorcontrol_config;

    printstr(">>   SOMANET POSITION CONTROL SERVICE STARTING...\n");


    if (position_control_config.cascade_with_torque == 1) {
        i_motorcontrol.set_torque(0);
        delay_milliseconds(10);
        for (int i=0 ; i<2000; i++) {
            delay_milliseconds(1);
            i1_torque_j_sens_offset_accumulator += (i_motorcontrol.get_torque_actual());
        }
        i1_torque_j_sens_offset = i1_torque_j_sens_offset_accumulator / 2000;
        i_motorcontrol.set_voltage(0);
        printstrln(">>   POSITION CONTROL CASCADED WITH TORQUE");
    }

    t :> ts;

    pid_init(/*i1_P*/0, /*i1_I*/0, /*i1_D*/0, /*i1_P_error_limit*/0,
             /*i1_I_error_limit*/0, /*i1_itegral_limit*/0, /*i1_cmd_limit*/0, /*i1_T_s*/1000, velocity_control_pid_param);


    i_motorcontrol.set_offset_value(2440);
    delay_milliseconds(2000);
    i_motorcontrol.set_torque_control_enabled();
    delay_milliseconds(1000);

    while(1) {
#pragma ordered
        select {
            case t when timerafter(ts + USEC_STD * position_control_config.control_loop_period) :> ts:

                if (activate == 1) {
                        /* PID Controller */

                    int16_velocity_ref_k = int16_position_ref_k;

                    int16_velocity_k = i_motorcontrol.get_velocity_actual();

                    int16_velocity_cmd_k = pid_update(int16_velocity_ref_k, int16_velocity_k, 1000, velocity_control_pid_param);

                    i_motorcontrol.set_torque(int16_velocity_cmd_k);

                } // end control activated

                        xscope_int(VELOCITY_REF, int16_velocity_ref_k);
                        xscope_int(VELOCITY, int16_velocity_k);
                        xscope_int(VELOCITY_CMD, int16_velocity_cmd_k);

                break;

            case i_motorcontrol.notification():
                break;

            case i_position_control[int i].set_position(int in_target_position):
                    int16_position_ref_k = in_target_position;
                break;

            case i_position_control[int i].set_velocity_pid_coefficients(int int8_Kp, int int8_Ki, int int8_Kd):
                pid_set_coefficients(int8_Kp, int8_Ki, int8_Kd, velocity_control_pid_param);
                break;

            case i_position_control[int i].set_velocity_pid_limits(int int16_P_error_limit, int int16_I_error_limit, int int16_itegral_limit, int int16_cmd_limit):
                pid_set_limits(int16_P_error_limit, int16_I_error_limit, int16_itegral_limit, int16_cmd_limit, velocity_control_pid_param);
                break;

            case i_position_control[int i].set_torque_limit(int in_torque_limit):
                break;

            case i_position_control[int i].get_position() -> int out_position:
                break;

            case i_position_control[int i].get_target_position() -> int out_target_position:
                break;

            case i_position_control[int i].set_position_control_config(ControlConfig in_params):
                break;

            case i_position_control[int i].get_position_control_config() ->  ControlConfig out_config:
                break;

            case i_position_control[int i].set_position_sensor(int in_sensor_used):
                break;

            case i_position_control[int i].check_busy() -> int out_activate:
                break;

            case i_position_control[int i].enable_position_ctrl():
                    activate = 1;
                break;

            case i_position_control[int i].disable_position_ctrl():
                    activate = 0;
                break;
        }
    }
}
