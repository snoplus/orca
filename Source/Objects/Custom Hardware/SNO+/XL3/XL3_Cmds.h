//
//  XL3_Cmds.m
//  command protocol for the XL3 SNO Crate controller
//
//  Created by Jarek Kaspar on Sat, Jul 9, 2010.
//  Copyright (c) 2010 CENPA, University of Washington. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Washington at the Center for Experimental Nuclear Physics and 
//Astrophysics (CENPA) sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Washington reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#include <sys/types.h>
#include <stdint.h>

#define DAQ_QUIT_ID               (0x00) //disconnect from the daq
#define PONG_ID                   (0x01) //daq is alive
#define CHANGE_MODE_ID            (0x02) //change to INIT or NORMAL mode
#define STATE_MACHINE_RESET_ID    (0x03) //reset the state machine
#define DEBUGGING_MODE_ID         (0x04) //turn on verbose printout (not used in ORCA)
// XL3/FEC Level Tasks
#define FAST_CMD_ID               (0x20) //do one command, immediately respond with same packet (daq numbered)
#define MULTI_FAST_CMD_ID         (0x21) //do multiple commands, immediately respond with same packet (daq numbered)
#define QUEUE_CMDS_ID             (0x22) //add multiple cmds to cmd_queue, respond in cmd_ack packets (xl3 numbered)
#define CRATE_INIT_ID             (0x23) //one of the 17 packets containing the crate settings info from the database 
#define FEC_LOAD_CRATE_ADD_ID     (0x24) //???load crate address into FEC general csr
#define SET_CRATE_PEDESTALS_ID    (0x25) //Sets the pedestal enables on all connected fecs either on or off
#define BUILD_CRATE_CONFIG_ID     (0x26) //Updates the xl3's knowledge of the mb id's and db id's
#define LOADSDAC_ID               (0x27) //Load a single fec dac
#define MULTI_LOADSDAC_ID         (0x28) //Load multiple dacs
#define DESELECT_FECS_ID          (0x29) //deselect all fecs in vhdl
#define READ_PEDESTALS_ID         (0x2A) //queue any number of memory reads into cmd queue (not used in ORCA)
#define LOADTACBITS_ID            (0x2B) //loads tac bits on fecs
#define RESET_FIFOS_ID            (0x2C) //resets all the fec fifos
#define READ_LOCAL_VOLTAGE_ID     (0x2D) //read a single voltage on XL3 
#define CHECK_TOTAL_COUNT_ID      (0x2E) //readout cmos total count register 
#define SET_ALARM_DAC_ID          (0x2F) //???Set alarm dac
// HV Tasks
#define SET_HV_RELAYS_ID          (0x40) //turns on/off hv relays
#define GET_HV_STATUS_ID          (0x41) //checks voltage and current readback
#define HV_READBACK_ID            (0x42) //reads voltage and current 
#define READ_PMT_CURRENT_ID       (0x43) //reads pmt current from FEC hv csr 
#define SETUP_CHARGE_INJ_ID       (0x44) //setup charge injection in FEC hv csr
// Tests
#define FEC_TEST_ID               (0x60) //check read/write to FEC registers
#define MEM_TEST_ID               (0x61) //check read/write to FEC ram, address lines
#define VMON_ID                   (0x62) //reads FEC voltages
#define BOARD_ID_READ_ID          (0x63) //reads id of fec,dbs,hvc
#define ZDISC_ID                  (0x64) //zeroes discriminators
#define CALD_TEST_ID              (0x65) //checks adcs with calibration dac
#define SLOT_NOISE_RATE_ID        (0x66) //check the noise rate in a slot      

#define CALD_RESPONSE_ID        (0xAA) // response from cald_test, contains dac ticks and adc values 
#define PING_ID                 (0xBB) // check if daq is still connected
#define MEGA_BUNDLE_ID          (0xCC) // sending data, numbered by xl3
#define CMD_ACK_ID              (0xDD) // sending results of a cmd from the cmd queue, numbered by xl3
#define MESSAGE_ID              (0xEE) // sending a message, numbered by xl3 if a string, numbered by daq if an echod packet
#define ERROR_ID                (0xFE) // info on what error xl3 current has
#define SCREWED_ID              (0xFF) // info on what FEC is screwed

