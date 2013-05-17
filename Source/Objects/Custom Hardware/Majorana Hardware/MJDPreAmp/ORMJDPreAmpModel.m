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
#import "ORTimeRate.h"
#import "ORAlarm.h"

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
NSString* ORMJDFeedBackResistorArrayChanged = @"ORMJDFeedBackResistorArrayChanged";
NSString* ORMJDBaselineVoltageArrayChanged  = @"ORMJDBaselineVoltageArrayChanged";
NSString* ORMJDFeedBackResistorChanged      = @"ORMJDFeedBackResistorChanged";
NSString* ORMJDBaselineVoltageChanged		= @"ORMJDBaselineVoltageChanged";


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

#define kADCRange10Reg1		0x00A00000
#define kADCRange5Reg1		0x00AAA000
//#define kADCRange2_5Reg1	0x00BA40
#define kADCRange2_5Reg1	0x00B54000 // niko

#define kADCRange10Reg2		0x00C00000
#define kADCRange5Reg2		0x00CAA000
//#define kADCRange2_5Reg2	0x00DA40
#define kADCRange2_5Reg2	0x00D54000 // niko


#define kReadAdcChannel0 0x00801000 // 8 single-ended inputs mode
#define kReadAdcChannel1 0x00841000
#define kReadAdcChannel2 0x00881000
#define kReadAdcChannel3 0x008C1000
#define kReadAdcChannel4 0x00901000
#define kReadAdcChannel5 0x00941000
#define kReadAdcChannel6 0x00981000
#define kReadAdcChannel7 0x009C1000

#define kReadTempChannel7 0x009F1000 // 7 pseudo-differential inputs mode, temperature read out from channel 7 - niko


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
	int i;
	for(i=0;i<16;i++){
		[timeRates[i] release];
	}
    for(i=0;i<2;i++){
        [temperatureAlarm[i] clearAlarm];
        [temperatureAlarm[i] release];
    }
    for(i=0;i<2;i++){
        [adcAlarm[i] clearAlarm];
        [adcAlarm[i] release];
    }
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
		for(i=0;i<kMJDPreAmpAdcChannels;i++){
			[adcs addObject:[NSNumber numberWithInt:0]];
		}	
	}
    if(!feedBackResistors){
		[self setFeedBackResistors:[NSMutableArray arrayWithCapacity:kMJDPreAmpAdcChannels]];
		int i;
		for(i=0;i<kMJDPreAmpAdcChannels;i++){
			[feedBackResistors addObject:[NSNumber numberWithInt:0]];
		}
	}
    if(!baselineVoltages){
		[self setBaselineVoltages:[NSMutableArray arrayWithCapacity:kMJDPreAmpAdcChannels]];
		int i;
		for(i=0;i<kMJDPreAmpAdcChannels;i++){
			[baselineVoltages addObject:[NSNumber numberWithInt:0]];
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
- (ORTimeRate*)timeRate:(int)index
{
	return timeRates[index];
}

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

- (NSMutableArray*) feedBackResistors
{
    return feedBackResistors;
}
- (void) setFeedBackResistors:(NSMutableArray*)anArray
{
    [anArray retain];
    [feedBackResistors release];
    feedBackResistors = anArray;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDFeedBackResistorArrayChanged object:self];

}
- (float) feedBackResistor:(unsigned short) aChan
{
    if(aChan<[feedBackResistors count]){
        return [[feedBackResistors objectAtIndex:aChan] floatValue];
	}
	else return 0.0;

}
- (void) setFeedBackResistor:(int) aChan value:(float) aValue
{
    if(aChan<[feedBackResistors count]){
		[[[self undoManager] prepareWithInvocationTarget:self] setFeedBackResistor:aChan value:[self feedBackResistor:aChan]];
		[feedBackResistors replaceObjectAtIndex:aChan withObject:[NSNumber numberWithFloat:aValue]];
        
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithFloat:aChan] forKey: @"Channel"];
        
 		[[NSNotificationCenter defaultCenter] postNotificationName:ORMJDFeedBackResistorChanged
															object:self
														  userInfo: userInfo];
       
	}

}
- (NSMutableArray*) baselineVoltages
{
    return baselineVoltages;

}
- (void) setBaselineVoltages:(NSMutableArray*)anArray
{
    [anArray retain];
    [baselineVoltages release];
    baselineVoltages = anArray;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDBaselineVoltageArrayChanged object:self];
  
}
- (float) baselineVoltage:(unsigned short) aChan
{
    if(aChan<[baselineVoltages count]){
        return [[baselineVoltages objectAtIndex:aChan] floatValue];
	}
	else return 0.0;
 
}
- (void) setBaselineVoltage:(int) aChan value:(float) aValue
{
    if(aChan<[baselineVoltages count]){
		[[[self undoManager] prepareWithInvocationTarget:self] setBaselineVoltage:aChan value:[self baselineVoltage:aChan]];
		[baselineVoltages replaceObjectAtIndex:aChan withObject:[NSNumber numberWithFloat:aValue]];
        
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithFloat:aChan] forKey: @"Channel"];
        
 		[[NSNotificationCenter defaultCenter] postNotificationName:ORMJDBaselineVoltageChanged
															object:self
														  userInfo: userInfo];
        
	}
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

        if(timeRates[aChan] == nil) timeRates[aChan] = [[ORTimeRate alloc] init];
		[timeRates[aChan] addDataToTimeAverage:aValue];

        
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

