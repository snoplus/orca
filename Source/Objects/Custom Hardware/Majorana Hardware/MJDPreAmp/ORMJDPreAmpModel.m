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
#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"

#pragma mark ¥¥¥Notification Strings
NSString* ORMJDPreAmpModelAdcEnabledMaskChanged = @"ORMJDPreAmpModelAdcEnabledMaskChanged";
NSString* ORMJDPreAmpModelPollTimeChanged	= @"ORMJDPreAmpModelPollTimeChanged";
NSString* ORMJDPreAmpModelShipValuesChanged = @"ORMJDPreAmpModelShipValuesChanged";
NSString* ORMJDPreAmpAdcArrayChanged		= @"ORMJDPreAmpAdcArrayChanged";
NSString* ORMJDPreAmpLoopForeverChanged		= @"ORMJDPreAmpLoopForeverChanged";
NSString* ORMJDPreAmpPulseCountChanged		= @"ORMJDPreAmpPulseCountChanged";
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
NSString* ORMJDPreAmpAdcChanged				= @"ORMJDPreAmpAdcChanged";
NSString* ORMJDPreAmpAdcRangeChanged		= @"ORMJDPreAmpAdcRangeChanged";

#pragma mark ¥¥¥Local Strings
static NSString* MJDPreAmpInputConnector     = @"MJDPreAmpInputConnector";

#define kDAC1 0x80000000
#define kDAC2 0x81000000
#define kDAC3 0x82000000
#define kDAC4 0x83000000

#define kDACA_H_Base		0x00200000
#define kPulserLowTimeMask	0xC0000000
#define kPulserHighTimeMask	0xC1000000
#define kAttnPatternMask	0xC2000000
#define kPulserStartMask	0xC3000000
#define kPulserLoopForever  (0x1<<23)
#define kPulserUseLoopCount (0x1<<22)

#define kADC1		0xE0000000
#define kADC2		0xE1000000

#define kADCRange10Reg1		0x00A000
#define kADCRange5Reg1		0x00AAA0
#define kADCRange2_5Reg1	0x00BA40

#define kADCRange10Reg2		0x00C000
#define kADCRange5Reg2		0x00CAA0
#define kADCRange2_5Reg2	0x00DA40

#define kReadAdcChannel0 0x00801000
#define kReadAdcChannel1 0x00841000
#define kReadAdcChannel2 0x00881000
#define kReadAdcChannel3 0x008C1000
#define kReadAdcChannel4 0x00901000
#define kReadAdcChannel5 0x00941000
#define kReadAdcChannel6 0x00981000
#define kReadAdcChannel7 0x009C1000




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
    [adcs release];
    [dacs release];
    [super dealloc];
}

- (void) sleep
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[super sleep];
}

- (void) wakeUp
{
	[super wakeUp];
	if(pollTime){
		[self pollValues];
	}
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
	if(!adcs){
		[self setAdcs:[NSMutableArray arrayWithCapacity:kMJDPreAmpDacChannels]];
		int i;
		for(i=0;i<kMJDPreAmpDacChannels;i++){
			[adcs addObject:[NSNumber numberWithInt:0]];
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

- (unsigned long) adcEnabledMask
{
    return adcEnabledMask;
}

- (void) setAdcEnabledMask:(unsigned long)aAdcEnabledMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAdcEnabledMask:adcEnabledMask];
    
    adcEnabledMask = aAdcEnabledMask;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpModelAdcEnabledMaskChanged object:self];
}

- (BOOL) shipValues
{
    return shipValues;
}

- (void) setShipValues:(BOOL)aShipValues
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShipValues:shipValues];
    
    shipValues = aShipValues;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpModelShipValuesChanged object:self];
}

- (int) pollTime
{
    return pollTime;
}

- (void) setPollTime:(int)aPollTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollTime:aPollTime];
    pollTime = aPollTime;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpModelPollTimeChanged object:self];
	
	if(pollTime){
		[self performSelector:@selector(pollValues) withObject:nil afterDelay:2];
	}
	else {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollValues) object:nil];
	}
}

- (int) adcRange:(int)index
{
	if(index>=0 && index<2) return adcRange[index];
	else return 0;
}

- (void) setAdcRange:(int)index value:(int)aValue
{	
	if(index<0 || index>1) return;
	if(aValue<0)	  aValue = 0;
	else if(aValue>2) aValue = 2;
	[[[self undoManager] prepareWithInvocationTarget:self] setAdcRange:index value:[self adcRange:index]];
	adcRange[index] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpAdcRangeChanged
															object:self];
		
}

- (NSMutableArray*) adcs
{
    return adcs;
}