// global modes
// some cmds are not compatible with sno crate readout loop
#define INIT_MODE		(1) // readout loop not running
#define NORMAL_MODE		(2) // readout loop running
#define CGT_MODE		(3)

//xl3_code/include/main.h
//sbc in mtc crate is 10.0.0.2 (sudbury) 10.0.0.20 (penn)
//xl3 connects to 10.0.0.3 (sudbury) 10.0.0.21 (penn)
#define XL3_MAX_BUNDLES		100000
#define XL3_MAX_FEC_COMMANDS	10000
#define XL3_SEND_BUFSIZE	(1444)	// fixed buffer size of a mega bundle
#define XL3_MEGA_SIZE		(120)	// packet payload size in PMT bundles (12 B) "a mega bundle"
#define CMD_ID_BYTES		(4)	// packet header size in Bytes

//xl3_code/include/registers.h
// XL3 registers
#define RESET_REG		(0x02000000)
#define DATA_AVAIL_REG		(0x02000001)
#define XL3_CS_REG		(0x02000002)
#define XL3_MASK_REG		(0x02000003)
#define XL3_CLOCK_REG		(0x02000004)
#define RELAY_REG		(0x02000005)
#define XL3_XLCON_REG		(0x02000006)
#define TEST_REG		(0x02000007)
#define CRATE_GEO_REG		(0x02000008)
#define HV_CS_REG		(0x02000008)
#define HV_SETPOINTS		(0x02000009)
#define HV_VR_REG		(0x0200000A)
#define HV_CR_REG		(0x0200000B)
#define XL3_VM_REG		(0x0200000C)
#define XL3_VR_REG		(0x0200000E)

//FEC registers
//Discrete
#define GENERAL_CSR		(0x00000020)
#define ADC_VALUE_REG		(0x00000021)
#define VOLTAGE_MONITOR		(0x00000022)
#define PEDESTAL_ENABLE		(0x00000023)
#define DAC_PROGRAM		(0x00000024)
#define CALDAC_PROGRAM		(0x00000025)
#define CMOS_PROG_LOW		(0x0000002A)
#define CMOS_PROG_HIGH		(0x0000002B)
#define CMOS_LGISEL		(0x0000002C)
#define BOARD_ID_REG		(0x0000002D)
//Sequencer
#define SEQ_OUT_CSR		(0x00000080)
#define CMOS_CHIP_DISABLE	(0x00000090)
#define FIFO_DIFF_PTR		(0x0000009e)
//CMOS internal
#define CMOS_INTERN_TEST(num)	(0x00000100 + 0x00000004 + 0x00000008*num)
#define CMOS_INTERN_TOTAL(num)	(0x00000100 + 0x00000003 + 0x00000008*num)  

//CTC registers
#define CTC_DELAY_REG		(0x00000004)

// add to register value
#define READ_MEM		(0x30000000)
#define READ_REG		(0x10000000)
#define WRITE_MEM		(0x20000000)
#define WRITE_REG		(0x00000000)

#define FEC_SEL			(0x00100000) // to select board #i, (0..15), use FEC_SEL * i
#define CTC_SEL			(0x01000000)
#define XL3_SEL			(0x02000000)


//xl3_code/include/lwip_functions.h
typedef struct {
	uint16_t packet_num;
	uint8_t packet_type;
	uint8_t num_bundles;
}
XL3_CommandHeader;

#define XL3_MAXPAYLOADSIZE_BYTES	(1440)
#define XL3_HEADER_SIZE			(4)
#define XL3_PACKET_SIZE			(1444)

typedef struct {
	XL3_CommandHeader cmdHeader;
	char payload[XL3_MAXPAYLOADSIZE_BYTES];
}
XL3_Packet;

typedef struct {
	uint32_t cmd_num;	// id number unique in the packet it came from
	uint16_t packet_num;    // number of the packet that created this command
	uint16_t flags;		// 0 = ok, 1 = there was a bus error
	uint32_t address;	// address = spare MEMREG WRITE* SPARE Board_select<5..0> Address<19..0> 
	uint32_t data;
	}
