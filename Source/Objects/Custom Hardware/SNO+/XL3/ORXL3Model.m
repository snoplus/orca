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

NSString* ORXL3ModelSelectedRegisterChanged =		@"ORXL3ModelSelectedRegisterChanged";
NSString* ORXL3ModelRepeatCountChanged =		@"ORXL3ModelRepeatCountChanged";
NSString* ORXL3ModelRepeatDelayChanged =		@"ORXL3ModelRepeatDelayChanged";
NSString* ORXL3ModelAutoIncrementChanged =		@"ORXL3ModelAutoIncrementChanged";
NSString* ORXL3ModelBasicOpsRunningChanged =		@"ORXL3ModelBasicOpsRunningChanged";
NSString* ORXL3ModelWriteValueChanged =			@"ORXL3ModelWriteValueChanged";
NSString* ORXL3ModelXl3ModeChanged =			@"ORXL3ModelXl3ModeChanged";
NSString* ORXL3ModelSlotMaskChanged =			@"ORXL3ModelSlotMaskChanged";
NSString* ORXL3ModelXl3ModeRunningChanged =		@"ORXL3ModelXl3ModeRunningChanged";
NSString* ORXL3ModelXl3RWAddressValueChanged =		@"ORXL3ModelXl3RWAddressValueChanged";
NSString* ORXL3ModelXl3RWDataValueChanged =		@"ORXL3ModelXl3RWDataValueChanged";
NSString* ORXL3ModelXl3OpsRunningChanged =		@"ORXL3ModelXl3OpsRunningChanged";
NSString* ORXL3ModelXl3PedestalMaskChanged =		@"ORXL3ModelXl3PedestalMaskChanged";


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


#pragma mark •••DB Helpers

#define swapLong(x) (((uint32_t)(x) << 24) | (((uint32_t)(x) & 0x0000FF00) <<  8) | (((uint32_t)(x) & 0x00FF0000) >>  8) | ((uint32_t)(x) >> 24))
#define swapShort(x) (((uint16_t)(x) <<  8) | ((uint16_t)(x)>>  8))

- (void) synthesizeDefaultsIntoBundle:(mb_const_t*)aBundle forSLot:(unsigned short)aSlot
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
	aBundle->vint.vres = 205; //integrator output voltage

	//chinj
	aBundle->chinj.hv_id = 0x0000; // HV card id
	aBundle->chinj.hvref = 0x00; // MB control voltage
	aBundle->chinj.ped_time = 100; // MTCD pedestal width (DONT NEED THIS HERE)

	//tr100 width, channel 0 to 31, only bits 0 to 6 defined, bit0-5 delay, bit6 enable
	uint8_t s_tr100_twidth[32] = {  0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f,
					0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f,
					0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f,
					0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f };

	//tr20 width, channel 0 to 31, only bits 0 to 5 defined, bit0-4 width, bit5 enable from PennDB
	uint8_t s_tr20_twidth[32] = {	0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60,
					0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60,
					0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60,
					0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60 };

	// sane defaults from the DB spec
	/*
	uint8_t s_tr20_twidth[32] = {	0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20,
					0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20,
					0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20,
					0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20 };
	*/
	
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
	uint16_t s_scmos_stuff[32] = {	0, 0, 0, 0, 0, 0, 0, 0,
					0, 0, 0, 0, 0, 0, 0, 0,
					0, 0, 0, 0, 0, 0, 0, 0,
					0, 0, 0, 0, 0, 0, 0, 0 }; 

	//ch_disable bits 1 == disabled
	aBundle->mb_chan_disable.disable_mask = 0;
		
	memcpy(&aBundle->vbal.mb_id, s_mb_id, 2);
	memcpy(aBundle->vbal.dc_id, s_dc_id, 8);
	memcpy(aBundle->vbal.vbal, s_vbal, 64);
	memcpy(&aBundle->vthr.mb_id, s_mb_id, 2);
	memcpy(aBundle->vthr.dc_id, s_dc_id, 8);
	memcpy(aBundle->vthr.vthr, s_vthr, 32);
	memcpy(&aBundle->tdisc.mb_id, s_mb_id, 2);
	memcpy(aBundle->tdisc.dc_id, s_dc_id, 8);
	memcpy(aBundle->tdisc.rmp, s_tdisc_rmp, 8);
	memcpy(aBundle->tdisc.rmpup, s_tdisc_rmpup, 8);
	memcpy(aBundle->tdisc.vsi, s_tdisc_vsi, 8);
	memcpy(aBundle->tdisc.vli, s_tdisc_vli, 8);
	memcpy(&aBundle->tcmos.mb_id, s_mb_id, 2);
	memcpy(aBundle->tcmos.dc_id, s_dc_id, 8);
	memcpy(aBundle->tcmos.tac_shift, s_tcmos_tac_shift, 32);
	memcpy(&aBundle->vint.mb_id, s_mb_id, 2);
	memcpy(&aBundle->chinj.mb_id, s_mb_id, 2);
	memcpy(&aBundle->tr100.mb_id, s_mb_id, 2);
	memcpy(aBundle->tr100.dc_id, s_dc_id, 8);
	memcpy(aBundle->tr100.twidth, s_tr100_twidth, 32);
	memcpy(&aBundle->tr20.mb_id, s_mb_id, 2);
	memcpy(aBundle->tr20.dc_id, s_dc_id, 8);
	memcpy(aBundle->tr20.twidth, s_tr20_twidth, 32);
	memcpy(aBundle->tr20.tdelay, s_tr20_tdelay, 32);
	memcpy(&aBundle->scmos.mb_id, s_mb_id, 2);
	memcpy(aBundle->scmos.dc_id, s_dc_id, 8);
	memcpy(aBundle->scmos.stuff, s_scmos_stuff, 32);
	memcpy(&aBundle->hware.mb_id, s_mb_id, 2);
	memcpy(aBundle->hware.dc_id, s_dc_id, 8);
	memcpy(&aBundle->mb_chan_disable.mb_id, s_mb_id, 2);
	memcpy(aBundle->mb_chan_disable.dc_id, s_dc_id, 8);
}

