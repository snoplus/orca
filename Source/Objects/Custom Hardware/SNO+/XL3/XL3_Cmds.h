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

// xl3_code/include/xl3_functions.h
// possible cmdID's for packets recieved by XL3 (from the DAQ)
#define CHANGE_MODE_ID		(0x01)	// change mode
#define XL3_TEST_CMD_ID 	(0x02)	// do any of the test functions (check test_function.h)
#define SINGLE_CMD_ID		(0x04)	// execute one cmd and get result
#define DAQ_QUIT_ID		(0x05)	// quit
#define FEC_CMD_ID		(0x06)	// put one or many cmds in cmd queue
#define FEC_TEST_ID		(0x07)	// DAQ functions below ...
#define MEM_TEST_ID		(0x08)
#define CRATE_INIT_ID		(0x09)
#define VMON_START_ID		(0x0A)
#define BOARD_ID_READ_ID	(0x0B)
#define ZERO_DISCRIMINATOR_ID	(0x0C)
#define FEC_LOAD_CRATE_ADD_ID	(0x0D)
#define SET_CRATE_PEDESTALS_ID	(0x0E)
#define DESELECT_FECS_ID	(0x0F)
#define BUILD_CRATE_CONFIG_ID	(0x10)
#define LOADSDAC_ID		(0x11)
#define CALD_TEST_ID		(0x12)
#define STATE_MACHINE_RESET_ID	(0x13)
#define MULTI_CMD_ID		(0x14)
#define DEBUGGING_MODE_ID	(0x15)
#define READ_PEDESTALS_ID	(0x16)
#define PONG_ID			(0x17)
#define MULTI_LOADSDAC_ID	(0x18)
#define CGT_TEST_ID		(0x19)
#define LOADTACBITS_ID		(0x1A)
#define CMOSGTVALID_ID		(0x1B)
#define RESET_FIFOS_ID		(0x1C)

// possible cmdID's for packets sent by XL3 (to the DAQ)
#define CGT_UPDATE_ID		(0xAA)
#define PING_ID			(0xBB)
#define MEGA_BUNDLE_ID		(0xCC)
#define CMD_ACK_ID		(0xDD)
#define MESSAGE_ID		(0xEE)
#define STATUS_ID		(0xFF)

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
typedef
	struct {
		uint16_t packet_num;
		uint8_t packet_type;
		uint8_t num_bundles;
	}
XL3_CommandHeader;

#define XL3_MAXPAYLOADSIZE_BYTES	(1440)
#define XL3_HEADER_SIZE			(4)
#define XL3_PACKET_SIZE			(1444)

typedef
	struct {
		XL3_CommandHeader cmdHeader;
		char payload[XL3_MAXPAYLOADSIZE_BYTES];
	}
XL3_Packet;

typedef
	struct {
		uint16_t cmdID;
		uint8_t flags;
		uint32_t address;
		uint32_t data;
}
FECCommand;

// orca specific anonymous
typedef
	struct {
		uint32_t numberBytesinPayload;
		char payload[XL3_MAXPAYLOADSIZE_BYTES];
	}
XL3_PayloadStruct;


typedef struct
{
	uint16_t mb_id;
	uint16_t dc_id[4];
} mb_hware_vals_t;

// integrator voltage balance
typedef struct
{
	uint16_t mb_id;
	uint16_t dc_id[4];
	uint8_t vbal[2][32]; // 0 = high gain, 1 = low gain, channel 0 to 31
} vbal_vals_t;

// discriminator thresholds
typedef struct
{
	uint16_t mb_id;
	uint16_t dc_id[4];
	uint8_t vthr[32]; // channel 0 to 31
} vthr_vals_t;

// discriminator timing setup
typedef struct
{
	uint16_t mb_id;
	uint16_t dc_id[4];
	// index definitions: 0=ch0-3, 1=ch4-7, 2=ch8-11, etc
	uint8_t rmp[8]; // back edge timing ramp
	uint8_t rmpup[8]; // front edge timing ramp
	uint8_t vsi[8]; // short integrate voltage
	uint8_t vli[8]; // long integrate voltage
} tdisc_vals_t;

