//
//  ORVmeReadWriteCommand.h
//  Orca
//
//  Created by Mark Howe on 12/9/08.
//  Copyright 2008 Univerisity of North Carolina. All rights reserved.
//
/*-----------------------------------------------------------
This program was prepared for the Regents of the University of 
Washington at the Center for Experimental Nuclear Physics and 
Astrophysics (CENPA) sponsored in part by the United States 
Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
The University has certain rights in the program pursuant to 
the contract and the program should not be copied or distributed 
outside your organization.  The DOE and the University of 
Washington reserve all rights in the program. Neither the authors,
University of Washington, or U.S. Government make any warranty, 
express or implied, or assume any liability or responsibility 
for the use of this software.
-------------------------------------------------------------*/
#import "SBC_Cmds.h"

#define kWriteOp 0
#define kReadOp	 1
#define kDelayOp 2

@interface ORVmeReadWriteCommand : NSObject {
	long			milliSecondDelay;
	int				opType;				//read/write
	int				addressModifier;	//vme address modifier
	int				addressSpace;		//vme address space
	int				itemSize;
	int				numberItems;
	unsigned int	vmeAddress;			//hw Address
	int				returnCode;			//should be 1 for success, 0 for failure
	NSMutableData*	data;			//if read theData == returned data, if write theData = writeData
}
+ (id) delayCmd:(unsigned long) milliSeconds;
	
+ (id) writeLongBlock:(unsigned long *) writeAddress
			atAddress:(unsigned int) vmeAddress
		   numToWrite:(unsigned int) numberLongs
		   withAddMod:(unsigned short) anAddressModifier
		usingAddSpace:(unsigned short) anAddressSpace;

+ (id) readLongBlockAtAddress:(unsigned int) vmeAddress
				   numToRead:(unsigned int) numberLongs
				   withAddMod:(unsigned short) anAddressModifier
				usingAddSpace:(unsigned short) anAddressSpace;

- (id) initWithMilliSecondDelay:(unsigned long) aMilliSecondDelay;
	
- (id) initWithOp: (int) aOpType
	   dataAdress: (unsigned long*) dataAddress
	   vmeAddress: (unsigned int) vmeAddress
	  numberItems: (unsigned int) aNumberItems
		 itemSize: (unsigned int) anItemSize
	   withAddMod: (unsigned short) anAddressModifier
	usingAddSpace: (unsigned short) anAddressSpace;

- (unsigned long) milliSecondDelay;
- (int)	opType;
- (int)	addressModifier;
- (int)	addressSpace;
- (int) numberItems;
- (int) itemSize;
- (int)	returnCode;
- (void) setReturnCode:(int)aCode;
- (unsigned int)	vmeAddress;
- (unsigned char*) bytes;
- (NSMutableData*)	data;

- (SBC_Packet) SBCPacket;
- (void) extractData:(SBC_Packet*) aPacket;
- (void) throwError:(int)anError;
- (long) longValue;

@end

