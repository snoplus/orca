//
//  ORXL3Model.m
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
#import "XL3_Link.h"
#import "XL3_Cmds.h"
#import "ORXL3Model.h"
#import "ORSNOCrateModel.h"
#import "ORSNOConstants.h"
#import "ORFec32Model.h"
#import "ORDataTypeAssigner.h"

static Xl3RegNamesStruct reg[kXl3NumRegisters] = {
	{ @"SelectReg",		RESET_REG },
	{ @"DataAvailReg",	DATA_AVAIL_REG },
	{ @"CtrlStatReg",	XL3_CS_REG },
	{ @"SlotMaskReg",	XL3_MASK_REG},
	{ @"ClockReg",		XL3_CLOCK_REG},
	{ @"HVRelayReg",	RELAY_REG},
	{ @"XilinxReg",		XL3_XLCON_REG},
	{ @"TestReg",		TEST_REG},
	{ @"HVCtrlStatReg",	HV_CS_REG},
	{ @"HVSetPointReg",	HV_SETPOINTS},
	{ @"HVVltReadReg",	HV_VR_REG},
	{ @"HVCrntReadReg",	HV_CR_REG},
	{ @"XL3VMReg",		XL3_VM_REG},
	{ @"XL3VRReg",		XL3_VR_REG}
};


#pragma mark •••Definitions

NSString* ORXL3ModelSelectedRegisterChanged =	@"ORXL3ModelSelectedRegisterChanged";
NSString* ORXL3ModelRepeatCountChanged =		@"ORXL3ModelRepeatCountChanged";
NSString* ORXL3ModelRepeatDelayChanged =		@"ORXL3ModelRepeatDelayChanged";
NSString* ORXL3ModelAutoIncrementChanged =		@"ORXL3ModelAutoIncrementChanged";
NSString* ORXL3ModelBasicOpsRunningChanged =	@"ORXL3ModelBasicOpsRunningChanged";
NSString* ORXL3ModelWriteValueChanged =			@"ORXL3ModelWriteValueChanged";
NSString* ORXL3ModelXl3ModeChanged =			@"ORXL3ModelXl3ModeChanged";
NSString* ORXL3ModelSlotMaskChanged =			@"ORXL3ModelSlotMaskChanged";
NSString* ORXL3ModelXl3ModeRunningChanged =		@"ORXL3ModelXl3ModeRunningChanged";
NSString* ORXL3ModelXl3RWAddressValueChanged =	@"ORXL3ModelXl3RWAddressValueChanged";
NSString* ORXL3ModelXl3RWDataValueChanged =		@"ORXL3ModelXl3RWDataValueChanged";
NSString* ORXL3ModelXl3OpsRunningChanged =		@"ORXL3ModelXl3OpsRunningChanged";
NSString* ORXL3ModelXl3PedestalMaskChanged =	@"ORXL3ModelXl3PedestalMaskChanged";
NSString* ORXL3ModelXl3ChargeInjChanged =       @"ORXL3ModelXl3ChargeInjChanged";
NSString* ORXL3ModelPollXl3TimeChanged =        @"ORXL3ModelPollXl3TimeChanged";
NSString* ORXL3ModelIsPollingXl3Changed =       @"ORXL3ModelIsPollingXl3Changed";
NSString* ORXL3ModelIsPollingCMOSRatesChanged =     @"ORXL3ModelIsPollingCMOSRatesChanged";
NSString* ORXL3ModelPollCMOSRatesMaskChanged =      @"ORXL3ModelPollCMOSRatesMaskChanged";
NSString* ORXL3ModelIsPollingPMTCurrentsChanged =   @"ORXL3ModelIsPollingPMTCurrentsChanged";
NSString* ORXL3ModelPollPMTCurrentsMaskChanged  =   @"ORXL3ModelPollPMTCurrentsMaskChanged";
NSString* ORXL3ModelIsPollingFECVoltagesChanged =   @"ORXL3ModelIsPollingFECVoltagesChanged";
NSString* ORXL3ModelPollFECVoltagesMaskChanged =    @"ORXL3ModelPollFECVoltagesMaskChanged";
NSString* ORXL3ModelIsPollingXl3VoltagesChanged =   @"ORXL3ModelIsPollingXl3VoltagesChanged";
NSString* ORXL3ModelIsPollingHVSupplyChanged =      @"ORXL3ModelIsPollingHVSupplyChanged";
NSString* ORXL3ModelIsPollingXl3WithRunChanged =    @"ORXL3ModelIsPollingXl3WithRunChanged";
NSString* ORXL3ModelPollStatusChanged =             @"ORXL3ModelPollStatusChanged";
NSString* ORXL3ModelIsPollingVerboseChanged =       @"ORXL3ModelIsPollingVerboseChanged";
NSString* ORXL3ModelRelayMaskChanged = @"ORXL3ModelRelayMaskChanged";
NSString* ORXL3ModelRelayStatusChanged = @"ORXL3ModelRelayStatusChanged";
NSString* ORXL3ModelHvStatusChanged = @"ORXL3ModelHvStatusChanged";
NSString* ORXL3ModelTriggerStatusChanged = @"ORXL3ModelTriggerStatusChanged";
NSString* ORXL3ModelHVTargetValueChanged = @"ORXL3ModelHVTargetValueChanged";
NSString* ORXL3ModelHVCMOSRateLimitChanged = @"ORXL3ModelHVCMOSRateLimitChanged";
NSString* ORXL3ModelHVCMOSRateIgnoreChanged = @"ORXL3ModelHVCMOSRateIgnoreChanged";

@interface ORXL3Model (private)
- (void) doBasicOp;
- (void) _pollXl3;
- (void) _hvXl3;
@end

@implementation ORXL3Model
@synthesize pollDict, isPollingForced,
    calcCMOSRatesFromCounts = _calcCMOSRatesFromCounts,
    hvANextStepValue = _hvANextStepValue,
    hvBNextStepValue = _hvBNextStepValue,
    hvCMOSReadsCounter = _hvCMOSReadsCounter;


#pragma mark •••Initialization
- (id) init
{
	self = [super init];
	return self;
}

- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"XL3Card"]];
}

-(void)dealloc
{
	[xl3Link release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    if (pollThread) [pollThread release];
    if (hvThread) [hvThread release];
    [pollDict release];
    if (relayStatus) [relayStatus release];
    if (triggerStatus) [triggerStatus release];
	[super dealloc];
}

- (void) awakeAfterDocumentLoaded
{
    if (xl3Link) [xl3Link awakeAfterDocumentLoaded];
}

- (void) wakeUp 
{
	[super wakeUp];
	[xl3Link wakeUp];
}

- (void) sleep 
{
	[super sleep];
	if (xl3Link) {
		[xl3Link release];
		xl3Link = nil;
	}
}	

- (void) makeMainController
{
	[self linkToController:@"XL3_LinkController"];
}

#pragma mark •••Accessors
- (NSString*) shortName
{
	return @"XL3";
}

- (id) controllerCard
{
	return self;
}

- (XL3_Link*) xl3Link
{
	return xl3Link;
}

- (void) setXl3Link:(XL3_Link*) aXl3Link
{
	[xl3Link release];
	xl3Link = [aXl3Link retain];
}

- (void) setGuardian:(id)aGuardian
{
	id oldGuardian = guardian;
	[super setGuardian:aGuardian];
	if (guardian){
		if (!xl3Link) {
			xl3Link = [[XL3_Link alloc] init];
		}
		[xl3Link setCrateName:[NSString stringWithFormat:@"XL3 crate %d", [self crateNumber]]];
		[xl3Link setIPNumber:[guardian iPAddress]];
		[xl3Link setPortNumber:[guardian portNumber]];	
	}
	
	if(oldGuardian != aGuardian){
		[oldGuardian setAdapter:nil];	//old crate can't use this card any more
	}
	
	if (!guardian) {
		[xl3Link setCrateName:[NSString stringWithFormat:@"XL3 crate ---"]];
		[xl3Link setIPNumber:[NSString stringWithFormat:@"0.0.0.0"]];
		[xl3Link setPortNumber:0];
		if ([xl3Link isConnected]) {
			[xl3Link disconnectSocket];
		}
		[xl3Link release];
		xl3Link = 0;
	}
	[aGuardian setAdapter:self];		//our new crate will use this card for hardware access
}

- (void) setSlot:(int)aSlot
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSlot:[self slot]];
    [self setTag:aSlot];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORSNOCardSlotChanged
	 object: self];
}

- (short) getNumberRegisters
{
	return kXl3NumRegisters;
}

- (NSString*) getRegisterName:(short) anIndex
{
	return reg[anIndex].regName;
}

- (unsigned long) getRegisterAddress: (short) anIndex
{
	return reg[anIndex].address;
}

- (BOOL) basicOpsRunning
{
	return basicOpsRunning;
}

- (void) setBasicOpsRunning:(BOOL)aBasicOpsRunning
{
	basicOpsRunning = aBasicOpsRunning;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelBasicOpsRunningChanged object:self];
}

- (BOOL) compositeXl3ModeRunning
{
	return xl3ModeRunning;
}

- (void) setCompositeXl3ModeRunning:(BOOL)aCompositeXl3ModeRunning
{
	xl3ModeRunning = aCompositeXl3ModeRunning;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelXl3ModeRunningChanged object:self];
}

- (unsigned long) slotMask
{
	return slotMask;
}

- (void) setSlotMask:(unsigned long)aSlotMask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setSlotMask:slotMask];
	slotMask = aSlotMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelSlotMaskChanged object:self];
}

- (BOOL) autoIncrement
{
	return autoIncrement;
}

- (void) setAutoIncrement:(BOOL)aAutoIncrement
{
	[[[self undoManager] prepareWithInvocationTarget:self] setAutoIncrement:autoIncrement];
	autoIncrement = aAutoIncrement;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelAutoIncrementChanged object:self];
}

- (unsigned short) repeatDelay
{
	return repeatDelay;
}

- (void) setRepeatDelay:(unsigned short)aRepeatDelay
{
	if(aRepeatDelay<=0)aRepeatDelay = 1;
	[[[self undoManager] prepareWithInvocationTarget:self] setRepeatDelay:repeatDelay];
	
	repeatDelay = aRepeatDelay;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelRepeatDelayChanged object:self];
}

- (short) repeatOpCount
{
	return repeatOpCount;
}

- (void) setRepeatOpCount:(short)aRepeatCount
{
	if(aRepeatCount<=0)aRepeatCount = 1;
	[[[self undoManager] prepareWithInvocationTarget:self] setRepeatOpCount:repeatOpCount];
	
	repeatOpCount = aRepeatCount;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelRepeatCountChanged object:self];
}

- (unsigned long) writeValue
{
	return writeValue;
}

- (void) setWriteValue:(unsigned long)aWriteValue
{
	[[[self undoManager] prepareWithInvocationTarget:self] setWriteValue:writeValue];
	
	writeValue = aWriteValue;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelWriteValueChanged object:self];
}	


- (int) selectedRegister
{
	return selectedRegister;
}

- (void) setSelectedRegister:(int)aSelectedRegister
{
	[[[self undoManager] prepareWithInvocationTarget:self] setSelectedRegister:selectedRegister];	
	selectedRegister = aSelectedRegister;	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelSelectedRegisterChanged object:self];
}

- (NSString*) xl3LockName
{
	return @"ORXL3Lock";
}

- (unsigned int) xl3Mode
{
	return xl3Mode;
}

- (void) setXl3Mode:(unsigned int)aXl3Mode
{
	[[[self undoManager] prepareWithInvocationTarget:self] setXl3Mode:xl3Mode];
	xl3Mode = aXl3Mode;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelXl3ModeChanged object:self];
}	

- (BOOL) xl3ModeRunning
{
	return xl3ModeRunning;
}

- (void) setXl3ModeRunning:(BOOL)anXl3ModeRunning
{
	[[[self undoManager] prepareWithInvocationTarget:self] setXl3ModeRunning:xl3ModeRunning];
	xl3ModeRunning = anXl3ModeRunning;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelXl3ModeRunningChanged object:self];
}

- (unsigned long) xl3RWAddressValue
{
	return xl3RWAddressValue;
}

- (void) setXl3RWAddressValue:(unsigned long)anXl3RWAddressValue
{
	[[[self undoManager] prepareWithInvocationTarget:self] setXl3RWAddressValue:xl3RWAddressValue];
	xl3RWAddressValue = anXl3RWAddressValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelXl3RWAddressValueChanged object:self];
}

- (unsigned long) xl3RWDataValue
{
	return xl3RWDataValue;
}

- (void) setXl3RWDataValue:(unsigned long)anXl3RWDataValue;
{
	[[[self undoManager] prepareWithInvocationTarget:self] setXl3RWDataValue:xl3RWDataValue];
	xl3RWDataValue = anXl3RWDataValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelXl3RWDataValueChanged object:self];
}

- (BOOL) xl3OpsRunningForKey:(id)aKey
{
	return [[xl3OpsRunning objectForKey:aKey] boolValue];
}

- (void) setXl3OpsRunning:(BOOL)anXl3OpsRunning forKey:(id)aKey
{
	[[[self undoManager] prepareWithInvocationTarget:self] setXl3OpsRunning:NO forKey:aKey];
	[xl3OpsRunning setObject:[NSNumber numberWithBool:anXl3OpsRunning] forKey:aKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelXl3OpsRunningChanged object:self];
}

- (unsigned long) xl3PedestalMask
{
	return xl3PedestalMask;
}

- (void) setXl3PedestalMask:(unsigned long)anXl3PedestalMask;
{
	[[[self undoManager] prepareWithInvocationTarget:self] setXl3PedestalMask:xl3PedestalMask];
	xl3PedestalMask = anXl3PedestalMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelXl3PedestalMaskChanged object:self];
}
 

- (unsigned long) xl3ChargeInjMask
{
    return xl3ChargeInjMask;
}

- (void) setXl3ChargeInjMask:(unsigned long)aXl3ChargeInjMask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setXl3ChargeInjMask:xl3ChargeInjMask];
	xl3ChargeInjMask = aXl3ChargeInjMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelXl3ChargeInjChanged object:self];
    
}

- (unsigned char) xl3ChargeInjCharge
{
    return xl3ChargeInjCharge;
}

- (void) setXl3ChargeInjCharge:(unsigned char)aXl3ChargeInjCharge
{
	[[[self undoManager] prepareWithInvocationTarget:self] setXl3ChargeInjCharge:xl3ChargeInjCharge];
	xl3ChargeInjCharge = aXl3ChargeInjCharge;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelXl3ChargeInjChanged object:self];    
}

- (unsigned short) pollXl3Time
{
    return pollXl3Time;
}

- (void) setPollXl3Time:(unsigned short)aPollXl3Time
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollXl3Time:pollXl3Time];
    pollXl3Time = aPollXl3Time;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelPollXl3TimeChanged object:self];    
}

- (BOOL) isPollingXl3
{
    return isPollingXl3;
}

- (void) setIsPollingXl3:(BOOL)aIsPollingXl3
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIsPollingXl3:isPollingXl3];
    isPollingXl3 = aIsPollingXl3;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelIsPollingXl3Changed object:self];
    if (isPollingXl3) {
        [self setPollStatus:@"Polling loop running"];
        [self setCalcCMOSRatesFromCounts:NO];
        [self performSelector:@selector(pollXl3:) withObject:nil afterDelay:0.1];
    }    
    else {
        [self setPollStatus:@"Polling loop stopped."];
        if (pollThread && ![pollThread isFinished]) [pollThread cancel];
    }
}

- (BOOL) isPollingCMOSRates
{
    return isPollingCMOSRates;
}

- (void) setIsPollingCMOSRates:(BOOL)aIsPollingCMOSRates
{
    if (isPollingXl3Voltages != aIsPollingCMOSRates) {
        [[[self undoManager] prepareWithInvocationTarget:self] setIsPollingCMOSRates:isPollingCMOSRates];
        isPollingCMOSRates = aIsPollingCMOSRates;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelIsPollingCMOSRatesChanged object:self];
        [self setCalcCMOSRatesFromCounts:NO];
    }
}

- (unsigned short) pollCMOSRatesMask
{
    return pollCMOSRatesMask;
}

