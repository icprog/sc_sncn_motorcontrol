/**
 * @file adc_server_ad7949.xc
 * @brief ADC Server
 * @author Synapticon GmbH <support@synapticon.com>
*/

#include <xs1.h>
#include <stdint.h>
#include <xclib.h>
#include <refclk.h>
#include <print.h>
#include <adc_ad7949.h>
#include <xscope.h>

#define BIT13 0x00002000
#define BIT12 0x00001000
#define BIT11 0x00000800
#define BIT10 0x00000400
#define BIT09 0x00000200
#define BIT08 0x00000100
#define BIT07 0x00000080
#define BIT06 0x00000040
#define BIT05 0x00000020
#define BIT04 0x00000010
#define BIT03 0x00000008
#define BIT02 0x00000004
#define BIT01 0x00000002
#define BIT0  0x00000001

#define ADC_CALIB_POINTS 64
#define Factor 6

void output_adc_config_data(clock clk, in buffered port:32 p_data_a, in buffered port:32 p_data_b,
                            buffered out port:32 p_adc, int adc_cfg_data)
{
#pragma unsafe arrays
    int bits[4];

    bits[0]=0x80808000;
    if(adc_cfg_data & BIT13)
        bits[0] |= 0x0000B300;
    if(adc_cfg_data & BIT12)
        bits[0] |= 0x00B30000;
    if(adc_cfg_data & BIT11)
        bits[0] |= 0xB3000000;

    bits[1]=0x80808080;
    if(adc_cfg_data & BIT10)
        bits[1] |= 0x000000B3;
    if(adc_cfg_data & BIT09)
        bits[1] |= 0x0000B300;
    if(adc_cfg_data & BIT08)
        bits[1] |= 0x00B30000;
    if(adc_cfg_data & BIT07)
        bits[1] |= 0xB3000000;

    bits[2]=0x80808080;
    if(adc_cfg_data & BIT06)
        bits[2] |= 0x000000B3;
    if(adc_cfg_data & BIT05)
        bits[2] |= 0x0000B300;
    if(adc_cfg_data & BIT04)
        bits[2] |= 0x00B30000;
    if(adc_cfg_data & BIT03)
        bits[2] |= 0xB3000000;

    bits[3]=0x00808080;
    if(adc_cfg_data & BIT02)
        bits[3] |= 0x000000B3;
    if(adc_cfg_data & BIT01)
        bits[3] |= 0x0000B300;
    if(adc_cfg_data & BIT0)
        bits[3] |= 0x00B30000;

    stop_clock(clk);
    clearbuf(p_data_a);
    clearbuf(p_data_b);
    clearbuf(p_adc);
    p_adc <: bits[0];
    start_clock(clk);

    p_adc <: bits[1];
    p_adc <: bits[2];
    p_adc <: bits[3];

    sync(p_adc);
    stop_clock(clk);
}

static void configure_adc_ports(clock clk,
                                buffered out port:32 p_sclk_conv_mosib_mosia,
                                in buffered port:32 p_data_a,
                                in buffered port:32 p_data_b)
{
    /* SCLK period >= 22ns (45.45 MHz)
       clk needs to be configured twice as fast as the required SCLK frequency */
    configure_clock_rate_at_most(clk, 250, 7); // 83.3  --  < (2*45.45)

    /* when idle, keep clk and mosi low, conv high */
    configure_out_port(p_sclk_conv_mosib_mosia, clk, 0b0100);
    configure_in_port(p_data_a, clk);
    configure_in_port(p_data_b, clk);
    start_clock(clk);
}

static inline unsigned convert(unsigned raw)
{
    unsigned int data;

    /* raw == 0b xxxx aabb ccdd eeff ...
       we read every data bit twice because of port clock setting */

    raw = bitrev(raw);
    data  = raw & 0x06000000;
    data >>= 2;
    data |= raw & 0x00600000;
    data >>= 2;
    data |= raw & 0x00060000;
    data >>= 2;
    data |= raw & 0x00006000;
    data >>= 2;
    data |= raw & 0x00000600;
    data >>= 2;
    data |= raw & 0x00000060;
    data >>= 2;
    data |= raw & 0x00000006;
    data >>= 1;
    return data;
}

