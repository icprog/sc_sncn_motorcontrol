
/**
 * \file comm_loop.h
 *
 *	Commutation Loop based on Space Vector PWM method
 *
 * Copyright 2013, Synapticon GmbH. All rights reserved.
 * Authors: Pavan Kanajar <pkanajar@synapticon.com>, Ludwig Orgler <orgler@tin.it>
 * 			& Martin Schwarz <mschwarz@synapticon.com>
 *
 * In the case where this code is a modification of existing code
 * under a separate license, the separate license terms are shown
 * below. The modifications to the code are still covered by the
 * copyright notice above.
 *
 **/

#pragma once

#include <pwm_config.h>
#include "pwm_cli_inv.h"
#include "predriver/a4935.h"
#include "sine_table_big.h"
#include "adc_client_ad7949.h"
#include "hall_client.h"
#include "dc_motor_config.h"


typedef struct S_COMMUTATION {
	int angle_variance;
	int max_speed_reached;
	int qei_forward_offset;
	int qei_backward_offset;
	int flag;
} commutation_par;

/**
* \brief initialize commutation parameters
*
* \param commutation_params struct defines the commutation angle parameters
*/
void init_commutation_param(commutation_par &commutation_params, hall_par &hall_params, int nominal_speed);

void commutation_sensor_select(chanend c_commutation, int sensor_select);

int init_commutation(chanend c_signal);

/**
 * \brief Sinusoidal based Commutation Loop
 *
 * \channel c_hall channel to receive position information
 * \channel c_pwm_ctrl channel to set pwm level output
 * \channel signal_adc channel for signaling to start adc after initialization
 * \channel c_commutation_p1 channel to receive motor voltage input value - priority 1
 * \channel c_commutation_p2 channel to receive motor voltage input value - priority 2
 * \channel c_commutation_p3 channel to receive motor voltage input value - priority 3
 */
void  commutation_sinusoidal(int sensor_select, hall_par &hall_params, qei_par &qei_params, commutation_par &commutation_params, chanend c_hall, chanend c_qei, chanend c_pwm_ctrl, chanend signal_adc,\
		chanend c_signal, chanend c_sync, chanend  c_commutation_p1, chanend  c_commutation_p2, chanend  c_commutation_p3);
/**
 *  \brief Set Input voltage for commutation loop
 *
 * 	\channel c_commutation channel to send out motor voltage input value
 * 	\param input_voltage is motor voltage input value to be set (range allowed -13739 to 13739)
 */
void set_commutation_sinusoidal(chanend c_commutation, int input_voltage);

void set_commutation_params(chanend c_commutation, commutation_par &commutation_params);
