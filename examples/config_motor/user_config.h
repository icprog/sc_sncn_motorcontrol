/**
 * @file user_config.h
 * @brief Motor Control config file (define your motor specifications here)
 * @author Synapticon GmbH <support@synapticon.com>
 */

#pragma once

#include <refclk.h>

#include <motor_config_qmot_qbl5704.h>

/////////////////////////////////////////////
//////  MOTOR SENSORS CONFIGURATION
/////////////////////////////////////////////
#include <sensor_config_biss_AC36_1213.h>
#include <sensor_config.h>
///////////////////////
// SENSOR 1 SETTINGS //
///////////////////////

// SENSOR 1 TYPE [HALL_SENSOR, REM_14_SENSOR, REM_16MT_SENSOR, BISS_SENSOR]
#define SENSOR_1_TYPE                     BISS_SENSOR//HALL_SENSOR

// FUNCTION OF SENSOR_1 [ SENSOR_FUNCTION_DISABLED, SENSOR_FUNCTION_COMMUTATION_AND_MOTION_CONTROL,
//                        SENSOR_FUNCTION_COMMUTATION_AND_FEEDBACK_DISPLAY_ONLY,
//                        SENSOR_FUNCTION_MOTION_CONTROL, SENSOR_FUNCTION_FEEDBACK_DISPLAY_ONLY
//                        SENSOR_FUNCTION_COMMUTATION_ONLY]
// Only one sensor can be selected for commutation, motion control or feedback display only
#define SENSOR_1_FUNCTION                 SENSOR_FUNCTION_COMMUTATION_AND_MOTION_CONTROL

// RESOLUTION (TICKS PER TURN) OF SENSOR_1
#define SENSOR_1_RESOLUTION               BISS_SENSOR_RESOLUTION

// VELOCITY COMPUTE PERIOD (ALSO POLLING RATE) OF SENSOR_1 (in microseconds)
#define SENSOR_1_VELOCITY_COMPUTE_PERIOD  BISS_SENSOR_VELOCITY_COMPUTE_PERIOD

// POLARITY OF SENSOR_1 SENSOR [1,-1]
#define SENSOR_1_POLARITY                 SENSOR_POLARITY_INVERTED

///////////////////////
// SENSOR 2 SETTINGS //
///////////////////////

// SENSOR 2 TYPE [HALL_SENSOR, REM_14_SENSOR, REM_16MT_SENSOR, BISS_SENSOR]
#define SENSOR_2_TYPE                     QEI_SENSOR//HALL_SENSOR

// FUNCTION OF SENSOR_2 [ SENSOR_FUNCTION_DISABLED, SENSOR_FUNCTION_COMMUTATION_AND_MOTION_CONTROL,
//                        SENSOR_FUNCTION_COMMUTATION_AND_FEEDBACK_DISPLAY_ONLY,
//                        SENSOR_FUNCTION_MOTION_CONTROL, SENSOR_FUNCTION_FEEDBACK_DISPLAY_ONLY
//                        SENSOR_FUNCTION_COMMUTATION_ONLY]
// Only one sensor can be selected for commutation, motion control or feedback display only
#define SENSOR_2_FUNCTION                 SENSOR_FUNCTION_FEEDBACK_DISPLAY_ONLY

// RESOLUTION (TICKS PER TURN) OF SENSOR_2
#define SENSOR_2_RESOLUTION               QEI_SENSOR_RESOLUTION

// VELOCITY COMPUTE PERIOD (ALSO POLLING RATE) OF SENSOR_2 (in microseconds)
#define SENSOR_2_VELOCITY_COMPUTE_PERIOD  QEI_SENSOR_VELOCITY_COMPUTE_PERIOD

// POLARITY OF SENSOR_2 SENSOR [1,-1]
#define SENSOR_2_POLARITY                 SENSOR_POLARITY_NORMAL

//////////////////////////////////////////////
//////  PROTECTION CONFIGURATION
//////////////////////////////////////////////
#define PROTECTION_MAXIMUM_CURRENT        100       //maximum tolerable value of phase current (under abnormal conditions)
#define PROTECTION_MINIMUM_VOLTAGE        10        //minimum tolerable value of dc-bus voltave (under abnormal conditions)
#define PROTECTION_MAXIMUM_VOLTAGE        55        //maximum tolerable value of dc-bus voltage (under abnormal conditions)
#define TEMP_BOARD_MAX                    80        //maximum tolerable value of board temperature (Degree Centigrade)


//////////////////////////////////////////////
//////  IFM TILE FREQ CONFIGURATION
//////////////////////////////////////////////

#define IFM_TILE_USEC       USEC_FAST      // Number of ticks in a microsecond for IFM Tile

//////////////////////////////////////////////
//////  MOTOR COMMUTATION CONFIGURATION
//////////////////////////////////////////////
#define DC_BUS_VOLTAGE             20

