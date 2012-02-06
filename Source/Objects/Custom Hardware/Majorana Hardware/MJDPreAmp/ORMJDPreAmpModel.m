//
//  MJDPreAmpModel.m
//  Orca
//
//  Created by Mark Howe on Wed Jan 18 2012.
//  Copyright © 2012 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------


#pragma mark ¥¥¥Imported Files
#import "ORMJDPreAmpModel.h"

#pragma mark ¥¥¥Notification Strings
NSString* ORMJDPreAmpModelLoopForeverChanged = @"ORMJDPreAmpModelLoopForeverChanged";
NSString* ORMJDPreAmpModelPulseCountChanged = @"ORMJDPreAmpModelPulseCountChanged";
NSString* ORMJDPreAmpEnabledChanged			= @"ORMJDPreAmpEnabledChanged";
NSString* ORMJDPreAmpAttenuatedChanged		= @"ORMJDPreAmpAttenuatedChanged";
NSString* ORMJDPreAmpFinalAttenuatedChanged	= @"ORMJDPreAmpFinalAttenuatedChanged";
NSString* ORMJDPreAmpPulserMaskChanged		= @"ORMJDPreAmpPulserMaskChanged";
NSString* ORMJDPreAmpPulseHighTimeChanged	= @"ORMJDPreAmpPulseHighTimeChanged";
NSString* ORMJDPreAmpPulseLowTimeChanged	= @"ORMJDPreAmpPulseLowTimeChanged";
NSString* ORMJDPreAmpDacArrayChanged		= @"ORMJDPreAmpDacArrayChanged";
NSString* ORMJDPreAmpDacChanged				= @"ORMJDPreAmpDacChanged";
NSString* ORMJDPreAmpAmplitudeArrayChanged	= @"ORMJDPreAmpAmplitudeArrayChanged";
NSString* ORMJDPreAmpAmplitudeChanged		= @"ORMJDPreAmpAmplitudeChanged";
NSString* MJDPreAmpSettingsLock				= @"MJDPreAmpSettingsLock";

#pragma mark ¥¥¥Local Strings
static NSString* MJDPreAmpInputConnector     = @"MJDPreAmpInputConnector";

#define kDAC1 0x80000000
#define kDAC2 0x81000000
#define kDAC3 0x82000000
#define kDAC4 0x83000000

#define kDACA_H_Base		0x00200000
#define kFrequencyMask		0xc0000000
#define kAttnPatternMask	0xc1000000
#define kAttnPulseCountMask	0xc2000000
#define kPulserLoopForever  (0x1<<23)
#define kPulserUseLoopCount (0x1<<22)


@implementation ORMJDPreAmpModel
#pragma mark ¥¥¥initialization
- (id) init //designated initializer
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
	[self setUpArrays];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc
{
    [dacs release];
    [super dealloc];
}

- (void) setUpArrays
{
	if(!dacs){
		[self setDacs:[NSMutableArray arrayWithCapacity:kMJDPreAmpDacChannels]];
		int i;
		for(i=0;i<kMJDPreAmpDacChannels;i++){
			[dacs addObject:[NSNumber numberWithInt:0]];
		}	
	}
	if(!amplitudes){
		[self setAmplitudes:[NSMutableArray arrayWithCapacity:kMJDPreAmpDacChannels]];
		int i;
		for(i=0;i<kMJDPreAmpDacChannels;i++){
			[amplitudes addObject:[NSNumber numberWithInt:0]];
		}	
	}
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint(2,[self frame].size.height/2 - kConnectorSize/2) withGuardian:self withObjectLink:self];
	[aConnector setConnectorType: 'SPII' ];
	[aConnector addRestrictedConnectionType: 'SPIO' ]; 
	[aConnector setOffColor:[NSColor colorWithCalibratedRed:0 green:.68 blue:.65 alpha:1.]];
    [[self connectors] setObject:aConnector forKey:MJDPreAmpInputConnector];
    [aConnector release];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"MJDPreAmp"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORMJDPreAmpController"];
}

#pragma mark ¥¥¥Accessors

- (BOOL) loopForever
{
    return loopForever;
}

- (void) setLoopForever:(BOOL)aLoopForever
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLoopForever:loopForever];
    
    loopForever = aLoopForever;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpModelLoopForeverChanged object:self];
}

- (unsigned short) pulseCount
{
    return pulseCount;
}

- (void) setPulseCount:(unsigned short)aPulseCount
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPulseCount:pulseCount];
    
    pulseCount = aPulseCount;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpModelPulseCountChanged object:self];
}