- (void) byteSwapBundle:(mb_const_t*)aBundle
{
	int i;
	
	//vbal_vals_t
	aBundle->vbal.mb_id = swapShort(aBundle->vbal.mb_id);
	for (i=0; i<4; i++) aBundle->vbal.dc_id[i] = swapShort(aBundle->vbal.dc_id[i]);
	//vthr_vals_t
	aBundle->vthr.mb_id = swapShort(aBundle->vthr.mb_id);
	for (i=0; i<4; i++) aBundle->vthr.dc_id[i] = swapShort(aBundle->vthr.dc_id[i]);
	//tdisc_vals_t
	aBundle->tdisc.mb_id = swapShort(aBundle->tdisc.mb_id);
	for (i=0; i<4; i++) aBundle->tdisc.dc_id[i] = swapShort(aBundle->tdisc.dc_id[i]);
	//tcmos_vals_t
	aBundle->tcmos.mb_id = swapShort(aBundle->tcmos.mb_id);
	for (i=0; i<4; i++) aBundle->tcmos.dc_id[i] = swapShort(aBundle->tcmos.dc_id[i]);
	//vint_vals_t
	aBundle->vint.mb_id = swapShort(aBundle->vint.mb_id);
	//chinj_vals_t
	aBundle->chinj.mb_id = swapShort(aBundle->chinj.mb_id);
	aBundle->chinj.hv_id = swapShort(aBundle->chinj.hv_id);
	aBundle->chinj.ped_time = swapLong(aBundle->chinj.ped_time);
	//tr100_vals_t
	aBundle->tr100.mb_id = swapShort(aBundle->tr100.mb_id);
	for (i=0; i<4; i++) aBundle->tr100.dc_id[i] = swapShort(aBundle->tr100.dc_id[i]);
	//tr20_vals_t
	aBundle->tr20.mb_id = swapShort(aBundle->tr20.mb_id);
	for (i=0; i<4; i++) aBundle->tr20.dc_id[i] = swapShort(aBundle->tr20.dc_id[i]);
	//scmos_vals_t
	aBundle->scmos.mb_id = swapShort(aBundle->scmos.mb_id);
	for (i=0; i<4; i++)  aBundle->scmos.dc_id[i] = swapShort(aBundle->scmos.dc_id[i]);
	for (i=0; i<15; i++) aBundle->scmos.stuff[i] = swapShort(aBundle->scmos.stuff[i]);
	//mb_hware_vals_t
	aBundle->hware.mb_id = swapShort(aBundle->hware.mb_id);
	for (i=0; i<4; i++)  aBundle->hware.dc_id[i] = swapShort(aBundle->hware.dc_id[i]);
	//mb_chan_disable_vals_t
	aBundle->hware.mb_id = swapShort(aBundle->mb_chan_disable.mb_id);
	for (i=0; i<4; i++)  aBundle->mb_chan_disable.dc_id[i] = swapShort(aBundle->mb_chan_disable.dc_id[i]);
	aBundle->mb_chan_disable.disable_mask = swapLong(aBundle->mb_chan_disable.disable_mask);	
}