// COMMUTATION FREQUENCY [kHz]
#define COMMUTATION_FRQ            24

//// COMMUTATION CW SPIN OFFSET (if applicable) [0:4095]
#define COMMUTATION_ANGLE_OFFSET    1636

// (OPTIONAL) MOTOR ANGLE IN EACH HALL STATE. IN CASE HALL SENSOR IS USED FIND THE
// FOLLOWING VALUES BY RUNNING OFFSET DETECTION FUNCTION, OR SET THEM ALL TO 0
#define HALL_STATE_1_ANGLE     0
#define HALL_STATE_2_ANGLE     0
#define HALL_STATE_3_ANGLE     0
#define HALL_STATE_4_ANGLE     0
#define HALL_STATE_5_ANGLE     0
#define HALL_STATE_6_ANGLE     0

// MOTOR POLARITY [MOTOR_PHASES_NORMAL, MOTOR_PHASES_INVERTED]
#define MOTOR_PHASE_CONFIGURATION       MOTOR_PHASES_NORMAL


///////////////////////////////////////////////
//////  MOTOR CONTROL CONFIGURATION
///////////////////////////////////////////////

// motor id (in case more than 1 motor is controlled)
#define MOTOR_ID 0

// PID FOR TORQUE CONTROL (if applicable) [will be divided by 10000]
#define TORQUE_P_VALUE         40
#define TORQUE_I_VALUE         40
#define TORQUE_D_VALUE          0

// (maximum) generated torque while finding offset value as a percentage of rated torque
#define APPLIED_TUNING_TORQUE_PERCENT 20


/////////////////////////////////////////////////
//////  PROFILES AND LIMITS CONFIGURATION
/////////////////////////////////////////////////

// POLARITY OF THE MOVEMENT OF YOUR MOTOR [MOTION_POLARITY_NORMAL(0), MOTION_POLARITY_INVERTED(1)]
#define POLARITY           MOTION_POLARITY_NORMAL

#define MOTION_PROFILE_TYPE LINEAR


/////////////////////////////////////////////////
//////  POSITION CONTROLLER
/////////////////////////////////////////////////

//home offset
#define HOME_OFFSET                             0

//Limits
#define MIN_POSITION_RANGE_LIMIT                -0x7fffffff
#define MAX_POSITION_RANGE_LIMIT                 0x7fffffff

//Integrated Profiler
#define ENABLE_PROFILER                         0
#define MAX_ACCELERATION_PROFILER               10000    // [rpm/sec]
#define MAX_DECELERATION_PROFILER               10000    // [rpm/sec]
#define MAX_SPEED_PROFILER                      2000     // [rpm]


//nonlinear mode
#define POSITION_Kp                             20000
#define POSITION_Ki                             500
#define POSITION_Kd                             41000


/*
 * set "POSITION_INTEGRAL_LIMIT" equal to:
 *      "MOTOR_MAXIMUM_TORQUE" in case of using position controller in "POS_PID_CONTROLLER"                   mode
 *      "PEAK_SPEED"           in case of using position controller in "POS_PID_VELOCITY_CASCADED_CONTROLLER" mode
 *      "1000"                 in case of using position controller in "NL_POSITION_CONTROLLER"               mode
 */
#define POSITION_INTEGRAL_LIMIT                 1000 //MAXIMUM_TORQUE

#define MOMENT_OF_INERTIA                       0    //set this variable only if it is known in [gram square centimiter]
                                                     //otherwise set as 0

//PID parameters of the velocity PID controller
#define VELOCITY_Kp                             300000
#define VELOCITY_Ki                             2000
#define VELOCITY_Kd                             0
#define VELOCITY_INTEGRAL_LIMIT                 MOTOR_MAXIMUM_TORQUE


//////////////////////////////////////////////
//////  BRAKE CONFIGURATION
//////////////////////////////////////////////
#define BRAKE_RELEASE_STRATEGY     0    // 0 disabled, 1 normal, 2-100 shaking

#define BRAKE_RELEASE_DELAY        0    // delay in milliseconds between the brake blocking and the stop of the control

/*
 * Define: Voltage which will be applied to electric brake to release (pull) the brake at startup in [milli-Volt].
 * Note: The final voltage (on brake terminals) depends on brake loading characteristics. Generated voltage is precise in the case of pure resistive brake.
 */
#define PULL_BRAKE_VOLTAGE     13000    // [milli-Volts]

/*
 * Define: Voltage which will be applied to electric brake to hold the brake after it is pulled [milli-Volt].
 * Note: The final voltage (on brake terminals) depends on brake loading characteristics. Generated voltage is precise in the case of pure resistive brake.
 */
#define HOLD_BRAKE_VOLTAGE     7000     // [milli-Volts]

#define PULL_BRAKE_TIME        10000    //Time period in which it is tried to release (pull) the brake [milli seconds]


