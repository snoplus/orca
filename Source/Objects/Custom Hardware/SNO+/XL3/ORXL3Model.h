//
//  ORXL3Model.h
//  Orca
//
//  Created by Mark Howe on Tue, Apr 30, 2008.
//  Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
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

#pragma mark •••Imported Files
#import "ORSNOCard.h"

typedef struct  {
	NSString*	regName;
	unsigned long	address;
} Xl3RegNamesStruct; 

enum {
	kXl3SelectReg,
	kXl3DataAvailReg,
	kXl3CsReg,
	kXl3MaskReg,
	kXl3ClockReg,
	kXl3HvRelayReg,
	kXl3XilinxReg,
	kXl3TestReg,
	kXl3HvCsReg,
	kXl3HvSetPointReg,
	kXl3HvVoltageReg,
	kXl3HvCurrentReg,
	kXl3VmReg,
	kXl3VrReg,
	kXl3NumRegisters //must be last
};


@class XL3_Link;
@class ORCommandList;

@interface ORXL3Model : ORSNOCard 
{
	XL3_Link*	xl3Link;
	short		selectedRegister;
	BOOL		basicOpsRunning;
	BOOL		autoIncrement;	
	unsigned short	repeatDelay;
	short		repeatOpCount;
	BOOL		doReadOp;
	unsigned long	workingCount;
	unsigned long	writeValue;
	BOOL		deselectCompositeRunning;
	unsigned int	xl3Mode;
	unsigned long	slotMask;
	BOOL		xl3ModeRunning;
}

#pragma mark •••Initialization
- (id)   init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;
- (void) wakeUp;
- (void) sleep;

#pragma mark •••Accessors
- (NSString*) shortName;
- (id) controllerCard;
- (void) setSlot:(int)aSlot;
- (XL3_Link*) xl3Link;
- (void) setXl3Link:(XL3_Link*) aXl3Link;
- (void) setGuardian:(id)aGuardian;
- (short) getNumberRegisters;
- (NSString*) getRegisterName:(short) anIndex;
- (unsigned long) getRegisterAddress: (short) anIndex;
- (BOOL) basicOpsRunning;
- (void) setBasicOpsRunning:(BOOL)aBasicOpsRunning;
- (BOOL) deselectCompositeRunning;
- (void) setDeselectCompositeRunning:(BOOL)aDeselectCompositeRunning;
- (BOOL) compositeXl3ModeRunning;
- (void) setCompositeXl3ModeRunning:(BOOL)aCompositeXl3ModeRunning;
- (unsigned long) slotMask;
- (void) setSlotMask:(unsigned long)aSlotMask;
- (BOOL) autoIncrement;
- (void) setAutoIncrement:(BOOL)aAutoIncrement;
- (unsigned short) repeatDelay;
- (void) setRepeatDelay:(unsigned short)aRepeatDelay;
- (short) repeatOpCount;
- (void) setRepeatOpCount:(short)aRepeatCount;
- (unsigned long) writeValue;
- (void) setWriteValue:(unsigned long)aWriteValue;
- (unsigned int) xl3Mode;
- (void) setXl3Mode:(unsigned int)aXl3Mode;
- (BOOL) xl3ModeRunning;
- (void) setXl3ModeRunning:(BOOL)anXl3ModeRunning;

- (int) selectedRegister;
- (void) setSelectedRegister:(int)aSelectedRegister;
- (NSString*) xl3LockName;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

#pragma mark •••Hardware Access
- (void) selectCards:(unsigned long) selectBits;
- (void) deselectCards;
- (void) select:(ORSNOCard*) aCard;
- (void) writeHardwareRegister:(unsigned long) anAddress value:(unsigned long) aValue;
- (unsigned long) readHardwareRegister:(unsigned long) regAddress;
- (void) writeHardwareMemory:(unsigned long) memAddress value:(unsigned long) aValue;
- (unsigned long) readHardwareMemory:(unsigned long) memAddress;
- (void) writeXL3Register:(short)aRegister value:(unsigned long)aValue;
- (unsigned long) readXL3Register:(short)aRegister;

#pragma mark •••Basic Ops
- (void) readBasicOps;
- (void) writeBasicOps;
- (void) stopBasicOps;
- (void) reportStatus;

#pragma mark •••Composite
- (void) deselectComposite;
- (void) writeXl3Mode;
- (void) reset;

- (id) writeHardwareRegisterCmd:(unsigned long) aRegister value:(unsigned long) aBitPattern;
- (id) readHardwareRegisterCmd:(unsigned long) regAddress;
- (void) executeCommandList:(ORCommandList*)aList;
- (id) delayCmd:(unsigned long) milliSeconds;

@end

extern NSString* ORXL3ModelSelectedRegisterChanged;
extern NSString* ORXL3ModelRepeatCountChanged;
extern NSString* ORXL3ModelRepeatDelayChanged;
extern NSString* ORXL3ModelAutoIncrementChanged;
extern NSString* ORXL3ModelBasicOpsRunningChanged;
extern NSString* ORXL3ModelWriteValueChanged;
extern NSString* ORXL3ModelDeselectCompositeRunningChanged;
extern NSString* ORXL3ModelXl3ModeChanged;
extern NSString* ORXL3ModelSlotMaskChanged;
extern NSString* ORXL3ModelXl3ModeRunningChanged;
