/*
 *  ORCaen965Model.m
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
#import "ORCaen965Model.h"

// Address information for this unit.
#define k862DefaultBaseAddress 		0xa00000
#define k862DefaultAddressModifier 	0x39

// Define all the registers available to this unit.
static RegisterNamesStruct reg[kNumRegisters] = {
	{@"Output Buffer",      true,	true, 	true,	0x0000,		kReadOnly,	kD32},
	{@"FirmWare Revision",	false,  false, 	false,	0x1000,		kReadOnly,	kD16},
	{@"Geo Address",		false,	false, 	false,	0x1002,		kReadWrite,	kD16},
	{@"MCST CBLT Address",	false,	false, 	true,	0x1004,		kReadWrite,	kD16},
	{@"Bit Set 1",			false,	true, 	true,	0x1006,		kReadWrite,	kD16},
	{@"Bit Clear 1",		false,	true, 	true,	0x1008,		kReadWrite,	kD16},
	{@"Interrup Level",     false,	true, 	true,	0x100A,		kReadWrite,	kD16},
	{@"Interrup Vector",	false,	true, 	true,	0x100C,		kReadWrite,	kD16},
	{@"Status Register 1",	false,	true, 	true,	0x100E,		kReadOnly,	kD16},
	{@"Control Register 1",	false,	true, 	true,	0x1010,		kReadWrite,	kD16},
	{@"ADER High",			false,	false, 	true,	0x1012,		kReadWrite,	kD16},
	{@"ADER Low",			false,	false, 	true,	0x1014,		kReadWrite,	kD16},
	{@"Single Shot Reset",	false,	false, 	false,	0x1016,		kWriteOnly,	kD16},
	{@"MCST CBLT Ctrl",     false,	false, 	true,	0x101A,		kReadWrite,	kD16},
	{@"Event Trigger Reg",	false,	true, 	true,	0x1020,		kReadWrite,	kD16},
	{@"Status Register 2",	false,	true, 	true,	0x1022,		kReadOnly,	kD16},
	{@"Event Counter L",	true,	true, 	true,	0x1024,		kReadOnly,	kD16},
	{@"Event Counter H",	true,	true, 	true,	0x1026,		kReadOnly,	kD16},
	{@"Increment Event",	false,	false, 	false,	0x1028,		kWriteOnly,	kD16},
	{@"Increment Offset",	false,	false, 	false,	0x102A,		kWriteOnly,	kD16},
	{@"Load Test Register",	false,	false, 	false,	0x102C,		kReadWrite,	kD16},
	{@"FCLR Window",		false,	true, 	true,	0x102E,		kReadWrite,	kD16},
	{@"Bit Set 2",			false,	true, 	true,	0x1032,		kReadWrite,	kD16},
	{@"Bit Clear 2",		false,	true, 	true,	0x1034,		kWriteOnly,	kD16},
	{@"W Mem Test Address",	false,	true, 	true,	0x1036,		kWriteOnly,	kD16},
	{@"Mem Test Word High",	false,	true, 	true,	0x1038,		kWriteOnly,	kD16},
	{@"Mem Test Word Low",	false,	false, 	false,	0x103A,		kWriteOnly,	kD16},
	{@"Crate Select",       false,	true, 	true,	0x103C,		kReadWrite,	kD16},
	{@"Test Event Write",	false,	false, 	false,	0x103E,		kWriteOnly,	kD16},
	{@"Event Counter Reset",false,	false, 	false,	0x1040,		kWriteOnly,	kD16},
	{@"I current pedestal", false,  true, true,		0x1060,		kReadWrite, kD16},
	{@"R Test Address",     false,	true, 	true,	0x1064,		kWriteOnly,	kD16},
	{@"SW Comm",			false,	false, 	false,	0x1068,		kWriteOnly,	kD16},
	{@"ADD",				false,	false, 	false,	0x1070,		kReadOnly,	kD16},
	{@"BADD",				false,	false, 	false,	0x1072,		kReadOnly,	kD16},
	{@"Thresholds",			false,	false, 	false,	0x1080,		kReadWrite,	kD16},
};

@implementation ORCaen965Model

#pragma mark ***Initialization
- (id) init //designated initializer
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
	
    [self setBaseAddress:k862DefaultBaseAddress];
    [self setAddressModifier:k862DefaultAddressModifier];
	
    [[self undoManager] enableUndoRegistration];
   
    return self;
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"Caen965"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORCaen965Controller"];
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,0x1080);
}

- (int) numberOfChannels
{
    return 16;
}

#pragma mark ***Register - General routines
- (short) getNumberRegisters
{
    return kNumRegisters;
}

- (unsigned long) getBufferOffset
{
    return reg[kOutputBuffer].addressOffset;
}

- (unsigned short) getDataBufferSize
{
    return k862OutputBufferSize;
}

- (unsigned long) getThresholdOffset
{
    return reg[kThresholds].addressOffset;
}

- (short) getStatusRegisterIndex:(short) aRegister
{
    if (aRegister == 1) return kStatusRegister1;
    else		return kStatusRegister2;
}

- (short) getThresholdIndex
{
    return(kThresholds);
}

- (short) getOutputBufferIndex
{
    return(kOutputBuffer);
}

#pragma mark ***Register - Register specific routines
- (NSString*) getRegisterName:(short) anIndex
{
    return reg[anIndex].regName;
}
- (unsigned long) getAddressOffset:(short) anIndex
{
    return(reg[anIndex].addressOffset);
}

- (short) getAccessType:(short) anIndex
{
    return reg[anIndex].accessType;
}

- (short) getAccessSize:(short) anIndex
{
    return reg[anIndex].size;
}

- (BOOL) dataReset:(short) anIndex
{
    return reg[anIndex].dataReset;
}

- (BOOL) swReset:(short) anIndex
{
    return reg[anIndex].softwareReset;
}

- (BOOL) hwReset:(short) anIndex
{
    return reg[anIndex].hwReset;
}

- (unsigned short) threshold:(unsigned short) aChnl
{
    return thresholds[aChnl] & 0xff;
}

- (void) setThreshold:(unsigned short) aChnl threshold:(unsigned short) aValue
{
    if(aValue>255)aValue = 255;
    // Set the undo manager action.  The label has already been set by the controller calling this method.
    [[[self undoManager] prepareWithInvocationTarget:self] setThreshold:aChnl threshold:[self threshold:aChnl]];
    
    // Set the new value in the model.
    thresholds[aChnl] = aValue;
    
    // Create a dictionary object that stores a pointer to this object and the channel that was changed.
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChnl] forKey:caenChnl];
    
    // Send out notification that the value has changed.
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:caenChnlThresholdChanged
	 object:self
	 userInfo:userInfo];
}


#pragma mark ***DataTaker
- (void) runTaskStarted:(ORDataPacket*) aDataPacket userInfo:(id)userInfo
{
    [super runTaskStarted:aDataPacket userInfo:userInfo];
    
    // Clear unit
    [self write:kBitSet2 sendValue:kClearData];			// Clear data, 
    [self write:kBitClear2 sendValue:kClearData];       // Clear "Clear data" bit of status reg.
    [self write:kEventCounterReset sendValue:0x0000];	// Clear event counter

    // Set options

    // Set thresholds in unit
    [self writeThresholds];
    
}

- (void) runTaskStopped:(ORDataPacket*) aDataPacket userInfo:(id)userInfo
{
    [super runTaskStopped:aDataPacket userInfo:userInfo];
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"CAEN 965 (Slot %d) ",[self slot]];
}

#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*) aDecoder
{
    self = [super initWithCoder:aDecoder];

    [[self undoManager] disableUndoRegistration];

    
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) encodeWithCoder:(NSCoder*) anEncoder
{
    [super encodeWithCoder:anEncoder];
}

@end

@implementation ORCaen965DecoderForCAEN : ORCaenDataDecoder
- (NSString*) identifier
{
    return @"CAEN 965 QDC";
}
@end

