//
//  ORTristanFLTModel.m
//  Orca
//
//  Created by Mark Howe on 1/23/18.
//  Copyright 2018, University of North Carolina. All rights reserved.
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

#import "ORTristanFLTModel.h"
#import "ORIpeCrateModel.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORDataTypeAssigner.h"
#import "ORTimeRate.h"

NSString* ORTristanFLTModelEnabledChanged            = @"ORTristanFLTModelEnabledChanged";
NSString* ORTristanFLTModelShapingLengthChanged      = @"ORTristanFLTModelShapingLengthChanged";
NSString* ORTristanFLTModelGapLengthChanged          = @"ORTristanFLTModelGapLengthChanged";
NSString* ORTristanFLTModelThresholdsChanged         = @"ORTristanFLTModelThresholdsChanged";
NSString* ORTristanFLTModelPostTriggerTimeChanged    = @"ORTristanFLTModelPostTriggerTimeChanged";
NSString* ORTristanFLTModelFrameSizeChanged          = @"ORTristanFLTModelFrameSizeChanged";
NSString* ORTristanFLTSettingsLock                   = @"ORTristanFLTSettingsLock";

@interface ORTristanFLTModel (private)
- (void) addCurrentState:(NSMutableDictionary*)dictionary boolArray:(bool*)anArray forKey:(NSString*)aKey;
- (void) addCurrentState:(NSMutableDictionary*)dictionary longArray:(unsigned long*)anArray forKey:(NSString*)aKey;
- (int)  restrictIntValue:(int)aValue min:(int)aMinValue max:(int)aMaxValue;
@end

@implementation ORTristanFLTModel

- (id) init
{
    self = [super init];
    return self;
}
  

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void) sleep
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void) wakeUp
{
    [super wakeUp];
    [self registerNotificationObservers];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"TristanFLTCard"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORTristanFLTController"];
}

- (Class) guardianClass 
{
	return NSClassFromString(@"ORIpeV4CrateModel");
}

//'stationNumber' returns the logical number of the FLT (FLT#) (1...20),
//method 'slot' returns index (0...9,11-20) of the FLT, so it represents the position of the FLT in the crate. 
- (int) stationNumber
{
	//is it a minicrate?
	if([[[self crate] class]  isSubclassOfClass: NSClassFromString(@"ORIpeV4MiniCrateModel")]){
		if([self slot]<3)   return [self slot]+1;
		else                return [self slot]; //there is a gap at slot 3 (for the SLT) -tb-
	}
	//... or a full crate?
	if([[[self crate] class]  isSubclassOfClass: NSClassFromString(@"ORIpeV4CrateModel")]){
		if([self slot]<11)  return [self slot]+1;
		else                return [self slot]; //there is a gap at slot 11 (for the SLT) -tb-
	}
	//fallback
	return [self slot]+1;
}

- (ORTimeRate*) totalRate   { return totalRate; }

#pragma mark ***Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
 	[notifyCenter removeObserver:self]; //guard against a double register
   
    [notifyCenter addObserver : self
                     selector : @selector(runIsAboutToChangeState:)
                         name : ORRunAboutToChangeState
                       object : nil];
					   
    [notifyCenter addObserver : self
                     selector : @selector(runIsAboutToStop:)
                         name : ORRunAboutToStopNotification
                       object : nil];
}

- (void) runIsAboutToStop:(NSNotification*)aNote
{
}

- (void) runIsAboutToChangeState:(NSNotification*)aNote
{
  //  int state = [[[aNote userInfo] objectForKey:@"State"] intValue];
}
- (void) reset
{
}

#pragma mark ***Accessors
- (unsigned short) shapingLength
{
    return shapingLength;
}

- (void) setShapingLength:(unsigned short)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShapingLength:shapingLength];
    shapingLength = [self restrictIntValue:aValue min:0 max:0xf];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTristanFLTModelShapingLengthChanged object:self];
}

- (int) gapLength
{
    return gapLength;
}

- (void) setGapLength:(int)aGapLength
{
    [[[self undoManager] prepareWithInvocationTarget:self] setGapLength:gapLength];
    gapLength = [self restrictIntValue:aGapLength min:0 max:0xF];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTristanFLTModelGapLengthChanged object:self];
}

- (unsigned short) postTriggerTime
{
    return postTriggerTime;
}