FECCommand;

#define MAX_ACKS_SIZE (80)
typedef struct
{
        uint32_t howmany;
        FECCommand cmd[MAX_ACKS_SIZE];
} MultiFC;

// orca specific anonymous
typedef
	struct {
		uint32_t numberBytesinPayload;
		char payload[XL3_MAXPAYLOADSIZE_BYTES];
	}
XL3_PayloadStruct;

//db_types.h
typedef struct {
    uint16_t mb_id;
    uint16_t dc_id[4];
} hware_vals_t;

typedef struct {
    /* index definitions [0=ch0-3; 1=ch4-7; 2=ch8-11, etc] */
    unsigned char     rmp[8];    // back edge timing ramp    
    unsigned char     rmpup[8];  // front edge timing ramp    
    unsigned char     vsi[8];    // short integrate voltage     
    unsigned char     vli[8];    // long integrate voltage
} tdisc_t;

typedef struct {
    /* the folowing are motherboard wide constants */
    unsigned char     vmax;           // upper TAC reference voltage
    unsigned char     tacref;         // lower TAC reference voltage
    unsigned char     isetm[2];       // primary   timing current [0= tac0; 1= tac1]
    unsigned char     iseta[2];       // secondary timing current [0= tac0; 1= tac1]
    /* there is one unsigned char of TAC bits for each channel */
    unsigned char     tac_shift[32];  // TAC shift register load bits (see 
    // loadcmosshift.c for details)
    // [channel 0 to 31]      
} tcmos_t;

/* CMOS shift register 100nsec trigger setup */
typedef struct {
    unsigned char      mask[32];   
    unsigned char      tdelay[32];    // tr100 width (see loadcmosshift.c for details)
    // [channel 0 to 31], only bits 0 to 6 defined
} tr100_t;

/* CMOS shift register 20nsec trigger setup */
typedef struct {
    unsigned char      mask[32];    
    unsigned char      twidth[32];    //tr20 width (see loadcmosshift.c for details)
    // [channel 0 to 31], only bits 0 to 6 defined
    unsigned char      tdelay[32];    //tr20 delay (see loadcmosshift.c for details)
    // [channel 0 to 31], only buts 0 to 4 defined
} tr20_t;

typedef struct {
    uint16_t mb_id;
    uint16_t dc_id[4];
    unsigned char vbal[2][32];
    unsigned char vthr[32];
    tdisc_t tdisc;
    tcmos_t tcmos;
    unsigned char vint;       // integrator output voltage 
    unsigned char hvref;     // MB control voltage 
    tr100_t tr100;
    tr20_t tr20;
    uint16_t scmos[32];     // remaining 10 bits (see loadcmosshift.c for 
    uint32_t  disable_mask;
} mb_t;


//packet_types.h
typedef struct{
    uint32_t slot_mask;
} fec_test_args_t;

typedef struct{
    uint32_t error_flag;
    uint32_t discrete_reg_errors[16]; 
    uint32_t cmos_test_reg_errors[16];
} fec_test_results_t;

typedef struct{
    uint32_t slot_num;
} mem_test_args_t;

typedef struct{
    uint32_t error_flag;
    uint32_t address_bit_failures;
    uint32_t error_location;
    uint32_t expected_data;
    uint32_t read_data;
} mem_test_results_t;

typedef struct{
    uint32_t slot_num;
} vmon_args_t;

typedef struct{
    float voltages[21];
} vmon_results_t;

typedef struct{
    uint32_t slot;
    uint32_t chip;
    uint32_t reg;
} board_id_args_t;

typedef struct{
    uint32_t id;
} board_id_results_t;

typedef struct{
    uint32_t slot_mask;
} ped_run_args_t;

typedef struct{
    uint32_t error_flag;
    uint32_t discrete_reg_errors[16]; 
    uint32_t cmos_test_reg_errors[16];
} ped_run_results_t;

typedef struct{
    uint32_t slot;
    uint32_t reads;
} read_pedestals_args_t;