- (void) writeAdcChipRanges
{
	//[self writeRangeForAdcChip:0];
	//[self writeRangeForAdcChip:1];
    [self writeRangeForAdcChip:0 withValue:0]; // 10V range by default - niko
	[self writeRangeForAdcChip:1 withValue:0];
}

//- (void) writeRangeForAdcChip:(int)index - niko
- (void) writeRangeForAdcChip:(int)aChip withValue:(int)index
{
	//if(index>=0 && index<2){
    if(index>=0 && index<3){
        
        unsigned long rangeValue[2][3] = {
	  		{kADCRange10Reg1, kADCRange5Reg1, kADCRange2_5Reg1},
	  		{kADCRange10Reg2, kADCRange5Reg2, kADCRange2_5Reg2}
	  	};
		unsigned long adcBase[2] = {kADC1, kADC2};
		
		//unsigned long aValue = adcBase[index] | rangeValue[index][adcRange[index]];
        unsigned long aValue = adcBase[aChip] | rangeValue[0][index]; // first register on chip
        [self writeAuxIOSPI:aValue];
        
        aValue = adcBase[aChip] | rangeValue[1][index]; // second register on chip
        [self writeAuxIOSPI:aValue];
    }
}

- (void) readAllAdcs
{
    [self readAllAdcs:NO];
}

- (void) readAllAdcs:(BOOL)verbose
{
	[self readAdcsOnChip:0 verbose:verbose];
	[self readAdcsOnChip:1 verbose:verbose];
}

- (void) readAdcsOnChip:(int)aChip verbose:(BOOL)verbose
{
    if(aChip<0 || aChip>1) return;
    
    //[self writeRangeForAdcChip:aChip ];
    [self writeRangeForAdcChip:aChip withValue:0]; // use 10V range for baseline values
    
    //float voltageMultiplier = 10./pow(2.,adcRange[aChip]+12); 
    float voltageBase = 20./pow(2.,13); // 13 bits ADC, hardcoded 10V range - niko
    
    float voltageMultiplier = 2.; // account for voltage multiplier of 2 for +/-12V hard wired on ADC chip 1 and for first five channels of both ADC chips - niko
    
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
            
			readBack = ~readBack;
			int channelReadBack = (readBack & 0xE000) >> 13;
 
			if(channelReadBack != i) {
			  NSLog(@"Warning! channelReadBack = %d, not %d\n", channelReadBack, i);
			}

			if(aChip && (channelReadBack == 5 || channelReadBack == 6)){ // account for voltage multiplier of 4 for +/-24V - niko
			  voltageMultiplier *= 2.;
			}

			int voltage = readBack & 0xfff;
			if(readBack & 0x1000) voltage |= 0xfffff000;

			if(verbose)NSLog(@"Read voltage %f*%f*%d=%f on channel %d, for baseline %f and Rf %f\n", voltageBase, voltageMultiplier, voltage, voltageBase*voltageMultiplier*voltage, channelReadBack, [self baselineVoltage:((aChip*8)+channelReadBack)], [self feedBackResistor:((aChip*8)+channelReadBack)]);
            
			[self setAdc:(aChip*8)+i value:voltageBase*voltageMultiplier*voltage];
            
            [self checkAdcIsWithinLimits:(aChip*8)+i value:voltageBase*voltageMultiplier*voltage];
            
			voltageMultiplier = 2.;

		}
		else [self setAdc:(aChip*8)+i value:0.0];
	}
    
    
    
	
	//get the time(UT!) for the data record. 
	time_t	ut_Time;
	time(&ut_Time);
	timeMeasured[aChip] = ut_Time;
}

