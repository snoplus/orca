//
//  ORFec32Model.h
//  Orca
//
//  Created by Mark Howe on Wed Oct 15,2008.
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
#import "ORFec32Model.h"
#import "ORXL1Model.h"
#import "ORXL2Model.h"
#import "ORSNOCrateModel.h"
#import "ORFecDaughterCardModel.h"
#import "ORSNOConstants.h"
#import "OROrderedObjManager.h"
#import "ObjectFactory.h"
#import "ORSNOCrateModel.h"
#import "ORVmeReadWriteCommand.h"
#import "ORCommandList.h"

//#define VERIFY_CMOS_SHIFT_REGISTER	// uncomment this to verify CMOS shift register loads - PH 09/17/99

// the bottom 16 and upper 16 FEC32 channels
#define BOTTOM_CHANNELS	0
#define UPPER_CHANNELS	1


NSString* ORFec32ModelCmosReadDisabledMaskChanged	= @"ORFec32ModelCmosReadDisabledMaskChanged";
NSString* ORFec32ModelCmosRateChanged				= @"ORFec32ModelCmosRateChanged";
NSString* ORFec32ModelBaseCurrentChanged			= @"ORFec32ModelBaseCurrentChanged";
NSString* ORFec32ModelVariableDisplayChanged		= @"ORFec32ModelVariableDisplayChanged";
NSString* ORFecShowVoltsChanged						= @"ORFecShowVoltsChanged";
NSString* ORFecCommentsChanged						= @"ORFecCommentsChanged";
NSString* ORFecCmosChanged							= @"ORFecCmosChanged";
NSString* ORFecVResChanged							= @"ORFecVResChanged";
NSString* ORFecHVRefChanged							= @"ORFecHVRefChanged";
NSString* ORFecLock									= @"ORFecLock";
NSString* ORFecOnlineMaskChanged					= @"ORFecOnlineMaskChanged";
NSString* ORFecPedEnabledMaskChanged				= @"ORFecPedEnabledMaskChanged";
NSString* ORFecSeqDisabledMaskChanged				= @"ORFecSeqDisabledMaskChanged";
NSString* ORFecTrigger100nsDisabledMaskChanged		= @"ORFecTrigger100nsDisabledMaskChanged";
NSString* ORFecTrigger20nsDisabledMaskChanged		= @"ORFecTrigger20nsDisabledMaskChanged";
NSString* ORFecQllEnabledChanged					= @"ORFecQllEnabledChanged";
NSString* ORFec32ModelAdcVoltageChanged				= @"ORFec32ModelAdcVoltageChanged";
NSString* ORFec32ModelAdcVoltageStatusChanged		= @"ORFec32ModelAdcVoltageStatusChanged";
NSString* ORFec32ModelAdcVoltageStatusOfCardChanged	= @"ORFec32ModelAdcVoltageStatusOfCardChanged";

@interface ORFec32Model (private)
- (ORCommandList*) cmosShiftLoadAndClock:(unsigned short) registerAddress cmosRegItem:(unsigned short) cmosRegItem bitMaskStart:(short) bit_mask_start;
- (void) cmosShiftLoadAndClockBit3:(unsigned short) registerAddress cmosRegItem:(unsigned short) cmosRegItem bitMaskStart:(short) bit_mask_start;
- (void) loadCmosShiftRegData:(unsigned short)whichChannels triggersDisabled:(BOOL)aTriggersDisabled;
- (void) loadCmosShiftRegisters:(BOOL) aTriggersDisabled;
@end

@interface ORFec32Model (SBC)
- (void) loadAllDacsUsingSBC;
- (NSString*) performBoardIDReadUsingSBC:(short) boardIndex;
@end

@interface ORFec32Model (LocalAdapter)
- (void) loadAllDacsUsingLocalAdapter;
- (NSString*) performBoardIDReadUsingLocalAdapter:(short) boardIndex;
@end

@implementation ORFec32Model

#pragma mark •••Initialization
- (id) init //designated initializer
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
	[self setComments:@""];
    [[self undoManager] enableUndoRegistration];
    
    return self;
}
- (void) dealloc
{
    [comments release];
    [super dealloc];
}

- (void) objectCountChanged
{
	int i;
	for(i=0;i<4;i++){
		dcPresent[i] =  NO;
		dc[i] = nil;
	}
	
	id aCard;
	NSEnumerator* e = [self objectEnumerator];
	while(aCard = [e nextObject]){
		if([aCard isKindOfClass:[ORFecDaughterCardModel class]]){
			dcPresent[[(ORFecDaughterCardModel*)aCard slot]] = YES;
			dc[[(ORFecDaughterCardModel*)aCard slot]] = aCard;
		}
	}
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"Fec32 (%d,%d)",[self crateNumber],[self stationNumber]];
}

- (NSComparisonResult)	slotCompare:(id)otherCard
{
    return [self stationNumber] - [otherCard stationNumber];
}

#pragma mark ***Accessors

- (unsigned long) cmosReadDisabledMask;
{
    return cmosReadDisabledMask;
}

- (void) setCmosReadDisabledMask:(unsigned long)aCmosReadDisabledMask;
{
    cmosReadDisabledMask = aCmosReadDisabledMask;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORFec32ModelCmosReadDisabledMaskChanged object:self];
}

- (BOOL) cmosReadDisabled:(short)aChannel
{
	return (cmosReadDisabledMask & (1<aChannel))!=0;
}

- (long) cmosRate:(short)index
{
    return cmosRate[index];
}

- (void) setCmosRate:(short)index withValue:(long)aCmosRate
{
    cmosRate[index] = aCmosRate;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORFec32ModelCmosRateChanged object:self];
}

- (float) baseCurrent:(short)index
{
    return baseCurrent[index];
}

- (void) setBaseCurrent:(short)index withValue:(float)aBaseCurrent
{
    baseCurrent[index] = aBaseCurrent;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORFec32ModelBaseCurrentChanged object:self];
}

- (int) variableDisplay
{
    return variableDisplay;
}

- (void) setVariableDisplay:(int)aVariableDisplay
{
    [[[self undoManager] prepareWithInvocationTarget:self] setVariableDisplay:variableDisplay];
    
    variableDisplay = aVariableDisplay;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORFec32ModelVariableDisplayChanged object:self];
}

- (float) adcVoltage:(int)index
{
	if(index>=0 && index<kNumFecMonitorAdcs) return adcVoltage[index];
	else return -1;
}

- (void) setAdcVoltage:(int)index withValue:(float)aValue
{
	if(index>=0 && index<kNumFecMonitorAdcs){
		adcVoltage[index] = aValue;
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:index] forKey:@"index"];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORFec32ModelAdcVoltageChanged object:self userInfo:userInfo];
	}
}

- (eFecMonitorState) adcVoltageStatusOfCard
{
	return adcVoltageStatusOfCard;
}

- (void) setAdcVoltageStatusOfCard:(eFecMonitorState)aState
{
	adcVoltageStatusOfCard = aState;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORFec32ModelAdcVoltageStatusOfCardChanged object:self userInfo:nil];
}

- (eFecMonitorState) adcVoltageStatus:(int)index
{
	if(index>=0 && index<kNumFecMonitorAdcs) return adcVoltageStatus[index];
	else return kFecMonitorNeverMeasured;
}

- (void) setAdcVoltageStatus:(int)index withValue:(eFecMonitorState)aState
{
	if(index>=0 && index<kNumFecMonitorAdcs){
		adcVoltageStatus[index] = aState;
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:index] forKey:@"index"];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORFec32ModelAdcVoltageStatusChanged object:self userInfo:userInfo];
	}
}

- (BOOL) dcPresent:(unsigned short)index
{
	if(index<4)return dcPresent[index];
	else return NO;
}

- (BOOL) qllEnabled
{
	return qllEnabled;
}

- (void) setQllEnabled:(BOOL) state
{
    [[[self undoManager] prepareWithInvocationTarget:self] setQllEnabled:pedEnabledMask];
	qllEnabled = state;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORFecQllEnabledChanged object:self];
}

- (BOOL) pmtOnline:(unsigned short)index
{
	if(index<32) return [self dcPresent:index/8] && (onlineMask & (1L<<index));
	else return NO;
}

- (unsigned long) pedEnabledMask
{
	return pedEnabledMask;
}

- (void) setPedEnabledMask:(unsigned long) aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPedEnabledMask:pedEnabledMask];
    pedEnabledMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFecPedEnabledMaskChanged object:self];
	
}

- (unsigned long) seqDisabledMask
{
	return seqDisabledMask;
}

- (void) setSeqDisabledMask:(unsigned long) aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSeqDisabledMask:seqDisabledMask];
    seqDisabledMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFecSeqDisabledMaskChanged object:self];
	
}

- (BOOL) seqDisabled:(short)chan
{
	return (seqDisabledMask & (1<<chan))!=0;
}

- (BOOL) trigger20nsDisabled:(short)chan
{
	return (trigger20nsDisabledMask & (1<<chan))!=0;
}
- (void) setTrigger20ns:(short) chan disabled:(short)state
{
	if(state) trigger20nsDisabledMask |= (1<<chan);
	else      trigger20nsDisabledMask &= ~(1<<chan);
}

- (BOOL) trigger100nsDisabled:(short)chan
{
	return (trigger100nsDisabledMask & (1<<chan))!=0;
}
- (void) setTrigger100ns:(short) chan disabled:(short)state
{
	if(state) trigger100nsDisabledMask |= (1<<chan);
	else      trigger100nsDisabledMask &= ~(1<<chan);
}
- (unsigned long) trigger20nsDisabledMask
{
	return trigger20nsDisabledMask;
}

- (void) setTrigger20nsDisabledMask:(unsigned long) aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTrigger20nsDisabledMask:trigger20nsDisabledMask];
    trigger20nsDisabledMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFecTrigger20nsDisabledMaskChanged object:self];
}

- (unsigned long) trigger100nsDisabledMask
{
	return trigger100nsDisabledMask;
}

- (void) setTrigger100nsDisabledMask:(unsigned long) aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTrigger100nsDisabledMask:trigger100nsDisabledMask];
    trigger100nsDisabledMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFecTrigger100nsDisabledMaskChanged object:self];
}

- (unsigned long) onlineMask
{
	return onlineMask;
}