- (void) setPostTriggerTime:(unsigned short)aPostTriggerTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPostTriggerTime:postTriggerTime];
    postTriggerTime = [self restrictIntValue:aPostTriggerTime min:0 max:0xf];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTristanFLTModelPostTriggerTimeChanged object:self];
}

- (BOOL) enabled:(unsigned short) aChan
{
    if(aChan<kNumTristanFLTChannels)return enabled[aChan];
    else return NO;
}

- (void) setEnabled:(unsigned short) aChan withValue:(BOOL) aState
{
    if(aChan>=kNumTristanFLTChannels)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setEnabled:aChan withValue:enabled[aChan]];
    enabled[aChan] = aState;
    [[NSNotificationCenter defaultCenter]postNotificationName:ORTristanFLTModelEnabledChanged object:self];
}

- (unsigned long) threshold:(unsigned short)aChan
{
    if(aChan<kNumTristanFLTChannels)return threshold[aChan];
    else return NO;
}

-(void) setThreshold:(unsigned short) aChan withValue:(unsigned long) aValue
{
    if(aChan>=kNumTristanFLTChannels)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setThreshold:aChan withValue:threshold[aChan]];
    threshold[aChan] = aValue;
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChan] forKey: @"Channel"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTristanFLTModelThresholdsChanged object:self userInfo: userInfo];
}

- (void) setTotalRate:(ORTimeRate*)newTimeRate
{
	[totalRate autorelease];
	totalRate=[newTimeRate retain];
}

- (void) setToDefaults
{
}

- (void) initBoard
{

}

#pragma mark Data Taking
- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) aDataId
{
    dataId = aDataId;
}

- (void) setDataIds:(id)assigner
{
    dataId      = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
	
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORTristanFLTDecoderForTrace",		    @"decoder",
								 [NSNumber numberWithLong:dataId],		@"dataId",
								 [NSNumber numberWithBool:NO],			@"variable",
								 [NSNumber numberWithLong:7],			@"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"TristanFLTTrace"];
    
    return dataDictionary;
}

//this goes to the Run header ...
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    //TO DO....other things need to be added here.....
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    [self addCurrentState:objDictionary boolArray:(bool*)enabled       forKey:@"enabled"];
    [self addCurrentState:objDictionary longArray:threshold            forKey:@"threshold"];

    [objDictionary setObject:[NSNumber numberWithInt:shapingLength]    forKey:@"shapingLength"];
    [objDictionary setObject:[NSNumber numberWithInt:gapLength]        forKey:@"gapLength"];
    [objDictionary setObject:[NSNumber numberWithInt:postTriggerTime]  forKey:@"postTriggerTime"];

	return objDictionary;
}

#pragma mark ***Data Taking
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    //----------------------------------------------------------------------------------------
    // Add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORTristanFLTModel"];    
    //----------------------------------------------------------------------------------------	

    [self initBoard];
}

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{	
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
}

//not used, but need the method so just return the given index
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	return index;
}

- (BOOL) bumpRateFromDecodeStage:(short)channel
{
    if(channel>=0 && channel<kNumTristanFLTChannels){
        ++eventCount[channel];
    }
    return YES;
}

#pragma mark ***HW Access
- (void) loadThresholds
{
    
}

#pragma mark ***HW Wizard
- (BOOL) hasParmetersToRamp
{
	return NO;
}

- (int) numberOfChannels
{
    return kNumTristanFLTChannels;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
		
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Threshold"];
    [p setFormat:@"##0.00" upperLimit:0xfffff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setThreshold:withValue:) getMethod:@selector(threshold:)];
	[p setCanBeRamped:YES];
    [a addObject:p];
		
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Enable"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setEnabled:withValue:) getMethod:@selector(enabled:)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Post Trigger Delay"];
    [p setFormat:@"##0" upperLimit:0xffff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setPostTriggerTime:) getMethod:@selector(postTriggerTime)];
    [a addObject:p];
	

	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Gap Length"];
    [p setFormat:@"##0" upperLimit:0xf lowerLimit:0 stepSize:1 units:@""];//TODO: change it/add new class field! -tb-
    [p setSetMethod:@selector(setGapLength:) getMethod:@selector(gapLength)];
    [a addObject:p];			

	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Shaping Length"];
    [p setFormat:@"##0" upperLimit:0xf lowerLimit:2 stepSize:1 units:@""];
    [p setSetMethod:@selector(setShapingLength:) getMethod:@selector(shapingLength)];
    [a addObject:p];
	//----------------

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setUseValue:NO];
    [p setName:@"Init"];
    [p setSetMethodSelector:@selector(initBoard)];
    [a addObject:p];
    
    return a;
}

- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel name:@"Crate" className:@"ORIpeCrateModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Station" className:@"ORTristanFLTModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:@"ORTristanFLTModel"]];
    return a;
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
    if([param isEqualToString:     @"Threshold"])	        return [[cardDictionary objectForKey:@"thresholds"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"Enabled"])		        return [[cardDictionary objectForKey:@"enabled"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"Post Trigger Time"])	return [cardDictionary objectForKey: @"postTriggerTime"];
    else if([param isEqualToString:@"Gap Length"])			return [cardDictionary objectForKey: @"gapLength"];
    else if([param isEqualToString:@"Shaping Length"])		return [cardDictionary objectForKey: @"shapingLength"];
	
	//------------------
	//added MAH 11/09/11
    else if([param isEqualToString:@"Refresh Time"])		return [cardDictionary objectForKey:@"histMeasTime"];
    else if([param isEqualToString:@"Energy Offset"])		return [cardDictionary objectForKey:@"histEMin"];
    else if([param isEqualToString:@"Bin Width"])			return [cardDictionary objectForKey:@"histEBin"];
    else if([param isEqualToString:@"Ship Sum Histo"])		return [cardDictionary objectForKey:@"shipSumHistogram"];
    else if([param isEqualToString:@"Histo Mode"])			return [cardDictionary objectForKey:@"histMode"];
    else if([param isEqualToString:@"Histo Clr Mode"])		return [cardDictionary objectForKey:@"histClrMode"];
	//------------------
	
	else return nil;
}


#pragma mark ***archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setShapingLength:     [decoder decodeIntForKey:   @"shapingLength"]];
    [self setGapLength:         [decoder decodeIntForKey:   @"gapLength"]];
    [self setPostTriggerTime:   [decoder decodeIntForKey:   @"postTriggerTime"]];
    int i;
    for(i=0;i<kNumTristanFLTChannels;i++) {
        [self setThreshold:i withValue:[decoder decodeInt32ForKey: [NSString stringWithFormat:@"threshold%d",i]]];
        [self setEnabled:i   withValue:[decoder decodeBoolForKey:  [NSString stringWithFormat:@"enabled%d",i]]];
    }
    [[self undoManager] enableUndoRegistration];
    [self registerNotificationObservers];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    
    [encoder encodeInt:shapingLength             forKey:@"shapingLength"];
    [encoder encodeInt:gapLength                 forKey:@"gapLength"];
    [encoder encodeInt:postTriggerTime           forKey:@"postTriggerTime"];
    int i;
    for(i=0;i<kNumTristanFLTChannels;i++) {
        [encoder encodeInt32: threshold[i] forKey:[NSString stringWithFormat:@"threshold%d",i]];
        [encoder encodeBool:  enabled[i]   forKey:[NSString stringWithFormat:@"enabled%d",i]];
    }
}
@end

@implementation ORTristanFLTModel (private)

- (void) addCurrentState:(NSMutableDictionary*)dictionary boolArray:(bool*)anArray forKey:(NSString*)aKey
{
    NSMutableArray* ar = [NSMutableArray array];
    int i;
    for(i=0;i<kNumTristanFLTChannels;i++){
        [ar addObject:[NSNumber numberWithBool:anArray[i]]];
    }
    [dictionary setObject:ar forKey:aKey];
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary longArray:(unsigned long*)anArray forKey:(NSString*)aKey
{
    NSMutableArray* ar = [NSMutableArray array];
    int i;
    for(i=0;i<kNumTristanFLTChannels;i++){
        [ar addObject:[NSNumber numberWithUnsignedLong:anArray[i]]];
    }
    [dictionary setObject:ar forKey:aKey];
}

- (int) restrictIntValue:(int)aValue min:(int)aMinValue max:(int)aMaxValue
{
    if(aValue<aMinValue)return aMinValue;
    else if(aValue>aMaxValue)return aMaxValue;
    else return aValue;
}

@end