/*
 * ADC CONFIGURAION HOWTO
 *
 * Serialization: LSB first
 *
 * adc_config: !! reverse bit-order compared to AD7949 datasheet !!
 * Bit    Name  Description
 * 32:14  0     unused
 * 13     RB    Read back CFG reg       (  1 => no)
 * 12:11  SEQ   Sequencer               ( 00 => disable)
 * 10:8   REF   Reference selection     (100 => internal)
 * 7      BW    LPF bandwidth           (  1 => full)
 * 6:4    INx   Input channel selection (000 => CH0)
 * 3:1    INCC  Input channel config    (111 => unipolar, referenced to GND)
 * 0      CFG   Config update           (  1 => overwrite cfg reg)
 * -1     --PADDING-- (delay 1 clk cycle)
 * => adc_config = 0b100100100011110
 */

#pragma unsafe arrays
static int adc_ad7949_singleshot( buffered out port:32 p_sclk_conv_mosib_mosia,
                                   in buffered port:32 p_data_a,
                                   in buffered port:32 p_data_b,
                                   clock clk,
                                   const unsigned int adc_config_mot,
                                   const unsigned int adc_config_other[],
                                   const unsigned int delay,
                                   timer t,
                                   unsigned int adc_data_a[],
                                   unsigned int adc_data_b[],
                                   unsigned short &adc_index,
                                   int overcurrent_protection_is_active,
                                   interface WatchdogInterface client ?i_watchdog)
{
    unsigned int ts;
    unsigned int data_raw_a;
    unsigned int data_raw_b;
    int overcurrent_status;

    /* Reading/Writing after conversion (RAC)
       Read previous conversion result
       Write CFG for next conversion */
#define SPI_IDLE   configure_out_port(p_sclk_conv_mosib_mosia, clk, 0b0100)

    // CONGIG__other_n1     CFG_Imotx_x1       |CONGIG__other_n2     CFG_Imotx_x2     |CONGIG__other_n3     CFG_Imotx_x3       |
    // CONVERT_null         CONVERT_other_n1   |CONVERT_Imot_x1      CONVERT_other_n2 |CONVERT_Imot_x2      CONVERT_other_n3   |
    // READOUT_null         READOUT_other_null |READOUT_other_n1     READOUT_Imot_x1  |READOUT_other_n2     READOUT_Imot_x2    |
    // -----------
    // iIndexADC        0  			1			       2			      3
    // readout       extern   	temperature		current-voltage			extern

    SPI_IDLE;

    output_adc_config_data(clk, p_data_a, p_data_b, p_sclk_conv_mosib_mosia, adc_config_other[adc_index]);

    SPI_IDLE;

    t :> ts;
    p_data_a :> data_raw_a;
    adc_data_a[adc_index] = convert(data_raw_a);
    p_data_b :> data_raw_b;
    adc_data_b[adc_index] = convert(data_raw_b);
    adc_index++;
    adc_index &= 0x3;
    t when timerafter(ts + delay) :> ts;

    output_adc_config_data(clk, p_data_a, p_data_b, p_sclk_conv_mosib_mosia, adc_config_mot);
    SPI_IDLE;


    p_data_a :> data_raw_a;
    adc_data_a[4] = convert(data_raw_a);
    p_data_b :> data_raw_b;
    adc_data_b[4] = convert(data_raw_b);

