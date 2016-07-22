/*
 * tuning.xc
 *
 *  Created on: Jul 13, 2015
 *      Author: Synapticon GmbH
 */
#include <tuning.h>
#include <stdio.h>
#include <ctype.h>

int auto_offset(interface MotorcontrolInterface client i_motorcontrol,
        interface CONTELECInterface client ?i_contelec, interface AMSInterface client ?i_ams)
{
    const int calib_voltage = 1000;
    const int calib_time = 500;
    int offset = 0;
    int calib_angle;
    MotorcontrolConfig motorcontrol_config = i_motorcontrol.get_config();
    if (motorcontrol_config.polarity_type == INVERTED_POLARITY) {
        calib_angle = 0;
    } else {
        calib_angle = 2048;
    }

    //stop the motor
    i_motorcontrol.set_voltage(0);
    delay_milliseconds(calib_time);
    i_motorcontrol.set_calib(1);
    //set internal commutation voltage to calib_voltage
    i_motorcontrol.set_voltage(calib_voltage);
    //the motor will go to a fixed position
    delay_milliseconds(calib_time);
    //get the offsets
    if (!isnull(i_contelec))
        offset = i_contelec.reset_contelec_angle(calib_angle);
    else if (!isnull(i_ams))
        offset = i_ams.reset_ams_angle(calib_angle);
    motorcontrol_config.hall_offset[0] = 0;
    motorcontrol_config.hall_offset[1] = 0;

    //stop calib and set the offsets found
    i_motorcontrol.set_calib(0);
    i_motorcontrol.set_voltage(0);
    i_motorcontrol.set_config(motorcontrol_config);

    return offset;
}

