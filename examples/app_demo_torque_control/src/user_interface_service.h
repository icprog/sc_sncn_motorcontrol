/*
 * user_interface_service.h
 *
 *  Created on: Jul 13, 2015
 *      Author: Synapticon GmbH
 */


#pragma once

#include <motor_control_interfaces.h>


/**
 * @brief Update brake hold/pull voltages and pull time in the pwm service.
 *
 *        It take the DC, hold/pull voltages and pull time parameters
 *        and compute the corresponding duty cycles which are then sent to the pwm service.
 *
 * @param app_tile_usec
 * @param dc_bus_voltage,     the voltage of dc bus (in volts)
 * @param pull_brake_voltage, the voltage of dc bus (in milli-volts)
 * @param hold_brake_voltage, the voltage of dc bus (in milli-volts)
 * @param pull_brake_time,    the time for pulling the brake (in milli-seconds)
 * @param i_torque_control client interface to get the ifm tile frequency from the motorcontrol service.
 * @param i_update_brake client enterface to the pwm service to send the brake configuration
 *
 */
void update_brake(
        int app_tile_usec,
        int dc_bus_voltage,
        int pull_brake_voltage,
        int hold_brake_voltage,
        int pull_brake_time,
        client interface TorqueControlInterface i_torque_control, client interface UpdateBrake i_update_brake);

/*
 * The following service shows how to directly work with module_torque_control.
 * It is able to:
 *  - automatically find motor offset
 *  - read/set motor offsett
 *  - enable/disable torque controller
 *  - send the reference value of the torque to motor_control_service
 *  - lock/unlock the brakes
 *
 * @param i_torque_control -> interface of type TorqueControlInterface to communicate with torque controller
 */
void demo_torque_control(interface TorqueControlInterface client i_torque_control, client interface UpdateBrake i_update_brake);