- (void) synthesizeFECIntoBundle:(mb_const_t*)aBundle forSLot:(unsigned short)aSlot
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
				     [NSNumber numberWithBool:NO],			@"variable",
				     [NSNumber numberWithLong:362],			@"length",  //modified kLong header, 1440 bytes + 2 longs
				     nil];
	[dataDictionary setObject:aDictionary forKey:@"Xl3MegaBundle"];

//	NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
//				     @"ORXL3DecoderForCmosRate",	@"decoder",
//				     [NSNumber numberWithLong:dataId],       @"dataId",
//				     [NSNumber numberWithBool:YES],          @"variable",
//				     [NSNumber numberWithLong:-1],			 @"length",
//				     nil];
//	[dataDictionary setObject:aDictionary forKey:@"Xl3CmosRate"];
	
	return dataDictionary;
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	[xl3Link resetBundleBuffer];
	[aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORXL3Model"];	
}

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	//to be replaced with while...
	if ([xl3Link bundleAvailable]) {
		NSData* aBundle = [xl3Link readNextBundle]; //ORSafeCircularBuffer calls autorelease on the NSData
		unsigned long data_length = 2 + [aBundle length] / 4;
		unsigned long data[data_length];
		data[0] = xl3MegaBundleDataId | data_length;
		data[1] = 0; //packet count, maybe time, and crate ID in a meaningful way
		memcpy(&data[2], [aBundle bytes], [aBundle length]);
		[aDataPacket addLongsToFrameBuffer:data length:data_length];
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
	[self setXl3PedestalMask:	[decoder decodeIntForKey:	@"ORXL3ModelXl3PedestalMask"]];

	if (xl3Mode == 0) [self setXl3Mode: 1];
	if (xl3OpsRunning == nil) xl3OpsRunning = [[NSMutableDictionary alloc] init];

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
	payload.numberBytesinPayload = sizeof(mb_const_t) + 4;
	unsigned long* aMbId = (unsigned long*) payload.payload;
	mb_const_t* aConfigBundle = (mb_const_t*) (payload.payload + 4);
	
	BOOL loadOk = YES;
	unsigned short i;

	NSLog(@"XL3 Init Crate...\n");

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
			NSLog(@"Init crate failed; error: %@ reason: %@\n", [e name], [e reason]);
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
			if (*(unsigned int*)payload.payload != 0) {
				NSLog(@"error during init.\n", i);
			}
			
			//todo look into the hw params returned
			/* xl3 does the following on successfull init, or returns zeros here if things go wrong
			 for (i=0;i<16;i++){
			 response_hware_vals = (mb_hware_vals_t *) (payload+4+i*sizeof(mb_hware_vals_t));
			 *response_hware_vals = hware_vals[i];
			*/
			
			NSLog(@"init ok! (for the moment)\n");
		}
		@catch (NSException* e) {
			NSLog(@"Init crate failed; error: %@ reason: %@\n", [e name], [e reason]);
		}
	}
	else {
		NSLog(@"error loading config, init skipped\n");
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
	NSLog(@"Deselect FECs...\n");
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
	NSLog(@"Send XL3 Quit ...\n");
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
	NSLog(@"Set Pedestal ...\n");
	@try {
		[[self xl3Link] sendCommand:SET_CRATE_PEDESTALS_ID withPayload:&payload expectResponse:YES];
		if ([xl3Link needToSwap]) *data = swapLong(*data);
		if (*data == 0) NSLog(@"ok\n");
		else NSLog(@"failed with XL3 error: 0x%08x\n", *data);
	}
	@catch (NSException* e) {
		NSLog(@"Send XL3 Quit failed; error: %@ reason: %@\n", [e name], [e reason]);
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
	NSLog(@"Get Board IDs ...\n");

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
	NSLog(@"Reset FIFO and Sequencer.\n");
	//slot mask?
	
	[self setXl3OpsRunning:NO forKey:@"compositeResetFIFOAndSequencer"];
}

- (void) compositeResetXL3StateMachine
{
	[self setXl3OpsRunning:YES forKey:@"compositResetXL3StateMachine"];
	NSLog(@"Reset XL3 State Machine.\n");

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