- (void) setAdcs:(NSMutableArray*)aAdcs
{
    [aAdcs retain];
    [adcs release];
    adcs = aAdcs;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpAdcArrayChanged object:self];
}

- (float) adc:(unsigned short) aChan
{
	if(aChan<[adcs count]){
		if(adcEnabledMask & (0x1<<aChan)){
		return [[adcs objectAtIndex:aChan] floatValue];
		}
		else return 0.0;
	}
	else return 0.0;
}

- (void) setAdc:(int) aChan value:(float) aValue
{
	if(aChan<[adcs count]){
		[[[self undoManager] prepareWithInvocationTarget:self] setAdc:aChan value:[self adc:aChan]];
		[adcs replaceObjectAtIndex:aChan withObject:[NSNumber numberWithFloat:aValue]];
	
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithFloat:aChan] forKey: @"Channel"];
	
		[[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpAdcChanged
															object:self
														  userInfo: userInfo];
	}
}

- (BOOL) loopForever
{
    return loopForever;
}

- (void) setLoopForever:(BOOL)aLoopForever
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLoopForever:loopForever];
    
    loopForever = aLoopForever;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpLoopForeverChanged object:self];
}

- (unsigned short) pulseCount
{
    return pulseCount;
}

- (void) setPulseCount:(unsigned short)aPulseCount
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPulseCount:pulseCount];
    
    pulseCount = aPulseCount;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpPulseCountChanged object:self];
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
	else if(aPulseHighTime>0xFFFF)	aPulseHighTime = 0xFFFF;
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
	else if(aPulseLowTime>0xFFFF)	aPulseLowTime = 0xFFFF;
	
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
    return [[dacs objectAtIndex:aChan] unsignedShortValue];
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

- (unsigned long) timeMeasured:(int)index
{
	if(index>=0 && index<2)return timeMeasured[index];
	else return 0;
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
    return [[amplitudes objectAtIndex:aChan] unsignedShortValue];
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

- (void) writeAmplitudes
{
	int i;
	for(i=0;i<kMJDPreAmpDacChannels;i++){
		[self writeAmplitude:i];
	}
}

- (void) writeAmplitude:(int)index
{
	if(index>=0 && index<16){
		unsigned long theValue;
		//set up the Octal chip mask first
		if(index<8)	theValue = kDAC1;
		else		theValue = kDAC2;
		
		//set up which of eight DAC on that octal chip
		theValue |= (kDACA_H_Base | (index%8 << 16));
		
		//set up the value
		theValue |= [self amplitude:index];
		[self writeAuxIOSPI:theValue];
	}
}

- (void) zeroAmplitudes
{
    unsigned long zeroAllOctalChips = 0x2F0000;
	[self writeAuxIOSPI:(kDAC1 | zeroAllOctalChips)];
	[self writeAuxIOSPI:(kDAC2 | zeroAllOctalChips)];
}


- (void) writeRangeForAdcChip:(int)index
{
	if(index>=0 && index<2){
		unsigned long rangeValue[2][3] = {
			{kADCRange10Reg1, kADCRange5Reg1, kADCRange2_5Reg1},
			{kADCRange10Reg2, kADCRange5Reg2, kADCRange2_5Reg2}
		};
		unsigned long adcBase[2] = {kADC1, kADC2};
		
		unsigned long aValue = adcBase[index] | rangeValue[index][adcRange[index]];
		[self writeAuxIOSPI:aValue];
	}
}

- (void) writeAdcChipRanges
{
	[self writeRangeForAdcChip:0];
	[self writeRangeForAdcChip:1];
}

- (void) readAdcsOnChip:(int)aChip
{
	if(aChip<0 || aChip>1) return;

	[self writeRangeForAdcChip:aChip ];
    float voltageMultiplier = 10./pow(2.,adcRange[aChip]+12);

	unsigned long adcBase = kADC1;
    if(aChip) adcBase = kADC2;
	unsigned long channelSelect[8] = {
		kReadAdcChannel0,kReadAdcChannel1,kReadAdcChannel2,kReadAdcChannel3,
		kReadAdcChannel4,kReadAdcChannel5,kReadAdcChannel6,kReadAdcChannel7,
	};

	//have to select a channel to be digitized, then the next time a selection is done the last channel can be read
	int i;
    unsigned long readBack;
	for(i=0;i<8;i++){
		if(adcEnabledMask&(0x1<<((aChip*8)+i))){
			int j;
			for(j=0;j<4;j++) readBack = [self writeAuxIOSPI:adcBase | channelSelect[i]];
			//if(i>0){
				//readBack = readBack & 0x1fff; //!!!!fix to put the sign in the right place and convert to a number
				readBack = ~readBack;
				int channelReadBack = (readBack & 0xE000) >> 13;
				//if(channelReadBack != i-1) {
				if(channelReadBack != i) {
				  NSLog(@"Warning! channelReadBack = %d, not %d\n", channelReadBack, i);
				}
				int voltage = readBack & 0xfff;
				if(readBack & 0x1000) voltage |= 0xfffff000;
				//NSLog(@"Got voltage %f*%d=%f for channel %d\n", voltageMultiplier, voltage, voltageMultiplier*voltage, i);
				//[self setAdc:(aChip*8)+i-1 value:voltage];
				[self setAdc:(aChip*8)+i value:voltageMultiplier*voltage];
			//}
		}
		else [self setAdc:(aChip*8)+i value:0.0];
	}
	
	if(adcEnabledMask & (0x1<<(aChip*8))){
		//select the first one and to readBack the last one
		readBack = [self writeAuxIOSPI:adcBase | channelSelect[0]];
		//readBack = readBack & 0x1fff; //!!!!fix to put the sign in the right place and convert to a number
		[self setAdc:(aChip*8)+7 value:readBack];
	}
	else [self setAdc:(aChip*8)+7 value:0.0];
	
	
	//get the time(UT!) for the data record. 
	time_t	ut_Time;
	time(&ut_Time);
	timeMeasured[aChip] = ut_Time;
}

- (void) pollValues
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollValues) object:nil];
	[self readAdcs];
	if(shipValues)[self shipRecords];
	if(pollTime)[self performSelector:@selector(pollValues) withObject:nil afterDelay:pollTime];
}

