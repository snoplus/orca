/*
 *  ORCVCfdLedModel.m
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
#import "ORCVCfdLedModel.h"

// Address information for this unit.
#define k812DefaultBaseAddress 		0xF0000000
#define k812DefaultAddressModifier 	0x39

enum {
	kReadOnly,
	kWriteOnly,
	kReadWrite
};

// Define all the registers available to this unit. Some of the values in the struct are not used.
static CV812RegNamesStruct CV812Reg[kNumRegisters] = {
	{@"Threshold 0",		0x00,		kWriteOnly},
	{@"Threshold 1",		0x02,		kWriteOnly},
	{@"Threshold 2",		0x04,		kWriteOnly},
	{@"Threshold 3",		0x06,		kWriteOnly},
	{@"Threshold 4",		0x08,		kWriteOnly},
	{@"Threshold 5",		0x0A,		kWriteOnly},
	{@"Threshold 6",    	0x0C,		kWriteOnly},
	{@"Threshold 7",		0x0E,		kWriteOnly},
	{@"Threshold 8",		0x10,		kWriteOnly},
	{@"Threshold 9",		0x12,		kWriteOnly},
	{@"Threshold 10",		0x14,		kWriteOnly},
	{@"Threshold 11",		0x16,		kWriteOnly},
	{@"Threshold 12",		0x18,		kWriteOnly},
	{@"Threshold 13",    	0x1A,		kWriteOnly},
	{@"Threshold 14",		0x1C,		kWriteOnly},
	{@"Threshold 15",		0x1E,		kWriteOnly},
	
	{@"Output Width 0-7",	0x40,		kWriteOnly},
	{@"Output Width 8-15",	0x42,		kWriteOnly},
	{@"Dead Time 0-7",		0x44,		kWriteOnly},
	{@"Dead Time 8-15",		0x46,		kWriteOnly},

	{@"Majority Thres",		0x48,		kWriteOnly},
	{@"Pattern Inhib",		0x4A,		kWriteOnly},
	{@"Test Pulse",			0x4C,		kWriteOnly},

	{@"Fixed Code",			0xFA,		kReadOnly},
	{@"Module Type",		0xFC,		kReadOnly},
	{@"Version",			0xFE,		kReadOnly},
};


NSString* ORCVCfdLedModelTestPulseChanged			= @"ORCVCfdLedModelTestPulseChanged";
NSString* ORCVCfdLedModelPatternInhibitChanged		= @"ORCVCfdLedModelPatternInhibitChanged";
NSString* ORCVCfdLedModelMajorityThresholdChanged	= @"ORCVCfdLedModelMajorityThresholdChanged";
NSString* ORCVCfdLedModelDeadTime0_7Changed		= @"ORCVCfdLedModelDeadTime0_7Changed";
NSString* ORCVCfdLedModelDeadTime8_15Changed		= @"ORCVCfdLedModelDeadTime8_15Changed";
NSString* ORCVCfdLedModelOutputWidth8_15Changed	= @"ORCVCfdLedModelOutputWidth8_15Changed";
NSString* ORCVCfdLedModelOutputWidth0_7Changed		= @"ORCVCfdLedModelOutputWidth0_7Changed";
NSString* ORCVCfdLedModelThresholdChanged			= @"ORCVCfdLedModelThresholdChanged";
NSString* ORCVCfdLedModelThresholdLock				= @"ORCVCfdLedModelThresholdLock";

@implementation ORCVCfdLedModel

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
- (unsigned short) threshold:(unsigned short) aChnl
{
    return(thresholds[aChnl]);
}

- (void) setThreshold:(unsigned short) aChnl threshold:(unsigned short) aValue
{
    
    [[[self undoManager] prepareWithInvocationTarget:self] setThreshold:aChnl threshold:[self threshold:aChnl]];
    
    thresholds[aChnl] = aValue;
    
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
	[userInfo setObject:[NSNumber numberWithInt:aChnl] forKey:@"Channel"];
    
    [[NSNotificationCenter defaultCenter]postNotificationName:ORCVCfdLedModelThresholdChanged object:self userInfo:userInfo];
}

- (unsigned short) testPulse
{
    return testPulse;
}

- (void) setTestPulse:(unsigned short)aTestPulse
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTestPulse:testPulse];
    testPulse = aTestPulse;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCVCfdLedModelTestPulseChanged object:self];
}

- (unsigned short) patternInhibit
{
    return patternInhibit;
}

- (void) setPatternInhibit:(unsigned short)aPatternInhibit
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPatternInhibit:patternInhibit];
    patternInhibit = aPatternInhibit;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCVCfdLedModelPatternInhibitChanged object:self];
}

- (unsigned short) majorityThreshold
{
    return majorityThreshold;
}

- (void) setMajorityThreshold:(unsigned short)aMajorityThreshold
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMajorityThreshold:majorityThreshold];
    majorityThreshold = aMajorityThreshold;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCVCfdLedModelMajorityThresholdChanged object:self];
}

- (unsigned short) deadTime0_7
{
    return deadTime0_7;
}

- (void) setDeadTime0_7:(unsigned short)aDeadTime0_7
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDeadTime0_7:deadTime0_7];
    deadTime0_7 = aDeadTime0_7;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCVCfdLedModelDeadTime0_7Changed object:self];
}

- (unsigned short) deadTime8_15
{
    return deadTime8_15;
}

- (void) setDeadTime8_15:(unsigned short)aDeadTime8_15
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDeadTime8_15:deadTime8_15];
    deadTime8_15 = aDeadTime8_15;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCVCfdLedModelDeadTime8_15Changed object:self];
}

- (unsigned short) outputWidth8_15
{
    return outputWidth8_15;
}

- (void) setOutputWidth8_15:(unsigned short)aOutputWidth8_15
{
    [[[self undoManager] prepareWithInvocationTarget:self] setOutputWidth8_15:outputWidth8_15];
    outputWidth8_15 = aOutputWidth8_15;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCVCfdLedModelOutputWidth8_15Changed object:self];
}

- (unsigned short) outputWidth0_7
{
    return outputWidth0_7;
}

- (void) setOutputWidth0_7:(unsigned short)aOutputWidth0_7
{
    [[[self undoManager] prepareWithInvocationTarget:self] setOutputWidth0_7:outputWidth0_7];
    outputWidth0_7 = aOutputWidth0_7;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCVCfdLedModelOutputWidth0_7Changed object:self];
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,0xFF);
}

#pragma mark ***HW Access
- (void) initBoard
{
	int i;
	for(i=0;i<16;i++)[self writeThreshold:i];
	[self writeDeadTime0_7];
	[self writeDeadTime8_15];
	[self writeOutputWidth0_7];
	[self writeOutputWidth8_15];
	[self writeTestPulse];
	[self writePatternInhibit];
	[self writeMajorityThreshold];
}

- (void) writeThreshold:(unsigned short) pChan
{
    unsigned short 	threshold = [self threshold:pChan];
    
    [[self adapter] writeWordBlock:&threshold
                         atAddress:[self baseAddress] +  CV812Reg[kThreshold0].addressOffset + (pChan * sizeof(short))
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeDeadTime0_7
{
    [[self adapter] writeWordBlock:&deadTime0_7
                         atAddress:[self baseAddress] +  CV812Reg[kDeadTime0_7].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeDeadTime8_15
{
    [[self adapter] writeWordBlock:&deadTime8_15
                         atAddress:[self baseAddress] +  CV812Reg[kDeadTime8_15].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeOutputWidth0_7
{
    [[self adapter] writeWordBlock:&outputWidth0_7
                         atAddress:[self baseAddress] +  CV812Reg[kOutputWidt0_7].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeOutputWidth8_15
{
    [[self adapter] writeWordBlock:&outputWidth8_15
                         atAddress:[self baseAddress] +  CV812Reg[kOutputWidth8_15].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeTestPulse
{
    [[self adapter] writeWordBlock:&testPulse
                         atAddress:[self baseAddress] +  CV812Reg[kTestPulse].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writePatternInhibit
{
    [[self adapter] writeWordBlock:&patternInhibit
                         atAddress:[self baseAddress] +  CV812Reg[kPatternInhibit].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeMajorityThreshold
{
    [[self adapter] writeWordBlock:&majorityThreshold
                         atAddress:[self baseAddress] +  CV812Reg[kMajorityThreshold].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) probeBoard
{
	unsigned short moduleType;
    [[self adapter] readWordBlock:&moduleType
                         atAddress:[self baseAddress] +  CV812Reg[kModuleType].addressOffset
                        numToRead:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	
	unsigned short version;
    [[self adapter] readWordBlock:&version
						atAddress:[self baseAddress] +  CV812Reg[kVersion].addressOffset
					   numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	
	NSLog(@"Version: 0x%01x   Serial Number: 0x%03x\n",(version>>12)&0xf,version%0xfff);
	NSLog(@"Manufacturer Code: 0x%x\n",(moduleType>>10)&0x3F);
	NSLog(@"Module Type: 0x%\n",moduleType&0x3ff);
}

#pragma mark ***Register - Register specific routines

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    int i;
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:32];
    for(i=0;i<32;i++){
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


