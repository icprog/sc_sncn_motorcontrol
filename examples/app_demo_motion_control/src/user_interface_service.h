/*
 * user_interface_service.h
 *
 *      Author: Synapticon GmbH
 */

#pragma once

#include <platform.h>
#include <motor_control_interfaces.h>
#include <advanced_motor_control.h>
#include <refclk.h>
#include <adc_service.h>
#include <motion_control_service.h>

#include <xscope.h>
#include <mc_internal_constants.h>

interface PositionLimiterInterface {
    void set_limit(int limit);
    int get_limit();
};


/**
 * @brief Structure type to recieve user inputs from xtimecomposer console
 */
typedef struct
{
    char first_char;
    char second_char;
    char third_char;
    int  value;
}ConsoleInputs;

/**
 * @brief receive user inputs from xtimecomposer. By default, it gets 3 characters, and one value from the console.
 *
 * @return ConsoleInputs structure including the user inputs.
 */
ConsoleInputs get_user_command();

/**
 * @brief Demonstrate usage of:
 *      - position controller (with a simple profiler)
 *      - velocity controller (with a simple profiler)
 *      - torque controller   (bypassing higher level controllers, with a simple profiler)
 *
 * @return ConsoleInputs structure including the user inputs.
 */
void demo_motion_control(client interface MotionControlInterface i_motion_control);