void run_offset_tuning(int position_limit, interface MotorcontrolInterface client i_commutation, interface TuningInterface client ?i_tuning,
                       interface ADCInterface client ?i_adc)
{
    delay_milliseconds(500);
    printf(">>   SOMANET OFFSET TUNING SERVICE STARTING...\n");
    int offset = 0;
    int field_control_flag = 1;
    int torque_flag = 0;
    int input_voltage = 0;
    //set position limit
    if (position_limit && !isnull(i_tuning))
        i_tuning.set_limit(position_limit);
    MotorcontrolConfig motorcontrol_config = i_commutation.get_config();
    if (motorcontrol_config.commutation_method == FOC) {
        field_control_flag = 0;
        i_commutation.set_control(field_control_flag);
        printf("FOC commutation\nField and Torque controllers deactivated\n");
    } else {
        printf("Sine commutation\n");
    }
    if (motorcontrol_config.commutation_sensor == HALL_SENSOR) {
        printf("Hall tuning, ");
    } else if (motorcontrol_config.commutation_sensor == BISS_SENSOR){
        offset = i_commutation.set_sensor_offset(-1);
        printf("BiSS tuning, Sensor offset %d, ", offset);
    } else if (motorcontrol_config.commutation_sensor == AMS_SENSOR){
        offset = i_commutation.set_sensor_offset(-1);
        printf("AMS tuning, Sensor offset %d, ", offset);
    } else if (motorcontrol_config.commutation_sensor == CONTELEC_SENSOR){
        offset = i_tuning.set_sensor_offset(-1);
        printf("CONTELEC tuning, Sensor offset %d, ", offset);
    }
    if (motorcontrol_config.commutation_method == FOC && motorcontrol_config.commutation_sensor != HALL_SENSOR) {
        printf ( "Polarity %d\noffset %d\n", motorcontrol_config.polarity_type, motorcontrol_config.hall_offset[0]);
    } else {
        printf ( "Polarity %d\noffset clk %d (for positive voltage)\noffset cclk %d (for negative voltage)\n", motorcontrol_config.polarity_type, motorcontrol_config.hall_offset[0], motorcontrol_config.hall_offset[1]);
    }
    printf("Enter a to start the auto sensor offset finding.\n");
    fflush(stdout);
    //read and adjust the offset.
    while (1) {
        char mode = 0;
        char c;
        int value = 0;
        int sign = 1;
        //reading user input.
        while((c = getchar ()) != '\n'){
            if(isdigit(c)>0){
                value *= 10;
                value += c - '0';
            } else if (c == '-') {
                sign = -1;
            } else if (c != ' ')
                mode = c;
        }
        switch(mode) {
        //auto find offset
        case 'a':
            //stop the motor
//            i_commutation.set_voltage(0);
//            delay_milliseconds(500);
//            i_commutation.set_calib(1);
//            //set internal commutation voltage to 1000
//            i_commutation.set_voltage(1000);
//            //the motor will go to a fixed position
//            delay_milliseconds(500);
//            offset = i_commutation.set_calib(0);
//            //start turning the motor and print the offsets found
//            i_commutation.set_voltage(input_voltage);
            if (!isnull(i_tuning))
                offset = i_tuning.auto_offset();
            motorcontrol_config = i_commutation.get_config();
            if (motorcontrol_config.commutation_sensor == AMS_SENSOR || motorcontrol_config.commutation_sensor == BISS_SENSOR
                    || motorcontrol_config.commutation_sensor == CONTELEC_SENSOR) {
                printf("Sensor offset: %d, ", offset);
            }
            printf("Voltage %d, Polarity %d\n", input_voltage, motorcontrol_config.polarity_type);
            if (motorcontrol_config.commutation_method == FOC && motorcontrol_config.commutation_sensor != HALL_SENSOR) {
                printf("offset %d\n", motorcontrol_config.hall_offset[0]);
            } else {
                printf("offset clk %d (for positive voltage)\noffset cclk %d (for negative voltage)\n", motorcontrol_config.hall_offset[0], motorcontrol_config.hall_offset[1]);
            }
            if (motorcontrol_config.commutation_sensor == HALL_SENSOR) {
                printf("Hall sensor are not precise!\nOffsets could be wrong.\n");
            }
            printf("Enter c to start the auto tuning\nor enter o with a value to set the offset manually\n");
            break;
        //auto tune the offset by mesuring the current consumption
        case 'c':
            i_tuning.tune(input_voltage);
            break;
        //reverse motor direction
        case 'd':
            if (motorcontrol_config.commutation_sensor == HALL_SENSOR) {
                int temp = motorcontrol_config.hall_offset[0];
                motorcontrol_config.hall_offset[0] = (motorcontrol_config.hall_offset[1] + 2048) & 4095;
                motorcontrol_config.hall_offset[1] = (temp + 2048) & 4095;
                i_commutation.set_config(motorcontrol_config);
            } else if (motorcontrol_config.commutation_sensor == BISS_SENSOR) {
                offset = (offset + 2048) & 4095;
                i_commutation.set_sensor_offset(offset);
            } else if (motorcontrol_config.commutation_sensor == AMS_SENSOR || motorcontrol_config.commutation_sensor == CONTELEC_SENSOR) {
                motorcontrol_config.hall_offset[0] = (motorcontrol_config.hall_offset[0] + 2048) & 4095;
                i_commutation.set_config(motorcontrol_config);
            }
            printf("Direction inverted\n");
            break;
        //pole pairs
        case 'e':
            i_tuning.set_pole_pairs(value);
            printf("Pole pairs %d\n", value);
            break;
        //toggle field controler
        case 'f':
            if (motorcontrol_config.commutation_method == FOC) {
                if (field_control_flag == 0) {
                    field_control_flag = 1;
                    printf("Field controler activated\n");
                } else {
                    field_control_flag = 0;
                    printf("Field and Torque controlers deactivated\n");
                }
                i_commutation.set_control(field_control_flag);
            }
            break;
        //position limit
        case 'l':
            i_tuning.set_limit(value * sign);
            break;
        //reverse sensor direction
        case 'm':
            motorcontrol_config = i_commutation.get_config();
            if (motorcontrol_config.polarity_type == NORMAL_POLARITY) {
                motorcontrol_config.polarity_type = INVERTED_POLARITY;
                motorcontrol_config.bldc_winding_type = DELTA_WINDING;
            } else {
                motorcontrol_config.polarity_type = NORMAL_POLARITY;
                motorcontrol_config.bldc_winding_type = STAR_WINDING;
            }
            i_commutation.set_config(motorcontrol_config);
            printf("Polarity %d\n", motorcontrol_config.polarity_type);
            break;
        //set offset
        case 'o':
            if (input_voltage >= 0 || (motorcontrol_config.commutation_method == FOC && motorcontrol_config.commutation_sensor != HALL_SENSOR)) {
                motorcontrol_config.hall_offset[0] = value;
                printf("offset clk: %d\n", value);
            } else {
                motorcontrol_config.hall_offset[1] = value;
                printf("offset cclk: %d\n", value);
            }
            i_commutation.set_config(motorcontrol_config);
            break;
        //print offsets, voltage and polarity
        case 'p':
            motorcontrol_config = i_commutation.get_config();
            if (motorcontrol_config.commutation_sensor == AMS_SENSOR || motorcontrol_config.commutation_sensor == BISS_SENSOR || motorcontrol_config.commutation_sensor == CONTELEC_SENSOR) {
                offset = i_tuning.set_sensor_offset(-1);
                printf("Sensor offset %d, ", offset);
            }
            if (motorcontrol_config.commutation_method == FOC && motorcontrol_config.commutation_sensor != HALL_SENSOR) {
                printf("Polarity %d\noffset %d\n", motorcontrol_config.polarity_type, motorcontrol_config.hall_offset[0]);
            } else {
                printf("Polarity %d, Voltage %d\noffset clk %d (for positive voltage)\noffset cclk %d (for negative voltage)\n", motorcontrol_config.polarity_type, input_voltage, motorcontrol_config.hall_offset[0], motorcontrol_config.hall_offset[1]);
            }
            break;
        //reverse voltage
        case 'r':
            input_voltage = -input_voltage;
            if (motorcontrol_config.commutation_method == FOC && torque_flag) {
                i_commutation.set_torque(input_voltage);
                if (!isnull(i_tuning))
                    i_tuning.set_torque(input_voltage);
                printf("torque %d\n", input_voltage);
            } else {
                i_commutation.set_voltage(input_voltage);
                if (input_voltage >= 0 || (motorcontrol_config.commutation_method == FOC && motorcontrol_config.commutation_sensor != HALL_SENSOR))
                    printf("voltage: %i, offset clk: %d\n", input_voltage, motorcontrol_config.hall_offset[0]);
                else
                    printf("voltage: %i, offset cclk: %d\n", input_voltage, motorcontrol_config.hall_offset[1]);
            }
            break;
        //set sensor offset
        case 's':
            offset = value;
            i_tuning.set_sensor_offset(offset);
            printf("Sensor offset: %d\n", offset);
            break;
        //set torque
        case 't':
            if (motorcontrol_config.commutation_method == FOC) {
                field_control_flag = 1;
                input_voltage = value * sign;
                i_commutation.set_torque(input_voltage);
                torque_flag = 1;
                if (!isnull(i_tuning))
                    i_tuning.set_torque(input_voltage);
                printf("torque %d\n", input_voltage);
            }
            break;
        //restart watchdog
        case 'y':
            i_commutation.set_voltage(0);
            i_commutation.restart_watchdog();
            printf("Watchdog restarted\n");
            break;
        //go to 0 position
        case 'z':
            if (!isnull(i_tuning))
                i_tuning.set_position(value * sign);
            break;
        //set voltage
        default:
            torque_flag = 0;
            input_voltage = value * sign;
            i_commutation.set_voltage(input_voltage);
            if (input_voltage >= 0 || (motorcontrol_config.commutation_method == FOC && motorcontrol_config.commutation_sensor != HALL_SENSOR))
                printf("voltage: %i, offset clk: %d\n", input_voltage, motorcontrol_config.hall_offset[0]);
            else
                printf("voltage: %i, offset cclk: %d\n", input_voltage, motorcontrol_config.hall_offset[1]);
            break;
        }
        delay_milliseconds(10);
    }
}