- (void) setPollCMOSRatesMask:(unsigned short)aPollCMOSRatesMask
{
    if (pollCMOSRatesMask != aPollCMOSRatesMask) {
        [[[self undoManager] prepareWithInvocationTarget:self] setPollCMOSRatesMask:pollCMOSRatesMask];
        pollCMOSRatesMask = aPollCMOSRatesMask;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelPollCMOSRatesMaskChanged object:self];
        [self setCalcCMOSRatesFromCounts:NO];
    }
}

- (BOOL) isPollingPMTCurrents
{
    return isPollingPMTCurrents;
}

- (void) setIsPollingPMTCurrents:(BOOL)aIsPollingPMTCurrents
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIsPollingPMTCurrents:isPollingPMTCurrents];
    isPollingPMTCurrents = aIsPollingPMTCurrents;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelIsPollingPMTCurrentsChanged object:self];        
}

- (unsigned short) pollPMTCurrentsMask
{
    return pollPMTCurrentsMask;
}

- (void) setPollPMTCurrentsMask:(unsigned short)aPollPMTCurrentsMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollPMTCurrentsMask:pollPMTCurrentsMask];
    pollPMTCurrentsMask = aPollPMTCurrentsMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelPollPMTCurrentsMaskChanged object:self];    
}

- (BOOL) isPollingFECVoltages
{
    return isPollingFECVoltages;
}

- (void) setIsPollingFECVoltages:(BOOL)aIsPollingFECVoltages
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIsPollingFECVoltages:isPollingFECVoltages];
    isPollingFECVoltages = aIsPollingFECVoltages;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelIsPollingFECVoltagesChanged object:self];        
}

- (unsigned short) pollFECVoltagesMask
{
    return pollFECVoltagesMask;
}

- (void) setPollFECVoltagesMask:(unsigned short)aPollFECVoltagesMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollFECVoltagesMask:pollFECVoltagesMask];
    pollFECVoltagesMask = aPollFECVoltagesMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelPollFECVoltagesMaskChanged object:self];    
}

- (BOOL) isPollingXl3Voltages
{
    return isPollingXl3Voltages;
}

- (void) setIsPollingXl3Voltages:(BOOL)aIsPollingXl3Voltages
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIsPollingXl3Voltages:isPollingXl3Voltages];
    isPollingXl3Voltages = aIsPollingXl3Voltages;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelIsPollingXl3VoltagesChanged object:self];        
}

- (BOOL) isPollingHVSupply
{
    return isPollingHVSupply;
}

- (void) setIsPollingHVSupply:(BOOL)aIsPollingHVSupply
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIsPollingHVSupply:isPollingHVSupply];
    isPollingHVSupply = aIsPollingHVSupply;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelIsPollingHVSupplyChanged object:self];        
}

- (BOOL) isPollingXl3WithRun
{
    return isPollingXl3WithRun;
}

- (void) setIsPollingXl3WithRun:(BOOL)aIsPollingXl3WithRun
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIsPollingXl3WithRun:isPollingXl3WithRun];
    isPollingXl3WithRun = aIsPollingXl3WithRun;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelIsPollingXl3WithRunChanged object:self];        
}

- (BOOL) isPollingVerbose
{
    return isPollingVerbose;
}

- (void) setIsPollingVerbose:(BOOL)aIsPollingVerbose
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIsPollingVerbose:isPollingVerbose];
    isPollingVerbose = aIsPollingVerbose;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelIsPollingVerboseChanged object:self];        
}

- (NSString*) pollStatus
{
    if (!pollStatus) {
        return @"Status unknown";
    }
    return pollStatus;
}

- (void) setPollStatus:(NSString*)aPollStatus
{
    if (pollStatus) [pollStatus autorelease];
    if (aPollStatus) pollStatus = [aPollStatus copy];

	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelPollStatusChanged object:self];        
}

- (BOOL) hvASwitch
{
    return hvASwitch;
}

- (void) setHvASwitch:(BOOL)aHvASwitch
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHvASwitch:hvASwitch];
    hvASwitch = aHvASwitch;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelHvStatusChanged object:self];        
}

- (BOOL) hvBSwitch
{
    return hvBSwitch;
}

- (void) setHvBSwitch:(BOOL)aHvBSwitch
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHvBSwitch:hvBSwitch];
    hvBSwitch = aHvBSwitch;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelHvStatusChanged object:self];        
}

- (unsigned long) hvAVoltageDACSetValue
{
    return hvAVoltageDACSetValue;
}

- (void) setHvAVoltageDACSetValue:(unsigned long)aHvAVoltageDACSetValue {
    [[[self undoManager] prepareWithInvocationTarget:self] setHvAVoltageDACSetValue:aHvAVoltageDACSetValue];
    hvAVoltageDACSetValue = aHvAVoltageDACSetValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelHvStatusChanged object:self];        
}

- (unsigned long) hvBVoltageDACSetValue
{
    return hvBVoltageDACSetValue;
}

- (void) setHvBVoltageDACSetValue:(unsigned long)aHvBVoltageDACSetValue {
    [[[self undoManager] prepareWithInvocationTarget:self] setHvBVoltageDACSetValue:aHvBVoltageDACSetValue];
    hvBVoltageDACSetValue = aHvBVoltageDACSetValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelHvStatusChanged object:self];        
}

- (float) hvAVoltageReadValue
{
    return _hvAVoltageReadValue;
}

- (void) setHvAVoltageReadValue:(float)hvAVoltageReadValue
{
    _hvAVoltageReadValue = hvAVoltageReadValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelHvStatusChanged object:self];        
}

- (float) hvBVoltageReadValue
{
    return _hvBVoltageReadValue;
}

- (void) setHvBVoltageReadValue:(float)hvBVoltageReadValue
{
    _hvBVoltageReadValue = hvBVoltageReadValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelHvStatusChanged object:self];        
}

- (float) hvACurrentReadValue
{
    return _hvACurrentReadValue;
}

- (void) setHvACurrentReadValue:(float)hvACurrentReadValue
{
    _hvACurrentReadValue = hvACurrentReadValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelHvStatusChanged object:self];        
}

- (float) hvBCurrentReadValue
{
    return _hvBCurrentReadValue;
}

- (void) setHvBCurrentReadValue:(float)hvBCurrentReadValue
{
    _hvBCurrentReadValue = hvBCurrentReadValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelHvStatusChanged object:self];        
}

- (unsigned long) hvAVoltageTargetValue
{
    return _hvAVoltageTargetValue;
}

- (void) setHvAVoltageTargetValue:(unsigned long)hvAVoltageTargetValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHvAVoltageTargetValue:_hvAVoltageTargetValue];
    _hvAVoltageTargetValue = hvAVoltageTargetValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelHVTargetValueChanged object:self];        
}

- (unsigned long) hvBVoltageTargetValue
{
    return _hvBVoltageTargetValue;
}

- (void) setHvBVoltageTargetValue:(unsigned long)hvBVoltageTargetValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHvBVoltageTargetValue:_hvBVoltageTargetValue];
    _hvBVoltageTargetValue = hvBVoltageTargetValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelHVTargetValueChanged object:self];        
}

- (unsigned long) hvACMOSRateLimit
{
    return _hvACMOSRateLimit;
}

- (void) setHvACMOSRateLimit:(unsigned long)hvACMOSRateLimit
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHvACMOSRateLimit:_hvACMOSRateLimit];
    _hvACMOSRateLimit = hvACMOSRateLimit;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelHVCMOSRateLimitChanged object:self];            
}

- (unsigned long) hvBCMOSRateLimit
{
    return _hvBCMOSRateLimit;
}

- (void) setHvBCMOSRateLimit:(unsigned long)hvBCMOSRateLimit
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHvBCMOSRateLimit:_hvBCMOSRateLimit];
    _hvBCMOSRateLimit = hvBCMOSRateLimit;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelHVCMOSRateLimitChanged object:self];            
}

- (unsigned long) hvACMOSRateIgnore
{
    return _hvACMOSRateIgnore;
}

- (void) setHvACMOSRateIgnore:(unsigned long)hvACMOSRateIgnore
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHvACMOSRateIgnore:_hvACMOSRateIgnore];
    _hvACMOSRateIgnore = hvACMOSRateIgnore;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelHVCMOSRateIgnoreChanged object:self];            
}

- (unsigned long) hvBCMOSRateIgnore
{
    return _hvBCMOSRateIgnore;
}

- (void) setHvBCMOSRateIgnore:(unsigned long)hvBCMOSRateIgnore
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHvBCMOSRateIgnore:_hvBCMOSRateIgnore];
    _hvBCMOSRateIgnore = hvBCMOSRateIgnore;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelHVCMOSRateIgnoreChanged object:self];            
}

- (unsigned long long) relayMask
{
    return relayMask;
}

- (void) setRelayMask:(unsigned long long)aRelayMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRelayMask:relayMask];
    relayMask = aRelayMask;
    //NSLog(@"relay mask:0x%016x",relayMask);
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelRelayMaskChanged object:self];        
}

- (NSString*) relayStatus
{
    if (!relayStatus) {
        return @"status: UNKNOWN";
    }
    id result;
    @synchronized(self) {
        result = [relayStatus retain];
    }
    return [result autorelease];
}

- (void) setRelayStatus:(NSString *)aRelayStatus
{
    @synchronized(self) {
        if (relayStatus != aRelayStatus) {
            if (relayStatus) [relayStatus autorelease];
            if (aRelayStatus) relayStatus = [aRelayStatus copy];
        }
    }
    
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelRelayStatusChanged object:self];        
}

- (NSString*) triggerStatus
{
    if (!triggerStatus) {
        return @"OFF";
    }
    return triggerStatus;
}

- (void) setTriggerStatus:(NSString *)aTriggerStatus
{
    if (triggerStatus) [triggerStatus autorelease];
    if (aTriggerStatus) triggerStatus = [aTriggerStatus copy];
    
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelTriggerStatusChanged object:self];        
}

- (int) slotConv
{
    return [self slot];
}

- (int) crateNumber
{
    return [guardian crateNumber];
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"SNO Crate %d, card %d",[self crateNumber], [self stationNumber]];
}

- (NSComparisonResult)	slotCompare:(id)otherCard
{
    return [self stationNumber] - [otherCard stationNumber];
}

- (void) setCrateNumber:(int)crateNumber
{
	[[self guardian] setCrateNumber:crateNumber];
}

- (NSComparisonResult) XL3NumberCompare:(id)aCard
{
    return [self crateNumber] - [aCard crateNumber];
}

#pragma mark •••DB Helpers

#define swapLong(x) (((uint32_t)(x) << 24) | (((uint32_t)(x) & 0x0000FF00) <<  8) | (((uint32_t)(x) & 0x00FF0000) >>  8) | ((uint32_t)(x) >> 24))
#define swapShort(x) (((uint16_t)(x) <<  8) | ((uint16_t)(x)>>  8))

void SwapLongBlock(void* p, int32_t n)
{
    int32_t* lp = (int32_t*)p;
    int32_t i;
    for(i=0;i<n;i++){
        int32_t x = *lp;
        *lp =  (((x) & 0x000000FF) << 24) |    
        (((x) & 0x0000FF00) <<  8) |    
        (((x) & 0x00FF0000) >>  8) |    
        (((x) & 0xFF000000) >> 24);
        lp++;
    }
}

- (void) synthesizeDefaultsIntoBundle:(mb_t*)aBundle forSLot:(unsigned short)aSlot
{
	uint16_t s_mb_id[1] = {0x0000};
	uint16_t s_dc_id[4] = {0x0000, 0x0000, 0x0000, 0x0000};

	//vbals are gains per channel x: [0][x] high, [1][x] low
	uint8_t s_vbal[2][32] = {{ 110, 110, 110, 110, 110, 110, 110, 110,
		 		   110, 110, 110, 110, 110, 110, 110, 110,
				   110, 110, 110, 110, 110, 110, 110, 110,
				   110, 110, 110, 110, 110, 110, 110, 110 },
				 { 110, 110, 110, 110, 110, 110, 110, 110,
				   110, 110, 110, 110, 110, 110, 110, 110,
				   110, 110, 110, 110, 110, 110, 110, 110,
				   110, 110, 110, 110, 110, 110, 110, 110 }};

	uint8_t s_vthr[32] = {	255, 255, 255, 255, 255, 255, 255, 255,
				255, 255, 255, 255, 255, 255, 255, 255,
				255, 255, 255, 255, 255, 255, 255, 255,
				255, 255, 255, 255, 255, 255, 255, 255 };


	//tdisc index definitions: 0=ch0-3, 1=ch4-7, 2=ch8-11, etc
	uint8_t s_tdisc_rmp[8] =   { 120, 120, 120, 120, 120, 120, 120, 120 }; // back edge timing ramp
	uint8_t s_tdisc_rmpup[8] = { 115, 115, 115, 115, 115, 115, 115, 115 }; // front edge timing ramp
	uint8_t s_tdisc_vsi[8] =   { 120, 120, 120, 120, 120, 120, 120, 120 }; // short integrate voltage
	uint8_t s_tdisc_vli[8] =   { 120, 120, 120, 120, 120, 120, 120, 120 }; // long integrate voltage
	

	//tcmos: the following are motherboard wide constants
	aBundle->tcmos.vmax = 203; // upper TAC reference voltage
	aBundle->tcmos.tacref = 72; // lower TAC reference voltage
	aBundle->tcmos.isetm[0] = 200; // primary timing current (0=tac0,1=tac1)
	aBundle->tcmos.isetm[1] = 200; // primary timing current (0=tac0,1=tac1)
	aBundle->tcmos.iseta[0] = 0; // secondary timing current 
	aBundle->tcmos.iseta[1] = 0; // secondary timing current 
	// TAC shift register load bits channel 0 to 31, assume same bits for all channels
	// bits go from right to left
	// TAC0-adj0  0 (1=enable), TAC0-adj1  0 (1=enable), TAC0-adj2 0 (1=enable), TAC0-main 0 (0=enable)
	// same for TAC1	
	uint8_t s_tcmos_tac_shift[32] = { 0, 0, 0, 0, 0, 0, 0, 0,
					  0, 0, 0, 0, 0, 0, 0, 0,
					  0, 0, 0, 0, 0, 0, 0, 0,
					  0, 0, 0, 0, 0, 0, 0, 0 };
	// vint
	aBundle->vint = 205; //integrator output voltage

	//chinj
	//aBundle->chinj.hv_id = 0x0000; // HV card id
//	aBundle->hvref = 0x00; // MB control voltage
	aBundle->hvref = 0xff; // !!!charge injection test!!!
	//aBundle->chinj.ped_time = 100; // MTCD pedestal width (DONT NEED THIS HERE)

	//tr100 width, channel 0 to 31, only bits 0 to 6 defined, bit0-5 delay, bit6 enable
	uint8_t s_tr100_tdelay[32] = {  0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f,
					0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f,
					0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f,
					0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f };

	//tr20 width, channel 0 to 31, only bits 0 to 5 defined, bit0-4 width, bit5 enable from PennDB
	uint8_t s_tr20_twidth[32] = {	0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30,
					0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30,
					0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30,
					0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30 };
	
	//tr20 delay, channel 0 to 31, only bits 0 to 3 defined from PennDB
	uint8_t s_tr20_tdelay[32] = {	0, 0, 0, 0, 0, 0, 0, 0,
					0, 0, 0, 0, 0, 0, 0, 0,
					0, 0, 0, 0, 0, 0, 0, 0,
					0, 0, 0, 0, 0, 0, 0, 0 }; 
	//sane defaults from DB spec
	/*
	uint8_t s_tr20_tdelay[32] = {	2, 2, 2, 2, 2, 2, 2, 2,
					2, 2, 2, 2, 2, 2, 2, 2,
					2, 2, 2, 2, 2, 2, 2, 2,
					2, 2, 2, 2, 2, 2, 2, 2 }; 
	*/
	
	//scmos remaining 10 bits, channel 0 to 31, only bits 0 to 9 defined
	uint16_t s_scmos[32] = {	0, 0, 0, 0, 0, 0, 0, 0,
					0, 0, 0, 0, 0, 0, 0, 0,
					0, 0, 0, 0, 0, 0, 0, 0,
					0, 0, 0, 0, 0, 0, 0, 0 }; 

	//ch_disable bits 1 == disabled
	aBundle->disable_mask = 0;
		
	memcpy(&aBundle->mb_id, s_mb_id, 2);
	memcpy(aBundle->dc_id, s_dc_id, 8);
	memcpy(aBundle->vbal, s_vbal, 64);
	memcpy(aBundle->vthr, s_vthr, 32);
	memcpy(aBundle->tdisc.rmp, s_tdisc_rmp, 8);
	memcpy(aBundle->tdisc.rmpup, s_tdisc_rmpup, 8);
	memcpy(aBundle->tdisc.vsi, s_tdisc_vsi, 8);
	memcpy(aBundle->tdisc.vli, s_tdisc_vli, 8);
	memcpy(aBundle->tcmos.tac_shift, s_tcmos_tac_shift, 32);
	memcpy(aBundle->tr100.tdelay, s_tr100_tdelay, 32);
	memcpy(aBundle->tr20.twidth, s_tr20_twidth, 32);
	memcpy(aBundle->tr20.tdelay, s_tr20_tdelay, 32);
	memcpy(aBundle->scmos, s_scmos, 32);
}

