/*
 * tuning.xc
 *
 *  Created on: Jul 13, 2015
 *      Author: Synapticon GmbH
 */
#include <tuning.h>
#include <stdio.h>
#include <ctype.h>

int auto_offset(interface MotorcontrolInterface client i_motorcontrol)
{
    printf("Sending offset_detection command ...\n");
    i_motorcontrol.set_offset_detection_enabled();

    while(i_motorcontrol.set_calib(0)==-1) delay_milliseconds(50);//wait until offset is detected

    int offset=i_motorcontrol.set_calib(0);
    printf("Detected offset is: %i\n", offset);
    //    printf(">>  CHECK PROPER OFFSET POLARITY ...\n");
    int proper_sensor_polarity=i_motorcontrol.get_sensor_polarity_state();
    if(proper_sensor_polarity == 1) {
        printf(">>  PROPER POSITION SENSOR POLARITY ...\n");
    } else {
        printf(">>  WRONG POSITION SENSOR POLARITY ...\n");
    }
    return offset;
}


void demo_torque_position_velocity_control(client interface PositionVelocityCtrlInterface i_position_control)
{
    delay_milliseconds(500);
    printf(">>   SOMANET PID TUNING SERVICE STARTING...\n");

    DownstreamControlData downstream_control_data;
    PosVelocityControlConfig pos_velocity_ctrl_config;

    MotorcontrolConfig motorcontrol_config;
    int proper_sensor_polarity=0;
    int offset=0;

    int velocity_running = 0;
    int velocity = 0;

    int torque = 0;
    int brake_flag = 0;
    int period_us;     // torque generation period in micro-seconds
    int pulse_counter; // number of generated pulses
    int torque_control_flag = 0;

    fflush(stdout);
    //read and adjust the offset.
    while (1)
    {
        char mode = '@';
        char mode_2 = '@';
        char mode_3 = '@';
        char c;
        int value = 0;
        int sign = 1;
        //reading user input.
        while((c = getchar ()) != '\n')
        {
            if(isdigit(c)>0)
            {
                value *= 10;
                value += c - '0';
            }
            else if (c == '-')
            {
                sign = -1;
            }
            else if (c != ' ')
            {
                if (mode == '@')
                {
                    mode = c;
                }
                else if (mode_2 == '@')
                {
                    mode_2 = c;
                }
                else
                {
                    mode_3 = c;
                }
            }
        }
        value *= sign;

        switch(mode)
        {
        //position commands
        case 'p':
                downstream_control_data.offset_torque = 0;
                downstream_control_data.position_cmd = value;
                pos_velocity_ctrl_config = i_position_control.get_position_velocity_control_config();
                switch(mode_2)
                {
                //direct command with profile
                case 'p':
                        //bug: the first time after one p# command p0 doesn't use the profile; only the way back to zero
                        pos_velocity_ctrl_config.enable_profiler = 1;
                        i_position_control.set_position_velocity_control_config(pos_velocity_ctrl_config);
                        printf("Go to %d with profile\n", value);
                        i_position_control.update_control_data(downstream_control_data);
                        break;
                //step command (forward and backward)
                case 's':
                        switch(mode_3)
                        {
                        //with profile
                        case 'p':
                                pos_velocity_ctrl_config.enable_profiler = 1;
                                printf("position cmd: %d to %d with profile\n", value, -value);
                                break;
                        //without profile
                        default:
                                pos_velocity_ctrl_config.enable_profiler = 0;
                                printf("position cmd: %d to %d\n", value, -value);
                                break;
                        }
                        i_position_control.set_position_velocity_control_config(pos_velocity_ctrl_config);
                        downstream_control_data.offset_torque = 0;
                        downstream_control_data.position_cmd = value;
                        i_position_control.update_control_data(downstream_control_data);
                        delay_milliseconds(1500);
                        downstream_control_data.position_cmd = -value;
                        i_position_control.update_control_data(downstream_control_data);
                        delay_milliseconds(1500);
                        downstream_control_data.position_cmd = 0;
                        i_position_control.update_control_data(downstream_control_data);
                        break;
                //direct command
                default:
                        pos_velocity_ctrl_config.enable_profiler = 0;
                        i_position_control.set_position_velocity_control_config(pos_velocity_ctrl_config);
                        printf("Go to %d\n", value);
                        i_position_control.update_control_data(downstream_control_data);
                        break;
                }
                break;

        //velocity commands
        case 'v':
                switch(mode_2)
                {
                //step command (forward and backward)
                case 's':
                        printf("velocity cmd: %d to %d\n", value, -value);
                        downstream_control_data.offset_torque = 0;
                        downstream_control_data.velocity_cmd = value;
                        i_position_control.update_control_data(downstream_control_data);
                        delay_milliseconds(1000);
                        downstream_control_data.velocity_cmd = -value;
                        i_position_control.update_control_data(downstream_control_data);
                        delay_milliseconds(1000);
                        downstream_control_data.velocity_cmd = 0;
                        i_position_control.update_control_data(downstream_control_data);
                        break;
                //direct command
                default:
                        if(value==0)
                            velocity_running = 0;
                        else
                            velocity_running = 1;
                        downstream_control_data.offset_torque = 0;
                        velocity = value;
                        downstream_control_data.velocity_cmd = velocity;
                        i_position_control.update_control_data(downstream_control_data);
                        printf("set velocity %d\n", downstream_control_data.velocity_cmd);
                        break;
                }
                break;

        //enable and disable torque controller
        case 't':
                downstream_control_data.offset_torque = 0;
                downstream_control_data.torque_cmd = value;
                i_position_control.update_control_data(downstream_control_data);
                printf("torque command %d milli-Nm\n", downstream_control_data.torque_cmd);
                break;

        //reverse torque
        case 'r':
                downstream_control_data.torque_cmd = -downstream_control_data.torque_cmd;
//                if(velocity_running)
//                {
//                    velocity = -velocity;
//                    downstream_control_data.offset_torque = 0;
//                    downstream_control_data.velocity_cmd = velocity;
//                    i_position_control.update_control_data(downstream_control_data);
//                }
                i_position_control.update_control_data(downstream_control_data);
                printf("torque command %d milli-Nm\n", downstream_control_data.torque_cmd);
                break;

        //pid coefficients
        case 'k':
                pos_velocity_ctrl_config = i_position_control.get_position_velocity_control_config();
                switch(mode_2)
                {
                case 'p': //position
                        switch(mode_3)
                        {
                        case 'p':
                                pos_velocity_ctrl_config.P_pos = value;
                                break;
                        case 'i':
                                pos_velocity_ctrl_config.I_pos = value;
                                break;
                        case 'd':
                                pos_velocity_ctrl_config.D_pos = value;
                                break;
                        case 'l':
                                pos_velocity_ctrl_config.integral_limit_pos = value;
                                break;
                        case 'j':
                                pos_velocity_ctrl_config.j = value;
                                break;
                        default:
                                break;
                        }
                        i_position_control.set_position_velocity_control_config(pos_velocity_ctrl_config);
                        pos_velocity_ctrl_config = i_position_control.get_position_velocity_control_config();
                        printf("Kp:%d Ki:%d Kd:%d j%d i_lim:%d\n",
                                pos_velocity_ctrl_config.P_pos, pos_velocity_ctrl_config.I_pos, pos_velocity_ctrl_config.D_pos,
                                pos_velocity_ctrl_config.j, pos_velocity_ctrl_config.integral_limit_pos);
                        break;

                case 'v': //velocity
                        switch(mode_3)
                        {
                        case 'p':
                                pos_velocity_ctrl_config.P_velocity = value;
                                break;
                        case 'i':
                                pos_velocity_ctrl_config.I_velocity = value;
                                break;
                        case 'd':
                                pos_velocity_ctrl_config.D_velocity = value;
                                break;
                        case 'l':
                                pos_velocity_ctrl_config.integral_limit_velocity = value;
                                break;
                        default:
                                break;
                        }
                        i_position_control.set_position_velocity_control_config(pos_velocity_ctrl_config);
                        pos_velocity_ctrl_config = i_position_control.get_position_velocity_control_config();
                        printf("Kp:%d Ki:%d Kd:%d i_lim:%d\n", pos_velocity_ctrl_config.P_velocity, pos_velocity_ctrl_config.I_velocity,
                                pos_velocity_ctrl_config.D_velocity, pos_velocity_ctrl_config.integral_limit_velocity);
                        break;

                default:
                        printf("kp->pos_ctrl ko->optimum_ctrl kv->vel_ctrl\n");
                        break;
                }

                i_position_control.set_position_velocity_control_config(pos_velocity_ctrl_config);
                break;

        //limits
        case 'L':
                pos_velocity_ctrl_config = i_position_control.get_position_velocity_control_config();
                switch(mode_2)
                {
                //max position limit
                case 'p':
                    switch(mode_3)
                    {
                    case 'u':
                        pos_velocity_ctrl_config.max_pos = value;
                        break;
                    case 'l':
                        pos_velocity_ctrl_config.min_pos = value;
                        break;
                    default:
                        pos_velocity_ctrl_config.max_pos = value;
                        pos_velocity_ctrl_config.min_pos = -value;
                        break;
                    }
                    break;

                //max velocity limit
                case 'v':
                        pos_velocity_ctrl_config.max_speed = value;
                        break;

                //max torque limit
                case 't':
                        pos_velocity_ctrl_config.max_torque = value;
                        break;

                default:
                        break;
                }
                i_position_control.set_position_velocity_control_config(pos_velocity_ctrl_config);
                printf("pos_max:%d pos_min:%d v_max:%d torq_max:%d\n", pos_velocity_ctrl_config.max_pos, pos_velocity_ctrl_config.min_pos, pos_velocity_ctrl_config.max_speed,
                        pos_velocity_ctrl_config.max_torque);
                break;

        //change direction/polarity of the movement in position/velocity control
        case 'd':
            pos_velocity_ctrl_config = i_position_control.get_position_velocity_control_config();
            if (pos_velocity_ctrl_config.polarity == -1)
            {
                pos_velocity_ctrl_config.polarity = 1;
                printf("normal movement polarity\n");
            }
            else
            {
                pos_velocity_ctrl_config.polarity = -1;
                printf("inverted movement polarity\n");
            }
            i_position_control.set_position_velocity_control_config(pos_velocity_ctrl_config);
            break;

        //enable
        case 'e':
                switch(mode_2)
                {
                case 'p':
                        if (value == 1)
                        {
                            i_position_control.enable_position_ctrl(POS_PID_CONTROLLER);
                            printf("simple PID pos ctrl enabled\n");
                        }
                        else if (value == 2)
                        {
                            i_position_control.enable_position_ctrl(POS_PID_VELOCITY_CASCADED_CONTROLLER);
                            printf("vel.-cascaded pos ctrl enabled\n");
                        }
                        else if (value == 3)
                        {
                            i_position_control.enable_position_ctrl(NL_POSITION_CONTROLLER);
                            printf("Nonlinear pos ctrl enabled\n");
                        }
                        else
                        {
                            i_position_control.disable();
                            printf("position ctrl disabled\n");
                        }
                        break;
                case 'v':
                        if (value == 1)
                        {
                            i_position_control.enable_velocity_ctrl();
                            printf("velocity ctrl enabled\n");
                        }
                        else
                        {
                            i_position_control.disable();
                            printf("velocity ctrl disabled\n");
                        }
                        break;
                case 't':
                        if (value == 1)
                        {
                            torque_control_flag = 1;
                            i_position_control.enable_torque_ctrl();
                            printf("torque ctrl enabled\n");
                        }
                        else
                        {
                            torque_control_flag = 0;
                            i_position_control.disable();
                            printf("torque ctrl disabled\n");
                        }
                        break;
                default:
                        printf("ep1->enable PID pos ctrl\n");
                        printf("ep2->enable cascaded pos ctrl\n");
                        printf("ep3->enable integral-optimum pos ctrl\n");
                        printf("ev1->enable PID velocity ctrl\n");
                        printf("et1->enable torque ctrl\n");
                        break;
                }
                break;
        //help
        case 'h':
                printf("p->set position\n");
                printf("v->set veloctiy\n");
                printf("k->set PIDs\n");
                printf("L->set limits\n");
                printf("e->enable controllers\n");
                break;

        //jerk limitation (profiler parameters)
        case 'j':
                pos_velocity_ctrl_config = i_position_control.get_position_velocity_control_config();
                switch(mode_2)
                {
                case 'a':
                        pos_velocity_ctrl_config.max_acceleration_profiler = value;
                        break;
                case 'v':
                        pos_velocity_ctrl_config.max_speed_profiler = value;
                        break;
                default:
                        break;
                }
                i_position_control.set_position_velocity_control_config(pos_velocity_ctrl_config);
                printf("acceleration_max:%d velocity_max:%d\n",pos_velocity_ctrl_config.max_acceleration_profiler, pos_velocity_ctrl_config.max_speed_profiler);
                break;

        //auto offset tuning
        case 'a':
                printf("Sending offset_detection command ...\n");

                motorcontrol_config = i_position_control.set_offset_detection_enabled();

                if(motorcontrol_config.commutation_angle_offset == -1)
                {
                    printf(">>  WRONG POSITION SENSOR POLARITY ...\n");
                }
                else
                {
                    motorcontrol_config = i_position_control.get_motorcontrol_config();
                    printf(">>  PROPER POSITION SENSOR POLARITY ...\n");

                    printf("Detected offset is: %i\n", motorcontrol_config.commutation_angle_offset);

                    if(motorcontrol_config.commutation_sensor==HALL_SENSOR)
                    {
                        printf("SET THE FOLLOWING CONSTANTS IN CASE OF LOW-QUALITY HALL SENSOR \n");
                        printf("      hall_state_1_angle: %d\n", motorcontrol_config.hall_state_1);
                        printf("      hall_state_2_angle: %d\n", motorcontrol_config.hall_state_2);
                        printf("      hall_state_3_angle: %d\n", motorcontrol_config.hall_state_3);
                        printf("      hall_state_4_angle: %d\n", motorcontrol_config.hall_state_4);
                        printf("      hall_state_5_angle: %d\n", motorcontrol_config.hall_state_5);
                        printf("      hall_state_6_angle: %d\n", motorcontrol_config.hall_state_6);
                    }
                }
                break;

        //set brake
        case 'b':
            switch(mode_2)
            {
            case 's':
                pos_velocity_ctrl_config = i_position_control.get_position_velocity_control_config();
                pos_velocity_ctrl_config.special_brake_release = value;
                i_position_control.set_position_velocity_control_config(pos_velocity_ctrl_config);
                break;
            default:
                if (brake_flag)
                {
                    brake_flag = 0;
                    printf("Brake blocking\n");
                }
                else
                {
                    brake_flag = 1;
                    printf("Brake released\n");
                }
                i_position_control.set_brake_status(brake_flag);
                break;
            }
            break;

        //set offset
        case 'o':
                motorcontrol_config = i_position_control.get_motorcontrol_config();
                switch(mode_2)
                {
                //set offset
                case 's':
                    motorcontrol_config.commutation_angle_offset = value;
                    i_position_control.set_motorcontrol_config(motorcontrol_config);
                    printf("set offset to %d\n", motorcontrol_config.commutation_angle_offset);
                    break;
                //print offset
                case 'p':
                    printf("offset %d\n", motorcontrol_config.commutation_angle_offset);
                    break;
                }
                break;

        //disable controllers
        default:
                i_position_control.disable();
                printf("controller disabled\n");
                break;

        }
        delay_milliseconds(10);
    }
}
