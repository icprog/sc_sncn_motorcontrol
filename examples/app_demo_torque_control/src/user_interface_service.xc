/*
 * user_interface_service.xc

 *
 *  Created on: Jul 13, 2015
 *      Author: Synapticon GmbH
 */

#include <stdio.h>
#include <ctype.h>
#include <print.h>

#include <user_interface_service.h>
#include <position_feedback_service.h>
#include <motor_control_interfaces.h>
#include <xscope.h>

void update_brake(
        int app_tile_usec,
        int dc_bus_voltage,
        int pull_brake_voltage,
        int hold_brake_voltage,
        int pull_brake_time,
        client interface TorqueControlInterface i_torque_control, client interface UpdateBrake i_update_brake)
{
    int error=0;
    int duty_min=0, duty_max=0, duty_divider=0;
    int duty_start_brake =0, duty_maintain_brake=0, period_start_brake=0;

    timer t;
    unsigned ts;

    i_torque_control.set_safe_torque_off_enabled();
    i_torque_control.set_brake_status(0);
    t :> ts;
    t when timerafter (ts + 2000*1000*app_tile_usec) :> void;


    if(dc_bus_voltage <= 0)
    {
        printstr("ERROR: negative Vdc value defined in settings");
        return;
    }

    if(pull_brake_voltage > (dc_bus_voltage*1000))
    {
        printstr("ERROR: pull brake voltage is higher than Vdc");
        return;
    }

    if(pull_brake_voltage < 0)
    {
        printstr("ERROR: negative pull brake voltage is entered");
        return;
    }

    if(hold_brake_voltage > (dc_bus_voltage*1000))
    {
        printstr("ERROR: hold brake voltage is higher than Vdc");
        return;
    }

    if(hold_brake_voltage < 0)
    {
        printstr("ERROR: hold brake voltage is negative");
        return;
    }

    if(period_start_brake < 0)
    {
        printstr("ERROR: period start brake is negative");
        return;
    }


    MotorcontrolConfig motorcontrol_config = i_torque_control.get_config();

    if(motorcontrol_config.ifm_tile_usec==250)
    {
        duty_min = 1500;
        duty_max = 13000;
        duty_divider = 16384;
    }
    else if(motorcontrol_config.ifm_tile_usec==100)
    {
        duty_min = 600;
        duty_max = 7000;
        duty_divider = 8192;
    }
    else if (motorcontrol_config.ifm_tile_usec!=100 && motorcontrol_config.ifm_tile_usec!=250)
    {
        error = 1;
    }

    duty_start_brake    = (duty_divider * pull_brake_voltage)/(1000*dc_bus_voltage);
    if(duty_start_brake < duty_min) duty_start_brake = duty_min;
    if(duty_start_brake > duty_max) duty_start_brake = duty_max;

    duty_maintain_brake = (duty_divider * hold_brake_voltage)/(1000*dc_bus_voltage);
    if(duty_maintain_brake < duty_min) duty_maintain_brake = duty_min;
    if(duty_maintain_brake > duty_max) duty_maintain_brake = duty_max;

    period_start_brake  = (pull_brake_time * 1000)/(motorcontrol_config.ifm_tile_usec);

    i_update_brake.update_brake_control_data(duty_start_brake, duty_maintain_brake, period_start_brake);
}