- (void) readAllTemperatures
{
    [self readAllTemperatures:NO];
}

- (void) readAllTemperatures:(BOOL) verbose
{
	[self readTempOnChip:0 verbose:verbose];
	[self readTempOnChip:1 verbose:verbose];
}

- (void) readTempOnChip:(int)aChip verbose:(BOOL)verbose // read temperature on ADC chips - niko
{
    if(aChip<0 || aChip>1) return;
    
    [self writeRangeForAdcChip:aChip withValue:2]; // use 2.5V range for temperatures

    unsigned long adcBase = kADC1;
    if(aChip) adcBase = kADC2;

    unsigned long channelSelect = kReadTempChannel7;

    unsigned long readBack;
    
    if(adcEnabledMask&(0x1<<((aChip*8)+7))){
        
        int j;
        for(j=0;j<4;j++) readBack = [self writeAuxIOSPI:adcBase | channelSelect];
        
        //readBack = [self writeAuxIOSPI:adcBase | channelSelect];
        //sleep(1);
        //readBack = [self writeAuxIOSPI:adcBase | channelSelect];
        //readBack = [self writeAuxIOSPI:adcBase | channelSelect];
        //readBack = [self writeAuxIOSPI:adcBase | channelSelect];

        readBack = ~readBack;
        int channelReadBack = (readBack & 0xE000) >> 13;
        
        if(channelReadBack != 7){
            NSLog(@"Warning! channelReadBack = %d, not %d\n", channelReadBack, 7);
        }
        
        int tempCode = readBack & 0xfff;
        if(readBack & 0x1000) tempCode |= 0xfffff000;

        
        tempCode += pow(2.,12); // not sure about that, but seems to work - niko

        
        // rough temperature-code calibration from curve in doc for 10V range
        //int tempMinCode = 4350;
        //int tempZeroCode = 4395;
        //float tempMaxValue = 80.;
        // rough temperature-code calibration from curve in doc for 2.5V range
        int tempMinCode = 5140;
        int tempZeroCode = 5320;
        float tempMaxValue = 80.;
        
        float tempOnChip = tempMaxValue - (tempCode - tempMinCode)*tempMaxValue/(tempZeroCode - tempMinCode);
        
        
        if(verbose) NSLog(@"chip %d, raw temp %d, temp %f on channel %d\n", aChip, tempCode, tempOnChip, channelReadBack);
        
        [self setAdc:(aChip*8)+7 value:tempOnChip];
        [self checkTempIsWithinLimits:aChip value:tempOnChip];
    }
    
    //get the time(UT!) for the data record.
	time_t	ut_Time;
	time(&ut_Time);
	timeMeasured[aChip] = ut_Time;
}


- (void) pollValues
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollValues) object:nil];
	[self readAllAdcs];
	if(shipValues)[self shipRecords];
	if(pollTime)[self performSelector:@selector(pollValues) withObject:nil afterDelay:pollTime];

	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollValues) object:nil];
	[self readAllTemperatures];
	if(shipValues)[self shipRecords];
	if(pollTime)[self performSelector:@selector(pollValues) withObject:nil afterDelay:pollTime];
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
    [self setFeedBackResistors:	[decoder decodeObjectForKey: @"feedBackResistors"]];
    [self setBaselineVoltages:	[decoder decodeObjectForKey: @"baselineVoltages"]];
	
    if(!dacs || !amplitudes || !feedBackResistors || !baselineVoltages)	[self setUpArrays];

    for(i=0;i<16;i++)timeRates[i] = [[ORTimeRate alloc] init];

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
	[encoder encodeObject:feedBackResistors			forKey:@"feedBackResistors"];
	[encoder encodeObject:baselineVoltages			forKey:@"baselineVoltages"];
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