- (void) byteSwapBundle:(mb_t*)aBundle
{
	int i;
	
	//vbal_vals_t
	aBundle->mb_id = swapShort(aBundle->mb_id);
	for (i=0; i<4; i++) aBundle->dc_id[i] = swapShort(aBundle->dc_id[i]);
	//scmos_vals_t
	for (i=0; i<15; i++) aBundle->scmos[i] = swapShort(aBundle->scmos[i]);
	//mb_chan_disable_vals_t
	aBundle->disable_mask = swapLong(aBundle->disable_mask);	
}

- (void) synthesizeFECIntoBundle:(mb_t*)aBundle forSLot:(unsigned short)aSlot
{
}

#pragma mark •••DataTaker
- (void) setDataIds:(id)assigner
{
	xl3MegaBundleDataId	= [assigner assignDataIds:kLongForm];
	cmosRateDataId		= [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherObj
{
	[self setXl3MegaBundleDataId:[anotherObj xl3MegaBundleDataId]];
	[self setCmosRateDataId:[anotherObj cmosRateDataId]];
}	

@synthesize xl3MegaBundleDataId, cmosRateDataId;

- (NSDictionary*) dataRecordDescription
{
	NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
	NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				     @"ORXL3DecoderForXL3MegaBundle",			@"decoder",
				     [NSNumber numberWithLong:xl3MegaBundleDataId],	@"dataId",
				     [NSNumber numberWithBool:YES],			@"variable",
				     [NSNumber numberWithLong:-1],			@"length",
				     //[NSNumber numberWithLong:362],			@"length",  //modified kLong header, 1440 bytes + 2 longs
				     nil];
	[dataDictionary setObject:aDictionary forKey:@"Xl3MegaBundle"];

	NSDictionary* bDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				     @"ORXL3DecoderForCmosRate",	@"decoder",
				     [NSNumber numberWithLong:cmosRateDataId],       @"dataId",
				     [NSNumber numberWithBool:NO],          @"variable",
				     [NSNumber numberWithLong:21+8*32],		@"length",
				     nil];
	[dataDictionary setObject:bDictionary forKey:@"Xl3CmosRate"];
	
	return dataDictionary;
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	[aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORXL3Model"];	
}

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	while ([xl3Link bundleAvailable]) {
        NSMutableData* aBundle = [xl3Link readNextBundle];
        unsigned long data_length = [aBundle length] / 4;
        unsigned long* data = (unsigned long*)[aBundle mutableBytes];
        data[0] = xl3MegaBundleDataId | data_length;
		data[1] = 0; //packet count, maybe time, and crate ID in a meaningful way

		[aDataPacket addLongsToFrameBuffer:data length:data_length];
		[aBundle release]; aBundle = nil; //this is correct even if the analyzer doesn't agree
	}
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
}

//never used
- (int) load_eCPU_HW_Config_Structure:(VME_crate_config*)configStruct index:(int)index
{
	return 0;
}


#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];
	[[self undoManager] disableUndoRegistration];

	[self setSlot:			[decoder decodeIntForKey:	@"slot"]];
	[self setSelectedRegister:	[decoder decodeIntForKey:	@"ORXL3ModelSelectedRegister"]];
	xl3Link = [[decoder decodeObjectForKey:@"XL3_Link"] retain];
	[self setAutoIncrement:		[decoder decodeBoolForKey:	@"ORXL3ModelAutoIncrement"]];
	[self setRepeatDelay:		[decoder decodeIntForKey:	@"ORXL3ModelRepeatDelay"]];
	[self setRepeatOpCount:		[decoder decodeIntForKey:	@"ORXL3ModelRepeatOpCount"]];
	[self setXl3Mode:		[decoder decodeIntForKey:	@"ORXL3ModelXl3Mode"]];
	[self setSlotMask:		[decoder decodeIntForKey:	@"ORXL3ModelSlotMask"]];
	[self setXl3RWAddressValue:	[decoder decodeIntForKey:	@"ORXL3ModelXl3RWAddressValue"]];
	[self setXl3RWDataValue:	[decoder decodeIntForKey:	@"ORXL3ModelXl3RWDataValue"]];
	[self setXl3PedestalMask:       [decoder decodeIntForKey:	@"ORXL3ModelXl3PedestalMask"]];
    [self setXl3ChargeInjMask:      [decoder decodeIntForKey: @"ORXL3ModelXl3ChargeInjMask"]];
    [self setXl3ChargeInjCharge:    [decoder decodeIntForKey: @"ORXL3ModelXl3ChargeInjCharge"]];

    [self setPollXl3Time:           [decoder decodeIntForKey:@"ORXL3ModelPollXl3Time"]];
    //[self setIsPollingXl3:          [decoder decodeBoolForKey:@"ORXL3ModelIsPollingXl3"]];
    [self setIsPollingXl3:NO];
    [self setIsPollingCMOSRates:    [decoder decodeBoolForKey:@"ORXL3ModelIsPollingCMOSRates"]];
    [self setPollCMOSRatesMask:     [decoder decodeIntForKey:@"ORXL3ModelPollCMOSRatesMask"]];
    [self setIsPollingPMTCurrents:  [decoder decodeBoolForKey:@"ORXL3ModelIsPollingPMTCurrents"]];
    [self setPollPMTCurrentsMask:   [decoder decodeIntForKey:@"ORXL3ModelPollPMTCurrentsMask"]];
    [self setIsPollingFECVoltages:  [decoder decodeBoolForKey:@"ORXL3ModelIsPollingFECVoltages"]];
    [self setPollFECVoltagesMask:   [decoder decodeIntForKey:@"ORXL3ModelPollFECVoltagesMask"]];
    [self setIsPollingXl3Voltages:  [decoder decodeBoolForKey:@"ORXL3ModelIsPollingXl3Voltages"]];
    [self setIsPollingHVSupply:     [decoder decodeBoolForKey:@"ORXL3ModelIsPollingHVSupply"]];
    [self setIsPollingXl3WithRun:   [decoder decodeBoolForKey:@"ORXL3ModelIsPollingXl3WithRun"]];
    [self setIsPollingVerbose:      [decoder decodeBoolForKey:@"ORXL3ModelIsPollingVerbose"]];
    [self setRelayMask:[decoder decodeInt64ForKey:@"ORXL3ModelRelayMask"]];
    [self setHvAVoltageDACSetValue:[decoder decodeIntForKey:@"ORXL3ModelHvAVoltageDACSetValue"]];
    [self setHvBVoltageDACSetValue:[decoder decodeIntForKey:@"ORXL3ModelHvBVoltageDACSetValue"]];
    [self setHvAVoltageTargetValue:[decoder decodeIntForKey:@"ORXL3ModelhvAVoltageTargetValue"]];
    [self setHvBVoltageTargetValue:[decoder decodeIntForKey:@"ORXL3ModelhvBVoltageTargetValue"]];
    [self setHvACMOSRateLimit:[decoder decodeIntForKey:@"ORXL3ModelhvACMOSRateLimit"]];
    [self setHvBCMOSRateLimit:[decoder decodeIntForKey:@"ORXL3ModelhvBCMOSRateLimit"]];
    [self setHvACMOSRateIgnore:[decoder decodeIntForKey:@"ORXL3ModelhvACMOSRateIgnore"]];
    [self setHvBCMOSRateIgnore:[decoder decodeIntForKey:@"ORXL3ModelhvBCMOSRateIgnore"]];

	if (xl3Mode == 0) [self setXl3Mode: 1];
	if (xl3OpsRunning == nil) xl3OpsRunning = [[NSMutableDictionary alloc] init];
    //if (isPollingXl3 == YES) [self setIsPollingXl3:NO];

    pollDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                @"XL3_status", @"doc_type", nil];

	[[self undoManager] enableUndoRegistration];
	return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
	[super encodeWithCoder:encoder];
	[encoder encodeInt:selectedRegister	forKey:@"ORXL3ModelSelectedRegister"];
	[encoder encodeInt:[self slot]		forKey:@"slot"];
	[encoder encodeObject:xl3Link		forKey:@"XL3_Link"];
	[encoder encodeBool:autoIncrement	forKey:@"ORXL3ModelAutoIncrement"];
	[encoder encodeInt:repeatDelay		forKey:@"ORXL3ModelRepeatDelay"];
	[encoder encodeInt:repeatOpCount	forKey:@"ORXL3ModelRepeatOpCount"];
	[encoder encodeInt:xl3Mode		forKey:@"ORXL3ModelXl3Mode"];
	[encoder encodeInt:slotMask		forKey:@"ORXL3ModelSlotMask"];
	[encoder encodeInt:xl3RWAddressValue	forKey:@"ORXL3ModelXl3RWAddressValue"];
	[encoder encodeInt:xl3RWDataValue	forKey:@"ORXL3ModelXl3RWDataValue"];
	[encoder encodeInt:xl3PedestalMask	forKey:@"ORXL3ModelXl3PedestalMask"];
    [encoder encodeInt:xl3ChargeInjMask forKey:@"ORXL3ModelXl3ChargeInjMask"];
    [encoder encodeInt:xl3ChargeInjCharge forKey:@"ORXL3ModelXl3ChargeInjCharge"];

    [encoder encodeInt:pollXl3Time              forKey:@"ORXL3ModelPollXl3Time"];
    [encoder encodeBool:isPollingXl3            forKey:@"ORXL3ModelIsPollingXl3"];
    [encoder encodeBool:isPollingCMOSRates      forKey:@"ORXL3ModelIsPollingCMOSRates"];
    [encoder encodeInt:pollCMOSRatesMask        forKey:@"ORXL3ModelPollCMOSRatesMask"];
    [encoder encodeBool:isPollingPMTCurrents    forKey:@"ORXL3ModelIsPollingPMTCurrents"];
    [encoder encodeInt:pollPMTCurrentsMask      forKey:@"ORXL3ModelPollPMTCurrentsMask"];
    [encoder encodeBool:isPollingFECVoltages    forKey:@"ORXL3ModelIsPollingFECVoltages"];
    [encoder encodeInt:pollFECVoltagesMask      forKey:@"ORXL3ModelPollFECVoltagesMask"];
    [encoder encodeBool:isPollingXl3Voltages    forKey:@"ORXL3ModelIsPollingXl3Voltages"];
    [encoder encodeBool:isPollingHVSupply       forKey:@"ORXL3ModelIsPollingHVSupply"];
    [encoder encodeBool:isPollingXl3WithRun     forKey:@"ORXL3ModelIsPollingXl3WithRun"];
    [encoder encodeBool:isPollingVerbose        forKey:@"ORXL3ModelIsPollingVerbose"];
    [encoder encodeInt:hvAVoltageDACSetValue forKey:@"ORXL3ModelHvAVoltageDACSetValue"];
    [encoder encodeInt:hvBVoltageDACSetValue forKey:@"ORXL3ModelHvBVoltageDACSetValue"];
    [encoder encodeInt:_hvAVoltageTargetValue forKey:@"ORXL3ModelhvAVoltageTargetValue"];
    [encoder encodeInt:_hvBVoltageTargetValue forKey:@"ORXL3ModelhvBVoltageTargetValue"];
    [encoder encodeInt64:relayMask forKey:@"ORXL3ModelRelayMask"];
    [encoder encodeInt:_hvACMOSRateLimit forKey:@"ORXL3ModelhvACMOSRateLimit"];
    [encoder encodeInt:_hvBCMOSRateLimit forKey:@"ORXL3ModelhvBCMOSRateLimit"];
    [encoder encodeInt:_hvACMOSRateIgnore forKey:@"ORXL3ModelhvACMOSRateIgnore"];
    [encoder encodeInt:_hvBCMOSRateIgnore forKey:@"ORXL3ModelhvBCMOSRateIgnore"];
}

#pragma mark •••Hardware Access
- (void) deselectCards
{
	[[self xl3Link] sendCommand:DESELECT_FECS_ID expectResponse:YES];
}

- (void) selectCards:(unsigned long) selectBits
{
	//??? xl2 compatibility
	//[self writeToXL2Register:XL2_SELECT_REG value: selectBits]; // select the cards by writing to the XL2 REG 0 
}


- (void) select:(ORSNOCard*) aCard
{
	//???xl2 compatibility
	/*
	unsigned long selectBits;
	if(aCard == self)	selectBits = 0; //XL2_SELECT_XL2;
	else				selectBits = (1L<<[aCard stationNumber]);
	//NSLog(@"selectBits for card in slot %d: 0x%x\n", [aCard slot], selectBits);
	[self selectCards:selectBits];
	*/
}

- (void) writeHardwareRegister:(unsigned long)regAddress value:(unsigned long) aValue
{
	unsigned long xl3Address = regAddress | WRITE_REG;

	@try {
		[xl3Link sendFECCommand:0UL toAddress:xl3Address withData:&aValue];
	}
	@catch (NSException* e) {
		NSLog(@"XL3 writeHadwareRegister at address: 0x%08x failed\n", regAddress);
		NSLog(@"Error: %@ with reason: %@\n", [e name], [e reason]);
	}
}

- (unsigned long) readHardwareRegister:(unsigned long)regAddress
{
	unsigned long xl3Address = regAddress | READ_REG;
	unsigned long aValue = 0UL;

	@try {
		[xl3Link sendFECCommand:0UL toAddress:xl3Address withData:&aValue];
	}
	@catch (NSException* e) {
		NSLog(@"XL3 readHadwareRegister at address: 0x%08x failed\n", regAddress);
		NSLog(@"Error: %@ with reason: %@\n", [e name], [e reason]);
	}
	
	return aValue;
}

- (void) writeHardwareMemory:(unsigned long)memAddress value:(unsigned long)aValue
{
	unsigned long xl3Address = memAddress | WRITE_MEM;
	@try {
		[xl3Link sendFECCommand:0UL toAddress:xl3Address withData:&aValue];
	}
	@catch (NSException* e) {
		NSLog(@"XL3 writeHadwareMemory at address: 0x%08x failed\n", memAddress);
		NSLog(@"Error: %@ with reason: %@\n", [e name], [e reason]);
	}
}

- (unsigned long) readHardwareMemory:(unsigned long) memAddress
{
	unsigned long xl3Address = memAddress | READ_MEM;
	unsigned long aValue = 0UL;
	@try {
		[xl3Link sendFECCommand:0UL toAddress:xl3Address withData:&aValue];
	}
	@catch (NSException* e) {
		NSLog(@"XL3 readHadwareMemory at address: 0x%08x failed\n", memAddress);
		NSLog(@"Error: %@ with reason: %@\n", [e name], [e reason]);
	}
	return aValue;
}

- (void) writeXL3Register:(short)aRegister value:(unsigned long)aValue
{
	if (aRegister >= kXl3NumRegisters) {
		NSLog(@"Error writing XL3 register out of range\n");
		return;
	}
	
	unsigned long address = XL3_SEL | [self getRegisterAddress:aRegister] | WRITE_REG;
	[self writeHardwareRegister:address value:aValue];
	return;
}


- (unsigned long) readXL3Register:(short)aRegister
{
	if (aRegister >= kXl3NumRegisters) {
		NSLog(@"Error reading XL3 register out of range\n");
		return 0;
	}

	unsigned long address = XL3_SEL | [self getRegisterAddress:aRegister] | READ_REG;
	unsigned long value = [self readHardwareRegister:address];
	return value;
}


//multi command calls
- (id) writeHardwareRegisterCmd:(unsigned long) aRegister value:(unsigned long) aBitPattern
{
	//return [[self xl1] writeHardwareRegisterCmd:aRegister value:aBitPattern];
	return self;
}

- (id) readHardwareRegisterCmd:(unsigned long) regAddress
{
	//return [[self xl1] readHardwareRegisterCmd:regAddress];
	return self;
}