void demo_torque_control(interface TorqueControlInterface client i_torque_control, client interface UpdateBrake i_update_brake)
{

    int app_tile_usec = 100; // reference clock frequency of tile where demo_torque_control() service is being executed (in MHz).
                             // default value is 100

    int torque_ref = 0;
    int torque_control_flag = 0;
    int offset=0;

    UpstreamControlData upstream_control_data;
    MotorcontrolConfig  motorcontrol_config;

    int brake_flag = 0;
    int dc_bus_voltage    = 0;
    int pull_brake_voltage= 0;
    int hold_brake_voltage= 0;
    int pull_brake_time   = 0;

    motorcontrol_config = i_torque_control.get_config();
    pull_brake_voltage= 16000; //milli-Volts
    hold_brake_voltage=  1000; //milli-Volts
    pull_brake_time   =  2000; //milli-Seconds
    dc_bus_voltage = motorcontrol_config.dc_bus_voltage;
    update_brake(app_tile_usec, dc_bus_voltage, pull_brake_voltage, hold_brake_voltage, pull_brake_time, i_torque_control, i_update_brake);

    printf(" DEMO_TORQUE_CONTROL started...\n");
    i_torque_control.set_brake_status(1);
    i_torque_control.set_torque_control_enabled();
    printf(" please enter torque reference in [milli-Nm]\n");

    upstream_control_data = i_torque_control.update_upstream_control_data(0);

    fflush(stdout);
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
        //automatic offset detection
        case 'a':
                int proper_sensor_polarity=0;

                printf("automatic offset detection started ...\n");
                i_torque_control.set_offset_detection_enabled();

                while(i_torque_control.get_offset()==-1) delay_milliseconds(50);//wait until offset is detected

                proper_sensor_polarity=i_torque_control.get_sensor_polarity_state();

                if(proper_sensor_polarity == 1)
                {
                    offset=i_torque_control.get_offset();
                    printf("detected offset is: %i\n", offset);

                    printf("offset is set to %d\n", offset);
                    i_torque_control.set_offset_value(offset);

                    motorcontrol_config = i_torque_control.get_config();
                    if(motorcontrol_config.commutation_sensor==HALL_SENSOR)
                    {
                        for (int i=0;i<6;i++)
                        {
                            printf("     hall_state_angle[%d]: %d\n", i, motorcontrol_config.hall_state[i]);
                        }
                    }

                    delay_milliseconds(2000);
                    i_torque_control.set_torque_control_enabled();
                }
                else
                {
                    printf(">>  ERROR: wrong polarity for commutation position sensor\n");
                }
                break;

        //set offset
        case 'o':
                offset = value;
                printf("offset set to %d\n", offset);
                i_torque_control.set_offset_value(offset);
                break;

        //enable/disable torque controller
        case 't':
                if (torque_control_flag == 0)
                {
                    torque_control_flag = 1;
                    i_torque_control.set_torque_control_enabled();
                    printf("Torque control activated\n");
                }
                else
                {
                    torque_control_flag = 0;
                    i_torque_control.set_torque_control_disabled();
                    printf("Torque control deactivated\n");
                }
                break;

        //reverse the direction of reference torque
        case 'r':
                torque_ref = -torque_ref;
                i_torque_control.set_torque(torque_ref);
                printf("torque %d [milli-Nm]\n", torque_ref);
                break;

        //set brake
         case 'b':
                 switch(mode_2)
                 {
                 case 'v'://brake voltage configure
                         motorcontrol_config = i_torque_control.get_config();
                         switch(mode_3)
                         {
                         case 'n':// nominal voltage of dc-bus
                                 dc_bus_voltage=value;
                                 update_brake(app_tile_usec, dc_bus_voltage, pull_brake_voltage, hold_brake_voltage, pull_brake_time, i_torque_control, i_update_brake);
                                 printf("nominal voltage of dc-bus for brake set to %d Volts \n", dc_bus_voltage);
                                 break;

                         case 'p':// pull voltage for releasing the brake at startup
                                 pull_brake_voltage=value;
                                 update_brake(app_tile_usec, dc_bus_voltage, pull_brake_voltage, hold_brake_voltage, pull_brake_time, i_torque_control, i_update_brake);
                                 printf("brake pull voltage set to %d milli-Volts \n", pull_brake_voltage);
                                 break;

                         case 'h':// hold voltage for holding the brake after it is pulled
                                 hold_brake_voltage=value;
                                 update_brake(app_tile_usec, dc_bus_voltage, pull_brake_voltage, hold_brake_voltage, pull_brake_time, i_torque_control, i_update_brake);
                                 printf("brake hold voltage is %d milli-Volts\n", hold_brake_voltage);
                                 break;

                         default:
                                 break;
                         }
                         break;

                 case 't'://set pull time
                         //set
                         pull_brake_time=value;
                         update_brake(app_tile_usec, dc_bus_voltage, pull_brake_voltage, hold_brake_voltage, pull_brake_time, i_torque_control, i_update_brake);
                         printf("brake pull time is %d milli-seconds \n", pull_brake_time);
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
                         i_torque_control.set_brake_status(brake_flag);
                         break;
                 }
                 break;

         //safe mode torque (all inverter power swieches open)
         case 's':
                 printf("safe torque off mode started\n");
                 i_torque_control.set_safe_torque_off_enabled();
                 break;

         //show on xscope for 10 seconds!
         //this will block this service (demo_torque_control) for almost 10 seconds
         case 'x':
                 printf("activate xscope during 20 seconds ...\n");
                 for(int i=0; i<=10000;i++)
                 {
                     upstream_control_data = i_torque_control.update_upstream_control_data(0);

                     xscope_int(COMPUTED_TORQUE, upstream_control_data.computed_torque);
                     xscope_int(V_DC, upstream_control_data.V_dc);
                     xscope_int(ANGLE, upstream_control_data.angle);
                     xscope_int(POSITION, upstream_control_data.position);
                     xscope_int(VELOCITY, upstream_control_data.velocity);
                     xscope_int(TEMPERATURE, upstream_control_data.temperature/motorcontrol_config.temperature_ratio);
                     xscope_int(FAULT_CODE, upstream_control_data.error_status);

                     delay_milliseconds(1);
                 }
                 break;

         //reset faults
         case 'z':
                 printf("reset faults, and check status ...\n");
                 i_torque_control.reset_faults();

                 delay_milliseconds(500);
                 upstream_control_data = i_torque_control.update_upstream_control_data(0);

                 if(upstream_control_data.error_status != NO_FAULT)
                     printf(">>system status: faulty (fault ID %x)\n", upstream_control_data.error_status);

                 if(upstream_control_data.error_status == NO_FAULT)
                 {
                     printf(">>system status: no fault\n");

                     torque_control_flag = 1;
                     i_torque_control.set_torque_control_enabled();
                     printf("torque control activated\n");

                     brake_flag = 1;
                     i_torque_control.set_brake_status(brake_flag);
                     printf("Brake released\n");

                     printf("set offset to %d\n", offset);
                     i_torque_control.set_offset_value(offset);
                 }
                 break;

        //play music! it sends a square-wave reference signal (with audible frequency) to torque controller.
        case 'm':
                int period_us;     // torque period in micro-seconds
                int pulse_counter; // number of generated pulses
                torque_ref=value;

                for(period_us=400;period_us<=(5*400);(period_us+=400))
                {
                    for(pulse_counter=0;pulse_counter<=(50000/period_us);pulse_counter++)//total period = period * pulse_counter=1000000 us
                    {
                        i_torque_control.set_torque(torque_ref);
                        delay_microseconds(period_us);

                        i_torque_control.set_torque(-torque_ref);
                        delay_microseconds(period_us);
                    }
                }

                for(period_us=(5*400);period_us>=400;(period_us-=400))
                {
                    for(pulse_counter=0;pulse_counter<=(50000/period_us);pulse_counter++)//total period = period * pulse_counter=1000000 us
                    {
                        i_torque_control.set_torque(torque_ref);
                        delay_microseconds(period_us);



                        i_torque_control.set_torque((-torque_ref*110)/100);
                        delay_microseconds((5*period_us)/100);

                        i_torque_control.set_torque(-torque_ref);
                        delay_microseconds(period_us);
                    }
                }

                i_torque_control.set_torque(0);
                break;

        //directly set the torque
        default:
                torque_ref = value;
                i_torque_control.set_torque(torque_ref);

                delay_milliseconds(1);
                motorcontrol_config = i_torque_control.get_config();
                if(torque_ref>motorcontrol_config.max_torque || torque_ref<-motorcontrol_config.max_torque)
                {
                    upstream_control_data = i_torque_control.update_upstream_control_data(0);
                    printf("above limits! torque %d [milli-Nm]\n", upstream_control_data.torque_set);
                }
                else
                    printf("torque %d [milli-Nm]\n", torque_ref);
                break;
        }
    }

}