- (BOOL) enabled:(int)index
{
	if(index>=0 && index<2) return enabled[index];
    else return NO;
}

- (void) setEnabled:(int)index value:(BOOL)aEnabled
{
	if(index<0 || index>1) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setEnabled:index value:enabled[index]];
    enabled[index] = aEnabled;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpEnabledChanged object:self];
}

- (BOOL) attenuated:(int)index
{
	if(index>=0 && index<2) return attenuated[index];
    else return NO;
}

- (void) setAttenuated:(int)index value:(BOOL)aAttenuated
{
	if(index<0 || index>1) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setAttenuated:index value:attenuated[index]];
    attenuated[index] = aAttenuated;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpAttenuatedChanged object:self];
}

- (BOOL) finalAttenuated:(int)index
{
	if(index>=0 && index<2) return finalAttenuated[index];
    else return NO;
}

- (void) setFinalAttenuated:(int)index value:(BOOL)aAttenuated
{
	if(index<0 || index>1) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setFinalAttenuated:index value:finalAttenuated[index]];
    finalAttenuated[index] = aAttenuated;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpFinalAttenuatedChanged object:self];
}


- (unsigned short) pulserMask
{
    return pulserMask;
}

- (void) setPulserMask:(unsigned short)aPulserMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPulserMask:pulserMask];
    pulserMask = aPulserMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpPulserMaskChanged object:self];
}

- (int) pulseHighTime
{
	return pulseHighTime;
}

- (void) setPulseHighTime:(int)aPulseHighTime
{
	if(aPulseHighTime<1)			aPulseHighTime=1;
	else if(aPulseHighTime>4095)	aPulseHighTime = 4095;
	[[[self undoManager] prepareWithInvocationTarget:self] setPulseHighTime:pulseHighTime];
    pulseHighTime = aPulseHighTime;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpPulseHighTimeChanged object:self];
}

- (int) pulseLowTime
{
	return pulseLowTime;
}

- (void) setPulseLowTime:(int)aPulseLowTime
{
	if(aPulseLowTime<1)			aPulseLowTime=1;
	else if(aPulseLowTime>4095)	aPulseLowTime = 4095;
	
	[[[self undoManager] prepareWithInvocationTarget:self] setPulseLowTime:pulseLowTime];
    pulseLowTime = aPulseLowTime;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpPulseLowTimeChanged object:self];
}

- (NSMutableArray*) dacs
{
    return dacs;
}

- (void) setDacs:(NSMutableArray*)anArray
{
    [anArray retain];
    [dacs release];
    dacs = anArray;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpDacArrayChanged object:self];
}

- (unsigned long) dac:(unsigned short) aChan
{
    return [[dacs objectAtIndex:aChan] shortValue];
}

- (void) setDac:(unsigned short) aChan withValue:(unsigned long) aValue
{
	if(aValue>0xffff) aValue = 0xffff;
    [[[self undoManager] prepareWithInvocationTarget:self] setDac:aChan withValue:[self dac:aChan]];
	[dacs replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
	
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChan] forKey: @"Channel"];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpDacChanged
														object:self
													  userInfo: userInfo];
}

- (NSMutableArray*) amplitudes
{
    return amplitudes;
}

- (void) setAmplitudes:(NSMutableArray*)anArray
{
    [anArray retain];
    [amplitudes release];
    amplitudes = anArray;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpAmplitudeArrayChanged object:self];
}

- (unsigned long) amplitude:(int) aChan
{
    return [[amplitudes objectAtIndex:aChan] shortValue];
}

- (void) setAmplitude:(int) aChan withValue:(unsigned long) aValue
{
	if(aValue>0xffff) aValue = 0xffff;
    [[[self undoManager] prepareWithInvocationTarget:self] setAmplitude:aChan withValue:[self amplitude:aChan]];
	[amplitudes replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
	
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithUnsignedShort:aChan] forKey: @"Channel"];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpAmplitudeChanged
														object:self
													  userInfo: userInfo];
}

- (NSString*) helpURL
{
	return nil;
}

#pragma mark ¥¥¥HW Access

- (void) writeFetVdsToHW
{
	int i;
	for(i=0;i<kMJDPreAmpDacChannels;i++){
		[self writeFetVds:i];
	}
}

