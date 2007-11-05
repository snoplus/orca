
/*---------------------------------------------------------------------------
/	SBC_Cmds.h
/  command protocol for the PCI controller
/
/	02/21/06 Mark A. Howe
/	CENPA, University of Washington. All rights reserved.
/	ORCA project
/  ---------------------------------------------------------------------------
*/
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

#ifndef _H_SBCCMDS_
#define _H_SBCCMDS_

#include <sys/types.h>
#include "SBC_Config.h"

/*destinations*/
#define kSBC_Process	0x1
#define kAcqirisDC440	0x2

/* SBC commands */
#define kSBC_Command			0x01
#define kSBC_ReadBlock			0x02
#define kSBC_WriteBlock			0x03
#define kSBC_LoadConfig			0x04
#define kSBC_RunInfoRequest		0x05
#define kSBC_DataBlock			0x06
#define kSBC_AcqirisDC440Cmd	0x07
#define kSBC_CBBlock			0x08
#define kSBC_StartRun			0x0a
#define kSBC_StopRun			0x0b
#define kSBC_CBRead				0x0c
#define kSBC_ConnectionStatus	0x0d
#define kSBC_VmeReadBlock		0x0e
#define kSBC_VmeWriteBlock		0x0f

#define kSBC_Exit				0xFFFFFFFF /*close socket and quit application*/

typedef 
	struct {
		unsigned long destination;	/*should be kSBC_Command*/
		unsigned long cmdID;
		unsigned long numberBytesinPayload;
	}
SBC_CommandHeader;

typedef 
	struct {
		SBC_info_struct runInfo;
	}
SBC_RunInfo;

#define kMaxOptions 10
typedef 
	struct {
		unsigned long option[kMaxOptions];
	}
SBC_CmdOptionStruct;

typedef 
	struct {
		unsigned long address;		/*first address*/
		unsigned long numLongs;		/*number of longs to read*/
	}
SBC_ReadBlockStruct;

typedef 
	struct {
		unsigned long address;		/*first address*/
		unsigned long numLongs;		/*number Longs of data to follow*/
		/*followed by the requested data, number of longs from above*/
	}
SBC_WriteBlockStruct;

typedef 
	struct {
		unsigned long address;		/*first address*/
		unsigned long addressModifier;
		unsigned long addressSpace;
		unsigned long unitSize;		/*1,2,or 4*/
		unsigned long errorCode;	/*filled on return*/
		unsigned long numItems;		/*number of items to read*/
	}
SBC_VmeReadBlockStruct;

typedef 
	struct {
		unsigned long address;		/*first address*/
		unsigned long addressModifier;
		unsigned long addressSpace;
		unsigned long unitSize;		/*1,2,or 4*/
		unsigned long errorCode;	/*filled on return*/
		unsigned long numItems;		/*number Items of data to follow*/
		/*followed by the requested data, number of items from above*/
	}
SBC_VmeWriteBlockStruct;



#define kSBC_MaxPayloadSize	1024*200
#define kSBC_MaxMessageSize	256
typedef 
	struct {
		unsigned long numBytes;				//filled in automatically
		SBC_CommandHeader cmdHeader;
		char message[kSBC_MaxMessageSize];
		char payload[kSBC_MaxPayloadSize];
	}
SBC_Packet;


//---------------------

typedef
	struct {
		 unsigned long readIndex;
		 unsigned long writeIndex;
		 unsigned long lostByteCount;
		 unsigned long amountInBuffer;
		 unsigned long wrapArounds;
	}
BufferInfo;

#endif