- (id) delayCmd:(unsigned long) milliSeconds
{
	//return [[self xl1] delayCmd:milliSeconds]; 
	return self;
}

- (void) executeCommandList:(ORCommandList*)aList
{
	//[[self xl1] executeCommandList:aList];		
}

- (void) initCrateWithXilinx:(BOOL)aXilinxFlag autoInit:(BOOL)anAutoInitFlag
{
	XL3_PayloadStruct payload;
	memset(payload.payload, 0, XL3_MAXPAYLOADSIZE_BYTES);
	payload.numberBytesinPayload = sizeof(mb_t) + 4;
	unsigned long* aMbId = (unsigned long*) payload.payload;
	mb_t* aConfigBundle = (mb_t*) (payload.payload + 4);
	
	BOOL loadOk = YES;
	unsigned short i;

	NSLog(@"%@ Init Crate...\n",[[self xl3Link] crateName]);

	for (i=0; i<16; i++) {
		memset(payload.payload, 0, XL3_MAXPAYLOADSIZE_BYTES);
		*aMbId = i;
		[self synthesizeDefaultsIntoBundle:aConfigBundle forSLot:i];
		if ([xl3Link needToSwap]) {
			*aMbId = swapLong(*aMbId);
			[self byteSwapBundle:aConfigBundle];
		}
		@try {
			[[self xl3Link] sendCommand:CRATE_INIT_ID withPayload:&payload expectResponse:NO];
			/*
			if (*(unsigned int*) payload.payload != 0) {
				NSLog(@"XL3 doesn't like the config bundle for slot %d, exiting.\n", i);
				loadOk = NO;
				break;
			}
			*/
		}
		@catch (NSException* e) {
			NSLog(@"%@ Init crate failed; error: %@ reason: %@\n",[[self xl3Link] crateName], [e name], [e reason]);
			loadOk = NO;
			break;
		}
	}
		
	if (loadOk) {
		memset(payload.payload, 0, XL3_MAXPAYLOADSIZE_BYTES);
		// time to fly (never say 16 here!)
		aMbId[0] = 666;
		
		// xil load
		if (aXilinxFlag == YES) aMbId[1] = 1;
		else aMbId[1] = 0;
		
		// hv reset, talk to Rob first
		aMbId[2] = 0;
		
		// slot mask
		if (anAutoInitFlag == YES) {
			aMbId[3] = 0xFFFF;
			NSLog(@"AutoInits not yet implemented, XL3 will freeze probably.\n");
		}
		else {
			unsigned int msk = 0;
			ORFec32Model* aFec;
			NSArray* fecs = [[self guardian] collectObjectsOfClass:NSClassFromString(@"ORFec32Model")];
			for (aFec in fecs) {
				msk |= 1 << [aFec stationNumber];
			}
			aMbId[3] = msk;
		}

		// ctc delay
		aMbId[4] = 0;
		// cmos shift regs only if != 0
		aMbId[5] = 0;
		
		if ([xl3Link needToSwap]) {
			for (i=0; i<6; i++) aMbId[i] = swapLong(aMbId[i]);
		}
		@try {
			[[self xl3Link] sendCommand:CRATE_INIT_ID withPayload:&payload expectResponse:YES];
            /*
			if (*(unsigned int*)payload.payload != 0) {
                NSLog(@"%@ error during init.\n",[[self xl3Link] crateName]);
			}
             */
			
			//todo look into the hw params returned
			/* xl3 does the following on successfull init, or returns zeros here if things go wrong
			 for (i=0;i<16;i++){
			 response_hware_vals = (mb_hware_vals_t *) (payload+4+i*sizeof(mb_hware_vals_t));
			 *response_hware_vals = hware_vals[i];
			 */
		}
		@catch (NSException* e) {
			NSLog(@"%@ init crate failed; error: %@ reason: %@\n",[[self xl3Link] crateName], [e name], [e reason]);
		}
        
        NSLog(@"%@ init ok!\n",[[self xl3Link] crateName]);
        [self setTriggerStatus:@"ON"];
	}
	else {
		NSLog(@"%@ error loading config, init skipped\n",[[self xl3Link] crateName]);
	}
}

#pragma mark •••Basic Ops
- (void) readBasicOps
{
	doReadOp = YES;
	workingCount = 0;
	[self setBasicOpsRunning:YES];
	[self doBasicOp];	
}


- (void) writeBasicOps
{
	doReadOp = NO;
	workingCount = 0;
	[self setBasicOpsRunning:YES];
	[self doBasicOp];
}

- (void) stopBasicOps
{
	[self setBasicOpsRunning:NO];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doBasicOp) object:nil];
}

- (void) reportStatus
{
	NSLog(@"not yet implemented\n");
	//that what we did for MTC
	//NSLog(@"Mtc control reg: 0x%0x\n", [self getMTC_CSR]);
	//parse csr to human friendly output, e.g. 0x3 firing pedestals...
}


#pragma mark •••Composite HW Functions

- (void) deselectComposite
{
	[self setXl3OpsRunning:YES forKey:@"compositeDeselect"];
	NSLog(@"%@ Deselect FECs...\n",[[self xl3Link] crateName]);
	@try {
		[[self xl3Link] sendCommand:DESELECT_FECS_ID expectResponse:YES];
		NSLog(@"ok\n");
	}
	@catch (NSException * e) {
		NSLog(@"Deselect FECs failed; error: %@ reason: %@\n", [e name], [e reason]);
	}
	[self setXl3OpsRunning:NO forKey:@"compositeDeselect"];
}

- (void) writeXl3Mode
{
	XL3_PayloadStruct payload;
	payload.numberBytesinPayload = 8;
	unsigned long* data = (unsigned long*) payload.payload;

	if ([xl3Link needToSwap]) {
		data[0] = swapLong([self xl3Mode]);
		data[1] = swapLong([self slotMask]);
	}
	else {
		data[0] = [self xl3Mode];
		data[1] = [self slotMask];
	}
	
	[self setXl3ModeRunning:YES];
	NSLog(@"%@ Set mode: %d slot mask: 0x%04x ...\n",[[self xl3Link] crateName], [self xl3Mode], [self slotMask]);
	@try {
		[[self xl3Link] sendCommand:CHANGE_MODE_ID withPayload:&payload expectResponse:YES];
		NSLog(@"ok\n");
	}
	@catch (NSException* e) {
		NSLog(@"Set XL3 mode failed; error: %@ reason: %@\n", [e name], [e reason]);
	}
	[self setXl3ModeRunning:NO];
	//XL3 sends the payload back not touching it, should we check?	
}

- (void) compositeXl3RW
{
	unsigned long aValue = [self xl3RWDataValue];
	NSLog(@"%@ XL3_rw to address: 0x%08x with data: 0x%08x\n",[[self xl3Link] crateName], [self xl3RWAddressValue], aValue);
	[self setXl3OpsRunning:YES forKey:@"compositeXl3RW"];
	
	@try {
		[xl3Link sendFECCommand:0UL toAddress:[self xl3RWAddressValue] withData:&aValue];
		NSLog(@"XL3_rw returned data: 0x%08x\n", aValue);
	}
	@catch (NSException* e) {
		NSLog(@"XL3_rw failed; error: %@ reason: %@\n", [e name], [e reason]);
	}

	[self setXl3OpsRunning:NO forKey:@"compositeXl3RW"];
}

- (void) compositeQuit
{
	XL3_PayloadStruct payload;
	payload.numberBytesinPayload = 8;
	unsigned long* data = (unsigned long*) payload.payload;
	
	if ([xl3Link needToSwap]) {
		data[0] = 0x20657942UL;
		data[1] = 0x00334C58UL;
	}
	else {
		data[0] = 0x42796520UL;
		data[1] = 0x584C3300UL;
	}
	
	[self setXl3OpsRunning:YES forKey:@"compositeQuit"];
	NSLog(@"%@ Send XL3 Quit ...\n", [[self xl3Link] crateName]);
	@try {
		[[self xl3Link] sendCommand:DAQ_QUIT_ID withPayload:&payload expectResponse:NO];
		NSLog(@"ok\n");
	}
	@catch (NSException* e) {
		NSLog(@"Send XL3 Quit failed; error: %@ reason: %@\n", [e name], [e reason]);
	}
	[self setXl3OpsRunning:NO forKey:@"compositeQuit"];
}

- (void) compositeSetPedestal
{
	XL3_PayloadStruct payload;
	payload.numberBytesinPayload = 8;
	unsigned long* data = (unsigned long*) payload.payload;

	if ([xl3Link needToSwap]) {
		data[0] = swapLong([self slotMask]);
		data[1] = swapLong([self xl3PedestalMask]);
	}
	else {
		data[0] = [self slotMask];
		data[1] = [self xl3PedestalMask];
	}
	
	[self setXl3OpsRunning:YES forKey:@"compositeSetPedestal"];
	NSLog(@"%@ Set Pedestal ...\n", [[self xl3Link] crateName]);
	@try {
		[[self xl3Link] sendCommand:SET_CRATE_PEDESTALS_ID withPayload:&payload expectResponse:YES];
		if ([xl3Link needToSwap]) *data = swapLong(*data);
		if (*data == 0) NSLog(@"ok\n");
		else NSLog(@"failed with XL3 error: 0x%08x\n", *data);
	}
	@catch (NSException* e) {
		NSLog(@"%@ Set Pedestal failed; error: %@ reason: %@\n", [[self xl3Link] crateName],[e name], [e reason]);
	}
	[self setXl3OpsRunning:NO forKey:@"compositeSetPedestal"];
}

- (unsigned short) getBoardIDForSlot:(unsigned short)aSlot chip:(unsigned short)aChip
{
	XL3_PayloadStruct payload;
	payload.numberBytesinPayload = 12;
	unsigned long* data = (unsigned long*) payload.payload;
	
	data[0] = aSlot;
	data[1] = aChip;
	data[2] = 15;
	
	if ([xl3Link needToSwap]) {
		data[0] = swapLong(data[0]);
		data[1] = swapLong(data[1]);
		data[2] = swapLong(data[2]);
	}

	@try {
		[[self xl3Link] sendCommand:BOARD_ID_READ_ID withPayload:&payload expectResponse:YES];
		if ([xl3Link needToSwap]) *data = swapLong(*data);
	}
	@catch (NSException* e) {
		NSLog(@"Get Board ID failed; error: %@ reason: %@\n", [e name], [e reason]);
		*data = 0;
	}

	return (unsigned short) *data;
}

- (void) getBoardIDs
{
	unsigned short i, j, val;
	unsigned long msk;
	NSString* bID[6];
	
	[self setXl3OpsRunning:YES forKey:@"compositeBoardID"];
	NSLog(@"%@ Get Board IDs ...\n", [[self xl3Link] crateName]);

	msk = [self slotMask];
	for (i=0; i < 16; i++) {
		if (1 << i & msk) {
			//HV chip not yet available
			//for (j = 0; j < 6; j++) {
			for (j = 0; j < 5; j++) {
				val = [self getBoardIDForSlot:i chip:(j+1)];
				if (val == 0x0) bID[j] = @"----";
				else bID[j] = [NSString stringWithFormat:@"0x%04x", val];
			}
			
			//NSLog(@"slot: %02d: MB: %@ DB1: %@ DB2:%@ DB3: %@ DB4: %@ HV: %@\n",
			//      i+1, bID[0], bID[1], bID[2], bID[3], bID[4], bID[5]);
			NSLog(@"slot: %02d: MB: %@ DB1: %@ DB2:%@ DB3: %@ DB4: %@\n",
			      i+1, bID[0], bID[1], bID[2], bID[3], bID[4]);
		}
	}

	[self setXl3OpsRunning:NO forKey:@"compositeBoardID"];	
}

- (void) compositeResetCrate
{
	//XL2_CONTROL_CRATE_RESET	0x80
	//XL2_CONTROL_DONE_PROG		0x100

	[self setXl3OpsRunning:YES forKey:@"compositResetCrate"];
	NSLog(@"Reset crate keep Xilinx code.\n");

	@try {
		[self deselectCards];
		//read XL3 select register
		unsigned long aValue = [self readXL3Register:kXl3CsReg];
		if ((aValue & 0x100UL) == 0) { 
			NSLog(@"Xilinx doesn't seem to be loaded, keeping it anyway!\n");
		}
		
		[[self xl3Link] newMultiCmd];
		[[self xl3Link] addMultiCmdToAddress:(XL3_SEL | [self getRegisterAddress:kXl3CsReg] | WRITE_REG) withValue:0x100UL]; //prog done
		[[self xl3Link] addMultiCmdToAddress:(XL3_SEL | [self getRegisterAddress:kXl3CsReg] | WRITE_REG) withValue:0x180UL]; //prog done | reset
		[[self xl3Link] addMultiCmdToAddress:(XL3_SEL | [self getRegisterAddress:kXl3CsReg] | WRITE_REG) withValue:0x100UL]; //prog done
		[[self xl3Link] executeMultiCmd];
		[self deselectCards];
		
		if ([[self xl3Link] multiCmdFailed]) NSLog(@"reset failed: XL3 bus error.\n");
	}
	@catch (NSException* e) {
		NSLog(@"reset failed; error: %@ reason: %@\n", [e name], [e reason]);
	}
	
	[self setXl3OpsRunning:NO forKey:@"compositeResetCrate"];
}

- (void) compositeResetCrateAndXilinX
{
	[self setXl3OpsRunning:YES forKey:@"compositResetCrateAndXilinX"];
	NSLog(@"Reset crate and XilinX code.\n");
	
	@try {
		[self deselectCards];
		[[self xl3Link] newMultiCmd];
		[[self xl3Link] addMultiCmdToAddress:(XL3_SEL | [self getRegisterAddress:kXl3CsReg] | WRITE_REG) withValue:0x00UL];
		[[self xl3Link] addMultiCmdToAddress:(XL3_SEL | [self getRegisterAddress:kXl3CsReg] | WRITE_REG) withValue:0x80UL]; //reset
		[[self xl3Link] addMultiCmdToAddress:(XL3_SEL | [self getRegisterAddress:kXl3CsReg] | WRITE_REG) withValue:0x00UL]; //done
		[[self xl3Link] executeMultiCmd];
		[self deselectCards];
		
		if ([[self xl3Link] multiCmdFailed]) NSLog(@"reset failed: XL3 bus error.\n");
	}
	@catch (NSException* e) {
		NSLog(@"reset failed; error: %@ reason: %@\n", [e name], [e reason]);
	}
	
	[self setXl3OpsRunning:NO forKey:@"compositeResetCrateAndXilinX"];
}

- (void) compositeResetFIFOAndSequencer
{
	[self setXl3OpsRunning:YES forKey:@"compositResetFIFOAndSeuencer"];
	NSLog(@"Reset FIFO and Sequencer to be implemented.\n");
	//slot mask?
	unsigned long xl3Address = XL3_SEL | [self getRegisterAddress:kXl3SelectReg] | WRITE_REG;
	unsigned long aValue = 0xffffffffUL;
    
	@try {
		[xl3Link sendFECCommand:0UL toAddress:xl3Address withData:&aValue];
	}
	@catch (NSException* e) {
		NSLog(@"%@ SW reset failed.\n",[[self xl3Link] crateName]);
        @throw e;
	}
    
	[self setXl3OpsRunning:NO forKey:@"compositeResetFIFOAndSequencer"];
}

- (void) compositeResetXL3StateMachine
{
	[self setXl3OpsRunning:YES forKey:@"compositResetXL3StateMachine"];
	NSLog(@"Reset XL3 State Machine.\n");

	@try {
		[[self xl3Link] sendCommand:STATE_MACHINE_RESET_ID expectResponse:YES];
        //we don't care about the response, but clean it from the array
	}
	@catch (NSException* e) {
		NSLog(@"Send XL3 command failed; error: %@ reason: %@\n", [e name], [e reason]);
	}
	[self setXl3OpsRunning:NO forKey:@"compositeResetXL3StateMachine"];
}