- (void) writeFetVds:(int)index
{
	if(index>=0 && index<16){
		unsigned long theValue;
		//set up the Octal chip mask first
		if(index<8)	theValue = kDAC3;
		else		theValue = kDAC4;
		
		//set up which of eight DAC on that octal chip
		theValue |= (kDACA_H_Base | (index%8 << 16));
		
		//set up the value
		theValue |= [self dac:index];
		[self writeAuxIOSPI:theValue];
	}
}
- (void) stopPulser
{
	//write zeros to the pattern, the attenuators, and the enabled fields.
	[self writeAuxIOSPI:kAttnPatternMask];
}	
- (void) startPulser
{
	unsigned long aValue = 0;
	//set the high and low times
	aValue = kFrequencyMask | ((pulseLowTime&0xFFF)<<12) | (pulseHighTime&0xFFF);
	[self writeAuxIOSPI:aValue];
	
	//set the frequency
	aValue =  kAttnPatternMask | 
		((pulserMask		 & 0xFFFF) << 8) | 
		((attenuated[0]      & 0x1) << 7)  |
		((finalAttenuated[0] & 0x1) << 6)  | 
		((!enabled[0]        & 0x1) << 5) |
		((attenuated[1]	     & 0x1) << 3)  | 
		((finalAttenuated[1] & 0x1) << 2)  | 
		((!enabled[1]        & 0x1) << 1) ;
	
	[self writeAuxIOSPI:aValue];
	
	aValue = kAttnPulseCountMask | (pulseCount & 0xffff);
	if(loopForever) aValue |= kPulserLoopForever;
	else			aValue |= kPulserUseLoopCount;
	[self writeAuxIOSPI:aValue];
}

- (unsigned long) readAuxIOSPI
{
	unsigned long aValue = 0;
	id connectedObj = [self objectConnectedTo:MJDPreAmpInputConnector];
	if([connectedObj respondsToSelector:@selector(readAuxIOSPI)]){
		aValue = [connectedObj readAuxIOSPI];
		NSLog(@"MJD Preamp got: 0x%x\n",aValue);
	}
	return aValue;
}

- (void)  writeAuxIOSPI:(unsigned long)aValue
{
	id connectedObj = [self objectConnectedTo:MJDPreAmpInputConnector];
	if([connectedObj respondsToSelector:@selector(writeAuxIOSPI:)]){
		[connectedObj writeAuxIOSPI:aValue];
	}
}

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
	int i;
	for(i=0;i<2;i++){
		[self setEnabled:i value:[decoder decodeBoolForKey:[NSString stringWithFormat:@"enabled%d",i]]];
		[self setAttenuated:i value:[decoder decodeBoolForKey:[NSString stringWithFormat:@"attenuated%d",i]]];
		[self setFinalAttenuated:i value:[decoder decodeBoolForKey:[NSString stringWithFormat:@"finalAttenuated%d",i]]];
	}
    [self setLoopForever:	[decoder decodeBoolForKey:@"loopForever"]];
    [self setPulseCount:	[decoder decodeIntForKey:@"pulseCount"]];
	[self setPulseHighTime:	[decoder decodeIntForKey:@"pulseHighTime"]];
	[self setPulseLowTime:	[decoder decodeIntForKey:@"pulseLowTime"]];
	[self setPulserMask:	[decoder decodeIntForKey:@"pulserMask"]];
    [self setDacs:			[decoder decodeObjectForKey:@"dacs"]];
    [self setAmplitudes:	[decoder decodeObjectForKey:@"amplitudes"]];
    if(!dacs || !amplitudes)	[self setUpArrays];
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	int i;
	for(i=0;i<2;i++){
		[encoder encodeBool:enabled[i]			forKey:[NSString stringWithFormat:@"enabled%d",i]];
		[encoder encodeBool:attenuated[i]		forKey:[NSString stringWithFormat:@"attenuated%d",i]];
		[encoder encodeBool:finalAttenuated[i]		forKey:[NSString stringWithFormat:@"finalAttenuated%d",i]];
	}
	
	[encoder encodeBool:loopForever		forKey:@"loopForever"];
	[encoder encodeInt:pulseCount		forKey:@"pulseCount"];
	[encoder encodeInt:pulseHighTime	forKey:@"pulseHighTime"];
	[encoder encodeInt:pulseLowTime		forKey:@"pulseLowTime"];
	[encoder encodeInt:pulserMask		forKey:@"pulserMask"];
	[encoder encodeObject:dacs			forKey:@"dacs"];
	[encoder encodeObject:amplitudes	forKey:@"amplitudes"];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];
    [objDictionary setObject:NSStringFromClass([self class]) forKey:@"Class Name"];
    [objDictionary setObject:[NSNumber numberWithInt:[self uniqueIdNumber]] forKey:@"preampID"];
    
    [dictionary setObject:objDictionary forKey:[self identifier]];
    return objDictionary;
}
@end