- (void) setOnlineMask:(unsigned long) aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setOnlineMask:onlineMask];
    onlineMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFecOnlineMaskChanged object:self];
	
}

- (int) globalCardNumber
{
	return ([guardian crateNumber] * 16) + [self stationNumber];
}

- (NSComparisonResult) globalCardNumberCompare:(id)aCard
{
	return [self globalCardNumber] - [aCard globalCardNumber];
}


- (BOOL) showVolts
{
    return showVolts;
}

- (void) setShowVolts:(BOOL)aShowVolts
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShowVolts:showVolts];
    
    showVolts = aShowVolts;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFecShowVoltsChanged object:self];
}

- (NSString*) comments
{
    return comments;
}

- (void) setComments:(NSString*)aComments
{
	if(!aComments) aComments = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setComments:comments];
    
    [comments autorelease];
    comments = [aComments copy];    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFecCommentsChanged object:self];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"Fec32Card"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORFec32Controller"];
}
- (unsigned char) cmos:(short)anIndex
{
	return cmos[anIndex];
}

- (void) setCmos:(short)anIndex withValue:(unsigned char)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCmos:anIndex withValue:cmos[anIndex]];
	cmos[anIndex] = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFecCmosChanged object:self];
}

- (float) vRes
{
	return vRes;
}

- (void) setVRes:(float)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setVRes:vRes];
	vRes = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFecVResChanged object:self];
}

- (float) hVRef
{
	return hVRef;
}

- (void) setHVRef:(float)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHVRef:hVRef];
	hVRef = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFecHVRefChanged object:self];
}

#pragma mark Converted Data Methods
- (void) setCmosVoltage:(short)n withValue:(float) value
{
	if(value>kCmosMax)		value = kCmosMax;
	else if(value<kCmosMin)	value = kCmosMin;
	
	[self setCmos:n withValue:255.0*(value-kCmosMin)/(kCmosMax-kCmosMin)+0.5];
}

- (float) cmosVoltage:(short) n
{
	return ((kCmosMax-kCmosMin)/255.0)*cmos[n]+kCmosMin;
}

- (void) setVResVoltage:(float) value
{
	if(value>kVResMax)		value = kVResMax;
	else if(value<kVResMin)	value = kVResMin;
	[self setVRes:255.0*(value-kVResMin)/(kVResMax-kVResMin)+0.5];
}

- (float) vResVoltage
{
	return ((kVResMax-kVResMin)/255.0)*vRes+kVResMin;
}

- (void) setHVRefVoltage:(float) value
{
	if(value>kHVRefMax)		 value = kHVRefMax;
	else if(value<kHVRefMin) value = kHVRefMin;
	[self setHVRef:(255.0*(value-kHVRefMin)/(kHVRefMax-kHVRefMin)+0.5)];
}

- (float) hVRefVoltage
{
	return ((kHVRefMax-kHVRefMin)/255.0)*hVRef+kHVRefMin;
}
//readVoltages
//read the voltage and temp adcs for a crate and card
//assumes that bus access has already been granted.
-(void) readVoltages
{	
	@try {
		
		[[self xl2] select:self];
		
		bool statusChanged = false;
		short whichADC;
		for(whichADC=0;whichADC<kNumFecMonitorAdcs;whichADC++){
			short theValue = [self readVoltageValue:fecVoltageAdc[whichADC].mask];
			eFecMonitorState old_channel_status = [self adcVoltageStatus:whichADC];
			eFecMonitorState new_channel_status;
			if( theValue != -1) {
				float convertedValue = ((float)theValue-128.0)*fecVoltageAdc[whichADC].multiplier;
				[self setAdcVoltage:whichADC withValue:convertedValue];
				if(fecVoltageAdc[whichADC].check_expected_value){
					float expected = fecVoltageAdc[whichADC].expected_value;
					float delta = fabs(expected*[[self xl1] adcAllowedError:whichADC]);
					if(fabs(convertedValue-expected) < delta)	new_channel_status = kFecMonitorInRange;
					else										new_channel_status = kFecMonitorOutOfRange;
				}
				else new_channel_status = kFecMonitorInRange;
			}
			else new_channel_status = kFecMonitorReadError;
			
			[self setAdcVoltageStatus:whichADC withValue:new_channel_status];
			
			if(old_channel_status != new_channel_status){
				statusChanged = true;
			}
		}
		if(statusChanged){
			//sync up the card status
			[self setAdcVoltageStatusOfCard:kFecMonitorInRange];
			short whichADC;
			for(whichADC=0;whichADC<kNumFecMonitorAdcs;whichADC++){
				if([self adcVoltageStatus:whichADC] == kFecMonitorReadError){
					[self setAdcVoltageStatusOfCard:kFecMonitorReadError];
					break;
				}
				else if([self adcVoltageStatus:whichADC] == kFecMonitorOutOfRange){
					[self setAdcVoltageStatusOfCard:kFecMonitorOutOfRange];
					break;
				}
				
			}
			
			//sync up the crate status
			[[self crate] setVoltageStatus: kFecMonitorInRange];
			unsigned short card;
			for(card=0;card<16;card++){
				if([self adcVoltageStatusOfCard] == kFecMonitorReadError){
					[[self crate] setVoltageStatus:kFecMonitorReadError];
					break;
				}
				else if([self adcVoltageStatusOfCard] == kFecMonitorOutOfRange){
					[[self crate] setVoltageStatus:kFecMonitorOutOfRange];
					break;
				}
			}
/*			//sync up the system status (TBD... 12/15/2008 MAH)
			theConfigDB->VoltageStatusOfSystem(kFecMonitorInRange);
			unsigned short crate;
			for(crate=0;crate<kNumSCs;crate++){
				if(theConfigDB->VoltageStatusOfCrate(theCrate)== kFecMonitorReadError){
					theConfigDB->VoltageStatusOfSystem(kFecMonitorReadError);
					break;
				}
				else if(theConfigDB->VoltageStatusOfCrate(theCrate) == kFecMonitorOutOfRange){
					theConfigDB->VoltageStatusOfSystem(kFecMonitorOutOfRange);
					break;
				}
			}
*/
			
		}
		
		
	}
	@catch(NSException* localException) {
		short whichADC;
		[self setAdcVoltageStatusOfCard:kFecMonitorReadError];
		for(whichADC=0;whichADC<kNumFecMonitorAdcs;whichADC++){
			[self setAdcVoltageStatus:whichADC withValue:kFecMonitorReadError];
		}
		[[self xl2] deselectCards];
	}
	[[self xl2] deselectCards];

	
}

const short kVoltageADCMaximumAttempts = 10;

-(short) readVoltageValue:(unsigned long) aMask
{
	short theValue = -1;
	
	@try {
		ORCommandList* aList = [ORCommandList commandList];
		
		// write the ADC mask keeping bits 14,15 high  i.e. CS,RD
		[aList addCommand: [self writeToFec32RegisterCmd:FEC32_VOLTAGE_MONITOR_REG value:aMask | 0x0000C000UL]];
		// write the ADC mask keeping bits 14,15 low -- this forces conversion
		[aList addCommand:[self delayCmd:0.001]];
		[aList addCommand: [self writeToFec32RegisterCmd:FEC32_VOLTAGE_MONITOR_REG value:aMask]];
		[aList addCommand:[self delayCmd:0.002]];
		int adcValueCmdIndex = [aList addCommand: [self readFromFec32RegisterCmd:FEC32_VOLTAGE_MONITOR_REG]];
		
		//MAH 8/30/99 leave the voltage register connected to a ground address.
		[aList addCommand: [self writeToFec32RegisterCmd:FEC32_VOLTAGE_MONITOR_REG value:groundMask | 0x0000C000UL]];
		[self executeCommandList:aList];
	
		//pull out the result
		unsigned long adcReadValue = [aList longValueForCmd:adcValueCmdIndex];
		if(adcReadValue & 0x100UL){
			theValue = adcReadValue & 0x000000ff; //keep only the lowest 8 bits.
		}
	}
	@catch(NSException* localException) {
	}

	
	return theValue;
}