    if ( (adc_data_a[4] > OVERCURRENT_IN_ADC_TICKS) || (adc_data_b[4] > OVERCURRENT_IN_ADC_TICKS)
        || (adc_data_a[4] < (MAX_ADC_VALUE - OVERCURRENT_IN_ADC_TICKS)) || (adc_data_b[4] < (MAX_ADC_VALUE - OVERCURRENT_IN_ADC_TICKS))){//overcurrent condition

        if(!isnull(i_watchdog) && overcurrent_protection_is_active){
                i_watchdog.stop();
                overcurrent_status = 1;
                printstr("\n> Overcurrent! ");printint(adc_data_a[4]);printstr(" ");printint(adc_data_b[4]);
        }
    }
    else overcurrent_status = 0;

    SPI_IDLE;
    t :> ts;
    return overcurrent_status;
}


void adc_ad7949_fixed_channel(interface ADCInterface server i_adc[2], AD7949Ports &adc_ports,
                                CurrentSensorsConfig &current_sensor_config, interface WatchdogInterface client ?i_watchdog)
{
    //#define AUTOCALIBRATION //FixMe: autocalibration should take place before PWM is activated.
    timer t;
    unsigned int ts;

    unsigned char ct;

    /********************************************************************************************************************************
     *  13  CFG     Configuration udpate
     *  12  INCC    Input channel configuration
     *  11  INCC    Input channel configuration
     *  10  INCC    Input channel configuration
     *  09  INx     Input channel selection bit 2 0..7
     *  08  INx     Input channel selection bit 1
     *  07  INx     Input channel selection bit 0
     *  06  BW      Select bandwidth for low-pass filter
     *  05  REF     Reference/buffer selection
     *  04  REF     Reference/buffer selection
     *  03  REF     Reference/buffer selection
     *  02  SEQ     Channel sequencer. Allows for scanning channels in an IN0 to IN[7:0] fashion.
     *  01  SEQ     Channel sequencer
     *  00  RB      Read back the CFG register.
     */

    /* Overwrite configuration update | unipolar, referenced to GND | Motor current (ADC Channel 0) | full Bandwidth | Internal reference, REF = 4,096V, temp enabled;
     * 1                                111                           000                             1                001
     *  Disable Sequencer | Do not read back contents of configuration
     *  00                  1
     */
    const unsigned int adc_config_mot     =   0b11110001001001;


    const unsigned int adc_config_other[] = { 0b10110001001001,   // Temperature
                                              0b11110101001001,   // ADC Channel 2, unipolar, referenced to GND  voltage and current
                                              0b11111001001001,   // ADC Channel 4, unipolar, referenced to GND  external A0/1_n
                                              0b11111011001001 }; // ADC Channel 5, unipolar, referenced to GND  external A0/1_p

    const unsigned int delay = (11*USEC_FAST) / 3; // 3.7 us
    unsigned int adc_data_a[5];
    unsigned int adc_data_b[5];
    unsigned short adc_index = 0;
    int i_calib_a = 0, i_calib_b = 0, i = 0, Icalibrated_a = 0, Icalibrated_b = 0;
    int overcurrent_protection_was_triggered = 0;
    int overcurrent_protection_is_active = 0;

    int i_max=100;
    int v_dc_max=100;
    int v_dc_min=0;
    int current_limit = i_max * 20;


    configure_adc_ports(adc_ports.clk, adc_ports.sclk_conv_mosib_mosia, adc_ports.data_a, adc_ports.data_b);

#ifdef AUTOCALIBRATION
    //Calibration
    while (i < ADC_CALIB_POINTS) {
        // get ADC reading

        adc_ad7949_singleshot(adc_ports.sclk_conv_mosib_mosia, adc_ports.data_a, adc_ports.data_b, adc_ports.clk,
                                               adc_config_mot,  adc_config_other, delay, t, adc_data_a, adc_data_b, adc_index, overcurrent_protection_is_active, i_watchdog);

        if (adc_data_a[4]>0 && adc_data_a[4]<16384  &&  adc_data_b[4]>0 && adc_data_b[4]<16384) {
            i_calib_a += adc_data_a[4];
            i_calib_b += adc_data_b[4];
            i++;
            if (i == ADC_CALIB_POINTS) {
                break;
            }
        }
    }

   i_calib_a = (i_calib_a >> Factor);
   i_calib_b = (i_calib_b >> Factor);
#else
   i_calib_a = 10002;
   i_calib_b = 10002;
#endif


   // TODO At least two dummy conversions to

    while (1)
    {
        #pragma ordered
        select
        {
        case i_adc[int i].set_protection_limits(int i_max_in, int i_ratio_in, int v_dc_max_in, int v_dc_min_in):
                i_max=i_max_in;
                v_dc_max=v_dc_max_in;
                v_dc_min=v_dc_min_in;
                current_limit = i_max * i_ratio_in;
                break;

        case i_adc[int i].get_all_measurements() -> {int phaseB_out, int phaseC_out, int V_dc_out, int torque_out, int fault_code_out}:
                t :> ts;
                unsigned int ts, te;
                unsigned int data_raw_a;
                unsigned int data_raw_b;

                /* Reading/Writing after conversion (RAC)
                   Read previous conversion result
                   Write CFG for next conversion */

                // CONGIG__other_n1     CFG_Imotx_x1       |CONGIG__other_n2     CFG_Imotx_x2     |CONGIG__other_n3     CFG_Imotx_x3       |
                // CONVERT_null         CONVERT_other_n1   |CONVERT_Imot_x1      CONVERT_other_n2 |CONVERT_Imot_x2      CONVERT_other_n3   |
                // READOUT_null         READOUT_other_null |READOUT_other_n1     READOUT_Imot_x1  |READOUT_other_n2     READOUT_Imot_x2    |
                // -----------
                // iIndexADC        0           1                  2                  3
                // readout       extern     temperature     current-voltage         extern

                configure_out_port(adc_ports.sclk_conv_mosib_mosia, adc_ports.clk, 0b0100);

//                #pragma unsafe arrays
//                int bits[4];
//
//                bits[0]=0x80808000;
//                if(adc_config_other[adc_index] & BIT13)
//                    bits[0] |= 0x0000B300;
//                if(adc_config_other[adc_index] & BIT12)
//                    bits[0] |= 0x00B30000;
//                if(adc_config_other[adc_index] & BIT11)
//                    bits[0] |= 0xB3000000;
//
//                bits[1]=0x80808080;
//                if(adc_config_other[adc_index] & BIT10)
//                    bits[1] |= 0x000000B3;
//                if(adc_config_other[adc_index] & BIT09)
//                    bits[1] |= 0x0000B300;
//                if(adc_config_other[adc_index] & BIT08)
//                    bits[1] |= 0x00B30000;
//                if(adc_config_other[adc_index] & BIT07)
//                    bits[1] |= 0xB3000000;
//
//                bits[2]=0x80808080;
//                if(adc_config_other[adc_index] & BIT06)
//                    bits[2] |= 0x000000B3;
//                if(adc_config_other[adc_index] & BIT05)
//                    bits[2] |= 0x0000B300;
//                if(adc_config_other[adc_index] & BIT04)
//                    bits[2] |= 0x00B30000;
//                if(adc_config_other[adc_index] & BIT03)
//                    bits[2] |= 0xB3000000;
//
//                bits[3]=0x00808080;
//                if(adc_config_other[adc_index] & BIT02)
//                    bits[3] |= 0x000000B3;
//                if(adc_config_other[adc_index] & BIT01)
//                    bits[3] |= 0x0000B300;
//                if(adc_config_other[adc_index] & BIT0)
//                    bits[3] |= 0x00B30000;
//
//                stop_clock(clk);
//                clearbuf(p_data_a);
//                clearbuf(p_data_b);
//                clearbuf(p_sclk_conv_mosib_mosia);
//                p_sclk_conv_mosib_mosia <: bits[0];
//                start_clock(clk);
//
//                p_sclk_conv_mosib_mosia <: bits[1];
//                p_sclk_conv_mosib_mosia <: bits[2];
//                p_sclk_conv_mosib_mosia <: bits[3];
//
//                sync(p_sclk_conv_mosib_mosia);
//                stop_clock(clk);
//
//                SPI_IDLE;
//
//                t :> ts;
//                p_data_a :> data_raw_a;
//                adc_data_a[adc_index] = convert(data_raw_a);
//                p_data_b :> data_raw_b;
//                adc_data_b[adc_index] = convert(data_raw_b);
//                adc_index++;
//                adc_index &= 0x3; // modulo, reset index
//                t when timerafter(ts + delay) :> ts;

                //output_adc_config_data(clk, p_data_a, p_data_b, p_sclk_conv_mosib_mosia, adc_config_mot);

                //void output_adc_config(clk, p_data_a, p_data_b, p_adc,                   adc_cfg_data);
                #pragma unsafe arrays
                int bits[4];

                bits[0]=0x80808000;
                if(adc_config_mot & BIT13)
                    bits[0] |= 0x0000B300;
                if(adc_config_mot & BIT12)
                    bits[0] |= 0x00B30000;
                if(adc_config_mot & BIT11)
                    bits[0] |= 0xB3000000;

                bits[1]=0x80808080;
                if(adc_config_mot & BIT10)
                    bits[1] |= 0x000000B3;
                if(adc_config_mot & BIT09)
                    bits[1] |= 0x0000B300;
                if(adc_config_mot & BIT08)
                    bits[1] |= 0x00B30000;
                if(adc_config_mot & BIT07)
                    bits[1] |= 0xB3000000;

                bits[2]=0x80808080;
                if(adc_config_mot & BIT06)
                    bits[2] |= 0x000000B3;
                if(adc_config_mot & BIT05)
                    bits[2] |= 0x0000B300;
                if(adc_config_mot & BIT04)
                    bits[2] |= 0x00B30000;
                if(adc_config_mot & BIT03)
                    bits[2] |= 0xB3000000;

                bits[3]=0x00808080;
                if(adc_config_mot & BIT02)
                    bits[3] |= 0x000000B3;
                if(adc_config_mot & BIT01)
                    bits[3] |= 0x0000B300;
                if(adc_config_mot & BIT0)
                    bits[3] |= 0x00B30000;

                stop_clock(adc_ports.clk);
                clearbuf(adc_ports.data_a);
                clearbuf(adc_ports.data_b);
                clearbuf(adc_ports.sclk_conv_mosib_mosia);
                adc_ports.sclk_conv_mosib_mosia <: bits[0];
                start_clock(adc_ports.clk);

                adc_ports.sclk_conv_mosib_mosia <: bits[1];
                adc_ports.sclk_conv_mosib_mosia <: bits[2];
                adc_ports.sclk_conv_mosib_mosia <: bits[3];

                sync(adc_ports.sclk_conv_mosib_mosia);
                stop_clock(adc_ports.clk);


                configure_out_port(adc_ports.sclk_conv_mosib_mosia, adc_ports.clk, 0b0100);

                adc_ports.data_a :> data_raw_a;
                adc_data_a[4] = convert(data_raw_a);
                adc_ports.data_b :> data_raw_b;
                adc_data_b[4] = convert(data_raw_b);

                configure_out_port(adc_ports.sclk_conv_mosib_mosia, adc_ports.clk, 0b0100);

                phaseB_out = current_sensor_config.sign_phase_b * (((int) adc_data_a[4]) - i_calib_a);
                phaseC_out = current_sensor_config.sign_phase_c * (((int) adc_data_b[4]) - i_calib_b);

                t :> te;

                xscope_int(CYCLE_TIME, te-ts);

                break;

        case i_adc[int i].get_currents() -> {int Ia, int Ib}:
                break;

        case i_adc[int i].get_temperature() -> {int out_temp}:
                break;

        case i_adc[int i].get_external_inputs() -> {int ext_a, int ext_b}:
                break;

        case i_adc[int i].helper_amps_to_ticks(float amps) -> int out_ticks:
                break;

        case i_adc[int i].helper_ticks_to_amps(int ticks) -> float out_amps:
                break;

        case i_adc[int i].enable_overcurrent_protection():
                break;

        case i_adc[int i].get_overcurrent_protection_status() -> int status:
                break;

        case i_adc[int i].reset_faults():
                break;
        }
    }
}