- (void) reset
{
	@try {
		[self deselectCards];
		//unsigned long readValue = 0; //[self readFromXL2Register: XL2_CONTROL_STATUS_REG];
/*
		if (readValue & XL2_CONTROL_DONE_PROG) {
			NSLog(@"XilinX code found in the crate, keeping it.\n");
			[self writeToXL2Register:XL2_CONTROL_STATUS_REG value: XL2_CONTROL_DONE_PROG]; 
			[self writeToXL2Register:XL2_CONTROL_STATUS_REG value: (XL2_CONTROL_CRATE_RESET | XL2_CONTROL_DONE_PROG)];
			[self writeToXL2Register:XL2_CONTROL_STATUS_REG value: XL2_CONTROL_DONE_PROG];
		}
		else {
			//do not set the dp bit if the xilinx hasn't been loaded
			[self writeToXL2Register:XL2_CONTROL_STATUS_REG value: 0UL]; 
			[self writeToXL2Register:XL2_CONTROL_STATUS_REG value: XL2_CONTROL_CRATE_RESET];
			[self writeToXL2Register:XL2_CONTROL_STATUS_REG value: 0UL];
		}
*/
		[self deselectCards];
		
	}
	@catch(NSException* localException) {
		NSLog(@"Failure during reset of XL2 Crate %d Slot %d.\n", [self crateNumber], [self stationNumber]);
		[NSException raise:@"XL2 Reset Failed" format:@"%@",localException];
	}		
	
}

- (void) compositeEnableChargeInjection
{
	[self setXl3OpsRunning:YES forKey:@"compositeEnableChargeInjection"];

    NSLog(@"%@, charge injection for slot: ", [[self xl3Link] crateName]);
    unsigned int i;
    unsigned long msk = [self xl3ChargeInjMask];
    for (i=0; i < 16; i++) {
		if (1 << i & msk) {
            NSLog(@"%d ", i);
            [self enableChargeInjectionForSlot:i channelMask:[self xl3ChargeInjMask]];
        }
    }    
	NSLog(@"enabled.\n");
    
	[self setXl3OpsRunning:NO forKey:@"compositeEnableChargeInjection"];
}


- (void) enableChargeInjectionForSlot:(unsigned short) aSlot channelMask:(unsigned long) aChannelMask
{
	XL3_PayloadStruct payload;
	memset(payload.payload, 0, XL3_MAXPAYLOADSIZE_BYTES);
	payload.numberBytesinPayload = 8;
	unsigned long* data = (unsigned long*) payload.payload;
    
    uint32_t slot = aSlot;
    uint32_t mask = aChannelMask;
    
    if ([xl3Link needToSwap]) {
        slot = swapLong(slot);
        mask = swapLong(mask);
    }

    data[0] = slot;
    data[1] = mask;

    @try {
        [[self xl3Link] sendCommand:SETUP_CHARGE_INJ_ID withPayload:&payload expectResponse:YES];
    }
    @catch (NSException *exception) {
        NSLog(@"error sending ChargeInjection command.\n");
    }

    if (*(unsigned int*)payload.payload != 0) {
        NSLog(@"XL3 error in enableChargeInjectionForSlot.\n");
    }

    //NSLog(@"%@: enabled charge injection for slot: %d, for channels: 0x%08x\n", [[self xl3Link] crateName], aSlot, aChannelMask);

/*
	@try {
        int index;
		//[[self xl3Link] newMultiCmd];
		for (index = 0; index < 16; index++){
			//[[self xl3Link] addMultiCmdToAddress:(FEC_SEL*aSlot | kFecHVCcsr | WRITE_REG) withValue:0x0UL];
			//[[self xl3Link] addMultiCmdToAddress:(FEC_SEL*aSlot | kFecHVCcsr | WRITE_REG) withValue:PMTI_CLOCK_HIGH];
		}
		//[[self xl3Link] executeMultiCmd];
		
		//if ([[self xl3Link] multiCmdFailed]) {
		//	NSLog(@"Enable charge injection failed: XL3 bus error.\n");
		//	return;
		//}
	}
	@catch (NSException* e) {
		NSLog(@"Enable charge injection failed; error: %@ reason: %@\n", [e name], [e reason]);
	}		
*/
}

#pragma mark •••HV
- (void) readCMOSCountWithArgs:(check_total_count_args_t*)aArgs counts:(check_total_count_results_t*)aCounts;
{
	XL3_PayloadStruct payload;
	memset(payload.payload, 0, XL3_MAXPAYLOADSIZE_BYTES);
	payload.numberBytesinPayload = sizeof(check_total_count_results_t);
    
	check_total_count_args_t* data = (check_total_count_args_t*) payload.payload;
    memcpy(data, aArgs, sizeof(check_total_count_args_t));
    
    //max 8 slots may be masked in
    unsigned int v = data->slot_mask;
    unsigned int c;
    for (c = 0; v; c++) v &= v - 1;
    if (c > 8) {
        NSLog(@"%@ error in readCMOSCountWithArgs: more than 8 slots were masked in, ask less.\n", [[self xl3Link] crateName]);
        @throw [NSException exceptionWithName:@"readCMOSCount error" reason:@"More than 8 slots were masked in slot_mask" userInfo:nil];
    }
    
    if ([xl3Link needToSwap]) {
        SwapLongBlock(data, sizeof(check_total_count_args_t)/4);
    }
    
    @try {
        [[self xl3Link] sendCommand:CHECK_TOTAL_COUNT_ID withPayload:&payload expectResponse:YES];
    }
    @catch (NSException *exception) {
        NSLog(@"%@ error sending CHECK_TOTAL_COUNT_ID command.\n",[[self xl3Link] crateName]);
        @throw exception;
    }
    
    if ([xl3Link needToSwap]) {
        SwapLongBlock(data, sizeof(check_total_count_results_t)/4);
    }
    
    memcpy(aCounts, data, sizeof(check_total_count_results_t));
}

- (void) readCMOSCountForSlot:(unsigned short)aSlot withChannelMask:(unsigned long)aChannelMask
{
    check_total_count_args_t args;
    check_total_count_results_t results;
    
    args.slot_mask |= 0x1 << aSlot;
    args.channel_masks[aSlot] = aChannelMask;
    
    @try {
        [self readCMOSCountWithArgs:&args counts:&results];
    }
    @catch (NSException *exception) {
        ;
    }
    
    if (results.error_flags != 0) {
        NSLog(@"%@ error in readCMOSCountForSlot, error_flags: 0x%08x.\n",[[self xl3Link] crateName], results.error_flags);
    }
    else{
        NSMutableString* msg = [NSMutableString stringWithFormat:@"%@ CMOS counts for slot: %d\n", [[self xl3Link] crateName], aSlot];
        unsigned int i;
        for (i=0; i<32; i++) {
            if (aChannelMask & 1 << i) {
                [msg appendFormat:@"%d: %u\n", i, results.counts[i]];
            }
        }
        NSLog(msg);
    }
}

- (void) readCMOSCount
{
    //all slots, all channels, two shots
    check_total_count_args_t args_lo;
    check_total_count_args_t args_hi;
    check_total_count_results_t results_lo;
    check_total_count_results_t results_hi;
    
    memset(&args_lo, 0, sizeof(check_total_count_args_t));
    memset(&args_hi, 0, sizeof(check_total_count_args_t));
    memset(&results_lo, 0, sizeof(check_total_count_results_t));
    memset(&results_hi, 0, sizeof(check_total_count_results_t));
    
    unsigned char i;
    NSLog(@"%@ error in readCMOSCount, error_flags_lo: 0x%08x, error_flags_hi: 0x%08x\n",
          [[self xl3Link] crateName], results_lo.error_flags, results_hi.error_flags);
    
    args_lo.slot_mask = 0xff;
    for (i = 0; i < 8; i++) args_lo.channel_masks[i] = 0xffffffff;
    
    args_hi.slot_mask = 0xff00;
    for (i = 8; i < 16; i++) args_hi.channel_masks[i] = 0xffffffff;
    
    @try {
        [self readCMOSCountWithArgs:&args_lo counts:&results_lo];
        [self readCMOSCountWithArgs:&args_hi counts:&results_hi];
    }
    @catch (NSException *exception) {
        ;
    }
    
    if (results_lo.error_flags != 0 || results_hi.error_flags != 0) {
        NSLog(@"%@ error in readCMOSCount, error_flags_lo: 0x%08x, error_flags_hi: 0x%08x\n",
              [[self xl3Link] crateName], results_lo.error_flags, results_hi.error_flags);
    }
    else{
        NSMutableString* msg = [NSMutableString stringWithFormat:@"%@ CMOS counts:\n", [[self xl3Link] crateName]];
        unsigned char j;
        for (i=0; i<32; i++) {
            [msg appendFormat:@"slot %d, ch%2d-%2d:", i/4, i%4 * 8, (i%4 + 1) * 8 - 1];
            for (j=0; j<8; j++) {
                [msg appendFormat:@"%u ", results_lo.counts[i*8 + j]];
            }
            [msg appendFormat:@"\n"];
        }
        for (i=0; i<32; i++) {
            [msg appendFormat:@"slot %d, ch%2d-%2d:", i/4 + 8, i%4 * 8, (i%4 + 1) * 8 - 1];
            for (j=0; j<8; j++) {
                [msg appendFormat:@"%u ", results_hi.counts[i*8 + j]];
            }
            [msg appendFormat:@"\n"];
        }
        NSLog(msg);
    }    
}

- (void) readCMOSRateWithArgs:(read_cmos_rate_args_t*)aArgs rates:(read_cmos_rate_results_t*)aRates;
{
	XL3_PayloadStruct payload;
	memset(payload.payload, 0, XL3_MAXPAYLOADSIZE_BYTES);
	payload.numberBytesinPayload = sizeof(read_cmos_rate_results_t);
    
	read_cmos_rate_args_t* data = (read_cmos_rate_args_t*) payload.payload;
    memcpy(data, aArgs, sizeof(read_cmos_rate_args_t));

    //max 8 slots may be masked in
    unsigned int v = data->slot_mask;
    unsigned int c;
    for (c = 0; v; c++) v &= v - 1;
    if (c > 8) {
        NSLog(@"%@ error in readCMOSRateWithArgs: more than 8 slots were masked in, ask less.\n", [[self xl3Link] crateName]);
        @throw [NSException exceptionWithName:@"readCMOSRate error" reason:@"More than 8 slots were masked in slot_mask" userInfo:nil];
    }
    
    if ([xl3Link needToSwap]) {
        SwapLongBlock(data, sizeof(read_cmos_rate_args_t)/4);
    }
    
    @try {
        [[self xl3Link] sendCommand:SLOT_NOISE_RATE_ID withPayload:&payload expectResponse:YES];
    }
    @catch (NSException *exception) {
        NSLog(@"%@ error sending SLOT_NOISE_RATE_ID command.\n",[[self xl3Link] crateName]);
        @throw exception;
    }
    
    if ([xl3Link needToSwap]) {
        SwapLongBlock(data, sizeof(read_cmos_rate_results_t)/4);
    }
    
    memcpy(aRates, data, sizeof(read_cmos_rate_results_t));
}

- (void) readCMOSRateForSlot:(unsigned short)aSlot withChannelMask:(unsigned long)aChannelMask withDelay:(unsigned long)aDelay
{
    read_cmos_rate_args_t args;
    read_cmos_rate_results_t results;
    
    args.slot_mask |= 0x1 << aSlot;
    args.channel_masks[aSlot] = aChannelMask;
    args.period = aDelay;
    
    @try {
        [self readCMOSRateWithArgs:&args rates:&results];
    }
    @catch (NSException *exception) {
        ;
    }
    
    if (results.error_flags != 0) {
        NSLog(@"%@ error in readCMOSCRateForSlot, error_flags: 0x%08x.\n",[[self xl3Link] crateName], results.error_flags);
    }
    else{
        NSMutableString* msg = [NSMutableString stringWithFormat:@"%@ CMOS rates for slot: %d\n", [[self xl3Link] crateName], aSlot];
        unsigned int i;
        for (i=0; i<32; i++) {
            if (aChannelMask & 1 << i) {
                [msg appendFormat:@"%d: %f\n", i, results.rates[i]];
            }
        }
        NSLog(msg);
    }
}