- (void) readAdcs
{
	[self readAdcsOnChip:0];
	[self readAdcsOnChip:1];
}

- (void) stopPulser
{
    // stop pulsing: write nothing to kPulserStartMask
	[self writeAuxIOSPI:kPulserStartMask];
	//[self writeAuxIOSPI:(kPulserStartMask | kPulserUseLoopCount)];

    //Now park it! First zero all pulse amplitudes
    [self zeroAmplitudes];
	//write zeros to the pattern, enable the attenuators, and disable the pulser outputs
	[self writeAuxIOSPI:(kAttnPatternMask | 0x22)];
	NSLog(@"PreAmp(%d) Disabled Pulser\n",[self uniqueIdNumber]);
}	

- (void) startPulser
{
    if(pulseCount == 0 && !loopForever) {
	  NSLog(@"PreAmp(%d)::startPulser() -- pulseCount = 0 but not looping forever, returning...\n",[self uniqueIdNumber]);
      return;
    }

	//set the pulser amplitudes
    [self writeAmplitudes];

	unsigned long aValue = 0;
	//set the high and low times (frequency)
	aValue = kPulserLowTimeMask | ((pulseLowTime&0xFFFF)<<8);
	[self writeAuxIOSPI:aValue];
	aValue = kPulserHighTimeMask | ((pulseHighTime&0xFFFF)<<8);
	[self writeAuxIOSPI:aValue];
	
	//set the bit pattern and global attenuators / enables
	aValue =  kAttnPatternMask | 
		((pulserMask		 & 0xFF00)) | 
		((pulserMask		 & 0x00FF) << 16) | 
		((attenuated[0]      & 0x1) << 7)  |
		((finalAttenuated[0] & 0x1) << 6)  | 
		((enabled[0]         & 0x1) << 5) |
		((attenuated[1]	     & 0x1) << 3)  | 
		((finalAttenuated[1] & 0x1) << 2)  | 
		((enabled[1]         & 0x1) << 1) ;
	[self writeAuxIOSPI:aValue];
	
    // start pulsing
	aValue = kPulserStartMask | ((pulseCount-1) & 0xffff);
	if(loopForever) aValue |= kPulserLoopForever;
	else			aValue |= kPulserUseLoopCount;
	[self writeAuxIOSPI:aValue];
	NSLog(@"PreAmp(%d) Started Pulser\n",[self uniqueIdNumber]);
}