// CMOS timing setup
typedef struct
{
	uint16_t mb_id;
	uint16_t dc_id[4];
	// the following are motherboard wide constants
	uint8_t vmax; // upper TAC reference voltage
	uint8_t tacref; // lower TAC reference voltage
	uint8_t isetm[2]; // primary timing current (0=tac0,1=tac1)
	uint8_t iseta[2]; // secondary timing current 
	// there is one byte of TAC bits for each channel
	uint8_t tac_shift[32]; // TAC shift register load bits channel 0 to 31
} tcmos_vals_t;

// integrator nominal voltage level setup
typedef struct
{
	uint16_t mb_id;
	uint8_t vres; //integrator output voltage
} vint_vals_t;

// charge injection control voltages and timing
typedef struct
{
	uint16_t mb_id;
	uint16_t hv_id; // HV card id
	uint8_t hvref; // MB control voltage
	uint32_t ped_time; // MTCD pedestal width (DONT NEED THIS HERE)
} chinj_vals_t;

// CMOS shift register 100nsec trigger setup
typedef struct
{
	uint16_t mb_id;
	uint16_t dc_id[4];
	uint8_t twidth[32]; // tr100 width, channel 0 to 31, only bits 0 to 6 defined
} tr100_vals_t;

// CMOS shift register 20nsec trigger setup
typedef struct
{
	uint16_t mb_id;
	uint16_t dc_id[4];
	uint8_t twidth[32]; //tr20 width, channel 0 to 31, only bits 0 to 6 defined
	uint8_t tdelay[32]; //tr20 delay, channel 0 to 31, only bits 0 to 4 defined
} tr20_vals_t;

typedef struct
{
	uint16_t mb_id;
	uint16_t dc_id[4];
	uint16_t stuff[32]; // remaining 10 bits, channel 0 to 31, only bits 0 to 9 defined
} scmos_vals_t;

typedef struct
{
	uint16_t mb_id;
	uint16_t dc_id[4];
	uint32_t disable_mask;
} mb_chan_disable_vals_t;

typedef struct
{
	uint16_t mb_id;
	uint16_t dc_id[4];
} hware_vals_t;

// struct that points to all motherboard constants
typedef struct
{
	vbal_vals_t vbal;
	vthr_vals_t vthr;
	tdisc_vals_t tdisc;
	tcmos_vals_t tcmos;
	vint_vals_t vint;
	chinj_vals_t chinj;
	tr100_vals_t tr100;
	tr20_vals_t tr20;
	scmos_vals_t scmos;
	mb_hware_vals_t hware;
	mb_chan_disable_vals_t mb_chan_disable;
} mb_const_t;

// struct that points to all mb constants for a full crate
typedef struct
{
	mb_const_t mb[16];
	uint32_t ctcdelay;
} crate_mb_const_t;


// struct for fec voltages
typedef struct
{
	uint16_t hvtst;
	uint16_t vref1m;
	uint16_t vref2m;
	uint16_t vsup3_3m;
	uint16_t vee;
	uint16_t vsup2m;
	uint16_t vsup15m;
	uint16_t vsup24m;
	uint16_t caldacv;
	uint16_t tempmon;
	uint16_t vref0_8p;
	uint16_t vref1p;
	uint16_t vsup3_3p;
	uint16_t vref4p;
	uint16_t vsup4p;
	uint16_t vref5p;
	uint16_t vsup8p;
	uint16_t vsup15p;
	uint16_t vsup24p;
	uint16_t vcc;
	uint16_t vsup6_5p;
} fec_voltage_t;

typedef struct
{
	char header1;
	char header2;
	char header3;
	char header4;
	vthr_vals_t vthr_vals_found[16];
} disc_zero_response_t;

