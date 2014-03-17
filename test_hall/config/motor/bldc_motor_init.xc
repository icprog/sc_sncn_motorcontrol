
/**
 *
 * \file bldc_motor_init.xc
 *	Motor Control config declarations
 *
 * Copyright (c) 2013, Synapticon GmbH
 * All rights reserved.
 * Author: Pavan Kanajar <pkanajar@synapticon.com> & Martin Schwarz <mschwarz@synapticon.com>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. Execution of this software or parts of it exclusively takes place on hardware
 *    produced by Synapticon GmbH.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * The views and conclusions contained in the software and documentation are those
 * of the authors and should not be interpreted as representing official policies,
 * either expressed or implied, of the Synapticon GmbH.
 *
 */

#include <bldc_motor_config.h>
#include "refclk.h"

extern int __qei_max_counts(int real_counts);

void init_hall_param(hall_par &hall_params)
{
	int max = MAX_POSITION_LIMIT;
	int min = MIN_POSITION_LIMIT;
	hall_params.pole_pairs = POLE_PAIRS;

	if(max >= 0 && min >= 0)
	{
		if(max > min)
			hall_params.max_ticks = max;
		else
			hall_params.max_ticks = min;
	}
	else if(max <= 0 && min <= 0)
	{
		if(max < min)
			hall_params.max_ticks = -max;
		else
			hall_params.max_ticks = -min;
	}
	else if(max > 0 && min < 0)
	{
		if(max > 0 - min)
			hall_params.max_ticks = max;
		else
			hall_params.max_ticks = 0 - min;
	}
	else if(max < 0 && min > 0)
	{
		if(min > 0 - max)
			hall_params.max_ticks = min;
		else
			hall_params.max_ticks = 0 - max;
	}
	hall_params.max_ticks_per_turn = POLE_PAIRS * 4096;
	//printintln(hall_params.max_ticks);
	hall_params.max_ticks += hall_params.max_ticks_per_turn ;  // tolerance
	//printintln(hall_params.max_ticks);

	return;
}

void init_qei_param(qei_par &qei_params)
{
	int max = MAX_POSITION_LIMIT;
	int min = MIN_POSITION_LIMIT;
	qei_params.real_counts = ENCODER_RESOLUTION;
	//qei_params.gear_ratio = GEAR_RATIO;

	if(max >= 0 && min >= 0)
	{
		if(max > min)
			qei_params.max_ticks = max;
		else
			qei_params.max_ticks = min;
	}
	else if(max <= 0 && min <= 0)
	{
		if(max < min)
			qei_params.max_ticks = -max;
		else
			qei_params.max_ticks = -min;
	}
	else if(max > 0 && min < 0)
	{
		if(max > 0 - min)
			qei_params.max_ticks = max;
		else
			qei_params.max_ticks = 0 - min;
	}
	else if(max < 0 && min > 0)
	{
		if(min > 0 - max)
			qei_params.max_ticks = min;
		else
			qei_params.max_ticks = 0 - max;
	}


	qei_params.index = QEI_SENSOR_TYPE;
	qei_params.max_ticks_per_turn = __qei_max_counts(qei_params.real_counts);
	qei_params.max_ticks += qei_params.max_ticks_per_turn;  // tolerance
	//printintln(qei_params.max_ticks);
	qei_params.poles = POLE_PAIRS;
	qei_params.sensor_polarity = SENSOR_PLACEMENT;
	return;
}

void init_csv_param(csv_par &csv_params)
{
	csv_params.max_motor_speed = MAX_NOMINAL_SPEED;
	if(POLARITY >= 0)
		csv_params.polarity = 1;
	else if(POLARITY < 0)
		csv_params.polarity = -1;
	return;
}

void init_csp_param(csp_par &csp_params)
{
	csp_params.base.max_motor_speed = MAX_NOMINAL_SPEED;
	if(POLARITY >= 0)
		csp_params.base.polarity = 1;
	else if(POLARITY < 0)
		csp_params.base.polarity = -1;
	csp_params.max_following_error = 0;
	csp_params.max_position_limit = MAX_POSITION_LIMIT;
	csp_params.min_position_limit = MIN_POSITION_LIMIT;
	return;
}


void init_pp_params(pp_par &pp_params)
{
	pp_params.base.max_profile_velocity = MAX_PROFILE_VELOCITY;
	pp_params.profile_velocity	= PROFILE_VELOCITY;
	pp_params.base.profile_acceleration = PROFILE_ACCELERATION;
	pp_params.base.profile_deceleration = PROFILE_DECELERATION;
	pp_params.base.quick_stop_deceleration = QUICK_STOP_DECELERATION;
	pp_params.max_acceleration = MAX_ACCELERATION;
	pp_params.base.polarity = POLARITY;
	pp_params.software_position_limit_max = MAX_POSITION_LIMIT;
	pp_params.software_position_limit_min = MIN_POSITION_LIMIT;
	return;
}

