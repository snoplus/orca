/*
 *  ORCaen965Model.h
 *  Orca
 *
 *  Created by Mark Howe on Friday June 19 2009.
 *  Copyright (c) 2009 UNC. All rights reserved.
 *
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

#import "ORCaenCardModel.h"
#import "ORDataTaker.h"
#import "ORHWWizard.h"

#define kV965  0
#define kV965A 1

// Declaration of constants for module.
enum {
    kOutputBuffer,		// 0000
    kFirmWareRevision,	// 1000
    kGeoAddress,		// 1002
    kMCST_CBLTAddress,	// 1004
    kBitSet1,			// 1006
    kBitClear1,			// 1008
    kInterrupLevel,		// 100A
    kInterrupVector,	// 100C
    kStatusRegister1,	// 100E
    kControlRegister1,	// 1010
    kADERHigh,			// 1012
    kADERLow,			// 1014
    kSingleShotReset,	// 1016
    kMCST_CBLTCtrl,		// 101A
    kEventTriggerReg,	// 1020
    kStatusRegister2,	// 1022
    kEventCounterL,		// 1024
    kEventCounterH,		// 1026
    kIncrementEvent,	// 1028
    kIncrementOffset,	// 102A
    kLoadTestRegister,	// 102C
    kFCLRWindow,		// 102E
    kBitSet2,			// 1032
    kBitClear2,			// 1034
    kWMemTestAddress,	// 1036
    kMemTestWord_High,	// 1038
    kMemTestWord_Low,	// 103A
    kCrateSelect,		// 103C
    kTestEventWrite,	// 103E
    kEventCounterReset,	// 1040
	kIpedReg,			// 1060
    kRTestAddress,		// 1064
    kSWComm,			// 1068
    kADD,				// 1070
    kBADD,				// 1072
    kThresholds,		// 1080
    kNumRegisters
};

// Size of output buffer
#define k965OutputBufferSize 0x07FF

// Class definition
@interface ORCaen965Model : ORCaenCardModel <ORDataTaker,ORHWWizard,ORHWRamping>
{
	int				cardType;
	unsigned short   onlineMask;
	//cached values for speed.
	unsigned long statusAddress;
	unsigned long dataBufferAddress;
	unsigned long location;
}

#pragma mark ***Accessors
- (int) cardType;
- (void) setCardType:(int)aCardType;
- (unsigned short)   onlineMask;
- (void)	    setOnlineMask:(unsigned short)anOnlineMask;
- (BOOL)	    onlineMaskBit:(int)bit;
- (void)	    setOnlineMaskBit:(int)bit withValue:(BOOL)aValue;

#pragma mark ***Register - General routines
- (short)			getNumberRegisters;
- (unsigned long) 	getBufferOffset;
- (unsigned short) 	getDataBufferSize;
- (unsigned long) 	getThresholdOffset;
- (short)			getStatusRegisterIndex: (short) aRegister;
- (short)			getThresholdIndex;
- (short)			getOutputBufferIndex;

#pragma mark ***Register - Register specific routines
- (NSString*) 		getRegisterName: (short) anIndex;
- (unsigned long) 	getAddressOffset: (short) anIndex;
- (short)			getAccessType: (short) anIndex;
- (short)			getAccessSize: (short) anIndex;
- (BOOL)			dataReset: (short) anIndex;
- (BOOL)			swReset: (short) anIndex;
- (BOOL)			hwReset: (short) anIndex;
@end

extern NSString* ORCaen965ModelCardTypeChanged;
extern NSString* ORCaen965ModelOnlineMaskChanged;