static inline void update_offset(MotorcontrolConfig &motorcontrol_config, int voltage, int offset)
{
    if (voltage >= 0)
        motorcontrol_config.hall_offset[0] =  offset;
    else
        motorcontrol_config.hall_offset[1] =  offset;
}

[[combinable]]
 void tuning_service(interface TuningInterface server i_tuning, interface MotorcontrolInterface client i_commutation,
                     interface ADCInterface client ?i_adc, interface PositionControlInterface client ?i_position_control,
                     interface HallInterface client ?i_hall, interface BISSInterface client ?i_biss, interface AMSInterface client ?i_ams,
                     interface CONTELECInterface client ?i_contelec)
{
    timer t;
    unsigned ts;
    t :> ts;
    MotorcontrolConfig motorcontrol_config = i_commutation.get_config();
    int count = 0;
    int torque_offset = 0;
    int velocity = 0;
    int position_limit = 0;
    int position_limit_reached = 0;
    int print_position_limit = 0;
    int voltage = 0;
    int target_torque = 0;
    int current_sampling = 0;
    int peak_current = 0;
    int last_peak_current = 0;
    int phase_b, phase_c;
    int adc_a, adc_b;
    int enable_tuning = 0;
    int best_offset_pos, best_offset_neg, offset_pos, offset_neg, start_offset_pos, start_offset_neg;
    int min_current_pos, last_min_current_pos, min_current_neg, last_min_current_neg;
    int range_pos, range_neg, step_pos, step_neg;
    int tuning_done_pos, tuning_done_neg;

