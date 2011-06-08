/*
 *  ORCV812Model.m
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
#import "ORCV812Model.h"

// Address information for this unit.
#define k812DefaultBaseAddress 		0xF0000000
#define k812DefaultAddressModifier 	0x39

// Define all the registers available to this unit. Some of the values in the struct are not used.
static RegisterNamesStruct reg[kNumRegisters] = {
	{@"Threshold 0",    false,	false, 	false,	0x00,		kWriteOnly,	kD32},
	{@"Threshold 1",	false,  false, 	false,	0x02,		kWriteOnly,	kD32},
	{@"Threshold 2",	false,	false, 	false,	0x04,		kWriteOnly,	kD32},
	{@"Threshold 3",	false,	false, 	false,	0x06,		kWriteOnly,	kD32},
	{@"Threshold 4",	false,	false, 	false,	0x08,		kWriteOnly,	kD32},
	{@"Threshold 5",	false,	false, 	false,	0x0A,		kWriteOnly,	kD32},
	{@"Threshold 6",    false,	false, 	false,	0x0C,		kWriteOnly,	kD32},
	{@"Threshold 7",	false,	false, 	false,	0x0E,		kWriteOnly,	kD32},
	{@"Threshold 8",	false,	false, 	false,	0x10,		kWriteOnly,	kD32},
	{@"Threshold 9",	false,	false, 	false,	0x12,		kWriteOnly,	kD32},
	{@"Threshold 10",	false,	false, 	false,	0x14,		kWriteOnly,	kD32},
	{@"Threshold 11",	false,	false, 	false,	0x16,		kWriteOnly,	kD32},
	{@"Threshold 12",	false,	false, 	false,	0x18,		kWriteOnly,	kD32},
	{@"Threshold 13",    false,	false, 	false,	0x1A,		kWriteOnly,	kD32},
	{@"Threshold 14",	false,	false, 	false,	0x1C,		kWriteOnly,	kD32},
	{@"Threshold 15",	false,	false, 	false,	0x1E,		kWriteOnly,	kD32},
	
	{@"Output Width 0-7",	false,	false, 	false,	0x40,	kWriteOnly,	kD32},
	{@"Output Width 8-15",	false,	false, 	false,	0x42,	kWriteOnly,	kD32},
	{@"Dead Time 0-7",	false,	false, 	false,	0x44,		kWriteOnly,	kD32},
	{@"Dead Time 8-15",	false,	false, 	false,	0x46,		kWriteOnly,	kD32},

	{@"Majority Thres",	false,	false, 	false,	0x48,		kWriteOnly,	kD32},
	{@"Pattern Inhib",	false,	false, 	false,	0x4A,		kWriteOnly,	kD32},
	{@"Test Pulse",		false,	false, 	false,	0x4C,		kWriteOnly,	kD32},

	{@"Fixed Code",		false,	false, 	false,	0xFA,		kReadOnly,	kD32},
	{@"Module Type",	false,	false, 	false,	0xFA,		kReadOnly,	kD32},
	{@"Version",		false,	false, 	false,	0xFE,		kReadOnly,	kD32},
};


NSString* ORCV812ModelTestPulseChanged			= @"ORCV812ModelTestPulseChanged";
NSString* ORCV812ModelPatternInhibitChanged		= @"ORCV812ModelPatternInhibitChanged";
NSString* ORCV812ModelMajorityThresholdChanged	= @"ORCV812ModelMajorityThresholdChanged";
NSString* ORCV812ModelDeadTime0_7Changed		= @"ORCV812ModelDeadTime0_7Changed";
NSString* ORCV812ModelDeadTime8_15Changed		= @"ORCV812ModelDeadTime8_15Changed";
NSString* ORCV812ModelOutputWidth8_15Changed	= @"ORCV812ModelOutputWidth8_15Changed";
NSString* ORCV812ModelOutputWidth0_7Changed		= @"ORCV812ModelOutputWidth0_7Changed";

@implementation ORCV812Model

#pragma mark ***Initialization
- (id) init //designated initializer
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
	
    [self setBaseAddress:k812DefaultBaseAddress];
    [self setAddressModifier:k812DefaultAddressModifier];
	
    [[self undoManager] enableUndoRegistration];
   
    return self;
}

#pragma mark ***Accessors

- (unsigned short) testPulse
{
    return testPulse;
}

- (void) setTestPulse:(unsigned short)aTestPulse
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTestPulse:testPulse];
    
    testPulse = aTestPulse;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCV812ModelTestPulseChanged object:self];
}

- (unsigned short) patternInhibit
{
    return patternInhibit;
}

- (void) setPatternInhibit:(unsigned short)aPatternInhibit
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPatternInhibit:patternInhibit];
    
    patternInhibit = aPatternInhibit;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCV812ModelPatternInhibitChanged object:self];
}

- (unsigned short) majorityThreshold
{
    return majorityThreshold;
}

- (void) setMajorityThreshold:(unsigned short)aMajorityThreshold
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMajorityThreshold:majorityThreshold];
    
    majorityThreshold = aMajorityThreshold;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCV812ModelMajorityThresholdChanged object:self];
}

- (unsigned short) deadTime0_7
{
    return deadTime0_7;
}

- (void) setDeadTime0_7:(unsigned short)aDeadTime0_7
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDeadTime0_7:deadTime0_7];
    
    deadTime0_7 = aDeadTime0_7;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCV812ModelDeadTime0_7Changed object:self];
}

- (unsigned short) deadTime8_15
{
    return deadTime8_15;
}

- (void) setDeadTime8_15:(unsigned short)aDeadTime8_15
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDeadTime8_15:deadTime8_15];
    
    deadTime8_15 = aDeadTime8_15;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCV812ModelDeadTime8_15Changed object:self];
}

- (unsigned short) outputWidth8_15
{
    return outputWidth8_15;
}

- (void) setOutputWidth8_15:(unsigned short)aOutputWidth8_15
{
    [[[self undoManager] prepareWithInvocationTarget:self] setOutputWidth8_15:outputWidth8_15];
    
    outputWidth8_15 = aOutputWidth8_15;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCV812ModelOutputWidth8_15Changed object:self];
}

- (unsigned short) outputWidth0_7
{
    return outputWidth0_7;
}

- (void) setOutputWidth0_7:(unsigned short)aOutputWidth0_7
{
    [[[self undoManager] prepareWithInvocationTarget:self] setOutputWidth0_7:outputWidth0_7];
    
    outputWidth0_7 = aOutputWidth0_7;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCV812ModelOutputWidth0_7Changed object:self];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"CV812"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORCV812Controller"];
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,0xFF);
}

- (NSString*) helpURL
{
	return @"VME/V812.html";
}

#pragma mark ***Register - General routines
- (short) getNumberRegisters
{
    return kNumRegisters;
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

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"CAEN 812 (Slot %d) ",[self slot]];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    int i;
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:[self numberOfChannels]];
    for(i=0;i<[self numberOfChannels];i++){
        [array addObject:[NSNumber numberWithShort:thresholds[i]]];
    }
    [objDictionary setObject:array forKey:@"thresholds"];
    [objDictionary setObject:[NSNumber numberWithInt:testPulse] forKey:@"testPulse"];
    [objDictionary setObject:[NSNumber numberWithInt:patternInhibit] forKey:@"patternInhibit"];
    [objDictionary setObject:[NSNumber numberWithInt:majorityThreshold] forKey:@"majorityThreshold"];
    [objDictionary setObject:[NSNumber numberWithInt:deadTime0_7] forKey:@"deadTime0_7"];
    [objDictionary setObject:[NSNumber numberWithInt:deadTime8_15] forKey:@"deadTime8_15"];
    [objDictionary setObject:[NSNumber numberWithInt:outputWidth0_7] forKey:@"outputWidth0_7"];
    [objDictionary setObject:[NSNumber numberWithInt:outputWidth8_15] forKey:@"outputWidth8_15"];
    
    return objDictionary;
}

#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*) aDecoder
{
    self = [super initWithCoder:aDecoder];

    [[self undoManager] disableUndoRegistration];

	[self setTestPulse:[aDecoder decodeIntForKey:@"testPulse"]];
	[self setPatternInhibit:[aDecoder decodeIntForKey:@"patternInhibit"]];
	[self setMajorityThreshold:[aDecoder decodeIntForKey:@"majorityThreshold"]];
	[self setDeadTime0_7:[aDecoder decodeIntForKey:@"deadTime0_7"]];
	[self setDeadTime8_15:[aDecoder decodeIntForKey:@"deadTime8_15"]];
	[self setOutputWidth0_7:[aDecoder decodeIntForKey:@"outputWidth0_7"]];
	[self setOutputWidth8_15:[aDecoder decodeIntForKey:@"outputWidth8_15"]];
	
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) encodeWithCoder:(NSCoder*) anEncoder
{
    [super encodeWithCoder:anEncoder];
    [anEncoder encodeInt:testPulse forKey:@"testPulse"];
    [anEncoder encodeInt:patternInhibit forKey:@"patternInhibit"];
    [anEncoder encodeInt:majorityThreshold forKey:@"majorityThreshold"];
    [anEncoder encodeInt:deadTime0_7 forKey:@"deadTime0_7"];
    [anEncoder encodeInt:deadTime8_15 forKey:@"deadTime8_15"];
    [anEncoder encodeInt:outputWidth0_7 forKey:@"outputWidth0_7"];
    [anEncoder encodeInt:outputWidth8_15 forKey:@"outputWidth8_15"];
}

@end