- (unsigned long)  writeAuxIOSPI:(unsigned long)aValue
{
	id connectedObj = [self objectConnectedTo:MJDPreAmpInputConnector];
	if([connectedObj respondsToSelector:@selector(writeAuxIOSPI:)]){
		return [connectedObj writeAuxIOSPI:aValue];
	}
    return 0;
}

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
    [self setAdcEnabledMask:[decoder decodeInt32ForKey:@"adcEnabledMask"]];
    [self setShipValues:	[decoder decodeBoolForKey: @"shipValues"]];
	[self setPollTime:		[decoder decodeIntForKey:  @"pollTime"]];
	
	int i;
	for(i=0;i<2;i++){
		[self setEnabled:i		   value:[decoder decodeBoolForKey:[NSString stringWithFormat: @"enabled%d",i]]];
		[self setAttenuated:i      value:[decoder decodeBoolForKey:[NSString stringWithFormat: @"attenuated%d",i]]];
		[self setFinalAttenuated:i value:[decoder decodeBoolForKey:[NSString stringWithFormat: @"finalAttenuated%d",i]]];
		[self setAdcRange:i        value:[decoder decodeIntForKey: [NSString stringWithFormat: @"adcRange%d",i]]];
	}
	
    [self setLoopForever:	[decoder decodeBoolForKey:   @"loopForever"]];
    [self setPulseCount:	[decoder decodeIntForKey:    @"pulseCount"]];
	[self setPulseHighTime:	[decoder decodeIntForKey:    @"pulseHighTime"]];
	[self setPulseLowTime:	[decoder decodeIntForKey:    @"pulseLowTime"]];
	[self setPulserMask:	[decoder decodeIntForKey:    @"pulserMask"]];
    [self setDacs:			[decoder decodeObjectForKey: @"dacs"]];
	[self setAdcs:			[decoder decodeObjectForKey: @"adcs"]];
    [self setAmplitudes:	[decoder decodeObjectForKey: @"amplitudes"]];
	
    if(!dacs || !amplitudes)	[self setUpArrays];
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	[encoder encodeInt32:adcEnabledMask forKey:@"adcEnabledMask"];
	[encoder encodeBool:shipValues		forKey:@"shipValues"];
	[encoder encodeInt:pollTime			forKey:@"pollTime"];
	int i;
	for(i=0;i<2;i++){
		[encoder encodeBool:enabled[i]			forKey:[NSString stringWithFormat:@"enabled%d",i]];
		[encoder encodeBool:attenuated[i]		forKey:[NSString stringWithFormat:@"attenuated%d",i]];
		[encoder encodeBool:finalAttenuated[i]	forKey:[NSString stringWithFormat:@"finalAttenuated%d",i]];
		[encoder encodeInt:adcRange[i]			forKey:[NSString stringWithFormat:@"adcRange%d",i]];
	}
	
	[encoder encodeBool:loopForever		forKey:@"loopForever"];
	[encoder encodeInt:pulseCount		forKey:@"pulseCount"];
	[encoder encodeInt:pulseHighTime	forKey:@"pulseHighTime"];
	[encoder encodeInt:pulseLowTime		forKey:@"pulseLowTime"];
	[encoder encodeInt:pulserMask		forKey:@"pulserMask"];
	[encoder encodeObject:dacs			forKey:@"dacs"];
	[encoder encodeObject:amplitudes	forKey:@"amplitudes"];
	[encoder encodeObject:adcs			forKey:@"adcs"];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];
    [objDictionary setObject:NSStringFromClass([self class]) forKey:@"Class Name"];
    [objDictionary setObject:[NSNumber numberWithInt:[self uniqueIdNumber]] forKey:@"preampID"];
    
    [dictionary setObject:objDictionary forKey:[self identifier]];
    return objDictionary;
}

#pragma mark ¥¥¥Data Records
- (unsigned long) dataId					{ return dataId;   }
- (void) setDataId: (unsigned long) DataId	{ dataId = DataId; }
- (void) setDataIds:(id)assigner			{ dataId = [assigner assignDataIds:kLongForm]; }
- (void) syncDataIdsWith:(id)anotherTPG262	{ [self setDataId:[anotherTPG262 dataId]]; }

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"MJDPreAmpModel"];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORMJDPreAmpDecoderForAdc",						@"decoder",
								 [NSNumber numberWithLong:dataId],					@"dataId",
								 [NSNumber numberWithBool:NO],						@"variable",
								 [NSNumber numberWithLong:kMJDPreAmpDataRecordLen],	@"length",
								 nil];
	
    [dataDictionary setObject:aDictionary forKey:@"Adcs"];
    
    return dataDictionary;
}

- (void) shipRecords
{
	
    if([[ORGlobal sharedGlobal] runInProgress]){
		
		unsigned long data[kMJDPreAmpDataRecordLen];
		
		data[0] = dataId | kMJDPreAmpDataRecordLen;
		data[1] = [self uniqueIdNumber]&0xfff;
		data[2] = timeMeasured[0];
		data[3] = timeMeasured[1];
		data[4] = adcEnabledMask;
		
		union {
			float asFloat;
			unsigned long asLong;
		} theData;
		
		int index = 5;
		int i;
		for(i=0;i<kMJDPreAmpDacChannels;i++){
			theData.asFloat = [self adc:i];
			data[index]     = theData.asLong;
			index++;
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName: ORQueueRecordForShippingNotification 
															object: [NSData dataWithBytes:data length:sizeof(long)*kMJDPreAmpDataRecordLen]];
	}
}

@end