    if (!isnull(i_position_control)) {
        /* Initialise the position profile generator */
        ProfilerConfig profiler_config;
        profiler_config.polarity = POLARITY;
        profiler_config.max_position = MAX_POSITION_LIMIT;
        profiler_config.min_position = MIN_POSITION_LIMIT;
        profiler_config.max_velocity = MAX_VELOCITY;
        profiler_config.max_acceleration = MAX_ACCELERATION;
        profiler_config.max_deceleration = MAX_DECELERATION;
        init_position_profiler(profiler_config, i_position_control, i_hall, null, i_biss, i_ams, i_contelec);
    }

    if (!isnull(i_adc)) {
        { adc_a, adc_b } = i_adc.get_external_inputs();
        torque_offset = adc_b - adc_a;
        torque_offset = 0;
    }

    while(1) {
        select {
        case t when timerafter(ts) :> void:
            //get position and velocity
//            if (motorcontrol_config.commutation_sensor == BISS_SENSOR && !isnull(i_biss)) {
//                velocity = i_biss.get_biss_velocity();
//                { count, void, void } = i_biss.get_biss_position();
//            } else if (motorcontrol_config.commutation_sensor == AMS_SENSOR && !isnull(i_ams)) {
//                velocity = i_ams.get_ams_velocity();
//                { count, void } = i_ams.get_ams_position();
//            } else if (motorcontrol_config.commutation_sensor == HALL_SENSOR && !isnull(i_hall)) {
//                count = i_hall.get_hall_position_absolute();
//                velocity = i_hall.get_hall_velocity();
//            } else if (motorcontrol_config.commutation_sensor == CONTELEC_SENSOR && !isnull(i_contelec)) {
//                velocity = i_contelec.get_contelec_velocity();
//                { count, void } = i_contelec.get_contelec_position();
//            }
//            if (motorcontrol_config.commutation_method == SINE)
//                xscope_int(VELOCITY, velocity);
//
            //torque display
//            if (motorcontrol_config.commutation_method == FOC) {
//                int torque = i_commutation.get_torque_actual();
//                int actual_voltage, error_torque_integral;
//                {actual_voltage, error_torque_integral} = i_commutation.get_torque_control_out();
//                xscope_int(VOLTAGE, actual_voltage);
//                xscope_int(TORQUE, torque);
//                xscope_int(TARGET_TORQUE, target_torque);
//                xscope_int(ERROR_TORQUE, target_torque-torque);
//            }

            //postion limiter
            if (position_limit > 0) {
                if (count >= position_limit && velocity > 10) {
                    i_commutation.set_voltage(0);
                    if (print_position_limit >= 0) {
                        print_position_limit = -1;
                        printf("up limit reached\n");
                    }
                    position_limit_reached = 1;
                } else if (count <= -position_limit && velocity < -10) {
                    i_commutation.set_voltage(0);
                    if (print_position_limit <= 0) {
                        print_position_limit = 1;
                        printf("down limit reached\n");
                    }
                    position_limit_reached = 1;
                } else {
                    position_limit_reached = 0;
                }
            }

            //current measurement
            if (!isnull(i_adc)) {
                {phase_b, phase_c} = i_adc.get_currents();
//                { adc_a, adc_b } = i_adc.get_external_inputs();

                if (current_sampling > 0) {
                    current_sampling--;
                    //find the peak current by sampling every [period] microseconds [times] times
                    if (phase_b > peak_current)
                        peak_current = phase_b;
                    else if (phase_b < -peak_current)
                        peak_current = -phase_b;
                }
//                if (motorcontrol_config.commutation_method == SINE) {
//                    xscope_int(PHASE_B, phase_b);
//                    xscope_int(PHASE_C, phase_c);
//                }
//                xscope_int(PEAK_CURRENT, last_peak_current);
//                xscope_int(TORQUE_SENSOR, (adc_b-adc_a-torque_offset)/4);
            }

            //tuning loop
            if (enable_tuning) {
                //reverse direction if the position limit is reached
                if (position_limit_reached) {
                    position_limit_reached = 0;
                    i_commutation.set_voltage(0);
                    delay_milliseconds(500);
                    voltage = -voltage;
                    i_commutation.set_voltage(voltage);
                    delay_milliseconds(500);
                    current_sampling = 200;
                    peak_current = 0;
                }

                //new measured peak current
                if (current_sampling <= 0) {

                    if (voltage > 0 && tuning_done_pos == 0) {
                        //update min current and best offset
                        if (peak_current < min_current_pos) {
                            min_current_pos = peak_current;
                            best_offset_pos = offset_pos;
                        }
                        //end of a range, check if the peak current is decreasing
                        if (range_pos <= 0) {
                            printf("offset pos %d, %d -> %d\n", offset_pos, last_min_current_pos, min_current_pos);
                            if (min_current_pos >= last_min_current_pos) {
                                if (step_pos > 0) { //now search by decreasing the offset
                                    step_pos = -step_pos;
                                    offset_pos = start_offset_pos;
                                } else { //offset pos tuning is done
                                    tuning_done_pos = 1;
                                    position_limit_reached = 1;
                                    printf("tuning pos done %d\n", best_offset_pos);
                                }
                            }
                            range_pos = 25;
                            last_min_current_pos = min_current_pos;
                        }
                        range_pos--;
                        offset_pos += step_pos;
                        if (motorcontrol_config.commutation_method == FOC && motorcontrol_config.commutation_sensor != HALL_SENSOR) {
                            i_commutation.set_sensor_offset(offset_pos);
                        } else {
                            update_offset(motorcontrol_config, voltage, (offset_pos & 4095));
                        }
                    } else if (voltage < 0 && tuning_done_neg == 0){ //negative voltage
                        //update min current and best offset
                        if (peak_current < min_current_neg) {
                            min_current_neg = peak_current;
                            best_offset_neg = offset_neg;
                        }
                        if (range_neg <= 0) { //end of a range, check if the peak current is decreasing
                            printf("offset neg %d, %d -> %d\n", offset_neg, last_min_current_neg, min_current_neg);
                            if (min_current_neg >= last_min_current_neg) {
                                if (step_neg > 0) { //now search by decreasing the offset
                                    step_neg = -step_neg;
                                    offset_neg = start_offset_neg;
                                } else { //offset neg tuning is done
                                    tuning_done_neg = 1;
                                    position_limit_reached = 1;
                                    printf("tuning neg done %d\n", best_offset_neg);
                                }
                            }
                            range_neg = 25;
                            last_min_current_neg = min_current_neg;
                        }
                        range_neg--;
                        offset_neg += step_neg;
                        if (motorcontrol_config.commutation_method == FOC && motorcontrol_config.commutation_sensor != HALL_SENSOR) {
                            i_commutation.set_sensor_offset(offset_neg);
                        } else {
                            update_offset(motorcontrol_config, voltage, (offset_neg & 4095));
                        }
                    }

                    if((tuning_done_pos + tuning_done_neg) >= 2) {//tuning is done
                        voltage = 0;
                        i_commutation.set_voltage(voltage);
                        enable_tuning = 0;
                        if (motorcontrol_config.commutation_method == FOC && motorcontrol_config.commutation_sensor == AMS_SENSOR) {
                            AMSConfig ams_config = i_ams.get_ams_config();
                            int ticks_per_turn = (1 << ams_config.resolution_bits);
                            best_offset_pos &= (ticks_per_turn - 1);
                            best_offset_neg &= (ticks_per_turn - 1);
                        } else {
                            best_offset_pos &= 4095;
                            best_offset_neg &= 4095;
                        }
                        motorcontrol_config.hall_offset[0] = best_offset_pos;
                        motorcontrol_config.hall_offset[1] = best_offset_neg;
                        printf("Tuning done\nauto tuned offset clk: %d\nauto tuned offset cclk: %d\n", motorcontrol_config.hall_offset[0], motorcontrol_config.hall_offset[1]);
                        if (motorcontrol_config.commutation_method == FOC && motorcontrol_config.commutation_sensor != HALL_SENSOR) {
                            i_commutation.set_sensor_offset((best_offset_pos+best_offset_neg)/2);
                            motorcontrol_config.hall_offset[0] = 0;
                            motorcontrol_config.hall_offset[1] = 0;
                            printf("mean offset: %d\n", (best_offset_pos+best_offset_neg)/2);
                        }
                        i_commutation.set_config(motorcontrol_config);
                    } else {
                        last_peak_current = peak_current; //for displaying peak current
                        peak_current = 0;       // reset
                        current_sampling = 200; // current sampling
                        i_commutation.set_config(motorcontrol_config); //update offset
                    }
                } //end new measured peak current
            } //end tuning

            if (current_sampling <= 0) {
                last_peak_current = peak_current;
                current_sampling = 200;
                peak_current = 0;
            }
            t :> ts;
            ts += USEC_STD * 1000;
            break;

        case i_tuning.tune(int in_voltage):
            if (!isnull(i_adc)) {
                voltage = in_voltage;
                if (voltage && enable_tuning == 0) {
                    motorcontrol_config = i_commutation.get_config();
                    if (motorcontrol_config.commutation_method == FOC && motorcontrol_config.commutation_sensor != HALL_SENSOR) {
                        if (!isnull(i_contelec)) {
                            CONTELECConfig contelec_config = i_contelec.get_contelec_config();
                            start_offset_pos = contelec_config.offset;
                        }
                        else if (!isnull(i_ams)) {
                            AMSConfig ams_config = i_ams.get_ams_config();
                            start_offset_pos = ams_config.offset;
                        }


                        start_offset_neg = start_offset_pos;
                    } else {
                        start_offset_pos = motorcontrol_config.hall_offset[0];
                        start_offset_neg = motorcontrol_config.hall_offset[1];
                    }
                    best_offset_pos = start_offset_pos;
                    offset_pos = start_offset_pos;
                    best_offset_neg = start_offset_neg;
                    offset_neg = start_offset_neg;
                    enable_tuning = 1;
                    last_min_current_pos = 10000;
                    min_current_pos = 10000;
                    last_min_current_neg = 10000;
                    min_current_neg = 10000;
                    peak_current = 0;
                    current_sampling = 200;
                    range_pos = 0;
                    step_pos = 2;
                    range_neg = 0;
                    step_neg = 2;
                    tuning_done_pos = 0;
                    tuning_done_neg = 0;
                    printf("Starting auto tuning...\n");
                } else {
                    enable_tuning = 0;
                    motorcontrol_config.hall_offset[0] = best_offset_pos;
                    motorcontrol_config.hall_offset[1] = best_offset_neg;
                    printf("Tuning aborted!\nauto tuned offset clk: %d\nauto tuned offset cclk: %d\n", motorcontrol_config.hall_offset[0], motorcontrol_config.hall_offset[1]);
                    if (motorcontrol_config.commutation_method == FOC && motorcontrol_config.commutation_sensor != HALL_SENSOR) {
                        i_commutation.set_sensor_offset((best_offset_pos+best_offset_neg)/2);
                        motorcontrol_config.hall_offset[0] = 0;
                        motorcontrol_config.hall_offset[1] = 0;
                        printf("mean offset: %d\n", (best_offset_pos+best_offset_neg)/2);
                    }
                    i_commutation.set_config(motorcontrol_config);
                }
            }
            break;

        case i_tuning.set_position(int in_position):
            if (!isnull(i_position_control)) {
                /* Set new target position for profile position control */
                set_profile_position(in_position, 200, 200, 200, i_position_control);
                printf("Returned to %d\n", in_position);
                i_position_control.disable_position_ctrl();
//                delay_milliseconds(500);
                i_commutation.set_fets_state(1);
            } else {
                printf("No position control\n");
            }
            break;


        case i_tuning.set_limit(int in_limit):
            if (motorcontrol_config.commutation_sensor == BISS_SENSOR && !isnull(i_biss)) {
                i_biss.reset_biss_position(0);
            } else if (motorcontrol_config.commutation_sensor == AMS_SENSOR && !isnull(i_ams)) {
                i_ams.reset_ams_position(0);
            } else if (motorcontrol_config.commutation_sensor == HALL_SENSOR && !isnull(i_hall)) {
                i_hall.reset_hall_absolute_position(0);
            }
            if (in_limit < 0) {
                position_limit = in_limit;
                printf("Position limit disabled\n");
            } else if (in_limit > 0) {
                printf("Position limited to %d ticks around here\n", in_limit);
                position_limit = in_limit;
            } else {
                printf("Position limited around here\n");
            }
            break;

        case i_tuning.set_torque(int in_torque):
            target_torque = in_torque;
            break;

        case i_tuning.set_pole_pairs(int in_pole_pairs):
            if (motorcontrol_config.commutation_sensor == BISS_SENSOR && !isnull(i_biss)) {
                BISSConfig biss_config = i_biss.get_biss_config();
                biss_config.pole_pairs = in_pole_pairs;
                i_biss.set_biss_config(biss_config);
            } else if (motorcontrol_config.commutation_sensor == AMS_SENSOR && !isnull(i_ams)) {
                AMSConfig ams_config = i_ams.get_ams_config();
                ams_config.pole_pairs = in_pole_pairs;
                i_ams.set_ams_config(ams_config);
            } else if (motorcontrol_config.commutation_sensor == CONTELEC_SENSOR && !isnull(i_contelec)) {
                CONTELECConfig contelec_config = i_contelec.get_contelec_config();
                contelec_config.pole_pairs = in_pole_pairs;
                i_contelec.set_contelec_config(contelec_config);
            }
            break;

        case i_tuning.auto_offset() -> int out_offset:
            out_offset = auto_offset(i_commutation, i_contelec, i_ams);
            break;

        case i_tuning.set_sensor_offset(int in_offset) -> int out_offset:
            if (in_offset >= 0)
            {
                if (motorcontrol_config.commutation_sensor == CONTELEC_SENSOR && !isnull(i_contelec)) {
                    CONTELECConfig contelec_config = i_contelec.get_contelec_config();
                    contelec_config.offset = in_offset;
                    i_contelec.set_contelec_config(contelec_config);
                }
                else if (motorcontrol_config.commutation_sensor == AMS_SENSOR && !isnull(i_ams)) {
                    AMSConfig ams_config = i_ams.get_ams_config();
                    ams_config.offset = in_offset;
                    i_ams.set_ams_config(ams_config);
                }
            }
            else
            {
                if (motorcontrol_config.commutation_sensor == CONTELEC_SENSOR && !isnull(i_contelec)) {
                                    CONTELECConfig contelec_config = i_contelec.get_contelec_config();
                                    out_offset = contelec_config.offset;
                }
                else if (motorcontrol_config.commutation_sensor == AMS_SENSOR && !isnull(i_ams)) {
                                    AMSConfig ams_config = i_ams.get_ams_config();
                                    out_offset = ams_config.offset;
                }
            }
            break;
        }
    }
}