void adc_ad7949_triggered(interface ADCInterface server i_adc[2], AD7949Ports &adc_ports,
                                CurrentSensorsConfig &current_sensor_config, chanend c_trig, interface WatchdogInterface client ?i_watchdog)
{
    //#define AUTOCALIBRATION //FixMe: autocalibration should take place before PWM is activated.
    timer t;
    unsigned int ts;

    unsigned char ct;
    const unsigned int adc_config_mot     =   0b11110001001001;   /* Motor current (ADC Channel 0), unipolar, referenced to GND */
    const unsigned int adc_config_other[] = { 0b10110001001001,   // Temperature
                                              0b11110101001001,   // ADC Channel 2, unipolar, referenced to GND  voltage and current
                                              0b11111001001001,   // ADC Channel 4, unipolar, referenced to GND
                                              0b11111011001001 }; // ADC Channel 5, unipolar, referenced to GND

    const unsigned int delay = (11*USEC_FAST) / 3; // 3.7 us
    unsigned int adc_data_a[5];
    unsigned int adc_data_b[5];
    unsigned short adc_index = 0;
    int i_calib_a = 0, i_calib_b = 0, i = 0, Icalibrated_a = 0, Icalibrated_b = 0;
    int overcurrent_protection_was_triggered = 0;
    int overcurrent_protection_is_active = 0;

    configure_adc_ports(adc_ports.clk, adc_ports.sclk_conv_mosib_mosia, adc_ports.data_a, adc_ports.data_b);

#ifdef AUTOCALIBRATION
    //Calibration
    while (i < ADC_CALIB_POINTS) {
        // get ADC reading

        adc_ad7949_singleshot(adc_ports.sclk_conv_mosib_mosia, adc_ports.data_a, adc_ports.data_b, adc_ports.clk,
                                               adc_config_mot,  adc_config_other, delay, t, adc_data_a, adc_data_b, adc_index, overcurrent_protection_is_active, i_watchdog);

        if (adc_data_a[4]>0 && adc_data_a[4]<16384  &&  adc_data_b[4]>0 && adc_data_b[4]<16384) {
            i_calib_a += adc_data_a[4];
            i_calib_b += adc_data_b[4];
            i++;
            if (i == ADC_CALIB_POINTS) {
                break;
            }
        }
    }

   i_calib_a = (i_calib_a >> Factor);
   i_calib_b = (i_calib_b >> Factor);
#else
   i_calib_a = 10002;
   i_calib_b = 10002;
#endif


    while (1)
    {
#pragma ordered
        select
        {

        case inct_byref(c_trig, ct):
            if (ct == XS1_CT_END)
            {
                t :> ts;
                t when timerafter(ts + 7080) :> ts; // 6200

                overcurrent_protection_was_triggered = adc_ad7949_singleshot( adc_ports.sclk_conv_mosib_mosia, adc_ports.data_a, adc_ports.data_b,
                                                                              adc_ports.clk, adc_config_mot,	adc_config_other, delay, t, adc_data_a,
                                                                              adc_data_b, adc_index, overcurrent_protection_is_active, i_watchdog);
            }

            break;
        case i_adc[int i].set_protection_limits(int i_max, int i_ratio, int v_dc_max, int v_dc_min):
                break;
        case i_adc[int i].get_all_measurements() -> {int phaseB_out, int phaseC_out, int V_dc_out, int torque_out, int fault_code_out}:
                break;

        case i_adc[int i].get_currents() -> {int Ia, int Ib}:

                Ia = current_sensor_config.sign_phase_b * Icalibrated_a;
                Ib = current_sensor_config.sign_phase_c * Icalibrated_b;

                break;

        case i_adc[int i].get_temperature() -> {int out_temp}:

                out_temp = adc_data_a[1];

                break;

        case i_adc[int i].get_external_inputs() -> {int ext_a, int ext_b}:

                ext_a = adc_data_a[3];
                ext_b = adc_data_b[3];

                break;

        case i_adc[int i].helper_amps_to_ticks(float amps) -> int out_ticks:


                if(amps >= current_sensor_config.current_sensor_amplitude)
                     out_ticks = MAX_ADC_VALUE/2; break;
                if(amps <= -current_sensor_config.current_sensor_amplitude)
                    out_ticks = -MAX_ADC_VALUE/2; break;

                out_ticks = (int) amps * (MAX_ADC_VALUE/(2*current_sensor_config.current_sensor_amplitude));

                break;

        case i_adc[int i].helper_ticks_to_amps(int ticks) -> float out_amps:

                if(ticks >= MAX_ADC_VALUE/2)
                    out_amps = current_sensor_config.current_sensor_amplitude; break;
                if(ticks <= -MAX_ADC_VALUE/2)
                    out_amps = -current_sensor_config.current_sensor_amplitude; break;

                out_amps = ticks/(MAX_ADC_VALUE/2.0) * current_sensor_config.current_sensor_amplitude;

                break;

        case i_adc[int i].enable_overcurrent_protection():
              //  printstr("\n> Overcurrent protection enabled");
                overcurrent_protection_is_active = 1;
                break;

        case i_adc[int i].get_overcurrent_protection_status() -> int status:
                status = overcurrent_protection_was_triggered;
                break;

        case i_adc[int i].reset_faults():
                break;
        }

        Icalibrated_a = ((int) adc_data_a[4]) - i_calib_a;
        Icalibrated_b =((int) adc_data_b[4]) - i_calib_b;
    }
}


