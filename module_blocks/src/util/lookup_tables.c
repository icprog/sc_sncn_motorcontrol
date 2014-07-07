/**
 * @file sine_table_big.c
 * @brief Sine Lookup tables
 * @author Ludwig Orgler <lorgler@synapticon.com>
 */

#include <stdint.h>

/* sin(x) + 1/3 * sin(3x), x=0..pi/2 */
/* TODO: why is the scaling factor the way it is? it probably depends
 * on PWM_MAX_VALUE in some way...*/
/* TODO: maybe normalize to 16384 and use fixed point arithmetic to
 * calculate pwm values */
uint16_t sine_third[257] = {
       0,   85,  170,  256,  341,  426,  511,  596,
     680,  765,  849,  934, 1018, 1102, 1186, 1269,
    1352, 1435, 1518, 1601, 1683, 1765, 1846, 1927,
    2008, 2089, 2169, 2248, 2328, 2407, 2485, 2563,
    2640, 2717, 2794, 2870, 2945, 3020, 3094, 3168,
    3241, 3314, 3386, 3457, 3528, 3598, 3668, 3736,
    3804, 3872, 3939, 4005, 4070, 4135, 4199, 4262,
    4324, 4386, 4447, 4507, 4566, 4625, 4682, 4739,
    4795, 4850, 4905, 4958, 5011, 5063, 5114, 5164,
    5214, 5262, 5310, 5356, 5402, 5447, 5491, 5534,
    5576, 5618, 5658, 5697, 5736, 5774, 5810, 5846,
    5881, 5915, 5948, 5980, 6012, 6042, 6071, 6100,
    6127, 6154, 6180, 6205, 6229, 6252, 6274, 6295,
    6315, 6335, 6353, 6371, 6388, 6404, 6419, 6433,
    6446, 6458, 6470, 6481, 6491, 6500, 6508, 6515,
    6522, 6528, 6533, 6537, 6540, 6543, 6545, 6546,
    6546, 6546, 6545, 6543, 6541, 6537, 6533, 6529,
    6524, 6518, 6511, 6504, 6496, 6488, 6479, 6469,
    6459, 6448, 6436, 6424, 6412, 6399, 6386, 6372,
    6357, 6342, 6327, 6311, 6294, 6278, 6261, 6243,
    6225, 6207, 6188, 6169, 6150, 6130, 6110, 6090,
    6070, 6049, 6028, 6007, 5985, 5963, 5942, 5919,
    5897, 5875, 5852, 5830, 5807, 5784, 5761, 5738,
    5715, 5692, 5669, 5646, 5622, 5599, 5576, 5553,
    5530, 5507, 5484, 5461, 5438, 5416, 5393, 5371,
    5348, 5326, 5304, 5283, 5261, 5240, 5219, 5198,
    5177, 5157, 5136, 5116, 5097, 5078, 5058, 5040,
    5021, 5003, 4985, 4968, 4951, 4934, 4918, 4902,
    4887, 4871, 4857, 4842, 4828, 4815, 4802, 4789,
    4777, 4765, 4754, 4743, 4733, 4723, 4714, 4705,
    4696, 4688, 4681, 4674, 4667, 4661, 4656, 4651,
    4647, 4643, 4639, 4637, 4634, 4632, 4631, 4630, 4630 };

/* sin(x), x=0..pi/2 */
uint16_t sine_table[257] = {
        0,   101,   201,   302,   402,   503,   603,   704,
      804,   904,  1005,  1105,  1205,  1306,  1406,  1506,
     1606,  1706,  1806,  1906,  2006,  2105,  2205,  2305,
     2404,  2503,  2603,  2702,  2801,  2900,  2999,  3098,
     3196,  3295,  3393,  3492,  3590,  3688,  3786,  3883,
     3981,  4078,  4176,  4273,  4370,  4467,  4563,  4660,
     4756,  4852,  4948,  5044,  5139,  5235,  5330,  5425,
     5520,  5614,  5708,  5803,  5897,  5990,  6084,  6177,
     6270,  6363,  6455,  6547,  6639,  6731,  6823,  6914,
     7005,  7096,  7186,  7276,  7366,  7456,  7545,  7635,
     7723,  7812,  7900,  7988,  8076,  8163,  8250,  8337,
     8423,  8509,  8595,  8680,  8765,  8850,  8935,  9019,
     9102,  9186,  9269,  9352,  9434,  9516,  9598,  9679,
     9760,  9841,  9921, 10001, 10080, 10159, 10238, 10316,
    10394, 10471, 10549, 10625, 10702, 10778, 10853, 10928,
    11003, 11077, 11151, 11224, 11297, 11370, 11442, 11514,
    11585, 11656, 11727, 11797, 11866, 11935, 12004, 12072,
    12140, 12207, 12274, 12340, 12406, 12472, 12537, 12601,
    12665, 12729, 12792, 12854, 12916, 12978, 13039, 13100,
    13160, 13219, 13279, 13337, 13395, 13453, 13510, 13567,
    13623, 13678, 13733, 13788, 13842, 13896, 13949, 14001,
    14053, 14104, 14155, 14206, 14256, 14305, 14354, 14402,
    14449, 14497, 14543, 14589, 14635, 14680, 14724, 14768,
    14811, 14854, 14896, 14937, 14978, 15019, 15059, 15098,
    15137, 15175, 15213, 15250, 15286, 15322, 15357, 15392,
    15426, 15460, 15493, 15525, 15557, 15588, 15619, 15649,
    15679, 15707, 15736, 15763, 15791, 15817, 15843, 15868,
    15893, 15917, 15941, 15964, 15986, 16008, 16029, 16049,
    16069, 16088, 16107, 16125, 16143, 16160, 16176, 16192,
    16207, 16221, 16235, 16248, 16261, 16273, 16284, 16295,
    16305, 16315, 16324, 16332, 16340, 16347, 16353, 16359,
    16364, 16369, 16373, 16376, 16379, 16381, 16383, 16384, 16384 };