#pragma mark •••Archival
- (id) initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
	
    [self setCmosReadDisabledMask:	[decoder decodeInt32ForKey:	@"cmosReadDisabledMask;"]];
    [self setVariableDisplay:		[decoder decodeIntForKey:	@"variableDisplay"]];
    [self setShowVolts:				[decoder decodeBoolForKey:  @"showVolts"]];
    [self setComments:				[decoder decodeObjectForKey:@"comments"]];
    [self setVRes:					[decoder decodeFloatForKey: @"vRes"]];
    [self setHVRef:					[decoder decodeFloatForKey: @"hVRef"]];
	[self setOnlineMask:			[decoder decodeInt32ForKey: @"onlineMask"]];
	[self setPedEnabledMask:		[decoder decodeInt32ForKey: @"pedEnableMask"]];
	[self setSeqDisabledMask:		[decoder decodeInt32ForKey: @"seqDisabledMask"]];
	[self setAdcVoltageStatusOfCard:[decoder decodeIntForKey:	@"adcVoltageStatusOfCard"]];
	int i;
	for(i=0;i<6;i++){
		[self setCmos:i withValue: [decoder decodeFloatForKey: [NSString stringWithFormat:@"cmos%d",i]]];
	}	
	for(i=0;i<kNumFecMonitorAdcs;i++){
		[self setAdcVoltage:i withValue: [decoder decodeFloatForKey: [NSString stringWithFormat:@"adcVoltage%d",i]]];
		[self setAdcVoltageStatus:i withValue: (eFecMonitorState)[decoder decodeIntForKey: [NSString stringWithFormat:@"adcStatus%d",i]]];
	}
	for(i=0;i<32;i++){
		[self setCmosRate:i withValue:[decoder decodeInt32ForKey:		[NSString stringWithFormat:@"cmosRate%d",i]]];
		[self setBaseCurrent:i withValue:[decoder decodeFloatForKey:	[NSString stringWithFormat:@"baseCurrent%d",i]]];
	}
	[[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
	[super encodeWithCoder:encoder];
	
	[encoder encodeInt32:cmosReadDisabledMask	forKey: @"cmosReadDisabledMask;"];

	[encoder encodeInt:variableDisplay			forKey: @"variableDisplay"];
	[encoder encodeBool:showVolts				forKey: @"showVolts"];
	[encoder encodeObject:comments				forKey: @"comments"];
	[encoder encodeFloat:vRes					forKey: @"vRes"];
	[encoder encodeFloat:hVRef					forKey: @"hVRef"];
	[encoder encodeInt32:onlineMask				forKey: @"onlineMask"];
	[encoder encodeInt32:pedEnabledMask			forKey: @"pedEnabledMask"];
	[encoder encodeInt32:seqDisabledMask		forKey: @"seqDisabledMask"];
	[encoder encodeInt:adcVoltageStatusOfCard	forKey: @"adcVoltageStatusOfCard"];
	
	int i;
	for(i=0;i<6;i++){
		[encoder encodeFloat:cmos[i] forKey:[NSString stringWithFormat:@"cmos%d",i]];
	}	
	for(i=0;i<kNumFecMonitorAdcs;i++){
		[encoder encodeFloat:adcVoltage[i] forKey:[NSString stringWithFormat:@"adcVoltage%d",i]];
		[encoder encodeInt:adcVoltageStatus[i] forKey:[NSString stringWithFormat:@"adcStatus%d",i]];
	}
	for(i=0;i<32;i++){
		[encoder encodeInt32:cmosRate[i]			forKey: [NSString stringWithFormat:@"cmosRate%d",i]];
		[encoder encodeFloat:baseCurrent[i]			forKey: [NSString stringWithFormat:@"baseCurrent%d",i]];
	}
}
#pragma mark •••Hardware Access

- (id) adapter
{
	id anAdapter = [[self guardian] adapter]; //should be the XL2 for this objects crate
	if(anAdapter)return anAdapter;
	else [NSException raise:@"No XL2" format:@"Check that the crate has an XL2"];
	return nil;
}
- (id) xl1
{
	return [[self xl2] xl1];
}
- (id) xl2
{
	id anAdapter = [[self guardian] adapter]; //should be the XL2 for this objects crate
	if(anAdapter)return anAdapter;
	else [NSException raise:@"No XL2" format:@"Check that the crate has an XL2"];
	return nil;
}

- (void) readBoardIds
{
	id xl2 = [self xl2];
	@try {
		[xl2 select:self];
		
		// Read the Daughter Cards for their ids
		NSEnumerator* e = [self objectEnumerator];
		id aCard;
		while(aCard = [e nextObject]){
			if([aCard isKindOfClass:[ORSNOCard class]]){
				[aCard readBoardIds];
			}
		}	
		// Read the PMTIC for its id
		//PerformBoardIDRead(HV_BOARD_ID_INDEX,&dataValue);
		
		//read the Mother Card for its id
		@try {
			[self setBoardID:[self performBoardIDRead:MC_BOARD_ID_INDEX]];
		}
		@catch(NSException* localException) {
			[self setBoardID:@"0000"];	
			[localException raise];
		}
		[xl2 deselectCards];
	}
	@catch(NSException* localException) {
		[xl2 deselectCards];
		[localException raise];
	}
}

- (void) scan:(SEL)aResumeSelectorInGuardian 
{
	workingSlot = 0;
	working = YES;
	[self performSelector:@selector(scanWorkingSlot)withObject:nil afterDelay:0];
	resumeSelectorInGuardian = aResumeSelectorInGuardian;
}

- (void) scanWorkingSlot
{
	BOOL xl2OK = YES;
	@try {
		[[self xl2] selectCards:1L<<[self slot]];	
	}
	@catch(NSException* localException) {
		xl2OK = NO;
		NSLog(@"Unable to reach XL2 in crate: %d (Not inited?)\n",[self crateNumber]);
	}
	if(!xl2OK) working = NO;
	if(working) {
		@try {
			
			ORFecDaughterCardModel* proxyDC = [ObjectFactory makeObject:@"ORFecDaughterCardModel"];
			[proxyDC setGuardian:self];
			
			NSString* aBoardID = [proxyDC performBoardIDRead:workingSlot];
			if(![aBoardID isEqual: @"0000"]){
				NSLog(@"\tDC Slot: %d BoardID: %@\n",workingSlot,aBoardID);
				ORFecDaughterCardModel* theCard = [[OROrderedObjManager for:self] objectInSlot:workingSlot];
				if(!theCard){
					[self addObject:proxyDC];
					[self place:proxyDC intoSlot:workingSlot];
					theCard = proxyDC;
				}
				[theCard setBoardID:aBoardID];
			}
			else {
				NSLog(@"\tDC Slot: %d BoardID: BAD\n",workingSlot);
				ORFecDaughterCardModel* theCard = [[OROrderedObjManager for:self] objectInSlot:workingSlot];
				if(theCard)[self removeObject:theCard];
			}
		}
		@catch(NSException* localException) {
			NSLog(@"\tDC Slot: %d BoardID: ----\n",workingSlot);
			ORFecDaughterCardModel* theCard = [[OROrderedObjManager for:self] objectInSlot:workingSlot];
			if(theCard)[self removeObject:theCard];
		}
	}
	
	workingSlot++;
	if(working && (workingSlot<kNumSNODaughterCards)){
		[self performSelector:@selector(scanWorkingSlot) withObject:nil afterDelay:0];
	}
	else {
		[[self xl2] deselectCards];
		if(resumeSelectorInGuardian){
			[[self guardian] performSelector:resumeSelectorInGuardian withObject:nil afterDelay:0];
			resumeSelectorInGuardian = nil;

		}
	}
}

- (NSString*) performBoardIDRead:(short) boardIndex
{
	if([[self xl2] adapterIsSBC])	return [self performBoardIDReadUsingSBC:boardIndex];
	else				return [self performBoardIDReadUsingLocalAdapter:boardIndex];
}


- (void) executeCommandList:(ORCommandList*)aList
{
	[[self xl2] executeCommandList:aList];		
}

- (unsigned long) fec32RegAddress:(unsigned long)aRegOffset
{
	return [[self guardian] registerBaseAddress] + aRegOffset;
}

- (id) writeToFec32RegisterCmd:(unsigned long) aRegister value:(unsigned long) aBitPattern
{
	unsigned long theAddress = [self fec32RegAddress:aRegister];
	return [[self xl2] writeHardwareRegisterCmd:theAddress value:aBitPattern];		
}

- (id) readFromFec32RegisterCmd:(unsigned long) aRegister
{
	unsigned long theAddress = [self fec32RegAddress:aRegister];
	return [[self xl2] readHardwareRegisterCmd:theAddress]; 		
}

- (id) delayCmd:(unsigned long) milliSeconds
{
	return [[self xl2] delayCmd:milliSeconds]; 		
}
								
- (void) writeToFec32Register:(unsigned long) aRegister value:(unsigned long) aBitPattern
{
	unsigned long theAddress = [self fec32RegAddress:aRegister];
	[[self xl2] writeHardwareRegister:theAddress value:aBitPattern];		
}

- (unsigned long) readFromFec32Register:(unsigned long) aRegister
{
	unsigned long theAddress = [self fec32RegAddress:aRegister];
	return [[self xl2] readHardwareRegister:theAddress]; 		
}
- (unsigned long) readFromFec32Register:(unsigned long) aRegister offset:(unsigned long)anO
{
	unsigned long theAddress = [self fec32RegAddress:aRegister];
	return [[self xl2] readHardwareRegister:theAddress]; 		
}
- (void) setFec32RegisterBits:(unsigned long) aRegister bitMask:(unsigned long) bits_to_set
{
	//set some bits in a register without destroying other bits
	unsigned long old_value = [self readFromFec32Register:aRegister];
	unsigned long new_value = (old_value & ~bits_to_set) | bits_to_set;
	[self writeToFec32Register:aRegister value:new_value]; 		
}

- (void) clearFec32RegisterBits:(unsigned long) aRegister bitMask:(unsigned long) bits_to_clear
{
	//Clear some bits in a register without destroying other bits
	unsigned long old_value = [self readFromFec32Register:aRegister];
	unsigned long new_value = (old_value & ~bits_to_clear);
	[self writeToFec32Register:aRegister value:new_value]; 		
}


- (void) boardIDOperation:(unsigned long)theDataValue boardSelectValue:(unsigned long) boardSelectVal beginIndex:(short) beginIndex
{
	unsigned long writeValue = 0UL;
	// load and clock in the instruction code

	
	ORCommandList* aList = [ORCommandList commandList];
	short index;
	for (index = beginIndex; index >= 0; index--){
		if ( theDataValue & (1U << index) ) writeValue = (boardSelectVal | BOARD_ID_DI);
		else								writeValue = boardSelectVal;
		[aList addCommand: [self writeToFec32RegisterCmd:FEC32_BOARD_ID_REG value:writeValue]];					// load data value
		[aList addCommand: [self writeToFec32RegisterCmd:FEC32_BOARD_ID_REG value:(writeValue | BOARD_ID_SK)]];	// now clock in value
	}
	[self executeCommandList:aList];
}

- (void) autoInit
{
	@try {
		
		[self readBoardIds];	//Find out if the HW is there...
		if(![boardID isEqualToString:@"0000"]  && ![boardID isEqualToString:@"FFFF"]){
			[self setOnlineMask:0xFFFFFFFF];
		}
		
		//Do standard Board Init Things
		[self fullResetOfCard];
		[self loadAllDacs];
		//LoadCmosShiftRegisters(true); //always disable TR20 and TR100 on autoinit - as per JFW instructions 07/23/98 PH
		[self setPedestals];			// set up the hardware according to the ConfigDB	//MAH 3/22/98
		[self performPMTSetup:YES];		// now setup the PMT's wrt online/offline status - added 8/20/98 PMT
		
	}
	@catch(NSException* localException) {	
		// set the flags for the off-line status
		//theConfigDB -> SlotOnline(GetTheSnoCrateNumber(),itsFec32SlotNumber,FALSE);
		[self setOnlineMask:0x00000000];
		@throw;
	}
}

- (void) initTheCard:(BOOL) flgAutoInit
{
	@try {
		
		[self setOnlineMask:0xFFFFFFFF];
		//Do standard Board Init Things
		[self fullResetOfCard];
		[self loadAllDacs];
		//LoadCmosShiftRegisters(true); //always disable TR20 and TR100 on autoinit - as per JFW instructions 07/23/98 PH
		[self setPedestals];			// set up the hardware according to the ConfigDB	//MAH 3/22/98
		[self performPMTSetup:flgAutoInit?YES:NO];		// now setup the PMT's wrt online/offline status - added 8/20/98 PMT
		
	}
	@catch(NSException* localException) {	
		// set the flags for the off-line status
		//theConfigDB -> SlotOnline(GetTheSnoCrateNumber(),itsFec32SlotNumber,FALSE);
		[self setOnlineMask:0x00000000];
		@throw;
	}
}


- (void) fullResetOfCard
{	
	@try {
		[[self xl2] select:self];
		[self setFec32RegisterBits:FEC32_GENERAL_CS_REG bitMask:FEC32_CSR_FULL_RESET]; // STEP 1: Master Reset the FEC32
		[self loadCrateAddress];													// STEP 2: Perform load of crate address
		
		// additional effect is to disable all the triggers
		short i;
		for(i=0;i<32;i++) {
			//theConfigDB->Pmt20nsTriggerDisabled(itsSNOCrate->Get_SC_Number(),itsFec32SlotNumber,i,true);
			//theConfigDB->Pmt100nsTriggerDisabled(itsSNOCrate->Get_SC_Number(),itsFec32SlotNumber,i,true);
		}
		
	}
	@catch(NSException* localException) {
		[[self xl2] deselectCards];
		NSLog(@"Failure during full reset of FEC32 (%d,%d).\n", [self crateNumber], [self stationNumber]);	
		@throw;
	}		
}

- (void) loadCrateAddress
{
	@try {	
		[[self xl2] select:self];
		unsigned long theOldCSRValue = [self readFromFec32Register:FEC32_GENERAL_CS_REG];
		// create new crate number in proper bit positions
		unsigned long crateNumber = (unsigned long) ( ( [self crateNumber] << FEC32_CSR_CRATE_BITSIFT ) & FEC32_CSR_CRATE_ADD );
		// clear old crate number, then mask in new.
		unsigned long theNewCSRValue = crateNumber | (theOldCSRValue & ~FEC32_CSR_CRATE_ADD);
		[self writeToFec32Register:FEC32_GENERAL_CS_REG value:theNewCSRValue];
		[[self xl2] deselectCards];
	}
	@catch(NSException* localException) {
		[[self xl2] deselectCards];
		NSLog(@"Failure during load of crate address on FEC32 Crate %d Slot %d.", [self crateNumber], [self stationNumber]);	
		@throw;
	}
}

- (void) resetFifo
{
	BOOL selected = NO;
	@try {	
		[[self xl2] select:self];
		selected = YES;
		//Reset the fifo 
		unsigned long theSequencerDisableMask = 0;
		//set the specified offline channels to max threshold
		short chan;
		for(chan=0;chan<32;chan++){
			//set up a sequencer disable mask, all chan that are offline and have the sequencer disable bit set.
			if([self seqDisabled:chan]) {
				theSequencerDisableMask |= (1UL<<chan); 
			}
			
		}	
		
		ORCommandList* aList = [ORCommandList commandList];
		[aList addCommand: [self writeToFec32RegisterCmd:FEC32_CMOS_CHIP_DISABLE_REG value:0xFFFFFFFFUL]];
		[aList addCommand: [self writeToFec32RegisterCmd:FEC32_GENERAL_CS_REG value:FEC32_CSR_FIFO_RESET]];
		[aList addCommand: [self writeToFec32RegisterCmd:FEC32_GENERAL_CS_REG value:FEC32_CSR_ZERO]];
		[aList addCommand: [self writeToFec32RegisterCmd:FEC32_CMOS_CHIP_DISABLE_REG value:theSequencerDisableMask]];
		[self executeCommandList:aList];
		
		[self loadCrateAddress]; 
	}
	@catch(NSException* localException) {
		if(!selected){
			NSLog(@"Could not select the XL2 for FEC32 Crate %d!\n", [self crateNumber]);	
		}
		else {
			[[self xl2] deselectCards];
			NSLog(@"Failure during fifo reset of FEC32 (%d,%d)/n",[self crateNumber], [self stationNumber]);	
		}
		@throw;
	}
}

// ResetFec32Cmos : Reset the CMOS chips on the mother card
- (void) resetCmos
{
	BOOL selected = NO;
	@try {	
		[[self xl2] select:self];
		selected = YES;
				
		//Reset the FEC32 cmos chips
		[self setFec32RegisterBits:FEC32_GENERAL_CS_REG bitMask:FEC32_CSR_CMOS_RESET];
		[self clearFec32RegisterBits:FEC32_GENERAL_CS_REG bitMask:FEC32_CSR_CMOS_RESET];
		
		// additional effect is to disable all the triggers
		[self setTrigger20nsDisabledMask:0xFFFFFFFF];
		[self setTrigger100nsDisabledMask:0xFFFFFFFF];
		
	}
	@catch(NSException* localException) {
		if(!selected){
			NSLog(@"Could not select the XL2 for FEC32 Crate %d!\n", [self crateNumber]);	
		}
		else {
			[[self xl2] deselectCards];
			NSLog(@"Failure during CMOS reset of FEC32 (%d,%d)/n",[self crateNumber], [self stationNumber]);	
		}
		@throw;
	}
}

- (void) resetSequencer
{
	BOOL selected = NO;
	@try {	
		[[self xl2] select:self];
		selected = YES;
		
		//Reset the FEC32 cmos chips
		[self setFec32RegisterBits:FEC32_GENERAL_CS_REG bitMask:FEC32_CSR_SEQ_RESET];
		[self clearFec32RegisterBits:FEC32_GENERAL_CS_REG bitMask:FEC32_CSR_SEQ_RESET];
	}
	@catch(NSException* localException) {
		if(!selected){
			NSLog(@"Could not select the XL2 for FEC32 Crate %d!\n", [self crateNumber]);	
		}
		else {
			[[self xl2] deselectCards];
			NSLog(@"Failure during Sequencer reset of FEC32 (%d,%d)/n",[self crateNumber], [self stationNumber]);	
		}
		@throw;
	}
}


- (void) loadAllDacs
{
	
	if([[self xl2] adapterIsSBC])	[self loadAllDacsUsingSBC];
	else				[self loadAllDacsUsingLocalAdapter];
}


- (void) setPedestals
{
	@try {
		[[self xl2] select:self];
		[self writeToFec32Register:FEC32_PEDESTAL_ENABLE_REG value:pedEnabledMask];
		[[self xl2] deselectCards];
	}
	@catch(NSException* localException) {
		[[self xl2] deselectCards];
		NSLog(@"Failure during Pedestal set of FEC32(%d,%d).\n", [self crateNumber], [self stationNumber]);			
		
	}	
	
}

-(void) performPMTSetup:(BOOL) aTriggersDisabled
{
	@try {
		
		[[self xl2] select:self];
		
		[self writeToFec32Register:FEC32_CMOS_CHIP_DISABLE_REG value:seqDisabledMask];
		
		//MAH 7/2/98
		unsigned long value = [self readFromFec32Register:FEC32_CMOS_LGISEL_SET_REG];
		if(qllEnabled)	value |= 0x00000001;
		else			value &= 0xfffffffe;	// JR 1999/06/04 Changed from 0xfffffff7
		[self writeToFec32Register:FEC32_CMOS_LGISEL_SET_REG value:value];
		
		//do the triggers
		[self loadCmosShiftRegisters:aTriggersDisabled];
		[[self xl2] deselectCards];
		
		
	}
	@catch(NSException* localException) {
		[[self xl2] deselectCards];
		NSLog(@"Error during taking channel(s) off-line on  FEC32 (%d,%d)!", [self crateNumber], [self stationNumber]);	 
		@throw;
	}
}

- (float) readPmtCurrent:(short) aChannel
{
	float theAveCurrent = 0.0;	
	
	BOOL selected = NO;
	@try {	
		[[self xl2] select:self];
		selected = YES;
		
		ORCommandList* aList = [ORCommandList commandList];
		unsigned long word;
		//shift in the channel selection first 5 bits
		short aBit;
		for(aBit=4; aBit >=0 ; aBit--) {
		    if( (0x1UL << aBit) & aChannel ) word = HV_CSR_DATIN;
			else							 word = 0x0UL;
			[aList addCommand:[self writeToFec32RegisterCmd:FEC32_HVC_CS_REG value:word]];				// write data bit
			[aList addCommand:[self writeToFec32RegisterCmd:FEC32_HVC_CS_REG value:word | HV_CSR_CLK]];	// toggle clock
		}
		
		//shift 0's into the next 32 bits for a total of 37 bits
		for(aBit=31; aBit >= 0; aBit--) {
		    word = 0x0UL;
		   	[aList addCommand:[self writeToFec32RegisterCmd:FEC32_HVC_CS_REG value:word]];
		    [aList addCommand:[self writeToFec32RegisterCmd:FEC32_HVC_CS_REG value:word | HV_CSR_CLK]];   // toggle clock
		}
		
		// finally, toggle HVLOAD
		[aList addCommand:[self writeToFec32RegisterCmd:FEC32_HVC_CS_REG value:0]];
		[aList addCommand:[self writeToFec32RegisterCmd:FEC32_HVC_CS_REG value:HV_CSR_LOAD]];
		[self executeCommandList:aList];
		
		theAveCurrent = ((float)[self readVoltageValue:fecVoltageAdc[0].mask] - 128.0)*fecVoltageAdc[0].multiplier;
		[self setBaseCurrent:aChannel withValue:theAveCurrent];
	}
	@catch(NSException* localException) {
		if(!selected){
			NSLog(@"Could not select the XL2 for FEC32 Crate %d!\n", [self crateNumber]);	
		}
		else {
			[[self xl2] deselectCards];
			NSLog(@"Failure during Pmt Current read for FEC32 (%d,%d)/n",[self crateNumber], [self stationNumber]);	
		}
		@throw;
	}
		
	return theAveCurrent;
}

- (int) stationNumber
{
	//we have a weird mapping because fec cards can only be in slots 1-16 and they are mapped to 0 - 15
	return [[self crate] maxNumberOfObjects] - [self slot] - 2;
}

#pragma mark •••OROrderedObjHolding Protocol
- (int) maxNumberOfObjects	{ return 4; }
- (int) objWidth			{ return 39; }
- (int) groupSeparation		{ return 37; }
- (NSString*) nameForSlot:(int)aSlot	{ return [NSString stringWithFormat:@"Slot %d",aSlot]; }
- (BOOL) slot:(int)aSlot excludedFor:(id)anObj {return NO;}

- (NSRange) legalSlotsForObj:(id)anObj
{
	return NSMakeRange(0,[self maxNumberOfObjects]);
}

- (int)slotAtPoint:(NSPoint)aPoint 
{
	//what really screws us up is the space in the middle
	float y = aPoint.y;
	int objWidth = [self objWidth];
	float w = objWidth * [self maxNumberOfObjects] + [self groupSeparation];
	
	if(y>=0 && y<objWidth)						return 0;
	else if(y>objWidth && y<objWidth*2)			return 1;
	else if(y>=w-objWidth*2 && y<w-objWidth)	return 2;
	else if(y>=w-objWidth && y<w)				return 3;
	else										return -1;
}

- (NSPoint) pointForSlot:(int)aSlot 
{
	int objWidth = [self objWidth];
	float w = objWidth * [self maxNumberOfObjects] + [self groupSeparation];
	if(aSlot == 0)		return NSMakePoint(0,0);
	else if(aSlot == 1)	return NSMakePoint(0,objWidth+1);
	else if(aSlot == 2) return NSMakePoint(0,w-2*objWidth+1);
	else return NSMakePoint(0,w-objWidth+1);
}


- (void) place:(id)aCard intoSlot:(int)aSlot
{
	[aCard setSlot: aSlot];
	[aCard moveTo:[self pointForSlot:aSlot]];
}

- (int) slotForObj:(id)anObj
{
	return [anObj slot];
}

- (int) numberSlotsNeededFor:(id)anObj
{
	return [anObj numberSlotsUsed];
}

//--Read_CMOS_Counts
//PH 03/09/98. Read the CMOS totals counter and calculate rates if calcRates is true
// otherwise sets rates to zero.  a negative rate indicates a CMOS or VME read error.
// returns true if rates were calculated
- (BOOL) readCMOSCounts:(BOOL)calcRates channelMask:(unsigned long) aChannelMask
{
	long		   	theRate = kCMOSRateUnmeasured;
	long		   	maxRate = kCMOSRateUnmeasured;
	unsigned long  	theCount;
	unsigned short 	channel;
	unsigned short	maxRateChannel = 0;
	
	NSDate* lastTime = cmosCountTimeStamp;
	NSDate* thisTime = [NSDate date];
	NSTimeInterval timeDiff = [thisTime timeIntervalSinceDate:lastTime];
	
	if (calcRates && (timeDiff<0 || timeDiff>kMaxTimeDiff)) {
		calcRates = 0;	// don't calculate rates if time diff is silly
	}
	
	float sampleFreq = 1 / (thisTime - lastTime);
	
	[cmosCountTimeStamp release];
	cmosCountTimeStamp = [thisTime retain];
	
	//unsigned long theOnlineMask = [self onlineMask];
	
	BOOL selected = NO;
	@try {	
		[[self xl2] select:self];
		selected = YES;
		
		ORCommandList* aList = [ORCommandList commandList];
		unsigned long resultIndex[32];
		for (channel=0; channel<32; ++channel) {
			if(aChannelMask & (1UL<<channel) && ![self cmosReadDisabled:channel]){
				resultIndex[channel] = [aList addCommand:[self readFromFec32RegisterCmd:FEC32_CMOS_TOTALS_COUNTER_OFFSET+32*channel]];
			}
		}
		[self executeCommandList:aList];
		//pull the results
		for (channel=0; channel<32; ++channel) {
			if(aChannelMask & (1UL<<channel) && ![self cmosReadDisabled:channel]){
				theCount = [aList longValueForCmd:resultIndex[channel]];
				//if( (theCount & 0x80000000) == 0x80000000 ){
				//busy... TBD put out error or something MAH 12/19/08
				//}
			}
			else {
				theCount = kCMOSRateUnmeasured;
			}
			
			if (calcRates) {
				if (aChannelMask & (1UL<<channel) && ![self cmosReadDisabled:channel]) {
					// get value of last totals counter read
					if ((theCount | cmosCount[channel]) & 0x80000000UL) {	// test for CMOS read error
						if( (cmosCount[channel] == 0x8000deadUL) || (theCount == 0x8000deadUL) ) theRate = kCMOSRateBusError;
						else															theRate = kCMOSRateBusyRead;
					} 
					else theRate = (theCount - cmosCount[channel]) * sampleFreq;
					
					// keep track of maximum count rate
					if (maxRate < theRate) {
						maxRate = theRate;
						maxRateChannel = channel;
					}
					if (theRate > 1e9) theRate = kCMOSRateCorruptRead;			//MAH 3/19/98
				} 
				else theRate = kCMOSRateUnmeasured;								//PH 04/07/99
			}
			
			cmosCount[channel] = theCount;	// save the new CMOS totals counter and rate
			cmosRate[channel]  = theRate;	// this will be kCMOSRateUnmeasured if not calculating rates
		}
	}
	@catch (NSException* localException){
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ORFec32ModelCmosRateChanged" object:self userInfo:nil];
	
	//	if (calcRates) {
	// save maximum rate
	//		theConfigDB->CardMaxCMOSRate(crate,slot,maxRateChannel,maxRate);
	//	}
	return calcRates;
}

@end

@implementation ORFec32Model (private)

- (void) loadCmosShiftRegisters:(BOOL) aTriggersDisabled
{
#ifdef VERIFY_CMOS_SHIFT_REGISTER
	int retry_cmos_load = 0;
#endif			
	
	@try {
		//	NSLog(@"Loading all CMOS Shift Registers for FEC32 (%d,%d)\n",[self crateNumber],[self stationNumber]);
		[[self xl2] select:self];
		
		short channel_index;
		unsigned long registerAddress=0;
		unsigned short whichChannels=0;
		for( channel_index = 0; channel_index < 2; channel_index++){
			
			switch (channel_index){
				case BOTTOM_CHANNELS:
					whichChannels = BOTTOM_CHANNELS;
					registerAddress = FEC32_CMOS_1_16_REG;
					break;
				case UPPER_CHANNELS:				
					whichChannels = UPPER_CHANNELS;
					registerAddress = FEC32_CMOS_17_32_REG;
					break;	
			}
			
			// load data into structure from database
			[self loadCmosShiftRegData:whichChannels triggersDisabled:aTriggersDisabled];
			
			// serially shift in 35 bits of data, the top 10 bits are shifted in as zero
			//STEP 1: first shift in the top 10 bits: the bottom 0-15 channels first
			//todo: split into two implementations
			if([[self xl2] adapterIsSBC]) {
				ORCommandList* aList = [ORCommandList commandList];
				short i;
				for (i = 0; i < 10; i++){
					[aList addCommand: [self writeToFec32RegisterCmd:registerAddress value:FEC32_CMOS_SHIFT_SERSTROB]];
					[aList addCommand: [self writeToFec32RegisterCmd:registerAddress value:FEC32_CMOS_SHIFT_SERSTROB | FEC32_CMOS_SHIFT_CLOCK]];
				}
				
				[aList addCommands:[self cmosShiftLoadAndClock:registerAddress cmosRegItem:TAC_TRIM1 bitMaskStart:TACTRIM_BITS]];		// STEP 2: tacTrim1
				[aList addCommands:[self cmosShiftLoadAndClock:registerAddress cmosRegItem:TAC_TRIM0 bitMaskStart:TACTRIM_BITS]];		// STEP 3: tacTrim0
				[aList addCommands:[self cmosShiftLoadAndClock:registerAddress cmosRegItem:NS20_MASK bitMaskStart:NS20_MASK_BITS]];		// STEP 4: ns20Mask
				[aList addCommands:[self cmosShiftLoadAndClock:registerAddress cmosRegItem:NS20_WIDTH bitMaskStart:NS20_WIDTH_BITS]];	// STEP 5: ns20Width
				[aList addCommands:[self cmosShiftLoadAndClock:registerAddress cmosRegItem:NS20_DELAY bitMaskStart:NS20_DELAY_BITS]];	// STEP 6: ns20Delay
				[aList addCommands:[self cmosShiftLoadAndClock:registerAddress cmosRegItem:NS100_MASK bitMaskStart:NS_MASK_BITS]];		// STEP 7: ns100Mask
				[aList addCommands:[self cmosShiftLoadAndClock:registerAddress cmosRegItem:NS100_DELAY bitMaskStart:NS100_DELAY_BITS]];	// STEP 8: ns100Delay
				[aList addCommand: [self writeToFec32RegisterCmd:registerAddress value:0x3FFFF]];										// FINAL STEP: SERSTOR
				[self executeCommandList:aList]; //send out the list (blocks until reply or timeout)
			}
			else {
				short i;
				for (i = 0; i < 10; i++){
					[self writeToFec32Register:registerAddress value:FEC32_CMOS_SHIFT_SERSTROB];
					[self writeToFec32Register:registerAddress value:FEC32_CMOS_SHIFT_SERSTROB | FEC32_CMOS_SHIFT_CLOCK];
				}
				
				[self cmosShiftLoadAndClockBit3:registerAddress cmosRegItem:TAC_TRIM1 bitMaskStart:TACTRIM_BITS];		// STEP 2: tacTrim1
				[self cmosShiftLoadAndClockBit3:registerAddress cmosRegItem:TAC_TRIM0 bitMaskStart:TACTRIM_BITS];		// STEP 3: tacTrim0
				[self cmosShiftLoadAndClockBit3:registerAddress cmosRegItem:NS20_MASK bitMaskStart:NS20_MASK_BITS];		// STEP 4: ns20Mask
				[self cmosShiftLoadAndClockBit3:registerAddress cmosRegItem:NS20_WIDTH bitMaskStart:NS20_WIDTH_BITS];	// STEP 5: ns20Width
				[self cmosShiftLoadAndClockBit3:registerAddress cmosRegItem:NS20_DELAY bitMaskStart:NS20_DELAY_BITS];	// STEP 6: ns20Delay
				[self cmosShiftLoadAndClockBit3:registerAddress cmosRegItem:NS100_MASK bitMaskStart:NS_MASK_BITS];		// STEP 7: ns100Mask
				[self cmosShiftLoadAndClockBit3:registerAddress cmosRegItem:NS100_DELAY bitMaskStart:NS100_DELAY_BITS];	// STEP 8: ns100Delay
				[self writeToFec32RegisterCmd:registerAddress value:0x3FFFF];										// FINAL STEP: SERSTOR
			}
			
				
#ifdef VERIFY_CMOS_SHIFT_REGISTER
			//-----VERIFY that we have set the shift register properly for the 16 channels just loaded - PH 09/17/99
			const short	kMaxCmosLoadAttempts = 2;	// maximum number of times to attempt loading the CMOS shift register before throwing an exception
			const short kMaxCmosReadAttempts = 3;	// maximum number of times to check the busy bit on the CMOS read before using the value
			
			int theChannel;
			for (theChannel=0; theChannel<16; ++theChannel) {		// verify each of the 16 channels that we just loaded
				unsigned long actualShiftReg;
				short retry_read;
				for (retry_read=0; retry_read<kMaxCmosReadAttempts; ++retry_read) {
					actualShiftReg = [self readFromFec32Register:FEC32_CMOS_SHIFT_REG_OFFSET + 32*(theChannel+16*channel_index)];	// read back the CMOS shift register
					if( !(actualShiftReg & 0x80000000) ) break;		//done if busy bit not set. Otherwise: busy, so try to read again
				}
				unsigned long expectedShiftReg = ((cmosShiftRegisterValue[theChannel].cmos_shift_item[TAC_TRIM1]   & 0x0fUL) << 20) |
				((cmosShiftRegisterValue[theChannel].cmos_shift_item[TAC_TRIM0]   & 0x0fUL) << 16) |
				((cmosShiftRegisterValue[theChannel].cmos_shift_item[NS100_DELAY] & 0x3fUL) << 10) |
				((cmosShiftRegisterValue[theChannel].cmos_shift_item[NS20_MASK]   & 0x01UL) <<  9) |
				((cmosShiftRegisterValue[theChannel].cmos_shift_item[NS20_WIDTH]  & 0x1fUL) <<  4) |
				((cmosShiftRegisterValue[theChannel].cmos_shift_item[NS20_DELAY]  & 0x0fUL));
				
				// check the shift register value, ignoring upper 8 bits (write address and read error flag)
				if ((actualShiftReg & 0x00ffffffUL) == expectedShiftReg) {
					if (retry_cmos_load) {	// success!
						// print a message if we needed to retry the load
						NSLog(@"Verified CMOS Shift Registers for Fec32 (%d,%d,%d) after %d attempts\n", [self crateNumber], [self stationNumber], theChannel + 16 * channel_index, retry_cmos_load+1);
						retry_cmos_load = 0;	// reset retry counter
					}		
				} 
				else if (++retry_cmos_load < kMaxCmosLoadAttempts) theChannel--;	//verification error but we still want to keep trying -- read the same channel again
				else {
					// verification error after maximum number of retries
					NSLog(@"Error verifying CMOS Shift Register for Crate %d, Card %d, Channel %d:\n",
						  [self crateNumber], [self stationNumber], theChannel + 16 * channel_index);
					unsigned long badBits = (actualShiftReg ^ expectedShiftReg);
					if (actualShiftReg == 0UL) {
						NSLog(@"  - all shift register bits read back as zero\n");
					} 
					else {
						if ((badBits >> 20) & 0x0fUL)	NSLog(@"Loaded TAC1 trim   0x%.2lx (read back 0x%.2lx)\n",(expectedShiftReg >> 20) & 0x0fUL,(actualShiftReg >> 20) & 0x0fUL);
						if ((badBits >> 16) & 0x0fUL)	NSLog(@"Loaded TAC0 trim   0x%.2lx (read back 0x%.2lx)\n",(expectedShiftReg >> 16) & 0x0fUL,(actualShiftReg >> 16) & 0x0fUL);
						if ((badBits >> 10) & 0x3fUL)	NSLog(@"Loaded 100ns width 0x%.2lx (read back 0x%.2lx)\n",(expectedShiftReg >> 10) & 0x3fUL,(actualShiftReg >> 10) & 0x3fUL);
						if ((badBits >> 9) & 0x01UL)	NSLog(@"Loaded 20ns enable 0x%.2lx (read back 0x%.2lx)\n",(expectedShiftReg >> 9)  & 0x01UL,(actualShiftReg >> 9) & 0x01UL);
						if ((badBits >> 4) & 0x1fUL)	NSLog(@"Loaded 20ns width  0x%.2lx (read back 0x%.2lx)\n",(expectedShiftReg >> 4)  & 0x1fUL,(actualShiftReg  >> 4) & 0x1fUL);
						if ((badBits >> 0) & 0x0fUL)	NSLog(@"Loaded 20ns delay  0x%.2lx (read back 0x%.2lx)\n",(expectedShiftReg >> 0)  & 0x0fUL,(actualShiftReg >> 0)  & 0x0fUL);
					}
					retry_cmos_load = 0;	// reset retry counter
				}
			}
#endif // VERIFY_CMOS_SHIFT_REGISTER
		}
		
		[[self xl2] deselectCards];
		
		//NSLog(@"CMOS Shift Registers for FEC32(%d,%d) have been loaded.\n",[selfcrateNumber],[self stationNumber]);
		
	}
	@catch(NSException* localException) {
		[[self xl2] deselectCards];
		NSLog(@"Could not load the CMOS Shift Registers for FEC32 (%d,%d)!\n", [self crateNumber], [self stationNumber]);	 		
		
	}
}


- (ORCommandList*) cmosShiftLoadAndClock:(unsigned short) registerAddress cmosRegItem:(unsigned short) cmosRegItem bitMaskStart:(short) bit_mask_start
{
	
	short bit_mask;
	ORCommandList* aList = [ORCommandList commandList];
	
	// bit_mask_start : the number of bits to peel off from cmosRegItem
	for(bit_mask = bit_mask_start; bit_mask >= 0; bit_mask--){
		
		unsigned long writeValue = 0UL;
		short channel_index;
		for(channel_index = 0; channel_index < 16; channel_index++){
			if ( cmosShiftRegisterValue[channel_index].cmos_shift_item[cmosRegItem] & (1UL << bit_mask) ) {
				writeValue |= (1UL << channel_index + 2);
			}
		}
		
		// place data on line
		[aList addCommand: [self writeToFec32RegisterCmd:registerAddress value:writeValue | FEC32_CMOS_SHIFT_SERSTROB]];
		// now clock in data without SERSTROB for bit_mask = 0 and cmosRegItem = NS100_DELAY
		if( (cmosRegItem == NS100_DELAY) && (bit_mask == 0) ){
			[aList addCommand: [self writeToFec32RegisterCmd:registerAddress value:writeValue | FEC32_CMOS_SHIFT_CLOCK]];
		}
		// now clock in data
		[aList addCommand: [self writeToFec32RegisterCmd:registerAddress value:writeValue | FEC32_CMOS_SHIFT_SERSTROB | FEC32_CMOS_SHIFT_CLOCK]];
	}
	return aList;
}


- (void) cmosShiftLoadAndClockBit3:(unsigned short) registerAddress cmosRegItem:(unsigned short) cmosRegItem bitMaskStart:(short) bit_mask_start
{
	
	short bit_mask;
	
	// bit_mask_start : the number of bits to peel off from cmosRegItem
	for(bit_mask = bit_mask_start; bit_mask >= 0; bit_mask--){
		
		unsigned long writeValue = 0UL;
		short channel_index;
		for(channel_index = 0; channel_index < 16; channel_index++){
			if ( cmosShiftRegisterValue[channel_index].cmos_shift_item[cmosRegItem] & (1UL << bit_mask) ) {
				writeValue |= (1UL << channel_index + 2);
			}
		}
		
		// place data on line
		[self writeToFec32Register:registerAddress value:writeValue | FEC32_CMOS_SHIFT_SERSTROB];
		// now clock in data without SERSTROB for bit_mask = 0 and cmosRegItem = NS100_DELAY
		if( (cmosRegItem == NS100_DELAY) && (bit_mask == 0) ){
			[self writeToFec32Register:registerAddress value:writeValue | FEC32_CMOS_SHIFT_CLOCK];
		}
		// now clock in data
		[self writeToFec32Register:registerAddress value:writeValue | FEC32_CMOS_SHIFT_SERSTROB | FEC32_CMOS_SHIFT_CLOCK];
	}
}


-(void) loadCmosShiftRegData:(unsigned short)whichChannels triggersDisabled:(BOOL)aTriggersDisabled
{
	unsigned short dc_offset=0;
	
	switch (whichChannels){
		case BOTTOM_CHANNELS:	dc_offset = 0;	break;
		case UPPER_CHANNELS:	dc_offset = 2;	break;
	}
	
	// initialize cmosShiftRegisterValue structure	
	unsigned short i;
	for (i = 0; i < 16 ; i++){
		unsigned short j;
		for (j = 0; j < 7 ; j++){
			cmosShiftRegisterValue[i].cmos_shift_item[j] = 0;
		}
	}
	
	// load the data from the database into theCmosShiftRegUnion
	//temp.....CHVStatus theHVStatus;
	unsigned short dc_index;
	for ( dc_index= 0; dc_index < 2 ; dc_index++){
		
		unsigned short offset_index = dc_index*8;
		
		unsigned short regIndex;
		for (regIndex = 0; regIndex < 8 ; regIndex++){
			unsigned short channel = 8*(dc_offset+dc_index) + regIndex;
			cmosShiftRegisterValue[offset_index + regIndex].cmos_shift_item[TAC_TRIM1] = [dc[dc_index + dc_offset]  tac1trim:regIndex];
			cmosShiftRegisterValue[offset_index + regIndex].cmos_shift_item[TAC_TRIM0] = [dc[dc_index + dc_offset]  tac0trim:regIndex];
			cmosShiftRegisterValue[offset_index + regIndex].cmos_shift_item[NS20_WIDTH] = ([dc[dc_index + dc_offset]  ns20width:regIndex]) >> 1;	 // since bit 1 is the LSB
			cmosShiftRegisterValue[offset_index + regIndex].cmos_shift_item[NS20_DELAY] = ([dc[dc_index + dc_offset]  ns20delay:regIndex]) >> 1;    // since bit 1 is the LSB
			cmosShiftRegisterValue[offset_index + regIndex].cmos_shift_item[NS100_DELAY] = ([dc[dc_index + dc_offset] ns100width:regIndex]) >> 1;   // since bit 1 is the LSB
			
			if (aTriggersDisabled /*|| !theHVStatus.IsHVOnThisChannel(itsSNOCrate->Get_SC_Number(),itsFec32SlotNumber,channel)*/ ) {
				cmosShiftRegisterValue[offset_index + regIndex].cmos_shift_item[NS20_MASK] = 0;
				cmosShiftRegisterValue[offset_index + regIndex].cmos_shift_item[NS100_MASK] = 0;
				[self setTrigger20ns:channel disabled:YES];
				[self setTrigger100ns:channel disabled:YES];
			} else {
				cmosShiftRegisterValue[offset_index + regIndex].cmos_shift_item[NS20_MASK]  = ![self trigger20nsDisabled:channel];
				cmosShiftRegisterValue[offset_index + regIndex].cmos_shift_item[NS100_MASK] = ![self trigger100nsDisabled:channel];
			}
		}
		
	}		
}


@end

@implementation ORFec32Model (SBC)
- (void) loadAllDacsUsingSBC
{
	//-------------- variables -----------------
	unsigned long	i,j,k;								
	short			theIndex;
	const short		numChannels = 8;
	unsigned long	writeValue  = 0;
	unsigned long	dacValues[8][17];
	//------------------------------------------
	
	NSLog(@"Setting all DACs for FEC32 (%d,%d)....\n", [self crateNumber],[self stationNumber]);
	
	@try {
		[[self xl2] select:self];
		
		// Need to do Full Buffer mode before and after the DACs are loaded the first time
		// Full Buffer Mode of DAC loading, before the DACs are loaded -- this works 1/20/97
		
		ORCommandList* aList = [ORCommandList commandList];
		[aList addCommand: [self writeToFec32RegisterCmd:FEC32_DAC_PROGRAM_REG value:0x0]];  // set DACSEL
		
		for ( i = 1; i<= 16 ; i++) {
			if ( ( i<9 ) || ( i == 10) ){
				writeValue = 0UL;
				[aList addCommand: [self writeToFec32RegisterCmd:FEC32_DAC_PROGRAM_REG value:writeValue]];
			}
			else {
				writeValue = 0x0007FFFC;
				[aList addCommand: [self writeToFec32RegisterCmd:FEC32_DAC_PROGRAM_REG value:writeValue]];	// address value, enable this channel					
			}
			[aList addCommand: [self writeToFec32RegisterCmd:FEC32_DAC_PROGRAM_REG value:writeValue+1]];
		}
		
		[aList addCommand: [self writeToFec32RegisterCmd:FEC32_DAC_PROGRAM_REG value:0x2]];// remove DACSEL
		
		// now clock in the address and data values
		for ( i = numChannels; i >= 1 ; i--) {			// 8 channels, i.e. there are 8 lines of data values
			
			[aList addCommand: [self writeToFec32RegisterCmd:FEC32_DAC_PROGRAM_REG value:0x0]];  // set DACSEL
			
			// clock in the address values
			for ( j = 1; j<= 8; j++){					
				if ( j == i) {
					// enable all 17 DAC address lines for a particular channel
					writeValue = 0x0007FFFC;
					[aList addCommand: [self writeToFec32RegisterCmd:FEC32_DAC_PROGRAM_REG value:writeValue]];
				}
				else{
					writeValue = 0UL;
					[aList addCommand: [self writeToFec32RegisterCmd:FEC32_DAC_PROGRAM_REG value:writeValue]]; //disable channel
				}
				[aList addCommand: [self writeToFec32RegisterCmd:FEC32_DAC_PROGRAM_REG value:writeValue+1]];	// clock in
			}
			
			// first load the DAC values from the database into a 8x17 matirx
			short cIndex;
			for (cIndex = 0; cIndex <= 16; cIndex++){
				short rIndex;
				for (rIndex = 0; rIndex <= 7; rIndex++){
					switch( cIndex ){
							
						case 0:
							if ( rIndex%2 == 0 )	{
								theIndex = (rIndex/2);
								dacValues[rIndex][cIndex]		= [dc[theIndex] rp2:0];
								dacValues[rIndex + 1][cIndex]	= [dc[theIndex] rp2:1];
							}	
							break;
							
						case 1:
							if ( rIndex%2 == 0)	{
								theIndex = (rIndex/2);
								dacValues[rIndex][cIndex]		= [dc[theIndex] vli:0];					
								dacValues[rIndex + 1][cIndex]	= [dc[theIndex] vli:1];	
							}	
							break;
							
						case 2:
							if ( rIndex%2 == 0 )	{
								theIndex = (rIndex/2);
								dacValues[rIndex][cIndex]		= [dc[theIndex] vsi:0];					
								dacValues[rIndex + 1][cIndex]	= [dc[theIndex] vsi:1];		
							}	
							break;
							
						case 15:
							if ( rIndex%2 == 0 )	{
								theIndex = (rIndex/2);
								dacValues[rIndex][cIndex]		= [dc[theIndex] rp1:0];						
								dacValues[rIndex + 1][cIndex]   = [dc[theIndex] rp1:0];		
							}	
							break;
					}
					
					if ( (cIndex >= 3) && (cIndex <= 6) ) {
						dacValues[rIndex][cIndex] = [dc[cIndex - 3] vt:rIndex];
					}
					
					else if ( (cIndex >= 7) && (cIndex <= 14) ) {
						if ( (cIndex - 7)%2 == 0)	{
							theIndex = ( (cIndex - 7) / 2 );
							
							unsigned long theGain;
							if (rIndex/4)	theGain = 1;
							else			theGain = 0;
							dacValues[rIndex][cIndex]	= [dc[theIndex] vb:rIndex%4    egain:theGain];
							dacValues[rIndex][cIndex+1] = [dc[theIndex] vb:(rIndex%4)+4 egain:theGain];
						}
					}
					else if ( cIndex == 16) {
						switch( rIndex){
							case 6:  dacValues[rIndex][cIndex] = [self vRes];			break;
							case 7:  dacValues[rIndex][cIndex] = [self hVRef];			break;
							default: dacValues[rIndex][cIndex] = [self cmos:rIndex];	break;
						}		
					}
				}
			}
			// load data values, 17 DAC values at a time, from the electronics database
			// there are a total of 8x17 = 136 DAC values
			// load the data values
			for (j = 8; j >= 1; j--){					// 8 bits of data per channel
				writeValue = 0UL;
				for (k = 2; k<= 18; k++){				// 17 octal DACs
					if ( (1UL << j-1 ) & dacValues[numChannels - i][k-2] ) {
						writeValue |= 1UL << k;
					}
				}
				
				[aList addCommand: [self writeToFec32RegisterCmd:FEC32_DAC_PROGRAM_REG value:writeValue]];
				[aList addCommand: [self writeToFec32RegisterCmd:FEC32_DAC_PROGRAM_REG value:writeValue+1]];	// clock in
			}
			
			[aList addCommand: [self writeToFec32RegisterCmd:FEC32_DAC_PROGRAM_REG value:0x2]]; // remove DACSEL
		}
		// Full Buffer Mode of DAC loading, after the DACs are loaded -- this works 1/13/97
		[aList addCommand: [self writeToFec32RegisterCmd:FEC32_DAC_PROGRAM_REG value:0x0]]; // set DACSEL
		
		for ( i = 1; i<= 16 ; i++){
			if ( ( i<9 ) || ( i == 10) ){
				writeValue = 0UL;
				[aList addCommand: [self writeToFec32RegisterCmd:FEC32_DAC_PROGRAM_REG value:writeValue]];
			}
			else{
				writeValue = 0x0007FFFC;
				[aList addCommand: [self writeToFec32RegisterCmd:FEC32_DAC_PROGRAM_REG value:writeValue]];
			}
			[aList addCommand: [self writeToFec32RegisterCmd:FEC32_DAC_PROGRAM_REG value:writeValue + 1]];	// clock in with bit 0 high
		}
		
		[aList addCommand: [self writeToFec32RegisterCmd:FEC32_DAC_PROGRAM_REG value:0x2]]; // remove DACSEL
		[self executeCommandList:aList];
		
		[[self xl2] deselectCards];		
	}
	@catch(NSException* localException) {
		[[self xl2] deselectCards];		
		NSLog(@"Could not load the DACs for FEC32(%d,%d)!\n", [self crateNumber], [self stationNumber]);			
	}	
}


- (NSString*) performBoardIDReadUsingSBC:(short) boardIndex
{
	unsigned short 	dataValue = 0;
	unsigned long	writeValue = 0UL;
	unsigned long	theRegister = BOARD_ID_REG_NUMBER;
	// first select the board (XL2 must already be selected)
	unsigned long boardSelectVal = 0;
	boardSelectVal |= (1UL << boardIndex);
	
	ORCommandList* aList = [ORCommandList commandList];		//start a command list.
	
	[aList addCommand: [self writeToFec32RegisterCmd:FEC32_BOARD_ID_REG value:boardSelectVal]];
	
	//-------------------------------------------------------------------------------------------
	// load and clock in the first 9 bits instruction code and register address
	//[self boardIDOperation:(BOARD_ID_READ | theRegister) boardSelectValue:boardSelectVal beginIndex: 8];
	//moved here so we could combine all the commands into one list for speed.
	unsigned long theDataValue = (BOARD_ID_READ | theRegister);
	short index;
	for (index = 8; index >= 0; index--){
		if ( theDataValue & (1U << index) ) writeValue = (boardSelectVal | BOARD_ID_DI);
		else								writeValue = boardSelectVal;
		[aList addCommand: [self writeToFec32RegisterCmd:FEC32_BOARD_ID_REG value:writeValue]];					// load data value
		[aList addCommand: [self writeToFec32RegisterCmd:FEC32_BOARD_ID_REG value:(writeValue | BOARD_ID_SK)]];	// now clock in value
	}
	//-------------------------------------------------------------------------------------------
	
	// now read the data value; 17 reads, the last data bit is a dummy bit
	writeValue = boardSelectVal;
	
	int cmdRef[16];
	for (index = 15; index >= 0; index--){
		[aList addCommand: [self writeToFec32RegisterCmd:FEC32_BOARD_ID_REG value:writeValue]];
		[aList addCommand: [self writeToFec32RegisterCmd:FEC32_BOARD_ID_REG value:(writeValue | BOARD_ID_SK)]];	// now clock in value
		cmdRef[index] = [aList addCommand: [self readFromFec32RegisterCmd:FEC32_BOARD_ID_REG]];											// read the data bit
	}
	
	[aList addCommand: [self writeToFec32RegisterCmd:FEC32_BOARD_ID_REG value:writeValue]];					// read out the dummy bit
	[aList addCommand: [self writeToFec32RegisterCmd:FEC32_BOARD_ID_REG value:(writeValue | BOARD_ID_SK)]];	// now clock in value
	[aList addCommand: [self writeToFec32RegisterCmd:FEC32_BOARD_ID_REG value:0UL]];						// Now de-select all and clock
	[aList addCommand: [self writeToFec32RegisterCmd:FEC32_BOARD_ID_REG value:BOARD_ID_SK]];				// now clock in value
	
	[self executeCommandList:aList]; //send out the list (blocks until reply or timeout)
	
	//OK, assemble the result
	for (index = 15; index >= 0; index--){
		long readValue = [aList longValueForCmd:cmdRef[index]];
		if ( readValue & BOARD_ID_DO)dataValue |= (1U << index);
	}
	
	return hexToString(dataValue);
}

@end

@implementation ORFec32Model (LocalAdapter)
- (void) loadAllDacsUsingLocalAdapter
{
	//-------------- variables -----------------
	unsigned long	i,j,k;								
	short			theIndex;
	const short		numChannels = 8;
	unsigned long	writeValue  = 0;
	unsigned long	dacValues[8][17];
	//------------------------------------------
	
	NSLog(@"Setting all DACs for FEC32 (%d,%d)....\n", [self crateNumber],[self stationNumber]);
	
	@try {
		[[self xl2] select:self];
		[self writeToFec32Register:FEC32_DAC_PROGRAM_REG value:0x0];  // set DACSEL
		
		for ( i = 1; i<= 16 ; i++) {
			if ( ( i<9 ) || ( i == 10) ){
				writeValue = 0UL;
				[self writeToFec32Register:FEC32_DAC_PROGRAM_REG value:writeValue];
			}
			else {
				writeValue = 0x0007FFFC;
				[self writeToFec32Register:FEC32_DAC_PROGRAM_REG value:writeValue];	// address value, enable this channel					
			}
			[self writeToFec32Register:FEC32_DAC_PROGRAM_REG value:writeValue+1];
		}
		
		[self writeToFec32Register:FEC32_DAC_PROGRAM_REG value:0x2];// remove DACSEL
		
		// now clock in the address and data values
		for ( i = numChannels; i >= 1 ; i--) {			// 8 channels, i.e. there are 8 lines of data values
			[self writeToFec32Register:FEC32_DAC_PROGRAM_REG value:0x0];  // set DACSEL
			// clock in the address values
			for ( j = 1; j<= 8; j++){					
				if ( j == i) {
					// enable all 17 DAC address lines for a particular channel
					writeValue = 0x0007FFFC;
					[self writeToFec32Register:FEC32_DAC_PROGRAM_REG value:writeValue];
				}
				else{
					writeValue = 0UL;
					[self writeToFec32Register:FEC32_DAC_PROGRAM_REG value:writeValue]; //disable channel
				}
				[self writeToFec32RegisterCmd:FEC32_DAC_PROGRAM_REG value:writeValue+1]; // clock in
			}
			
			// first load the DAC values from the database into a 8x17 matirx
			short cIndex;
			for (cIndex = 0; cIndex <= 16; cIndex++){
				short rIndex;
				for (rIndex = 0; rIndex <= 7; rIndex++){
					switch( cIndex ){
						case 0:
							if ( rIndex%2 == 0 )	{
								theIndex = (rIndex/2);
								dacValues[rIndex][cIndex]		= [dc[theIndex] rp2:0];
								dacValues[rIndex + 1][cIndex]	= [dc[theIndex] rp2:1];
							}	
							break;
						case 1:
							if ( rIndex%2 == 0)	{
								theIndex = (rIndex/2);
								dacValues[rIndex][cIndex]		= [dc[theIndex] vli:0];					
								dacValues[rIndex + 1][cIndex]	= [dc[theIndex] vli:1];	
							}	
							break;
						case 2:
							if ( rIndex%2 == 0 )	{
								theIndex = (rIndex/2);
								dacValues[rIndex][cIndex]		= [dc[theIndex] vsi:0];					
								dacValues[rIndex + 1][cIndex]	= [dc[theIndex] vsi:1];		
							}	
							break;
						case 15:
							if ( rIndex%2 == 0 )	{
								theIndex = (rIndex/2);
								dacValues[rIndex][cIndex]		= [dc[theIndex] rp1:0];						
								dacValues[rIndex + 1][cIndex]   = [dc[theIndex] rp1:0];		
							}	
							break;
					}
					if ( (cIndex >= 3) && (cIndex <= 6) ) {
						dacValues[rIndex][cIndex] = [dc[cIndex - 3] vt:rIndex];
					}
					else if ( (cIndex >= 7) && (cIndex <= 14) ) {
						if ( (cIndex - 7)%2 == 0)	{
							theIndex = ( (cIndex - 7) / 2 );
							
							unsigned long theGain;
							if (rIndex/4)	theGain = 1;
							else			theGain = 0;
							dacValues[rIndex][cIndex]	= [dc[theIndex] vb:rIndex%4    egain:theGain];
							dacValues[rIndex][cIndex+1] = [dc[theIndex] vb:(rIndex%4)+4 egain:theGain];
						}
					}
					else if ( cIndex == 16) {
						switch( rIndex){
							case 6:  dacValues[rIndex][cIndex] = [self vRes];			break;
							case 7:  dacValues[rIndex][cIndex] = [self hVRef];			break;
							default: dacValues[rIndex][cIndex] = [self cmos:rIndex];	break;
						}		
					}
				}
			}
			// load data values, 17 DAC values at a time, from the electronics database
			// there are a total of 8x17 = 136 DAC values
			// load the data values
			for (j = 8; j >= 1; j--){					// 8 bits of data per channel
				writeValue = 0UL;
				for (k = 2; k<= 18; k++){				// 17 octal DACs
					if ( (1UL << j-1 ) & dacValues[numChannels - i][k-2] ) {
						writeValue |= 1UL << k;
					}
				}
				[self writeToFec32Register:FEC32_DAC_PROGRAM_REG value:writeValue];
				[self writeToFec32Register:FEC32_DAC_PROGRAM_REG value:writeValue+1];	// clock in
			}
			[self writeToFec32Register:FEC32_DAC_PROGRAM_REG value:0x2]; // remove DACSEL
		}
		// Full Buffer Mode of DAC loading, after the DACs are loaded -- this works 1/13/97
		[self writeToFec32Register:FEC32_DAC_PROGRAM_REG value:0x0]; // set DACSEL
		
		for ( i = 1; i<= 16 ; i++){
			if ( ( i<9 ) || ( i == 10) ){
				writeValue = 0UL;
				[self writeToFec32Register:FEC32_DAC_PROGRAM_REG value:writeValue];
			}
			else{
				writeValue = 0x0007FFFC;
				[self writeToFec32Register:FEC32_DAC_PROGRAM_REG value:writeValue];
			}
			[self writeToFec32Register:FEC32_DAC_PROGRAM_REG value:writeValue + 1];	// clock in with bit 0 high
		}
		
		[self writeToFec32Register:FEC32_DAC_PROGRAM_REG value:0x2]; // remove DACSEL
		[[self xl2] deselectCards];		
	}
	@catch(NSException* localException) {
		[[self xl2] deselectCards];		
		NSLog(@"Could not load the DACs for FEC32(%d,%d)!\n", [self crateNumber], [self stationNumber]);			
	}	
}


- (NSString*) performBoardIDReadUsingLocalAdapter:(short) boardIndex
{
	unsigned short 	dataValue = 0;
	unsigned long	writeValue = 0UL;
	unsigned long	theRegister = BOARD_ID_REG_NUMBER;
	// first select the board (XL2 must already be selected)
	unsigned long boardSelectVal = 0;
	boardSelectVal |= (1UL << boardIndex);
	
	[self writeToFec32Register:FEC32_BOARD_ID_REG value:boardSelectVal];
	
	//-------------------------------------------------------------------------------------------
	// load and clock in the first 9 bits instruction code and register address
	//[self boardIDOperation:(BOARD_ID_READ | theRegister) boardSelectValue:boardSelectVal beginIndex: 8];
	//moved here so we could combine all the commands into one list for speed.
	unsigned long theDataValue = (BOARD_ID_READ | theRegister);
	short index;
	for (index = 8; index >= 0; index--){
		if (theDataValue & (1U << index))	writeValue = (boardSelectVal | BOARD_ID_DI);
		else					writeValue = boardSelectVal;
		[self writeToFec32Register:FEC32_BOARD_ID_REG value:writeValue];			// load data value
		[self writeToFec32Register:FEC32_BOARD_ID_REG value:(writeValue | BOARD_ID_SK)];	// now clock in value
	}
	//-------------------------------------------------------------------------------------------
	
	// now read the data value; 17 reads, the last data bit is a dummy bit
	writeValue = boardSelectVal;
	
	int cmdRef[16];
	for (index = 15; index >= 0; index--){
		[self writeToFec32Register:FEC32_BOARD_ID_REG value:writeValue];
		[self writeToFec32Register:FEC32_BOARD_ID_REG value:(writeValue | BOARD_ID_SK)];	// now clock in value
		cmdRef[index] = [self readFromFec32Register:FEC32_BOARD_ID_REG];			// read the data bit
	}
	
	[self writeToFec32Register:FEC32_BOARD_ID_REG value:writeValue];				// read out the dummy bit
	[self writeToFec32Register:FEC32_BOARD_ID_REG value:(writeValue | BOARD_ID_SK)];		// now clock in value
	[self writeToFec32Register:FEC32_BOARD_ID_REG value:0UL];					// Now de-select all and clock
	[self writeToFec32Register:FEC32_BOARD_ID_REG value:BOARD_ID_SK];				// now clock in value
		
	//OK, assemble the result
	for (index = 15; index >= 0; index--){
		long readValue = cmdRef[index];
		if (readValue & BOARD_ID_DO) dataValue |= (1U << index);
	}
	
	return hexToString(dataValue);
}
@end
