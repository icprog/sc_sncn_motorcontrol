
/**
 *
 * \file sine_table_big.c
 *	Sine Loopup tables
 *
 *
 * Copyright (c) 2013, Synapticon GmbH
 * All rights reserved.
 * Authors: Ludwig Orgler <lorgler@synapticon.com>
 *
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

#include "sine_table_big.h"

short arctg_table[1024+6]={//
        0,	1,	1,	2,	3,	3,	4,	4,	5,	6,	6,	7,	8,	8,	9,	10,	10,	11,	11,	12,	13,	13,	14,	15,	15,	16,	17,
        17,	18,	18,	19,	20,	20,	21,	22,	22,	23,	24,	24,	25,	25,	26,	27,	27,	28,	29,	29,	30,	31,	31,	32,	32,	33,	34,
        34,	35,	36,	36,	37,	38,	38,	39,	39,	40,	41,	41,	42,	43,	43,	44,	45,	45,	46,	46,	47,	48,	48,	49,	50,	50,	51,
       	52,	52,	53,	53,	54,	55,	55,	56,	57,	57,	58,	58,	59,	60,	60,	61,	62,	62,	63,	64,	64,	65,	65,	66,	67,	67,	68,
       	69,	69,	70,	70,	71,	72,	72,	73,	74,	74,	75,	75,	76,	77,	77,	78,	79,	79,	80,	81,	81,	82,	82,	83,	84,	84,	85,
       	86,	86,	87,	87,	88,	89,	89,	90,	91,	91,	92,	92,	93,	94,	94,	95,	96,	96,	97,	97,	98,	99,	99,	100,	101,	101,
       	102,	102,	103,	104,	104,	105,	105,	106,	107,	107,	108,	109,	109,	110,	110,	111,	112,	112,
       	113,	114,	114,	115,	115,	116,	117,	117,	118,	118,	119,	120,	120,	121,	122,	122,	123,	123,
       	124,	125,	125,	126,	126,	127,	128,	128,	129,	130,	130,	131,	131,	132,	133,	133,	134,	134,
       	135,	136,	136,	137,	137,	138,	139,	139,	140,	141,	141,	142,	142,	143,	144,	144,	145,	145,
       	146,	147,	147,	148,	148,	149,	150,	150,	151,	151,	152,	153,	153,	154,	154,	155,	156,	156,
       	157,	157,	158,	159,	159,	160,	160,	161,	162,	162,	163,	163,	164,	165,	165,	166,	166,	167,
       	168,	168,	169,	169,	170,	171,	171,	172,	172,	173,	174,	174,	175,	175,	176,	177,	177,	178,
       	178,	179,	179,	180,	181,	181,	182,	182,	183,	184,	184,	185,	185,	186,	187,	187,	188,	188,
       	189,	189,	190,	191,	191,	192,	192,	193,	194,	194,	195,	195,	196,	196,	197,	198,	198,	199,
       	199,	200,	201,	201,	202,	202,	203,	203,	204,	205,	205,	206,	206,	207,	207,	208,	209,	209,
       	210,	210,	211,	211,	212,	213,	213,	214,	214,	215,	215,	216,	217,	217,	218,	218,	219,	219,
      	220,	221,	221,	222,	222,	223,	223,	224,	225,	225,	226,	226,	227,	227,	228,	228,	229,	230,
      	230,	231,	231,	232,	232,	233,	234,	234,	235,	235,	236,	236,	237,	237,	238,	239,	239,	240,
      	240,	241,	241,	242,	242,	243,	244,	244,	245,	245,	246,	246,	247,	247,	248,	248,	249,	250,
      	250,	251,	251,	252,	252,	253,	253,	254,	255,	255,	256,	256,	257,	257,	258,	258,	259,	259,
      	260,	260,	261,	262,	262,	263,	263,	264,	264,	265,	265,	266,	266,	267,	267,	268,	269,	269,
      	270,	270,	271,	271,	272,	272,	273,	273,	274,	274,	275,	275,	276,	277,	277,	278,	278,	279,
      	279,	280,	280,	281,	281,	282,	282,	283,	283,	284,	284,	285,	285,	286,	287,	287,	288,	288,
      	289,	289,	290,	290,	291,	291,	292,	292,	293,	293,	294,	294,	295,	295,	296,	296,	297,	297,
      	298,	298,	299,	299,	300,	300,	301,	301,	302,	303,	303,	304,	304,	305,	305,	306,	306,	307,
      	307,	308,	308,	309,	309,	310,	310,	311,	311,	312,	312,	313,	313,	314,	314,	315,	315,	316,
      	316,	317,	317,	318,	318,	319,	319,	320,	320,	321,	321,	322,	322,	323,	323,	324,	324,	325,
      	325,	326,	326,	327,	327,	327,	328,	328,	329,	329,	330,	330,	331,	331,	332,	332,	333,	333,
      	334,	334,	335,	335,	336,	336,	337,	337,	338,	338,	339,	339,	340,	340,	341,	341,	342,	342,
      	342,	343,	343,	344,	344,	345,	345,	346,	346,	347,	347,	348,	348,	349,	349,	350,	350,	351,
      	351,	351,	352,	352,	353,	353,	354,	354,	355,	355,	356,	356,	357,	357,	358,	358,	358,	359,
      	359,	360,	360,	361,	361,	362,	362,	363,	363,	364,	364,	364,	365,	365,	366,	366,	367,	367,
      	368,	368,	369,	369,	369,	370,	370,	371,	371,	372,	372,	373,	373,	374,	374,	374,	375,	375,
      	376,	376,	377,	377,	378,	378,	378,	379,	379,	380,	380,	381,	381,	382,	382,	382,	383,	383,
      	384,	384,	385,	385,	386,	386,	386,	387,	387,	388,	388,	389,	389,	389,	390,	390,	391,	391,
      	392,	392,	392,	393,	393,	394,	394,	395,	395,	396,	396,	396,	397,	397,	398,	398,	399,	399,
      	399,	400,	400,	401,	401,	401,	402,	402,	403,	403,	404,	404,	404,	405,	405,	406,	406,	407,
      	407,	407,	408,	408,	409,	409,	409,	410,	410,	411,	411,	412,	412,	412,	413,	413,	414,	414,
      	414,	415,	415,	416,	416,	417,	417,	417,	418,	418,	419,	419,	419,	420,	420,	421,	421,	421,
      	422,	422,	423,	423,	423,	424,	424,	425,	425,	425,	426,	426,	427,	427,	427,	428,	428,	429,
      	429,	429,	430,	430,	431,	431,	431,	432,	432,	433,	433,	433,	434,	434,	435,	435,	435,	436,
      	436,	437,	437,	437,	438,	438,	439,	439,	439,	440,	440,	440,	441,	441,	442,	442,	442,	443,
      	443,	444,	444,	444,	445,	445,	445,	446,	446,	447,	447,	447,	448,	448,	449,	449,	449,	450,
      	450,	450,	451,	451,	452,	452,	452,	453,	453,	453,	454,	454,	455,	455,	455,	456,	456,	456,
      	457,	457,	458,	458,	458,	459,	459,	459,	460,	460,	461,	461,	461,	462,	462,	462,	463,	463,
      	463,	464,	464,	465,	465,	465,	466,	466,	466,	467,	467,	467,	468,	468,	469,	469,	469,	470,
      	470,	470,	471,	471,	471,	472,	472,	473,	473,	473,	474,	474,	474,	475,	475,	475,	476,	476,
      	476,	477,	477,	477,	478,	478,	479,	479,	479,	480,	480,	480,	481,	481,	481,	482,	482,	482,
      	483,	483,	483,	484,	484,	484,	485,	485,	485,	486,	486,	487,	487,	487,	488,	488,	488,	489,
      	489,	489,	490,	490,	490,	491,	491,	491,	492,	492,	492,	493,	493,	493,	494,	494,	494,	495,
      	495,	495,	496,	496,	496,	497,	497,	497,	498,	498,	498,	499,	499,	499,	500,	500,	500,	501,
      	501,	501,	502,	502,	502,	503,	503,	503,	504,	504,	504,	505,	505,	505,	506,	506,	506,	507,
      	507,	507,	508,	508,	508,	508,	509,	509,	509,	510,	510,	510,	511,	511,	511,	512,	512,    512};


short sine_third[257]={
		0,85,170,256,341,426,511,596,//
		680,765,849,934,1018,1102,1186,1269,//
		1352,1435,1518,1601,1683,1765,1846,1927,//
		2008,2089,2169,2248,2328,2407,2485,2563,//
		2640,2717,2794,2870,2945,3020,3094,3168,//
		3241,3314,3386,3457,3528,3598,3668,3736,//
		3804,3872,3939,4005,4070,4135,4199,4262,//
		4324,4386,4447,4507,4566,4625,4682,4739,//
		4795,4850,4905,4958,5011,5063,5114,5164,//
		5214,5262,5310,5356,5402,5447,5491,5534,//
		5576,5618,5658,5697,5736,5774,5810,5846,//
		5881,5915,5948,5980,6012,6042,6071,6100,//
		6127,6154,6180,6205,6229,6252,6274,6295,//
		6315,6335,6353,6371,6388,6404,6419,6433,//
		6446,6458,6470,6481,6491,6500,6508,6515,//
		6522,6528,6533,6537,6540,6543,6545,6546,//
		6546,6546,6545,6543,6541,6537,6533,6529,//
		6524,6518,6511,6504,6496,6488,6479,6469,//
		6459,6448,6436,6424,6412,6399,6386,6372,//
		6357,6342,6327,6311,6294,6278,6261,6243,//
		6225,6207,6188,6169,6150,6130,6110,6090,//
		6070,6049,6028,6007,5985,5963,5942,5919,//
		5897,5875,5852,5830,5807,5784,5761,5738,//
		5715,5692,5669,5646,5622,5599,5576,5553,//
		5530,5507,5484,5461,5438,5416,5393,5371,//
		5348,5326,5304,5283,5261,5240,5219,5198,//
		5177,5157,5136,5116,5097,5078,5058,5040,//
		5021,5003,4985,4968,4951,4934,4918,4902,//
		4887,4871,4857,4842,4828,4815,4802,4789,//
		4777,4765,4754,4743,4733,4723,4714,4705,//
		4696,4688,4681,4674,4667,4661,4656,4651,//
		4647,4643,4639,4637,4634,4632,4631,4630,//
		4630
};

short sine_table[257]={
		0,101,201,302,402,503,603,704,//
		804,904,1005,1105,1205,1306,1406,1506,//
		1606,1706,1806,1906,2006,2105,2205,2305,//
		2404,2503,2603,2702,2801,2900,2999,3098,//
		3196,3295,3393,3492,3590,3688,3786,3883,//
		3981,4078,4176,4273,4370,4467,4563,4660,//
		4756,4852,4948,5044,5139,5235,5330,5425,//
		5520,5614,5708,5803,5897,5990,6084,6177,//
		6270,6363,6455,6547,6639,6731,6823,6914,//
		7005,7096,7186,7276,7366,7456,7545,7635,//
		7723,7812,7900,7988,8076,8163,8250,8337,//
		8423,8509,8595,8680,8765,8850,8935,9019,//
		9102,9186,9269,9352,9434,9516,9598,9679,//
		9760,9841,9921,10001,10080,10159,10238,10316,//
		10394,10471,10549,10625,10702,10778,10853,10928,//
		11003,11077,11151,11224,11297,11370,11442,11514,//
		11585,11656,11727,11797,11866,11935,12004,12072,//
		12140,12207,12274,12340,12406,12472,12537,12601,//
		12665,12729,12792,12854,12916,12978,13039,13100,//
		13160,13219,13279,13337,13395,13453,13510,13567,//
		13623,13678,13733,13788,13842,13896,13949,14001,//
		14053,14104,14155,14206,14256,14305,14354,14402,//
		14449,14497,14543,14589,14635,14680,14724,14768,//
		14811,14854,14896,14937,14978,15019,15059,15098,//
		15137,15175,15213,15250,15286,15322,15357,15392,//
		15426,15460,15493,15525,15557,15588,15619,15649,//
		15679,15707,15736,15763,15791,15817,15843,15868,//
		15893,15917,15941,15964,15986,16008,16029,16049,//
		16069,16088,16107,16125,16143,16160,16176,16192,//
		16207,16221,16235,16248,16261,16273,16284,16295,//
		16305,16315,16324,16332,16340,16347,16353,16359,//
		16364,16369,16373,16376,16379,16381,16383,16384,//
		16384
};


