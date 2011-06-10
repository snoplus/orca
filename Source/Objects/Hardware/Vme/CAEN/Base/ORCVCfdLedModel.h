/*
 *  ORCVCfdLedModel.h
 *  Orca
 *
 *  Created by Mark Howe on Tuesday, June 7, 2011.
 *  Copyright (c) 2011 CENPA, University of North Carolina. All rights reserved.
 *
 */
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sonsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
#import "ORVmeIOCard.h"

// Declaration of constants for module.
enum {
    kThreshold0,		//  0x00
    kThreshold1,		//  0x02
    kThreshold2,		//  0x04
    kThreshold3,		//  0x06
    kThreshold4,		//  0x08
    kThreshold5,		//  0x0a
    kThreshold6,		//  0x0c
    kThreshold7,		//  0x0E
    kThreshold8,		//  0x10
    kThreshold9,		//  0x12
    kThreshold10,		//  0x14
    kThreshold11,		//  0x16
    kThreshold12,		//  0x18
    kThreshold13,		//  0x1A
    kThreshold14,		//  0x1C
    kThreshold15,		//  0x1E
	kOutputWidt0_7,		//  0x40
	kOutputWidth8_15,	//  0x42
	kDeadTime0_7,		//  0x44
	kDeadTime8_15,		//  0x46
	kMajorityThreshold,	//  0x48
	kPatternInhibit,	//  0x4A
	kTestPulse,			//  0x4C
	kFixedCode,			//  0xFA
	kModuleType,		//  0xFC
	kVersion,			//  0xFE
    kNumRegisters
};

typedef struct RegisterNamesStruct {
	NSString*       regName;
	unsigned long 	addressOffset;
	short		accessType;
} CV812RegNamesStruct; 

// Class definition
@interface ORCVCfdLedModel : ORVmeIOCard
{
	unsigned short testPulse;
	unsigned short patternInhibit;
	unsigned short majorityThreshold;
	unsigned short deadTime0_7;
	unsigned short deadTime8_15;
	unsigned short outputWidth0_7;
	unsigned short outputWidth8_15;
    unsigned short  thresholds[32];
}

- (unsigned short)	threshold: (unsigned short) anIndex;
- (void)		setThreshold: (unsigned short ) anIndex threshold: (unsigned short) aValue;
- (unsigned short) testPulse;
- (void) setTestPulse:(unsigned short)aTestPulse;
- (unsigned short) patternInhibit;
- (void) setPatternInhibit:(unsigned short)aPatternInhibit;
- (unsigned short) majorityThreshold;
- (void) setMajorityThreshold:(unsigned short)aMajorityThreshold;
- (unsigned short) deadTime0_7;
- (void) setDeadTime0_7:(unsigned short)aDeadTime0_7;
- (unsigned short) deadTime8_15;
- (void) setDeadTime8_15:(unsigned short)aDeadTime8_15;
- (unsigned short) outputWidth8_15;
- (void) setOutputWidth8_15:(unsigned short)aOutputWidth8_15;
- (unsigned short) outputWidth0_7;
- (void) setOutputWidth0_7:(unsigned short)aOutputWidth0_7;
- (BOOL)inhibitMaskBit:(int)bit;
- (void) setInhibitMaskBit:(int)bit withValue:(BOOL)aValue;

#pragma mark ***HW Accesss
- (void) writeThreshold:(unsigned short) pChan;
- (void) writeDeadTime0_7;
- (void) writeDeadTime8_15;
- (void) writeOutputWidth0_7;
- (void) writeOutputWidth8_15;
- (void) writeTestPulse;
- (void) writePatternInhibit;
- (void) writeMajorityThreshold;
- (void) initBoard;
- (void) probeBoard;
@end

extern NSString* ORCVCfdLedModelSelectedRegIndexChanged;
extern NSString* ORCVCfdLedModelThresholdChanged;
extern NSString* ORCVCfdLedModelTestPulseChanged;
extern NSString* ORCVCfdLedModelPatternInhibitChanged;
extern NSString* ORCVCfdLedModelMajorityThresholdChanged;
extern NSString* ORCVCfdLedModelDeadTime0_7Changed;
extern NSString* ORCVCfdLedModelDeadTime8_15Changed;
extern NSString* ORCVCfdLedModelOutputWidth8_15Changed;
extern NSString* ORCVCfdLedModelOutputWidth0_7Changed;
extern NSString* ORCVCfdLedModelThresholdLock;
