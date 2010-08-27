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
#import "XL3_Cmds.h"
#import "XL3_Link.h"
#import "ORXL3Model.h"
#import "ORSNOCrateModel.h"
#import "ORSNOCard.h"
#import "ORSNOConstants.h"

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

NSString* ORXL3ModelSelectedRegisterChanged =		@"ORXL3ModelSelectedRegisterChanged";
NSString* ORXL3ModelRepeatCountChanged =		@"ORXL3ModelRepeatCountChanged";
NSString* ORXL3ModelRepeatDelayChanged =		@"ORXL3ModelRepeatDelayChanged";
NSString* ORXL3ModelAutoIncrementChanged =		@"ORXL3ModelAutoIncrementChanged";
NSString* ORXL3ModelBasicOpsRunningChanged =		@"ORXL3ModelBasicOpsRunningChanged";
NSString* ORXL3ModelWriteValueChanged =			@"ORXL3ModelWriteValueChanged";
NSString* ORXL3ModelDeselectCompositeRunningChanged =	@"ORXL3ModelDeselectCompositeRunningChanged";
NSString* ORXL3ModelXl3ModeChanged =			@"ORXL3ModelXl3ModeChanged";
NSString* ORXL3ModelSlotMaskChanged =			@"ORXL3ModelSlotMaskChanged";
NSString* ORXL3ModelXl3ModeRunningChanged =		@"ORXL3ModelXl3ModeRunningChanged";
NSString* ORXL3ModelXl3RWAddressValueChanged =		@"ORXL3ModelXl3RWAddressValueChanged";
NSString* ORXL3ModelXl3RWDataValueChanged =		@"ORXL3ModelXl3RWDataValueChanged";
NSString* ORXL3ModelXl3RWRunningChanged =		@"ORXL3ModelXl3RWRunningChanged";


@interface ORXL3Model (private)
- (void) doBasicOp;
@end

@implementation ORXL3Model

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
	[super dealloc];
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
		[xl3Link setCrateName:[NSString stringWithFormat:@"XL3 crate %d", [self uniqueIdNumber] + 1]];
		[xl3Link setIPNumber:[guardian iPAddress]];
		[xl3Link setPortNumber: PORT];	
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

- (BOOL) deselectCompositeRunning
{
	return deselectCompositeRunning;
}

- (void) setDeselectCompositeRunning:(BOOL)aDeselectCompositeRunning
{
	deselectCompositeRunning = aDeselectCompositeRunning;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelDeselectCompositeRunningChanged object:self];
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

- (BOOL) xl3RWRunning
{
	return xl3RWRunning;
}

- (void) setXl3RWRunning:(BOOL)anXl3RWRunning
{
	[[[self undoManager] prepareWithInvocationTarget:self] setXl3RWRunning:xl3RWRunning];
	xl3RWRunning = anXl3RWRunning;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelXl3RWRunningChanged object:self];
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
    return [NSString stringWithFormat:@"card %d",[self stationNumber]];
}

- (NSComparisonResult)	slotCompare:(id)otherCard
{
    return [self stationNumber] - [otherCard stationNumber];
}

- (void) setCrateNumber:(int)crateNumber
{
	[[self guardian] setCrateNumber:crateNumber];
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

	if (xl3Mode == 0) [self setXl3Mode: 1];

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

#define swapLong(x) (((uint32_t)(x) << 24) | (((uint32_t)(x) & 0x0000FF00) <<  8) | (((uint32_t)(x) & 0x00FF0000) >>  8) | ((uint32_t)(x) >> 24))
#define swapShort(x) (((uint16_t)(x) <<  8) | ((uint16_t)(x)>>  8))

- (void) deselectComposite
{
	[self setDeselectCompositeRunning:YES];
	NSLog(@"Deselect FECs...\n");
	@try {
		[[self xl3Link] sendCommand:DESELECT_FECS_ID expectResponse:YES];
		NSLog(@"ok\n");
	}
	@catch (NSException * e) {
		NSLog(@"Deselect FECs failed; error: %@ reason: %@\n", [e name], [e reason]);
	}
	[self setDeselectCompositeRunning:NO];
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
	NSLog(@"Set XL3 mode: %d slot mask: 0x%04x ...\n", [self xl3Mode], [self slotMask]);
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
	NSLog(@"XL3_rw to address: 0x%08x with data: 0x%08x\n", [self xl3RWAddressValue], aValue);
	[self setXl3RWRunning: YES];
	
	@try {
		[xl3Link sendFECCommand:0UL toAddress:[self xl3RWAddressValue] withData:&aValue];
		NSLog(@"XL3_rw returned data: 0x%08x\n", aValue);
	}
	@catch (NSException* e) {
		NSLog(@"XL3_rw failed; error: %@ reason: %@\n", [e name], [e reason]);
	}
		
	[self setXl3RWRunning: NO];
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

@end


@implementation ORXL3Model (private)
- (void) doBasicOp
{
	@try {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doBasicOp) object:nil];
		if(doReadOp){
			NSLog(@"%@: 0x%08x\n", reg[selectedRegister].regName, [self readXL3Register:selectedRegister]);
		}
		else {
			[self writeXL3Register:selectedRegister value:writeValue];
			NSLog(@"Wrote 0x%08x to %@\n", writeValue, reg[selectedRegister].regName);
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
		NSLog(@"XL3 basic op exception: %@\n",localException);
		[localException raise];
	}
	
}

@end