void init_pv_params(pv_par &pv_params)
{
	pv_params.max_profile_velocity = MAX_PROFILE_VELOCITY;
	pv_params.profile_acceleration = PROFILE_ACCELERATION;
	pv_params.profile_deceleration = PROFILE_DECELERATION;
	pv_params.quick_stop_deceleration = QUICK_STOP_DECELERATION;
	pv_params.polarity = POLARITY;
	return;
}

void init_pt_params(pt_par &pt_params)
{
	pt_params.profile_slope = PROFILE_TORQUE_SLOPE;
	pt_params.polarity = POLARITY;
}

void init_velocity_control_param(ctrl_par &velocity_ctrl_params)
{
	velocity_ctrl_params.Kp_n = VELOCITY_Kp_NUMERATOR;
	velocity_ctrl_params.Kp_d = VELOCITY_Kp_DENOMINATOR;
	velocity_ctrl_params.Ki_n = VELOCITY_Ki_NUMERATOR;
	velocity_ctrl_params.Ki_d = VELOCITY_Ki_DENOMINATOR;
	velocity_ctrl_params.Kd_n = VELOCITY_Kd_NUMERATOR;
	velocity_ctrl_params.Kd_d = VELOCITY_Kd_DENOMINATOR;
	velocity_ctrl_params.Loop_time = 1 * MSEC_STD;  //units - core timer value //CORE 2/1/0 default

	velocity_ctrl_params.Control_limit = 13739; //default

	if(velocity_ctrl_params.Ki_n != 0)    							//auto calculated using control_limit
		velocity_ctrl_params.Integral_limit = velocity_ctrl_params.Control_limit * (velocity_ctrl_params.Ki_d/velocity_ctrl_params.Ki_n) ;
	else
		velocity_ctrl_params.Integral_limit = 0;

	return;
}

void init_position_control_param(ctrl_par &position_ctrl_params)
{

	position_ctrl_params.Kp_n = POSITION_Kp_NUMERATOR;
	position_ctrl_params.Kp_d = POSITION_Kp_DENOMINATOR;
	position_ctrl_params.Ki_n = POSITION_Ki_NUMERATOR;
	position_ctrl_params.Ki_d = POSITION_Ki_DENOMINATOR;
	position_ctrl_params.Kd_n = POSITION_Kd_NUMERATOR;
	position_ctrl_params.Kd_d = POSITION_Kd_DENOMINATOR;
	position_ctrl_params.Loop_time = 1 * MSEC_STD;  // units - for CORE 2/1/0 only default

	position_ctrl_params.Control_limit = 13739; 							 // default do not change

	if(position_ctrl_params.Ki_n != 0)										 // auto calculated using control_limit
	{
		position_ctrl_params.Integral_limit = position_ctrl_params.Control_limit * (position_ctrl_params.Ki_d/position_ctrl_params.Ki_n);
	}
	else
	{
		position_ctrl_params.Integral_limit = 0;
	}

	return;
}

void init_torque_control_param(ctrl_par &torque_ctrl_params)
{

	torque_ctrl_params.Kp_n = TORQUE_Kp_NUMERATOR;
	torque_ctrl_params.Kp_d = TORQUE_Kp_DENOMINATOR;
	torque_ctrl_params.Ki_n = TORQUE_Ki_NUMERATOR;
	torque_ctrl_params.Ki_d = TORQUE_Ki_DENOMINATOR;
	torque_ctrl_params.Kd_n = TORQUE_Kd_NUMERATOR;
	torque_ctrl_params.Kd_d = TORQUE_Kd_DENOMINATOR;
	torque_ctrl_params.Loop_time = 1 * MSEC_STD;  // units - for CORE 2/1/0 only default

	torque_ctrl_params.Control_limit = 13739; 							 // default do not change

	if(torque_ctrl_params.Ki_n != 0)										 // auto calculated using control_limit
	{
		torque_ctrl_params.Integral_limit = torque_ctrl_params.Control_limit * (torque_ctrl_params.Ki_d/torque_ctrl_params.Ki_n);
	}
	else
	{
		torque_ctrl_params.Integral_limit = 0;
	}

	return;
}

void init_cst_param(cst_par &cst_params)
{
	cst_params.nominal_current = MAX_NOMINAL_CURRENT;
	cst_params.nominal_motor_speed = MAX_NOMINAL_SPEED;
	cst_params.polarity = POLARITY;
	cst_params.max_torque = MOTOR_TORQUE_CONSTANT * MAX_NOMINAL_CURRENT * IFM_RESOLUTION;
	cst_params.motor_torque_constant = MOTOR_TORQUE_CONSTANT;
}

void init_sensor_filter_param(filter_par &sensor_filter_par) //optional for user to change
{
	sensor_filter_par.filter_length = VELOCITY_FILTER_SIZE;
	return;
}