void adc_ad7949(interface ADCInterface server i_adc[2], AD7949Ports &adc_ports,
                                CurrentSensorsConfig &current_sensor_config, interface WatchdogInterface client ?i_watchdog)
{
    timer t;
    const unsigned int adc_config_mot     =   0b11110001001001;   /* Motor current (ADC Channel 0), unipolar, referenced to GND */
    const unsigned int adc_config_other[] = { 0b10110001001001,   // Temperature
                                              0b11110101001001,   // ADC Channel 2, unipolar, referenced to GND  voltage and current
                                              0b11111001001001,   // ADC Channel 4, unipolar, referenced to GND
                                              0b11111011001001 }; // ADC Channel 5, unipolar, referenced to GND

    const unsigned int delay = (11*USEC_FAST) / 3; // 3.7 us
    unsigned int adc_data_a[5];
    unsigned int adc_data_b[5];
    unsigned short adc_index = 0;
    int i_calib_a = 0, i_calib_b = 0, i = 0, Icalibrated_a = 0, Icalibrated_b = 0;
    int overcurrent_protection_was_triggered = 0;
    int overcurrent_protection_is_active = 0;

    configure_adc_ports(adc_ports.clk, adc_ports.sclk_conv_mosib_mosia, adc_ports.data_a, adc_ports.data_b);

#ifdef AUTOCALIBRATION
    //Calibration
    while (i < ADC_CALIB_POINTS) {
        // get ADC reading

        adc_ad7949_singleshot(adc_ports.sclk_conv_mosib_mosia, adc_ports.data_a, adc_ports.data_b, adc_ports.clk,
                                               adc_config_mot,  adc_config_other, delay, t, adc_data_a, adc_data_b, adc_index, overcurrent_protection_is_active, i_watchdog);

        if (adc_data_a[4]>0 && adc_data_a[4]<16384  &&  adc_data_b[4]>0 && adc_data_b[4]<16384) {
            i_calib_a += adc_data_a[4];
            i_calib_b += adc_data_b[4];
            i++;
            if (i == ADC_CALIB_POINTS) {
                break;
            }
        }
    }

   i_calib_a = (i_calib_a >> Factor);
   i_calib_b = (i_calib_b >> Factor);
#else
   i_calib_a = 10002;
   i_calib_b = 10002;
#endif

    while (1)
    {
#pragma ordered
        select
        {
        case i_adc[int i].set_protection_limits(int i_max, int i_ratio, int v_dc_max, int v_dc_min):
                break;

        case i_adc[int i].get_all_measurements() -> {int phaseB_out, int phaseC_out, int V_dc_out, int torque_out, int fault_code_out}:
                break;

        case i_adc[int i].get_currents() -> {int Ia, int Ib}:


                //If no trigger exists on the system, we sample on request
                overcurrent_protection_was_triggered =  adc_ad7949_singleshot( adc_ports.sclk_conv_mosib_mosia, adc_ports.data_a, adc_ports.data_b,
                                                                               adc_ports.clk, adc_config_mot,  adc_config_other, delay, t, adc_data_a,
                                                                               adc_data_b, adc_index, overcurrent_protection_is_active, i_watchdog);

                Icalibrated_a = ((int) adc_data_a[4]) - i_calib_a;
                Icalibrated_b = ((int) adc_data_b[4]) - i_calib_b;

                Ia = current_sensor_config.sign_phase_b * Icalibrated_a;
                Ib = current_sensor_config.sign_phase_c *Icalibrated_b;

                break;

        case i_adc[int i].get_temperature() -> {int out_temp}:

                //If no trigger exists on the system, we sample on request
                adc_index = 1;
                adc_ad7949_singleshot( adc_ports.sclk_conv_mosib_mosia, adc_ports.data_a, adc_ports.data_b,
                                        adc_ports.clk, adc_config_mot,  adc_config_other, delay, t, adc_data_a,
                                        adc_data_b, adc_index, overcurrent_protection_is_active, i_watchdog);

                out_temp = adc_data_a[1];

                break;

        case i_adc[int i].get_external_inputs() -> {int ext_a, int ext_b}:

                //If no trigger exists on the system, we sample on request
                adc_index = 3;
                adc_ad7949_singleshot( adc_ports.sclk_conv_mosib_mosia, adc_ports.data_a, adc_ports.data_b,
                                        adc_ports.clk, adc_config_mot,  adc_config_other, delay, t, adc_data_a,
                                        adc_data_b, adc_index, overcurrent_protection_is_active, i_watchdog);

                ext_a = adc_data_a[3];
                ext_b = adc_data_b[3];

                break;

        case i_adc[int i].helper_amps_to_ticks(float amps) -> int out_ticks:


                if(amps >= current_sensor_config.current_sensor_amplitude)
                     out_ticks = MAX_ADC_VALUE/2; break;
                if(amps <= -current_sensor_config.current_sensor_amplitude)
                    out_ticks = -MAX_ADC_VALUE/2; break;

                out_ticks = (int) amps * (MAX_ADC_VALUE/(2*current_sensor_config.current_sensor_amplitude));

                break;

        case i_adc[int i].helper_ticks_to_amps(int ticks) -> float out_amps:

                if(ticks >= MAX_ADC_VALUE/2)
                    out_amps = current_sensor_config.current_sensor_amplitude; break;
                if(ticks <= -MAX_ADC_VALUE/2)
                    out_amps = -current_sensor_config.current_sensor_amplitude; break;

                out_amps = ticks/(MAX_ADC_VALUE/2.0) * current_sensor_config.current_sensor_amplitude;

                break;

        case i_adc[int i].enable_overcurrent_protection():
          //      printstr("\n> Overcurrent protection enabled");
                overcurrent_protection_is_active = 1;
                break;

        case i_adc[int i].get_overcurrent_protection_status() -> int status:
                status = overcurrent_protection_was_triggered;
                break;

        case i_adc[int i].reset_faults():
                break;
        }
    }
}

