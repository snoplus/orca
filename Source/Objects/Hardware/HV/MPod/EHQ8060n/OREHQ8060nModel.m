//
//  OREHQ8060nModel.m
//  Orca
//
//  Created by Mark Howe on Thurs Jan 6,2011
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Department of Physics and Astrophysics 
//sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark ***Imported Files
#import "OREHQ8060nModel.h"
#import "ORDataTypeAssigner.h"

NSString* OREHQ8060nSettingsLock		= @"OREHQ8060nSettingsLock";
NSString* OREHQ8060nModelVoltageChanged	= @"OREHQ8060nModelVoltageChanged";
NSString* OREHQ8060nModelCurrentChanged	= @"OREHQ8060nModelCurrentChanged";


@implementation OREHQ8060nModel

#pragma mark ***Initialization
- (id) init 
{
    self = [super init];
    return self;
}

- (void) dealloc 
{
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"EHQ8060n"]];	
}

- (void) makeMainController
{
    [self linkToController:@"OREHQ8060nController"];
}

#pragma mark ***Accessors
- (int) voltage:(short)chan	{ return voltage[chan]; }
- (void) setVoltage:(short)chan withValue:(int)aValue 
{ 
	if(aValue<0)aValue=0;
	else if(aValue>0xfFFF)aValue = 0xfFFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setVoltage:chan withValue:voltage[chan]];
	voltage[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:OREHQ8060nModelVoltageChanged object:self];
}

- (float) current:(short)chan	{ return current[chan]; }
- (void) setCurrent:(short)chan withValue:(float)aValue 
{ 
	if(aValue<0)aValue=0;
    [[[self undoManager] prepareWithInvocationTarget:self] setCurrent:chan withValue:current[chan]];
	current[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:OREHQ8060nModelCurrentChanged object:self];
}

#pragma mark •••Hardware Access
- (void) writeVoltage:(int)channel
{    
	[[self adapter] writeParam:@"outputVoltage" slot:[self slot] channel:channel floatValue:voltage[channel]];
}

#pragma mark •••Data Taker
- (unsigned long) dataId { return dataId; }

- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}

- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm]; //short form preferred
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"OREHQ8060nDecoderForWaveform",          @"decoder",
								 [NSNumber numberWithLong:dataId],        @"dataId",
								 [NSNumber numberWithBool:YES],           @"variable",
								 [NSNumber numberWithLong:-1],			  @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"Waveform"];
    
    return dataDictionary;
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
	
	int i;
	for(i=0;i<kNumEHQ8060nChannels;i++){
		[self setVoltage:i withValue:[decoder decodeIntForKey:[@"voltage" stringByAppendingFormat:@"%d",i]]];
		[self setCurrent:i withValue:[decoder decodeIntForKey:[@"current" stringByAppendingFormat:@"%d",i]]];
	}
	
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	int i;
 	for(i=0;i<kNumEHQ8060nChannels;i++){
		[encoder encodeInt:voltage[i] forKey:[@"voltage" stringByAppendingFormat:@"%d",i]];
		[encoder encodeFloat:current[i] forKey:[@"current" stringByAppendingFormat:@"%d",i]];
	}
	
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
	int i;
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
	[self addCurrentState:objDictionary cIntArray:voltage forKey:[@"voltage" stringByAppendingFormat:@"%d",i]];
	[self addCurrentState:objDictionary cFloatArray:current forKey:[@"current" stringByAppendingFormat:@"%d",i]];
	
    return objDictionary;
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary cIntArray:(short*)anArray forKey:(NSString*)aKey
{
	NSMutableArray* ar = [NSMutableArray array];
	int i;
	for(i=0;i<kNumEHQ8060nChannels;i++){
		[ar addObject:[NSNumber numberWithInt:*anArray]];
		anArray++;
	}
	[dictionary setObject:ar forKey:aKey];
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary cFloatArray:(float*)anArray forKey:(NSString*)aKey
{
	NSMutableArray* ar = [NSMutableArray array];
	int i;
	for(i=0;i<kNumEHQ8060nChannels;i++){
		[ar addObject:[NSNumber numberWithFloat:*anArray]];
		anArray++;
	}
	[dictionary setObject:ar forKey:aKey];
}

@end