#pragma mark ¥¥¥Alarms
- (void) checkTempIsWithinLimits:(int)aChip value:(float)aTemperature
{
    float maxAllowedTemperature = 50; //<<-Nikko, set this or make a dialog field for it
    if(aChip>=0 && aChip<2){
        if(aTemperature >= maxAllowedTemperature){
 			if(!temperatureAlarm[aChip]){
				temperatureAlarm[aChip] = [[ORAlarm alloc] initWithName:[NSString stringWithFormat:@"Preamp %lu Temperature",[self uniqueIdNumber]] severity:kRangeAlarm];
                [temperatureAlarm[aChip] setHelpString:[NSString stringWithFormat:@"Preamp %lu has exceeded %.1f C. This alarm will be in effect until the temperature returns to normal limits. It can be silenced by acknowledging it.",[self uniqueIdNumber],maxAllowedTemperature]];
				[temperatureAlarm[aChip] setSticky:YES];
			}
			[temperatureAlarm[aChip] postAlarm];
        }
        else {
            [temperatureAlarm[aChip] clearAlarm];
			[temperatureAlarm[aChip] release];
			temperatureAlarm[aChip] = nil;
        }
    }
}

- (void) checkAdcIsWithinLimits:(int)anIndex value:(float)aValue
{
    if(anIndex != 5 || anIndex!=6 || anIndex!= 13 || anIndex!= 14)return;
    
    BOOL postAlarm = NO;
    NSString* alarmName;
    int alarmIndex = -1;
    if(anIndex == 5){
        alarmIndex = 0;
        if(fabs(aValue - 12) >= 0.5){ //<---Niko, adjust this or make a dialog field 
            alarmName  = [NSString stringWithFormat:@"Preamp %lu +12V Supply",[self uniqueIdNumber]];
            postAlarm  = YES;
        }
    }
    else if(anIndex == 6){
        alarmIndex = 1;
        if(fabs(aValue - 12) >= 0.5){ //<---Niko, adjust this or make a dialog field
            alarmName = [NSString stringWithFormat:@"Preamp %lu -12V Supply",[self uniqueIdNumber]];
            postAlarm  = YES;
        }
    }
    else if(anIndex == 13){
        alarmIndex = 2;
        if(fabs(aValue - 24) >= 0.5){ //<---Niko, adjust this or make a dialog field
            alarmName = [NSString stringWithFormat:@"Preamp %lu +24V Supply",[self uniqueIdNumber]];
            postAlarm  = YES;
        }
    }
    else if(anIndex == 14){
        alarmIndex = 3;
        if(fabs(aValue - 24) >= 0.5){ //<---Niko, adjust this or make a dialog field
            alarmName = [NSString stringWithFormat:@"Preamp %lu -24V Supply",[self uniqueIdNumber]];
            postAlarm  = YES;
        }
    }
    
    if(alarmIndex>=0 && alarmIndex<4){
        if(postAlarm){
 			if(!adcAlarm[alarmIndex]){
				adcAlarm[alarmIndex] = [[ORAlarm alloc] initWithName:alarmName severity:kRangeAlarm];
                [adcAlarm[alarmIndex] setHelpString:[NSString stringWithFormat:@"Preamp %lu adc value exceeded limits. This alarm will be in effect until the adc value returns to normal limits. It can be silenced by acknowledging it.",[self uniqueIdNumber]]];
				[adcAlarm[alarmIndex] setSticky:YES];
			}
			[adcAlarm[alarmIndex] postAlarm];
        }
        else {
            [adcAlarm[alarmIndex] clearAlarm];
			[adcAlarm[alarmIndex] release];
			adcAlarm[alarmIndex] = nil;
            
        }
    }

}
@end