- (void) readCMOSRate
{
    check_total_count_args_t args_lo;
    check_total_count_args_t args_hi;
    check_total_count_results_t results_lo;
    check_total_count_results_t results_hi;
    unsigned char i;

    //NSArray* fecs = [guardian collectObjectsOfClass:NSClassFromString(@"ORFec32Model")];
	unsigned int msk = 0UL;

    NSEnumerator* e = [[[self guardian] objectEnumerator] retain];
    id anObj;
    while(anObj = [e nextObject]){
        if ([anObj class] == NSClassFromString(@"ORFec32Model")) {
            msk |= 1 << [anObj stationNumber];
        }
	}
    [e release]; e=nil;

	//for (id key in fecs) {
	//	msk |= 1 << [key stationNumber];
	//}
    if (isPollingXl3 || isPollingForced) {
        msk &= pollCMOSRatesMask;
    }
    
    unsigned int v = msk;
    unsigned int num_slots;
    for (num_slots = 0; v; num_slots++) v &= v - 1;
    
    if (num_slots > 8) {
        args_lo.slot_mask = msk & 0xff;
        args_hi.slot_mask = msk & 0xff00;
    }
    else {
        args_lo.slot_mask = msk;
    }
    
    for (i = 0; i < 16; i++) {
        args_lo.channel_masks[i] = 0xffffffff;
        args_hi.channel_masks[i] = 0xffffffff;
    }

    @try {
        //[self readCMOSCountWithArgs:&args_lo counts:&results_lo];
        //if (num_slots > 8) [self readCMOSCountWithArgs:&args_hi counts:&results_hi];
    }
    @catch (NSException *exception) {
        if (isPollingXl3) {
            NSLog(@"%@ Polling loop stopped because reading CMOS rates failed\n", [[self xl3Link] crateName]);
            [self setIsPollingXl3:NO];
        }
    }
    
    if (results_lo.error_flags != 0 || (num_slots > 8 &&  results_hi.error_flags != 0)) {
        NSLog(@"%@ error in readCMOSCountWithArgs, error_flags_lo: 0x%08x, error_flags_hi: 0x%08x\n",
              [[self xl3Link] crateName], results_lo.error_flags, results_hi.error_flags);
    }
    else {
        unsigned char slot_idx = 0;
        unsigned long counts[32];
        
        read_cmos_rate_results_t rates_lo;
        read_cmos_rate_results_t rates_hi;
        
        if (num_slots > 8) {
            slot_idx = 0;
            unsigned char j = 0;
            for (i=0; i<8; i++) {
                if ((msk >> i) & 0x1) {
                    for (j=0; j<32; j++) {
                        counts[j] = results_lo.counts[slot_idx*32 + j];
                    }
                    e = [[[self guardian] objectEnumerator] retain];
                    ORFec32Model* fec;
                    
                    while(anObj = [e nextObject]){
                        if ([anObj class] == NSClassFromString(@"ORFec32Model") && [anObj stationNumber] == i) {
                            fec = anObj;
                            break;
                        }
                    }
                    [e release]; e=nil;
                    [fec processCMOSCounts:counts calcRates:[self calcCMOSRatesFromCounts] withChannelMask:args_lo.channel_masks[i]];
                    for (j=0; j<32; j++) {
                        rates_lo.rates[slot_idx*32 + j] = [fec cmosRate:j];
                    }                    
                    slot_idx++;
                }
            }
            slot_idx=0;
            for (i=0; i<8; i++) {
                if ((msk >> (i + 8)) & 0x1) {
                    for (j=0; j<32; j++) {
                        counts[j] = results_hi.counts[slot_idx*32 + j];
                    }
                    e = [[[self guardian] objectEnumerator] retain];
                    ORFec32Model* fec;
                    while(anObj = [e nextObject]){
                        if ([anObj class] == NSClassFromString(@"ORFec32Model") && [anObj stationNumber] == i + 8) {
                            fec = anObj;
                            break;
                        }
                    }
                    [e release]; e=nil;
                    [fec processCMOSCounts:counts calcRates:[self calcCMOSRatesFromCounts] withChannelMask:args_hi.channel_masks[i]];
                    for (j=0; j<32; j++) {
                        rates_hi.rates[slot_idx*32 + j] = [fec cmosRate:j];
                    }                    
                    slot_idx++;
                }
            }
        }
        else {
            slot_idx = 0;
            unsigned char j = 0;
            for (i=0; i<16; i++) {
                if ((msk >> i) & 0x1) {
                    for (j=0; j<32; j++) {
                        counts[j] = results_lo.counts[slot_idx*32 + j];
                    }
                    e = [[[self guardian] objectEnumerator] retain];
                    ORFec32Model* fec;
                    while(anObj = [e nextObject]){
                        if ([anObj class] == NSClassFromString(@"ORFec32Model") && [anObj stationNumber] == i) {
                            fec = anObj;
                            break;
                        }
                    }
                    [e release]; e=nil;
                    [fec processCMOSCounts:counts calcRates:[self calcCMOSRatesFromCounts] withChannelMask:args_lo.channel_masks[i]];
                    for (j=0; j<32; j++) {
                        rates_lo.rates[slot_idx*32 + j] = [fec cmosRate:j];
                    }                    
                    slot_idx++;
                }
            }
        }
        
        if ((!isPollingXl3 || isPollingVerbose) && [self calcCMOSRatesFromCounts]) {
            NSMutableString* msg = [NSMutableString stringWithFormat:@"%@ CMOS rates:\n", [[self xl3Link] crateName]];
            unsigned char slot_idx = 0;
            
            if (num_slots > 8) {
                slot_idx = 0;
                unsigned char j = 0;
                for (i=0; i<8; i++) {
                    if ((msk >> i) & 0x1) {
                        [msg appendFormat:@"slot %2d, ch00-07:", i];
                        for (j=0; j<8; j++) [msg appendFormat:@"%3.1f ", rates_lo.rates[slot_idx*32 + j]];
                        [msg appendFormat:@"\nslot %2d, ch08-15:", i];
                        for (j=8; j<16; j++) [msg appendFormat:@"%3.1f ", rates_lo.rates[slot_idx*32 + j]];
                        [msg appendFormat:@"\nslot %2d, ch16-23:", i];
                        for (j=16; j<23; j++) [msg appendFormat:@"%3.1f ", rates_lo.rates[slot_idx*32 + j]];
                        [msg appendFormat:@"\nslot %2d, ch24-31:", i];
                        for (j=24; j<32; j++) [msg appendFormat:@"%3.1f ", rates_lo.rates[slot_idx*32 + j]];
                        [msg appendFormat:@"\n"];
                        slot_idx++;
                    }
                }
                slot_idx=0;
                for (i=0; i<8; i++) {
                    if ((msk >> (i + 8)) & 0x1) {
                        [msg appendFormat:@"slot %2d, ch00-07:", i + 8];
                        for (j=0; j<8; j++) [msg appendFormat:@"%3.1f ", rates_hi.rates[slot_idx*32 + j]];
                        [msg appendFormat:@"\nslot %2d, ch08-15:", i + 8];
                        for (j=8; j<16; j++) [msg appendFormat:@"%3.1f ", rates_hi.rates[slot_idx*32 + j]];
                        [msg appendFormat:@"\nslot %2d, ch16-23:", i + 8];
                        for (j=16; j<23; j++) [msg appendFormat:@"%3.1f ", rates_hi.rates[slot_idx*32 + j]];
                        [msg appendFormat:@"\nslot %2d, ch24-31:", i + 8];
                        for (j=24; j<32; j++) [msg appendFormat:@"%3.1f ", rates_hi.rates[slot_idx*32 + j]];
                        [msg appendFormat:@"\n"];
                        slot_idx++;
                    }
                }
            }
            else {
                slot_idx = 0;
                unsigned char j = 0;
                for (i=0; i<16; i++) {
                     if ((msk >> i) & 0x1) {
                         [msg appendFormat:@"slot %2d, ch00-07:", i];
                         for (j=0; j<8; j++) [msg appendFormat:@"%3.1f ", rates_lo.rates[slot_idx*32 + j]];
                         [msg appendFormat:@"\nslot %2d, ch08-15:", i];
                         for (j=8; j<16; j++) [msg appendFormat:@"%3.1f ", rates_lo.rates[slot_idx*32 + j]];
                         [msg appendFormat:@"\nslot %2d, ch16-23:", i];
                         for (j=16; j<23; j++) [msg appendFormat:@"%3.1f ", rates_lo.rates[slot_idx*32 + j]];
                         [msg appendFormat:@"\nslot %2d, ch24-31:", i];
                         for (j=24; j<32; j++) [msg appendFormat:@"%3.1f ", rates_lo.rates[slot_idx*32 + j]];
                         [msg appendFormat:@"\n"];
                         slot_idx++;
                     }
                }
            }
            NSLog(msg);
        }
        //pollDict
        if (isPollingXl3 && [self calcCMOSRatesFromCounts]) {
            NSDateFormatter* iso = [[NSDateFormatter alloc] init];
            [iso setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
            iso.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            //iso.calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
            //iso.locale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease];
            NSString* str = [iso stringFromDate:[NSDate date]];
            NSMutableArray* rates = [[NSMutableArray alloc] initWithCapacity:16];
            NSMutableArray* slot_rates;
            NSMutableArray* time_stamps = [[NSMutableArray alloc] initWithCapacity:16];
            unsigned char ch, sl;
            unsigned char slot_idx = 0;
            for (sl = 0; sl < 16; sl++) {
                slot_rates = [[NSMutableArray alloc] initWithCapacity:32];

                if ((msk >> sl) & 0x1) {
                    if (num_slots > 8) {
                        if (sl==8) slot_idx = 0;
                        if (sl < 8) {
                            for (ch = 0; ch < 32; ch++) {
                                NSNumber *number = [[NSNumber alloc] initWithInt:rates_lo.rates[slot_idx*32 + ch]];
                                [slot_rates addObject:number];
                                [number release];
                                number = nil;
                            }
                            slot_idx++;
                        }
                        else {
                            for (ch = 0; ch < 32; ch++) {
                                NSNumber *number = [[NSNumber alloc] initWithInt:rates_hi.rates[slot_idx*32 + ch]];
                                [slot_rates addObject:number];
                                [number release];
                                number = nil;
                            }
                            slot_idx++;
                        }
                    }
                    else {
                        for (ch = 0; ch < 32; ch++) {
                            NSNumber *number = [[NSNumber alloc] initWithInt:rates_lo.rates[slot_idx*32 + ch]];
                            [slot_rates addObject:number];
                            [number release];
                            number = nil;
                        }
                        slot_idx++;
                    }
                    [time_stamps addObject:str];
                }
                else {
                    [time_stamps addObject:@""];
                }
                [rates addObject:slot_rates]; //yes, we may add an empty array
                [slot_rates release]; slot_rates = nil;
            }
            [pollDict setObject:rates forKey:@"cmos_rt"];
            [pollDict setObject:time_stamps forKey:@"cmos_rt_time_stamp"];
            [pollDict setObject:[NSNumber numberWithInt:msk] forKey:@"cmos_rt_slot_mask"];
            [iso release]; iso = nil;
            [time_stamps release]; time_stamps = nil;
            [rates release]; rates = nil;
        
            if ([[ORGlobal sharedGlobal] runInProgress]) {
                unsigned long data[21 + 8*32];
                data[0] = cmosRateDataId | (21+8*32); 
                data[1] = [self crateNumber];
                data[2] = args_lo.slot_mask;
                memcpy(data+3, args_lo.channel_masks, 16*4);
                data[19] = 0;
                data[20] = results_lo.error_flags;
                unsigned int idx = 0;
                for (idx=0; idx < 8*32; idx++) {
                    *(float*)&data[21 + idx] = rates_lo.rates[idx];
                }
                //memcpy(data+21, rates_lo.rates, 8*32*4);
                
                [[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
                                                                object:[NSData dataWithBytes:data length:sizeof(long)*(21+8*32)]];

                if (num_slots > 8) {
                    data[2] = args_hi.slot_mask;
                    data[20] = results_hi.error_flags;
                    for (idx=0; idx < 8*32; idx++) {
                        *(float*)&data[21 + idx] = rates_hi.rates[idx];
                    }
                    //memcpy(data+21, rates_hi.rates, 8*32);
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
                                                                        object:[NSData dataWithBytes:data length:sizeof(long)*(21+8*32)]];
                }
            }
        }
        [self setCalcCMOSRatesFromCounts:YES];
        [self setHvCMOSReadsCounter:[self hvCMOSReadsCounter]+1];
    }
}

- (void) readPMTBaseCurrentsWithArgs:(read_pmt_base_currents_args_t*)aArgs currents:(read_pmt_base_currents_results_t*)result
{
	XL3_PayloadStruct payload;
	memset(payload.payload, 0, XL3_MAXPAYLOADSIZE_BYTES);
	payload.numberBytesinPayload = sizeof(read_pmt_base_currents_results_t);
    
	read_pmt_base_currents_args_t* data = (read_pmt_base_currents_args_t*) payload.payload;
    memcpy(data, aArgs, sizeof(read_pmt_base_currents_args_t));
    
    if ([xl3Link needToSwap]) {
        SwapLongBlock(data, sizeof(read_pmt_base_currents_args_t)/4);
    }
    
    @try {
        [[self xl3Link] sendCommand:READ_PMT_CURRENT_ID withPayload:&payload expectResponse:YES];
    }
    @catch (NSException *exception) {
        NSLog(@"%@ error sending readPMTBaseCurrentForSlot command.\n",[[self xl3Link] crateName]);
        @throw exception;
    }
    
    if ([xl3Link needToSwap]) {
        SwapLongBlock(data, 1);
    }
    
    memcpy(result, data, sizeof(read_pmt_base_currents_results_t));
}



- (void) readPMTBaseCurrentsForSlot:(unsigned short)aSlot withChannelMask:(unsigned long)aChannelMask
{
    read_pmt_base_currents_args_t args;
    read_pmt_base_currents_results_t results;

    args.slot_mask |= 0x1 << aSlot;
    args.channel_masks[aSlot] = aChannelMask;
    
    @try {
        [self readPMTBaseCurrentsWithArgs:&args currents:&results];
    }
    @catch (NSException *exception) {
        ;
    }

    if (results.error_flags != 0) {
        NSLog(@"%@ error in readPMTBaseCurrentsForSlot, error_flags: 0x%08x.\n",[[self xl3Link] crateName], results.error_flags);
    }
    else {
        NSMutableString* msg = [NSMutableString stringWithFormat:@"%@ PMT base currents for slot: %d\n", [[self xl3Link] crateName], aSlot];
        unsigned int i;
        for (i=0; i<32; i++) {
            if (aChannelMask & 0x1 << i) {
                [msg appendFormat:@"%d: %d\n", i, results.current_adc[aSlot*32 + i]];
            }
        }
        NSLog(msg);
    }
}

//used from polling loop and/or ORCA script
- (void) readPMTBaseCurrents
{
    read_pmt_base_currents_args_t args;
    read_pmt_base_currents_results_t results;
    unsigned char i;

	unsigned int msk = 0UL;
    NSEnumerator* e = [[[self guardian] objectEnumerator] retain];
    id anObj;
    while(anObj = [e nextObject]){
        if ([anObj class] == NSClassFromString(@"ORFec32Model")) {
            msk |= 1 << [anObj stationNumber];
        }
	}
    [e release]; e=nil;

    if (isPollingXl3 || isPollingForced) {
        msk &= pollPMTCurrentsMask;
    }
    
    args.slot_mask = msk;
    for (i=0; i<16; i++) {
        args.channel_masks[i] = 0xffffffff;
    }
    
    @try {
        [self readPMTBaseCurrentsWithArgs:&args currents:&results];
    }
    @catch (NSException *exception) {
        if (isPollingXl3) {
            NSLog(@"%@ Polling loop stopped becaused reading PMT based currents failed\n", [[self xl3Link] crateName]);
            [self setIsPollingXl3:NO];
        }
    }
    
    if (results.error_flags != 0) {
        NSLog(@"%@ error in readPMTBaseCurrentsForSlot, error_flags: 0x%08x.\n",[[self xl3Link] crateName], results.error_flags);
    }
    else if (!isPollingXl3 || isPollingVerbose) {    
        NSMutableString* msg = [NSMutableString stringWithFormat:@"%@ PMT base currents for crate:\n", [[self xl3Link] crateName]];
        unsigned char ch, sl;
        for (ch=0; ch<32; ch++) {
            [msg appendFormat:@"ch %2d: ", ch];
            for (sl=0; sl<16; sl++) {
                if ((msk >> sl) & 0x1) [msg appendFormat:@"%3d ", results.current_adc[sl*32 + ch] ^ (1UL << 7)];
                else [msg appendFormat:@"--- "];
            }
            [msg appendFormat:@"\n"];
        }
        NSLog(msg);
    }
    
    if (isPollingXl3) {
        NSDateFormatter* iso = [[NSDateFormatter alloc] init];
        [iso setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        iso.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        //iso.calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
        //iso.locale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease];
        NSString* str = [iso stringFromDate:[NSDate date]];
        NSMutableArray* currents = [[NSMutableArray alloc] initWithCapacity:16];
        NSMutableArray* slot_currents;
        unsigned char ch, sl;
        for (sl = 0; sl < 16; sl++) {
            slot_currents = [[NSMutableArray alloc] initWithCapacity:32];
            if ((msk >> sl) & 0x1) {
                for (ch = 0; ch < 32; ch++) {
                    NSNumber *number = [[NSNumber alloc] initWithInt:results.current_adc[sl*32 + ch] ^ (1U << 7)];
                    [slot_currents addObject:number];
                    [number release];
                    number = nil;
                }
            }
            [currents addObject:slot_currents]; //yes, we may add an empty array
            [slot_currents release]; slot_currents = nil;
        }
        
        [pollDict setObject:currents forKey:@"pmt_base_i"];
        [pollDict setObject:str forKey:@"pmt_base_i_time_stamp"];
        [pollDict setObject:[NSNumber numberWithInt:msk] forKey:@"pmt_base_i_slot_mask"];
        [iso release]; iso = nil;
        [currents release]; currents=nil;
    }
}

- (void) readHVStatus:(hv_readback_results_t*)status
{
	XL3_PayloadStruct payload;
	memset(payload.payload, 0, XL3_MAXPAYLOADSIZE_BYTES);
	payload.numberBytesinPayload = sizeof(hv_readback_results_t);
        
    @try {
        [[self xl3Link] sendCommand:HV_READBACK_ID withPayload:&payload expectResponse:YES];
        //[[self xl3Link] sendCommand:GET_HV_STATUS_ID withPayload:&payload expectResponse:YES];
    }
    @catch (NSException *exception) {
        NSLog(@"%@ error sending readHVStatus command.\n", [[self xl3Link] crateName]);
        @throw exception;
    }

    if ([xl3Link needToSwap]) {
        SwapLongBlock(payload.payload, sizeof(hv_readback_results_t)/4);
    }
    memcpy(status, payload.payload, sizeof(hv_readback_results_t));
}

//used from polling loop and/or ORCA script
- (void) readHVStatus
{
    hv_readback_results_t status;
    
    @try {
        [self readHVStatus:&status];
    }
    @catch (NSException *exception) {
        if (isPollingXl3) {
            NSLog(@"%@ Polling loop stopped because reading XL3 local voltages failed\n", [[self xl3Link] crateName]);
            [self setIsPollingXl3:NO];
        }
    }
    
    //unless (isPollingXl3 && !isPollingVerbose)
    if (!isPollingXl3 || isPollingVerbose) {    
        NSMutableString* msg = [NSMutableString stringWithFormat:@"%@ HV status: \n", [[self xl3Link] crateName]];
        [msg appendFormat:@"voltageA: %f\nvoltageB: %f\n", status.voltage_a * 300., status.voltage_b * 300.];
        [msg appendFormat:@"currentA: %f\ncurrentB: %f\n", status.current_a, status.current_b];
        NSLog(msg);
    }
    if (isPollingXl3) {
        NSDateFormatter* iso = [[NSDateFormatter alloc] init];
        [iso setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        iso.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        //iso.calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
        //iso.locale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease];
        NSString* str = [iso stringFromDate:[NSDate date]];
        NSDictionary* hvSupplyDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                     str, @"time_stamp",
                                     [NSNumber numberWithFloat:status.voltage_a * 300.], @"VLT_A",
                                     [NSNumber numberWithFloat:status.voltage_b * 300.], @"VLT_B",
                                     [NSNumber numberWithFloat:status.current_a * 10], @"CRR_A",
                                     [NSNumber numberWithFloat:status.current_b * 10], @"CRR_B",
                                     nil];
        [pollDict setObject:hvSupplyDict forKey:@"hv_supply"];
        [hvSupplyDict release];
        [iso release];
        iso = nil;
    }
    //save status
    
    [self setHvAVoltageReadValue:status.voltage_a * 300];
    [self setHvBVoltageReadValue:status.voltage_b * 300];
    [self setHvACurrentReadValue:status.current_a * 10];
    [self setHvACurrentReadValue:status.current_a * 10];
}

- (void) setHVRelays:(unsigned long long)aRelayMask error:(unsigned long*)aError
{
	XL3_PayloadStruct payload;
	memset(payload.payload, 0, XL3_MAXPAYLOADSIZE_BYTES);
	payload.numberBytesinPayload = 8;
    
    unsigned long* data = (unsigned long*)payload.payload;
    data[0] = aRelayMask & 0xffffffffUL; //mask1 bottom
    data[1] = aRelayMask >> 32;          //mask2 top

    NSLog(@"mask top: %x\n", data[1]);
    NSLog(@"mask bot: %x\n", data[0]);
    
    if ([xl3Link needToSwap]) {
        SwapLongBlock(data, 2);
    }

    @try {
        [[self xl3Link] sendCommand:SET_HV_RELAYS_ID withPayload:&payload expectResponse:YES];
    }
    @catch (NSException *exception) {
        NSLog(@"%@ error sending setHVRelays command.\n",[[self xl3Link] crateName]);
        @throw exception;
    }
    
    *aError = data[0];
    
    if ([xl3Link needToSwap]) {
        *aError = swapLong(*aError);
    }    
}

- (void) setHVRelays:(unsigned long long)aRelayMask
{
    unsigned long error;
    
    @try {
        [self setHVRelays:aRelayMask error:&error];
    }
    @catch (NSException *exception) {
        ;
    }
    
    if (error != 0) {
        NSLog(@"%@ error in setHVRelays relays were NOT set.\n",[[self xl3Link] crateName]);
    }
    else{
        NSLog(@"%@ HV relays set.\n",[[self xl3Link] crateName]);
    }
}

- (void) closeHVRelays
{
    unsigned long error;
    
    @try {
        [self setHVRelays:relayMask error:&error];
    }
    @catch (NSException *exception) {
        [self setRelayStatus:@"status: UNKNOWN"];
    }
    
    if (error != 0) {
        NSLog(@"%@ error in setHVRelays relays were NOT set.\n",[[self xl3Link] crateName]);
        [self setRelayStatus:@"status: UNKNOWN"];
    }
    else{
        NSLog(@"%@ HV relays closed.\n",[[self xl3Link] crateName]);
        [self setRelayStatus:@"relays CLOSED"];
    }
}

- (void) openHVRelays
{
    unsigned long error;
    
    @try {
        [self setHVRelays:0ULL error:&error];
    }
    @catch (NSException *exception) {
        [self setRelayStatus:@"status: UNKNOWN"];
    }
    
    if (error != 0) {
        NSLog(@"%@ error in openHVRelays relays were NOT set.\n",[[self xl3Link] crateName]);
        [self setRelayStatus:@"status: UNKNOWN"];
    }
    else{
        NSLog(@"%@ HV relays open.\n",[[self xl3Link] crateName]);
        [self setRelayStatus:@"relays OPENED"];
    }
}

- (void) setHVSwitchOnForA:(BOOL)aIsOn forB:(BOOL)bIsOn
{
	unsigned long xl3Address = XL3_SEL | [self getRegisterAddress:kXl3HvCsReg] | WRITE_REG;
	unsigned long aValue = 0UL;

    if (aIsOn) aValue |= 1UL;
    if (bIsOn) aValue |= 0x10000UL;
    
	@try {
		[xl3Link sendFECCommand:0UL toAddress:xl3Address withData:&aValue];
	}
	@catch (NSException* e) {
		NSLog(@"%@ error writing XL3 HV CS register\n",[[self xl3Link] crateName]);
        @throw e;
	}
}

- (void) readHVSwitchOnForA:(BOOL*)aIsOn forB:(BOOL*)bIsOn
{
	unsigned long xl3Address = XL3_SEL | [self getRegisterAddress:kXl3HvCsReg] | READ_REG;
	unsigned long aValue = 0UL;
    
	@try {
		[xl3Link sendFECCommand:0UL toAddress:xl3Address withData:&aValue];
	}
	@catch (NSException* e) {
		NSLog(@"%@ error reading XL3 HV CS register\n",[[self xl3Link] crateName]);
        @throw e;
	}
    
    *aIsOn = aValue & 0x1;
    *bIsOn = (aValue >> 16) & 0x1;
}

- (void) readHVSwitchOn
{
    BOOL switchAIsOn;
    BOOL switchBIsOn;
    
    @try {
        [self readHVSwitchOnForA:&switchAIsOn forB:&switchBIsOn];
    }
    @catch (NSException *exception) {
        NSLog(@"%@ error in readHVSwitchOn\n", [[self xl3Link] crateName]);
        return;
    }

    NSLog(@"%@ switch A is %@, switch B is %@.\n",[[self xl3Link] crateName], switchAIsOn?@"ON":@"OFF", switchBIsOn?@"ON":@"OFF");
}

- (void) setHVSwitch:(BOOL)aOn forPowerSupply:(unsigned char)sup
{
    BOOL xl3SwitchA, xl3SwitchB;

    @try {
        [self readHVSwitchOnForA:&xl3SwitchA forB:&xl3SwitchB];
    }
    @catch (NSException *exception) {
        NSLog(@"%@ error in readHVSwitch\n", [[self xl3Link] crateName]);
        return;
    }
    [self setHvASwitch:xl3SwitchA];
    [self setHvBSwitch:xl3SwitchB];
    
/*    
    if (xl3SwitchA != [self hvASwitch]) {
        NSLog(@"%@ HV switch A is reported %@ by XL3 and expected to be %@ by ORCA.\n",[[self xl3Link] crateName], xl3SwitchA?@"ON":@"OFF", hvASwitch?@"ON":@"OFF");
        [self setHvASwitch:xl3SwitchA];
    }

    if (xl3SwitchB != [self hvBSwitch]) {
        NSLog(@"%@ HV switch B is reported %@ by XL3 and expected to be %@ by ORCA.\n",[[self xl3Link] crateName], xl3SwitchB?@"ON":@"OFF", hvBSwitch?@"ON":@"OFF");
        [self setHvBSwitch:xl3SwitchB];
    }
*/
    BOOL interlockIsGood;
    
    @try {
        [self readHVInterlockGood:&interlockIsGood];
    }
    @catch (NSException *exception) {
        NSLog(@"%@ error in readHVInterlock\n",[[self xl3Link] crateName]);
        return;
    }

    if (!interlockIsGood) {
        NSLog(@"%@ HV interlock BAD\n",[[self xl3Link] crateName]);
        if (aOn) {
            NSLog(@"%@ NOT turning ON the HV power supply.\n",[[self xl3Link] crateName]);
            return;
        }
        else {
            NSLog(@"%@ continuing to turn OFF the HV power supply.\n",[[self xl3Link] crateName]);            
        }
    }

    @try {
        if (sup == 0 && ((!hvASwitch && aOn) || (hvASwitch && !aOn))) { //changing A from OFF to ON or ON to OFF
            [self setHVDacA:0 dacB:hvBVoltageDACSetValue];
        }
        else if (sup == 1 && ((!hvBSwitch && aOn) || (!hvBSwitch && aOn))) {
            [self setHVDacA:hvBVoltageDACSetValue dacB:0];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"%@ error in setting HC DAC value to 0.",[[self xl3Link] crateName]);
        return;
    }

    @try {
        if (sup == 0) { //A
            [self setHVSwitchOnForA:aOn forB:hvBSwitch];
        }
        else {
            [self setHVSwitchOnForA:hvASwitch forB:aOn];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"%@ error in setting the HV switch.",[[self xl3Link] crateName]);
        return;
    }

    //check the hv thread is running
    if (!hvASwitch && !hvBSwitch && aOn) {    
        if (hvThread) {
            if ([hvThread isFinished]) {
                [hvThread release];
                hvThread = nil;
            }
        }
        [self setHvANextStepValue:0];
        [self setHvBNextStepValue:0];
        if (!hvThread) {
            hvThread = [[NSThread alloc] initWithTarget:self selector:@selector(_hvXl3) object:nil];
            [hvThread start];
        }
    }

    //let's believe it worked
    if (sup == 0) { //A
        [self setHvASwitch:aOn];
    }
    else {
        [self setHvBSwitch:aOn];
    }
    
    usleep(10000);
    @try {
        [self readHVSwitchOnForA:&xl3SwitchA forB:&xl3SwitchB];
    }
    @catch (NSException *exception) {
        NSLog(@"%@ error in readHVSwitch\n", [[self xl3Link] crateName]);
        return;
    }
    
    [self setHvASwitch:xl3SwitchA];
    [self setHvBSwitch:xl3SwitchB];
    
    [self readHVStatus];
    
    //reading the swich right after the change is not reliable
    /*
    if (sup == 0 && xl3SwitchA != aOn) {
        NSLog(@"%@ HV switch A is reported %@ by XL3 and expected to be %@ by ORCA.\n",[[self xl3Link] crateName], xl3SwitchA?@"ON":@"OFF", aOn?@"ON":@"OFF");
        [self setHvASwitch:xl3SwitchA];
    }
    else if (sup == 1 && xl3SwitchA != [self hvASwitch]) {
        NSLog(@"%@ HV switch A is reported %@ by XL3 and expected to be %@ by ORCA.\n",[[self xl3Link] crateName], xl3SwitchA?@"ON":@"OFF", aOn?@"ON":@"OFF");
        [self setHvASwitch:xl3SwitchA];
    }
    else if (sup == 1 && xl3SwitchB != aOn) {
        NSLog(@"%@ HV switch B is reported %@ by XL3 and expected to be %@ by ORCA.\n",[[self xl3Link] crateName], xl3SwitchB?@"ON":@"OFF", aOn?@"ON":@"OFF");
        [self setHvBSwitch:xl3SwitchB];
    }
    else if (sup == 0 && xl3SwitchB != [self hvBSwitch]) {
        NSLog(@"%@ HV switch B is reported %@ by XL3 and expected to be %@ by ORCA.\n",[[self xl3Link] crateName], xl3SwitchB?@"ON":@"OFF", aOn?@"ON":@"OFF");
        [self setHvBSwitch:xl3SwitchB];
    }
    */
}


- (void) readHVInterlockGood:(BOOL*)isGood
{
	unsigned long xl3Address = XL3_SEL | [self getRegisterAddress:kXl3HvCsReg] | READ_REG;
	unsigned long aValue = 0UL;
    
	@try {
		[xl3Link sendFECCommand:0UL toAddress:xl3Address withData:&aValue];
	}
	@catch (NSException* e) {
		NSLog(@"%@ error reading XL3 HV CS register\n",[[self xl3Link] crateName]);
        @throw e;
	}
    
    *isGood = aValue & 0x4;
}

- (void) readHVInterlock
{
    BOOL isGood;
    
    @try {
        [self readHVInterlockGood:&isGood];
    }
    @catch (NSException *exception) {
        NSLog(@"%@ error in readHVInterlock\n",[[self xl3Link] crateName]);
        return;
    }
    
    NSLog(@"%@ HV interlock is %@\n",[[self xl3Link] crateName], isGood?@"GOOD":@"BAD");
}

- (void) setHVDacA:(unsigned short)aDac dacB:(unsigned short)bDac
{
    //todo a dedicated HV lock
    @synchronized (self) {
        unsigned long xl3Address = XL3_SEL | [self getRegisterAddress:kXl3HvSetPointReg] | WRITE_REG;
        unsigned long aValue = 0UL;
        
        aValue |= aDac & 0xFFFUL;
        aValue |= (bDac & 0xFFFUL) << 16;
        
        @try {
            [xl3Link sendFECCommand:0UL toAddress:xl3Address withData:&aValue];
        }
        @catch (NSException* e) {
            NSLog(@"%@ error writing XL3 HV CS register\n",[[self xl3Link] crateName]);
        }
    }
}

#pragma mark •••tests
- (void) readVMONForSlot:(unsigned short)aSlot voltages:(vmon_results_t*)aVoltages
{
    XL3_PayloadStruct payload;
    memset(payload.payload, 0, XL3_MAXPAYLOADSIZE_BYTES);
    payload.numberBytesinPayload = sizeof(vmon_results_t);

    vmon_args_t* data = (vmon_args_t*) payload.payload;
    data->slot_num = aSlot;

    if ([xl3Link needToSwap]) {
        SwapLongBlock(data, sizeof(vmon_args_t)/4);
    }

    @try {
        [[self xl3Link] sendCommand:VMON_ID withPayload:&payload expectResponse:YES];
    }
    @catch (NSException *exception) {
        NSLog(@"%@ error sending VMON_ID command.\n",[[self xl3Link] crateName]);
        @throw exception;
    }

    if ([xl3Link needToSwap]) {
        SwapLongBlock(data, sizeof(vmon_results_t)/4);
    }

    memcpy(aVoltages, data, sizeof(vmon_results_t));
}

- (void) readVMONForSlot:(unsigned short)aSlot
{
    vmon_results_t result;
        
    @try {
        [self readVMONForSlot:aSlot voltages:&result];
    }
    @catch (NSException *exception) {
        if (isPollingXl3) {
            NSLog(@"Polling loop stopped because reading FEC local voltages failed\n");
            [self setIsPollingXl3:NO];
        }
    }
    if (!isPollingXl3 || isPollingVerbose) {
        //it doesn't set error_flags
        NSMutableString* msg = [NSMutableString stringWithFormat:@"%@ voltages for slot: %d\n", [[self xl3Link] crateName], aSlot];
        [msg appendFormat:@" -24V Sup: %f V\n", result.voltages[0]];
        [msg appendFormat:@" -15V Sup: %f V\n", result.voltages[1]];
        [msg appendFormat:@"  VEE Sup: %f V\n", result.voltages[2]];
        [msg appendFormat:@"-3.3V Sup: %f V\n", result.voltages[3]];
        [msg appendFormat:@"-2.0V Sup: %f V\n", result.voltages[4]];
        [msg appendFormat:@" 3.3V Sup: %f V\n", result.voltages[5]];
        [msg appendFormat:@" 4.0V Sup: %f V\n", result.voltages[6]];
        [msg appendFormat:@"  VCC Sup: %f V\n", result.voltages[7]];
        [msg appendFormat:@" 6.5V Sup: %f V\n", result.voltages[8]];
        [msg appendFormat:@" 8.0V Sup: %f V\n", result.voltages[9]];
        [msg appendFormat:@"  15V Sup: %f V\n", result.voltages[10]];
        [msg appendFormat:@"  24V Sup: %f V\n", result.voltages[11]];
        [msg appendFormat:@"-2.0V Ref: %f V\n", result.voltages[12]];
        [msg appendFormat:@"-1.0V Ref: %f V\n", result.voltages[13]];
        [msg appendFormat:@" 0.8V Ref: %f V\n", result.voltages[14]];
        [msg appendFormat:@" 1.0V Ref: %f V\n", result.voltages[15]];
        [msg appendFormat:@" 4.0V Ref: %f V\n", result.voltages[16]];
        [msg appendFormat:@" 5.0V Ref: %f V\n", result.voltages[17]];
        [msg appendFormat:@"    Temp.: %f degC\n", result.voltages[18]];
        [msg appendFormat:@"  Cal DAC: %f V\n", result.voltages[19]];
        [msg appendFormat:@"  HV Curr: %f mA\n", result.voltages[20]];

        NSLog(msg);
    }
    if (isPollingXl3) {
        NSDateFormatter* iso = [[NSDateFormatter alloc] init];
        [iso setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        iso.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        //iso.calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
        //iso.locale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease];
        NSString* str = [iso stringFromDate:[NSDate date]];
        NSMutableArray* slot_voltages = [[[NSMutableArray alloc] initWithCapacity:21] autorelease];
        
        unsigned char vlt;
        for (vlt = 0; vlt < 21; vlt++) {
            NSNumber *number = [[NSNumber alloc] initWithFloat:result.voltages[vlt]];
            [slot_voltages addObject:number];
            [number release];
        }
        
        NSMutableArray* vlt_array; //16 slots * 32 floats
        if ([pollDict objectForKey:@"fec_vlt"]) vlt_array = [[[pollDict objectForKey:@"fec_vlt"] mutableCopy] autorelease];
        else {
            vlt_array = [NSMutableArray arrayWithCapacity:16];
            unsigned char sl;
            for (sl=0; sl<16; sl++) {
                [vlt_array addObject:[NSArray array]];
            }
        }
        NSMutableArray* vlt_time_stamp; //16 slot strings
        if ([pollDict objectForKey:@"fec_vlt_time_stamp"]) vlt_time_stamp = [[[pollDict objectForKey:@"fec_vlt_time_stamp"] mutableCopy] autorelease];
        else {
            vlt_time_stamp = [NSMutableArray arrayWithCapacity:16];
            unsigned char sl;
            for (sl=0; sl<16; sl++) {
                [vlt_time_stamp addObject:@""];
            }
        }
        NSArray* fec_vlts_tags = [NSArray arrayWithObjects:@"VM24SUP", @"VM15SUP", @"VEE", @"VM3.3SUP",\
                                  @"VM2.0SUP", @"VP3.3SUP", @"VP4.0SUP", @"VCC", @"VP6.5SUP", @"VP8.0SUP",
                                  @"VP15SUP", @"VP24SUP", @"VM2.0REF", @"VM1.0REF", @"VP0.8REF", @"VP1.0REF",
                                  @"VP4.0REF", @"VP5.0REF", @"TMP", @"CALDAC", @"HVCRR", nil];

        [vlt_array replaceObjectAtIndex:aSlot withObject:slot_voltages];
        [vlt_time_stamp replaceObjectAtIndex:aSlot withObject:str];
        [pollDict setObject:vlt_array forKey:@"fec_vlt"];
        [pollDict setObject:vlt_time_stamp forKey:@"fec_vlt_time_stamp"];
        [pollDict setObject:fec_vlts_tags forKey:@"fec_vlt_tag"];
        [iso release];
        iso = nil;
    }
}

//used from polling loop and/or ORCA script
- (void) readVMONWithMask:(unsigned short)aSlotMask
{
    unsigned int msk = 0UL;
    
    NSEnumerator* e = [[self guardian] objectEnumerator];
    id anObj;
    while(anObj = [e nextObject]){
        if ([anObj class] == NSClassFromString(@"ORFec32Model")) {
            msk |= 1 << [anObj stationNumber];
        }
    }

    if (isPollingXl3 || isPollingForced) {
        msk &= aSlotMask;
    }

    unsigned char slot;
    for (slot=0; slot<16; slot++) {
        if ((msk >> slot) & 0x1) {
            [self readVMONForSlot:slot];
            if (pollThread && [pollThread isCancelled]) break;
        }
    }
}

- (void) readVMONXL3:(vmon_xl3_results_t*)aVoltages
{
    XL3_PayloadStruct payload;
    memset(payload.payload, 0, XL3_MAXPAYLOADSIZE_BYTES);
    payload.numberBytesinPayload = sizeof(vmon_xl3_results_t);
    vmon_xl3_results_t* data = (vmon_xl3_results_t*) payload.payload;
        
    @try {
        [[self xl3Link] sendCommand:VMON_XL3_ID withPayload:&payload expectResponse:YES];
    }
    @catch (NSException *exception) {
        NSLog(@"%@ error sending VMON_XL3_ID command.\n",[[self xl3Link] crateName]);
        @throw exception;
    }
    
    if ([xl3Link needToSwap]) {
        SwapLongBlock(data, sizeof(vmon_xl3_results_t)/4);
    }
    
    memcpy(aVoltages, data, sizeof(vmon_xl3_results_t));
}

//used from polling loop and/or ORCA script
- (void) readVMONXL3
{
    vmon_xl3_results_t result;
    
    @try {
        [self readVMONXL3:&result];
    }
    @catch (NSException *exception) {
        if (isPollingXl3) {
            NSLog(@"Polling loop stopped becaused reading XL3 local voltages failed\n");
            [self setIsPollingXl3:NO];
        }
    }
    
    //unless (isPollingXl3 && !isPollingVerbose)
    if (!isPollingXl3 || isPollingVerbose) {
        //it doesn't set error_flags
        NSMutableString* msg = [NSMutableString stringWithFormat:@"%@ local voltages:\n", [[self xl3Link] crateName]];
        [msg appendFormat:@"VCC: %f V\n", result.voltages[0]];
        [msg appendFormat:@"VEE: %f V\n", result.voltages[1]];
        //[msg appendFormat:@"VP8: %f V\n", result.voltages[2]];
        [msg appendFormat:@"VP24: %f V\n", result.voltages[3]];
        [msg appendFormat:@"VM24: %f V\n", result.voltages[4]];
        [msg appendFormat:@"TMP0: %f degC\n", result.voltages[5]];
        [msg appendFormat:@"TMP1: %f degC\n", result.voltages[6]];
        [msg appendFormat:@"TMP2: %f degC\n", result.voltages[7]];
        NSLog(msg);
    }    
    
    if (isPollingXl3) {
        NSDateFormatter* iso = [[NSDateFormatter alloc] init];
        [iso setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        iso.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        //iso.calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
        //iso.locale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease];
        NSString* str = [iso stringFromDate:[NSDate date]];
        NSMutableArray* xl3_vlts = [[NSMutableArray alloc] initWithCapacity:7];
        NSArray* xl3_vlts_tags = [[NSArray alloc] initWithObjects:@"VCC", @"VEE", @"VP24", @"VM24", @"TMP0", @"TMP1", @"TMP2", nil];
        unsigned char vlt;
        for (vlt = 0; vlt < 8; vlt++) {
            if (vlt==2) continue;
            NSNumber *number = [[NSNumber alloc] initWithFloat:result.voltages[vlt]];
            [xl3_vlts addObject:number];
            [number release];
        }
        [pollDict setObject:xl3_vlts forKey:@"xl3_vlt"];
        [pollDict setObject:xl3_vlts_tags forKey:@"xl3_vlt_tag"];
        [pollDict setObject:str forKey:@"xl3_vlt_time_stamp"];
        [iso release];
        [xl3_vlts release];
        [xl3_vlts_tags release];
        iso = nil;
    }
}

- (void) pollXl3:(BOOL)forceFlag
{
    if (pollThread) {
        if ([pollThread isFinished]) {
            [pollThread release];
            pollThread = nil;
        }
        else return;
    }
    isPollingForced = forceFlag;
    //[NSThread detachNewThreadSelector:@selector(_pollXl3) toTarget:self withObject:nil];
    pollThread = [[NSThread alloc] initWithTarget:self selector:@selector(_pollXl3) object:nil];
    [pollThread start];
}


//TODO: pass erroflags
- (void) loadSingleDacForSlot:(unsigned short)aSlot dacNum:(unsigned short)aDacNum dacVal:(unsigned char)aDacVal
{
 	XL3_PayloadStruct payload;
	memset(payload.payload, 0, XL3_MAXPAYLOADSIZE_BYTES);
	payload.numberBytesinPayload = sizeof(loadsdac_args_t);
    
    loadsdac_args_t* data = (loadsdac_args_t*)payload.payload;
    loadsdac_results_t* result = (loadsdac_results_t*)payload.payload;
    data->slot_num = aSlot;
    data->dac_num = aDacNum;
    data->dac_value = aDacVal;
    
    if ([xl3Link needToSwap]) {
        SwapLongBlock(data, 3);
    }
    
    @try {
        [[self xl3Link] sendCommand:LOADSDAC_ID withPayload:&payload expectResponse:YES];
    }
    @catch (NSException *exception) {
        NSLog(@"%@ error sending loadSingleDac command.\n",[[self xl3Link] crateName]);
        @throw exception;
    }
    
    if ([xl3Link needToSwap]) {
        result->error_flags = swapLong(result->error_flags);
    }
    
    if (result->error_flags) {
        NSLog(@"%@ loadSingleDac failed with error_flags: 0x%x.\n",[[self xl3Link] crateName], result->error_flags);
    }
}

- (void) setVthrDACsForSlot:(unsigned short)aSlot withChannelMask:(unsigned long)aChannelMask dac:(unsigned char)aDac
{
    //setVthr loading single DAC at the time. works fine. takes 0.5 sec per DAC.
/*
    unsigned short i;
    for (i=0; i<32; i++) {
        if (aChannelMask & (1<<i)) {
            @try {
                [self loadSingleDacForSlot:aSlot dacNum:25+i dacVal:aDac]; 
            }
            @catch (NSException *exception) {
                NSLog(@"Error in setVthrDACsFor slot: %d in channel: %d\n", aSlot, i);
                return;
            }
        }
    }
    NSLog(@"Set VthrDACs for slot: %d\n", aSlot);
*/

 	XL3_PayloadStruct payload;
	memset(payload.payload, 0, XL3_MAXPAYLOADSIZE_BYTES);
	payload.numberBytesinPayload = sizeof(multi_loadsdac_args_t);
    
    multi_loadsdac_args_t* data = (multi_loadsdac_args_t*)payload.payload;
    multi_loadsdac_results_t* result = (multi_loadsdac_results_t*)payload.payload;

    unsigned short i;
    for (i=0; i<32; i++) {
        if (aChannelMask & (1<<i)) {
            data->dacs[data->num_dacs].slot_num = aSlot;
            data->dacs[data->num_dacs].dac_num = 25+i;
            data->dacs[data->num_dacs].dac_value = aDac;
            data->num_dacs++;
        }
    }

    if ([xl3Link needToSwap]) {
        SwapLongBlock(data, sizeof(multi_loadsdac_args_t)/4);
    }
    
    @try {
        [[self xl3Link] sendCommand:MULTI_LOADSDAC_ID withPayload:&payload expectResponse:YES];
    }
    @catch (NSException *exception) {
        NSLog(@"Error in setVthrDACsFor slot: %d\n", aSlot);
        return;
    }
        
    if ([xl3Link needToSwap]) {
        result->error_flags = swapLong(result->error_flags);
    }
    
    if (result->error_flags) {
        NSLog(@"set Vthr DACs for slot %d failed with error_flag:0x%x\n", aSlot, result->error_flags);
    }
    else {
        NSLog(@"set Vthr DACs for slot %d\n", aSlot);
    }
}

@end


@implementation ORXL3Model (private)
- (void) doBasicOp
{
	@try {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doBasicOp) object:nil];
		if(doReadOp){
			NSLog(@"%@ %@: 0x%08x\n",[[self xl3Link] crateName], reg[selectedRegister].regName, [self readXL3Register:selectedRegister]);
		}
		else {
			[self writeXL3Register:selectedRegister value:writeValue];
			NSLog(@"%@ Wrote 0x%08x to %@\n",[[self xl3Link] crateName], writeValue, reg[selectedRegister].regName);
		}

		if(++workingCount < repeatOpCount){
			if (autoIncrement) {
				selectedRegister++;
				if (selectedRegister == kXl3NumRegisters) selectedRegister = 0;
				[self setSelectedRegister:selectedRegister];
			}
			[self performSelector:@selector(doBasicOp) withObject:nil afterDelay:repeatDelay/1000.];
		}
		else {
			[self setBasicOpsRunning:NO];
		}
	}
	@catch(NSException* localException) {
		[self setBasicOpsRunning:NO];
		NSLog(@"%@ basic op exception: %@\n",[[self xl3Link] crateName],localException);
		[localException raise];
	}	
}

//polling thread
- (void) _pollXl3
{
    NSAutoreleasePool* pollPool = [[NSAutoreleasePool alloc] init];
    NSDate* pollStartDate = nil;
    NSDate* nextStartDate = nil;
    NSTimeInterval startTime;
    BOOL isTimeToQuit = NO;

    while (!isTimeToQuit) {
        if (pollStartDate) {
            [pollStartDate release];
            pollStartDate = nil;
        }
        pollStartDate = [[NSDate alloc] init];
        if (isPollingCMOSRates && (![[NSThread currentThread] isCancelled] || isPollingForced)) {
            [self readCMOSRate]; //[msec]
        }
        
        if (isPollingPMTCurrents && (![[NSThread currentThread] isCancelled] || isPollingForced)) {
            [self readPMTBaseCurrents];
        }
        
        if (isPollingFECVoltages && (![[NSThread currentThread] isCancelled] || isPollingForced)) {
            [self readVMONWithMask:[self pollFECVoltagesMask]];
        }
        
        if (isPollingXl3Voltages && (![[NSThread currentThread] isCancelled] || isPollingForced)) {
            [self readVMONXL3];
        }
        
        if (isPollingHVSupply && (![[NSThread currentThread] isCancelled] || isPollingForced)) {
            [self readHVStatus];
        }

        if (isPollingForced || [[NSThread currentThread] isCancelled]) isTimeToQuit = YES;

        startTime = pollXl3Time + [pollStartDate timeIntervalSinceNow];
        if (startTime < 0.1) startTime = -0.1;
        nextStartDate = [[NSDate alloc] initWithTimeIntervalSinceNow:startTime];
        while (!isTimeToQuit && [nextStartDate timeIntervalSinceNow] > 0.) {
            usleep(100000);
            if ([[NSThread currentThread] isCancelled]) isTimeToQuit = YES;
            if (![self isPollingXl3]) isTimeToQuit = YES;
        }
        [nextStartDate release];
        nextStartDate = nil;
        [self setIsPollingForced:NO];
    }
    if (pollStartDate) {
        [pollStartDate release];
        pollStartDate = nil;
    }

    [pollPool release];
}

- (void) _hvXl3
{
    NSAutoreleasePool* hvPool = [[NSAutoreleasePool alloc] init];
    BOOL isTimeToQuit = NO;

    unsigned int msk = 0UL;
    NSArray* fecs = [guardian collectObjectsOfClass:NSClassFromString(@"ORFec32Model")];
    for (id key in fecs) {
        msk |= 1 << [key stationNumber];
    }
    
    unsigned long channelsAboveLimit;
    unsigned long lastCMOSCountProcessed;
    unsigned long cmosLimit;
    
    while (!isTimeToQuit) {
        if ([self hvANextStepValue] != [self hvAVoltageDACSetValue]) {
            unsigned long aValueToSet = [self hvANextStepValue];
            
            if ([self hvANextStepValue] > [self hvAVoltageDACSetValue] + 10 / 3000. * 4096) {
                aValueToSet = [self hvAVoltageDACSetValue] + 10 / 3000. * 4096;
            }
            if ([self hvANextStepValue] < [self hvAVoltageDACSetValue] - 10 / 3000. * 4096) {
                aValueToSet = [self hvAVoltageDACSetValue] - 10 / 3000. * 4096;
            }
            if (aValueToSet > [self hvAVoltageTargetValue]) {
                aValueToSet = [self hvAVoltageTargetValue];
            }
            if (aValueToSet > [self hvAVoltageDACSetValue] + 10 / 3000. * 4096) {
                NSLog(@"%@ HV voltage calculation screwed. stopping\n", [[self xl3Link] crateName]);
            }
            @try {
                [self setHVDacA:aValueToSet dacB:[self hvBVoltageDACSetValue]];
                //assume it worked
                [self setHvAVoltageDACSetValue:aValueToSet];
            }
            @catch (NSException *exception) {
                NSLog(@"%@ HV failed to set HV!\n", [[self xl3Link] crateName]);
            }
            [self setCalcCMOSRatesFromCounts:NO];
            [self setHvCMOSReadsCounter:0];
            lastCMOSCountProcessed = 0;
        }
        
        while ([self hvCMOSReadsCounter] < 3) { //or panic flag
            usleep(100000);
        }
        
        //read back voltage
        if (fabs([self hvAVoltageReadValue] / 3000. * 4096 - [self hvAVoltageDACSetValue]) > 20) {
            NSLog(@"%@ read value differs from the set one. stopping!", [[self xl3Link] crateName]);
            usleep(100000);
            [self setHvANextStepValue:[self hvAVoltageDACSetValue]];
        }
        
        //if set reset CMOS rates and wait for first two count measurements unless panicFlag
        channelsAboveLimit = 0;
        cmosLimit = [self hvACMOSRateLimit];
        for (id key in fecs) {
            channelsAboveLimit += [key channelsWithCMOSRateHigherThan:[self hvACMOSRateLimit]];
        }
        
        if (channelsAboveLimit > [self hvACMOSRateIgnore]) {
            NSLog(@"%@ too many channels with high CMOS rate. stopping!", [[self xl3Link] crateName]);
            usleep(100000);
            [self setHvANextStepValue:[self hvAVoltageDACSetValue]];
        }

        if (!hvASwitch && !hvBSwitch) isTimeToQuit = YES;
        usleep(100000);
    }
    [hvPool release];
}
@end
