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

#ifndef _H_XL3CMDS_
#define _H_XL3CMDS_

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

// possible cmdID's for packets sent by XL3 (to the DAQ)
#define MEGA_BUNDLE_ID		(0x100)
#define CMD_ACK_ID		(0x101)
#define MESSAGE_ID		(0x099)
#define STATUS_ID		(0x999)

// possible packet types recieved by XL3 (from the DAQ)
#define FEC_CMD_PACKET		(401)
#define FEC_DATA_PACKET		(402)
#define DAQ_QUIT		(404)
#define XL3_TEST_CMD_PACKET	(405)
#define XL3_TEST_DATA_PACKET	(406)
#define CHANGE_MODE_PACKET	(407)
#define CRATE_INIT		(408)
#define FEC_TEST		(409)
#define MEM_TEST		(410)
#define VMON_START		(411)
#define BOARD_ID_READ		(412)
#define ZERO_DISCRIMINATOR	(413)
#define FEC_LOAD_CRATE_ADD	(414)
#define SET_CRATE_PEDESTALS	(415)
#define DESELECT_ALL_FECS	(416)

// global modes
// some cmds are not compatible with sno crate readout loop
#define INIT_MODE		(1) // readout loop not running
#define NORMAL_MODE		(2) // readout loop running
#define OTHER_MODE		(3)
#define CHANGE_MODE		(4)

//xl3_code/include/main.h
//xl3 terminal is 10.0.0.1
//sbc in mtc crate is 10.0.0.2
//xl3 connects to 10.0.0.3 at the moment (ORCA box)
#define XL3_MAX_BUNDLES		100000
#define XL3_MAX_FEC_COMMANDS	10000
#define XL3_SEND_BUFSIZE	(1444)	// fixed buffer size of a mega bundle
#define XL3_MEGA_SIZE		(120)	// packet payload size in PMT bundles (12 B) "a mega bundle"
#define CMD_ID_BYTES		(4)	// packet header size in Bytes
#define PORT			(6001)	// XL3 connects to PORT, ... PORT + 9
#define PORT2			(5002)	// ?

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
		//uint32_t destination;
		uint32_t cmdID;
		//uint32_t numberBytesinPayload;
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

#endif
