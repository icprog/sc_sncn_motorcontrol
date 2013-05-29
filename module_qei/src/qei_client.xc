/*
 *
 * File:    qei_client.xc
 *
 * Get the position from the QEI server
 *
 * The copyrights, all other intellectual and industrial 
 * property rights are retained by XMOS and/or its licensors. 
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2013
 *
 * In the case where this code is a modification of existing code
 * under a separate license, the separate license terms are shown
 * below. The modifications to the code are still covered by the 
 * copyright notice above.
 *
 */

#include <xs1.h>
#include <stdio.h>
#include "qei_commands.h"
#include "qei_client.h"
#include<print.h>
// = QEI_COUNT_MAX;


//only pos and valid
{unsigned, unsigned} get_qei_position(chanend c_qei )
{
	unsigned p, ts1, ts2, v;


	c_qei <: QEI_CMD_POS_REQ;
	master {
		c_qei :> p;
		c_qei :> ts1;
		c_qei :> ts2;
		c_qei :> v;
	}
	p &= (QEI_COUNT_MAX-1);

	return {p, v};
}

//counted up position
{int, int} get_qei_position_count(chanend c_qei)
{
	int pos;
	int dirn; 				// clockwise +1  counterclockwise -1
	c_qei <: 2;
	master
	{
		c_qei :> pos;
		c_qei :> dirn;
	}
	return {pos, dirn};
}

{unsigned, unsigned, unsigned } get_qei_data( chanend c_qei, qei_par &q_max)
{
	unsigned p, s, ts1, ts2, v, qei_count_m = q_max.max_count;
	c_qei <: QEI_CMD_POS_REQ;
	c_qei :> p;
	c_qei :> ts1;
	c_qei :> ts2;
	c_qei :> v;

	p &= (qei_count_m-1);// qei_count_m

	// Calculate the speed
	if (ts1 == ts2)
		s = 0;
	else {
#if PLATFORM_REFERENCE_MHZ == 100
		// 6000000000 = 10ns -> 1min (100 MHz ports)
		s = 3000000000 / ((ts1 - ts2) * qei_count_m);
		s <<= 1;
#else
		// 15000000000 = 4ns -> 1min (250 MHz ports)
		s = 1875000000 / ((ts1 - ts2) * qei_count_m);
		s <<= 3;
#endif
	}

	return {s, p, v};
}