typedef struct{
    uint32_t mb_num;
    uint32_t xilinx_load;
    uint32_t hv_reset;
    uint32_t slot_mask;
    uint32_t ctc_delay;
    uint32_t shift_reg_only;
} crate_init_args_t;

typedef struct{
    uint32_t error_flags;
    hware_vals_t hware_vals[16];
} crate_init_results_t;

typedef struct{
    uint32_t mode;
    uint32_t davail_mask;
} change_mode_args_t;

typedef struct{
    uint32_t slot_mask;
} build_crate_config_args_t;

typedef struct{
    uint32_t error_flags;
    hware_vals_t hware_vals[16];
} build_crate_config_results_t;

typedef struct{
    uint32_t slot_mask;
    uint32_t pattern;
} set_crate_pedestals_args_t;

typedef struct{
    uint32_t slot_num;
    uint32_t dac_num;
    uint32_t dac_value;
} loadsdac_args_t;

typedef struct{
    uint32_t error_flags;
} loadsdac_results_t;

typedef struct{
    uint32_t num_dacs;
    loadsdac_args_t dacs[50];
} multi_loadsdac_args_t;

typedef struct{
    uint32_t error_flags;
} multi_loadsdac_results_t;

typedef struct{
    uint32_t voltage_select;
} read_local_voltage_args_t;

typedef struct{
    uint32_t error_flags;
    float voltage;
} read_local_voltage_results_t;

typedef struct{
    float voltage_a;
    float voltage_b;
    float current_a;
    float current_b;
} hv_readback_results_t;

typedef struct{
    uint32_t slot_mask;
} reset_fifos_args_t;

typedef struct{
    uint32_t crate_num;
    uint32_t select_reg;
    uint16_t tacbits[32];
} loadtacbits_args_t;

typedef struct{
    uint32_t slot_num;
    uint32_t offset;
    float rate;
} zdisc_args_t;

typedef struct{
    uint32_t dacs[3];
} set_alarm_dac_args_t;

typedef struct{
    uint32_t error_flag;
    float MaxRate[32];
    float UpperRate[32];
    float LowerRate[32];
    uint8_t MaxDacSetting[32];
    uint8_t ZeroDacSetting[32];
    uint8_t UpperDacSetting[32];
    uint8_t LowerDacSetting[32];
} zdisc_results_t;

typedef struct{
    uint32_t slot_mask;
    uint32_t num_points;
    uint32_t samples;
    uint32_t upper;
    uint32_t lower;
} cald_test_args_t;

typedef struct{
    uint16_t slot;
    uint16_t point[100];
    uint16_t adc0[100];
    uint16_t adc1[100];
    uint16_t adc2[100];
    uint16_t adc3[100];
} cald_response_results_t;

//sweep slot from 0 to 15 and rates go to rates[bit_set_idx*32 + channel]
//if slot 2 and 4 are masked in, slot 2 goes to rates[0-31], slot 4 [32-63]
typedef struct{
    uint32_t slot_mask;
    uint32_t channel_masks[16];
} check_total_count_args_t;

typedef struct{
    uint32_t error_flags;
    uint32_t counts[8*32];
} check_total_count_results_t;

//same style as counts
typedef struct{
    uint32_t slot_mask;
    uint32_t channel_masks[16];
    uint32_t period; //delay between reads [usec]
} read_cmos_rate_args_t;

typedef struct{
    uint32_t error_flags;
    float rates[8*32];
} read_cmos_rate_results_t;

//if slot and channel set then current goes to current_adc[slot*32 + channel]
typedef struct{
    uint32_t slot_mask;
    uint32_t channel_masks[16];
} read_pmt_base_currents_args_t;

typedef struct{
    uint32_t error_flags;
    uint8_t current_adc[16*32];
} read_pmt_base_currents_results_t;

typedef struct{
    uint32_t cmd_in_rejected;
    uint32_t transfer_error;
    uint32_t xl3_data_avail_unknown;
    uint32_t bundle_read_error;
    uint32_t bundle_resync_error;
    uint32_t mem_level_unknown[16];
} error_packet_t;

typedef struct{
    uint32_t screwed[16];
} screwed_packet_t;

