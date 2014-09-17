//
//  MajoranaModel.m
//  Orca
//
//  Created by Mark Howe on Tue Apr 20, 2010.
//  Copyright (c) 2010  University of North Carolina. All rights reserved.
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


#pragma mark ¥¥¥Imported Files
#import "MajoranaModel.h"
#import "MajoranaController.h"
#import "ORSegmentGroup.h"
#import "ORDetectorSegment.h"
#import "ORMJDSegmentGroup.h"
#import "ORRemoteSocketModel.h"
#import "SynthesizeSingleton.h"
#import "ORTaskSequence.h"
#import "OROpSequence.h"
#import "ORShellStep.h"
#import "ORRemoteSocketStep.h"
#import "OROpSequenceQueue.h"
#import "ORInvocationStep.h"
#import "ORMPodCrateModel.h"
#import "ORiSegHVCard.h"
#import "ORAlarm.h"
#import "ORTimeRate.h"

NSString* MajoranaModelIgnorePanicOnBChanged = @"MajoranaModelIgnorePanicOnBChanged";
NSString* MajoranaModelIgnorePanicOnAChanged = @"MajoranaModelIgnorePanicOnAChanged";
NSString* ORMajoranaModelViewTypeChanged	= @"ORMajoranaModelViewTypeChanged";
NSString* ORMajoranaModelPollTimeChanged	= @"ORMajoranaModelPollTimeChanged";
NSString* ORMJDAuxTablesChanged             = @"ORMJDAuxTablesChanged";

static NSString* MajoranaDbConnector		= @"MajoranaDbConnector";

#define MJDStringMapFile(aPath)		[NSString stringWithFormat:@"%@_StringMap",	aPath]


@interface  MajoranaModel (private)
- (void)     checkConstraints;
- (void)     validateStringMap;
- (NSArray*) linesInFile:(NSString*)aPath;
@end

@implementation MajoranaModel

#pragma mark ¥¥¥Initialization
- (void) dealloc
{
    int i;
    for(i=0;i<2;i++){
        [scriptModel[i] setDelegate:nil];
        [scriptModel[i] cancel:nil];
        [scriptModel[i] release];
        [rampHVAlarm[i] clearAlarm];
        [rampHVAlarm[i] release];
    }
    [stringMap release];
    [super dealloc];
}

- (void) wakeUp
{
    [super wakeUp];
	if(pollTime){
        [self checkConstraints];
	}
}
- (void) sleep
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [super sleep];
}
- (void) setUpImage { [self setImage:[NSImage imageNamed:@"Majorana"]]; }

- (void) makeMainController
{
    [self linkToController:@"MajoranaController"];
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:MajoranaDbConnector];
    [aConnector setOffColor:[NSColor brownColor]];
    [aConnector setOnColor:[NSColor magentaColor]];
	[aConnector setConnectorType: 'DB O' ];
	[aConnector addRestrictedConnectionType: 'DB I' ]; //can only connect to DB outputs
    [aConnector release];
}

//- (NSString*) helpURL
//{
//	return @"Majorana/Index.html";
//}

- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(hvInfoRequest:)
                         name : ORiSegHVCardRequestHVMaxValues
                       object : nil];
}

- (void) hvInfoRequest:(NSNotification*)aNote
{
    if([[aNote object] isKindOfClass:NSClassFromString(@"ORiSegHVCard")]){
        ORiSegHVCard* anHVCard = [aNote object];
        id userInfo     = [aNote userInfo];
        int aCrate      = [[userInfo objectForKey:@"crate"]     intValue];
        int aCard       = [[userInfo objectForKey:@"card"]      intValue];
        int aChannel    = [[userInfo objectForKey:@"channel"]   intValue];
        BOOL foundIt    = NO;
        int aSet;
        for(aSet =0;aSet<2;aSet++){
            ORSegmentGroup* segmentGroup = [self segmentGroup:aSet];
            int numSegments = [self numberSegmentsInGroup:aSet];
            int i;
            for(i = 0; i<numSegments; i++){
                NSDictionary* params = [[segmentGroup segment:i]params];
                if(!params)break;
                if([[params objectForKey:@"kHVCrate"]intValue] != aCrate)continue;
                if([[params objectForKey:@"kHVCard"]intValue] != aCard)continue;
                if([[params objectForKey:@"kHVChan"]intValue] != aChannel)continue;
                id maxVoltNum = [params objectForKey:@"kMaxVoltage"];
                //get here and it's a match
                if(maxVoltNum){
                    //only if there is an entry for max voltage do we set it
                    [anHVCard setMaxVoltage:aChannel withValue:[maxVoltNum intValue] ];
                    [anHVCard setChan:aChannel name:[params objectForKey:@"kDetectorName"]];
                }
                foundIt = YES;
                break;
            }
        }
        if(!foundIt){
            [anHVCard setChan:aChannel name:@""];
            [anHVCard setMaxVoltage:aChannel withValue:0 ];
        }
    }
}

#pragma mark ***Accessors
- (BOOL) ignorePanicOnB
{
    return ignorePanicOnB;
}

- (void) setIgnorePanicOnB:(BOOL)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIgnorePanicOnB:ignorePanicOnB];
    
    if(ignorePanicOnB != aState){
        ignorePanicOnB = aState;
        if(ignorePanicOnB){
            NSLogColor([NSColor redColor],@"WARNING: HV checks will ignore HV Ramp Action on Module 2\n");
        }
        else {
            NSLog(@"HV checks will NOT ignore HV ramp action on Module 2\n");
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MajoranaModelIgnorePanicOnBChanged object:self];
}

- (BOOL) ignorePanicOnA
{
    return ignorePanicOnA;
}

- (void) setIgnorePanicOnA:(BOOL)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIgnorePanicOnA:ignorePanicOnA];
    
    if(ignorePanicOnA != aState){
        ignorePanicOnA = aState;
        if(ignorePanicOnA){
            NSLogColor([NSColor redColor],@"WARNING: HV checks will ignore HV Ramp Action on Module 1\n");
        }
        else {
            NSLog(@"HV checks will NOT ignore HV ramp action on Module 1\n");
        }
    }

    
    [[NSNotificationCenter defaultCenter] postNotificationName:MajoranaModelIgnorePanicOnAChanged object:self];
}

- (int) pollTime
{
    return pollTime;
}

- (void) setPollTime:(int)aPollTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollTime:pollTime];
    pollTime = aPollTime;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMajoranaModelPollTimeChanged object:self];
	
	if(pollTime){
		[self performSelector:@selector(checkConstraints) withObject:nil afterDelay:.2];
	}
	else {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkConstraints) object:nil];
	}
}


- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)aDictionary
{
    NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];
	
	[[segmentGroups objectAtIndex:0] addParametersToDictionary:objDictionary useName:@"DetectorGeometry" addInGroupName:NO];
	[[segmentGroups objectAtIndex:1] addParametersToDictionary:objDictionary useName:@"VetoGeometry" addInGroupName:NO];
    
    NSString* theContents = [self mapFileAsString];
    if([theContents length]) [objDictionary setObject:theContents forKey:@"StringGeometry"];

    
    [aDictionary setObject:objDictionary forKey:[self className]];

    return aDictionary;
}


- (NSMutableArray*) setupMapEntries:(int) groupIndex
{
    [self setCrateIndex:1];
    [self setCardIndex:2];
    [self setChannelIndex:3];
    
    NSMutableArray* mapEntries = [NSMutableArray array];
    if(groupIndex == 0){
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kSegmentNumber", @"key", [NSNumber numberWithInt:0], @"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kVME",			@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kCardSlot",      @"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kChannel",		@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kPreAmpChan",	@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kHVCrate",		@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kHVCard",        @"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kHVChan",		@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kMaxVoltage",	@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kDetectorName",  @"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kDetectorType",  @"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kStringNum",     @"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kPosition",      @"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
    }
    else if(groupIndex == 1){
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kSegmentNumber", @"key", [NSNumber numberWithInt:0], @"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kVME",			@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kCardSlot",      @"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kChannel",       @"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kHVCrate",		@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kHVCard",        @"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kHVChan",		@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
    }
	return mapEntries;
}

- (void) postCouchDBRecord
{
    if([[[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORCouchDBModel")] count]==0)return;
    
    NSMutableDictionary*  values  = [NSMutableDictionary dictionary];
    int aSet;
    int numGroups = [segmentGroups count];
    for(aSet=0;aSet<numGroups;aSet++){
        NSMutableDictionary* aDictionary= [NSMutableDictionary dictionary];
        NSMutableArray* thresholdArray  = [NSMutableArray array];
        NSMutableArray* totalCountArray = [NSMutableArray array];
        NSMutableArray* rateArray       = [NSMutableArray array];
        
        ORSegmentGroup* segmentGroup = [self segmentGroup:aSet];
        int numSegments = [self numberSegmentsInGroup:aSet];
        int i;
        for(i = 0; i<numSegments; i++){
            [thresholdArray     addObject:[NSNumber numberWithFloat:[segmentGroup getThreshold:i]]];
            [totalCountArray    addObject:[NSNumber numberWithFloat:[segmentGroup getTotalCounts:i]]];
            [rateArray          addObject:[NSNumber numberWithFloat:[segmentGroup getRate:i]]];
        }
        
        NSArray* mapEntries = [[segmentGroup paramsAsString] componentsSeparatedByString:@"\n"];
        
        if([thresholdArray count])  [aDictionary setObject:thresholdArray   forKey: @"thresholds"];
        if([totalCountArray count]) [aDictionary setObject:totalCountArray  forKey: @"totalcounts"];
        if([rateArray count])       [aDictionary setObject:rateArray        forKey: @"rates"];
        if([mapEntries count])      [aDictionary setObject:mapEntries       forKey: @"geometry"];
        
        NSArray* totalRateArray = [[[self segmentGroup:aSet] totalRate] ratesAsArray];
        if(totalRateArray)[aDictionary setObject:totalRateArray forKey:@"totalRate"];

        [values setObject:aDictionary forKey:[segmentGroup groupName]];
    }
    NSMutableDictionary* aDictionary= [NSMutableDictionary dictionary];
    NSArray* stringMapEntries = [[self mapFileAsString] componentsSeparatedByString:@"\n"];
    [aDictionary setObject:stringMapEntries       forKey: @"geometry"];
    [values setObject:aDictionary forKey:@"Strings"];
    

    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddObjectRecord" object:self userInfo:values];
}

#pragma mark ¥¥¥Segment Group Methods
- (void) makeSegmentGroups
{
    ORMJDSegmentGroup* group = [[ORMJDSegmentGroup alloc] initWithName:@"Detectors" numSegments:kNumDetectors mapEntries:[self setupMapEntries:0]];
	[self addGroup:group];
	[group release];
    
    ORSegmentGroup* group2 = [[ORSegmentGroup alloc] initWithName:@"Veto" numSegments:kNumVetoSegments mapEntries:[self setupMapEntries:1]];
	[self addGroup:group2];
	[group2 release];
}

- (int)  maxNumSegments
{
	return kNumDetectors;
}

- (int) numberSegmentsInGroup:(int)aGroup
{
	if(aGroup == 0) return kNumDetectors;
	else			return kNumVetoSegments;
}
- (void) showDataSetForSet:(int)aSet segment:(int)index
{ 
	if(aSet>=0 && aSet < [segmentGroups count]){
		ORSegmentGroup* aGroup = [segmentGroups objectAtIndex:aSet];
		NSString* crateName  = [aGroup segment:index objectForKey:@"kVME"];
		NSString* cardName = [aGroup segment:index objectForKey:@"kCardSlot"];
		NSString* chanName = [aGroup segment:index objectForKey:@"kChannel"];
		if(cardName && chanName && ![cardName hasPrefix:@"-"] && ![chanName hasPrefix:@"-"]){
			ORDataSet* aDataSet = nil;
			[[[self document] collectObjectsOfClass:NSClassFromString(@"OrcaObject")] makeObjectsPerformSelector:@selector(clearLoopChecked)];
			NSArray* objs = [[self document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
			if([objs count]){
				NSArray* arrayOfHistos = [[objs objectAtIndex:0] collectConnectedObjectsOfClass:NSClassFromString(@"ORHistoModel")];
				if([arrayOfHistos count]){
					id histoObj = [arrayOfHistos objectAtIndex:0];
					aDataSet = [histoObj objectForKeyArray:[NSMutableArray arrayWithObjects:@"Gretina", @"Energy",
															[NSString stringWithFormat:@"Crate %2d",[crateName intValue]],
															[NSString stringWithFormat:@"Card %2d",[cardName intValue]],
															[NSString stringWithFormat:@"Channel %2d",[chanName intValue]],
															nil]];
					
					[aDataSet doDoubleClick:nil];
				}
			}
		}
	}
}

- (NSString*) dataSetNameGroup:(int)aGroup segment:(int)index
{
	ORSegmentGroup* theGroup = [segmentGroups objectAtIndex:aGroup];
	
	NSString* crateName = [theGroup segment:index objectForKey:@"kCrate"];
	NSString* cardName  = [theGroup segment:index objectForKey:@"kCardSlot"];
	NSString* chanName  = [theGroup segment:index objectForKey:@"kChannel"];
	
	return [NSString stringWithFormat:@"Gretina4M,Energy,Crate %2d,Card %2d,Channel %2d",[crateName intValue],[cardName intValue],[chanName intValue]];
}

- (id) scriptModel:(int)index
{
    if(!scriptModel[index]){
        scriptModel[index] = [[OROpSequence alloc] initWithDelegate:self idIndex:index];
        [scriptModel[index] setSteps:[self scriptSteps:index]];
    }
    return scriptModel[index];
}

#pragma mark ¥¥¥Specific Dialog Lock Methods
- (NSString*) experimentMapLock     { return @"MajoranaMapLock";      }
- (NSString*) vetoMapLock           { return @"MajoranaVetoMapLock";  }
- (NSString*) experimentDetectorLock{ return @"MajoranaDetectorLock"; }
- (NSString*) experimentDetailsLock	{ return @"MajoranaDetailsLock";  }

- (void) setViewType:(int)aViewType
{
	[[[self undoManager] prepareWithInvocationTarget:self] setViewType:aViewType];
	viewType = aViewType;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMajoranaModelViewTypeChanged object:self userInfo:nil];
}

- (int) viewType { return viewType; }

- (ORRemoteSocketModel*) remoteSocket:(int)anIndex
{
    for(id obj in [self orcaObjects]){
        if([obj tag] == anIndex)return obj;
    }
    return nil;
}

- (void) updateAllowedToRunStates
{
    int i;
    for(i=0;i<2;i++){
        [scriptModel[i] setAllowedToRun:[self remoteSocket:i]!=nil];
    }
}

- (BOOL) anyHvOnVMECrate:(int)aVmeCrate
{
    //tricky .. we have to location the HV crates based on the hv map using the VME crate (detector group 0).
    //But we don't care about the Veto system (group 1).
    ORMPodCrateModel* hvCrateObj[2] = {nil,nil}; //will check for up to two HV crates (should just be one)
    hvCrateObj[0] = [[[NSApp delegate] document] findObjectWithFullID:@"ORMPodCrateModel,0"];
    hvCrateObj[1] = [[[NSApp delegate] document] findObjectWithFullID:@"ORMPodCrateModel,1"];

    ORSegmentGroup* group = [self segmentGroup:0]; //detector group
    int n = [group numSegments]; //both DAQ and Veto on the same HV supply for now
    int i;
    for(i=0;i<n;i++){
        ORDetectorSegment* seg =  [group segment:i];                    //get a segment from the group
		int vmeCrate = [[seg objectForKey:@"kVME"] intValue];           //pull out the crate
        if(vmeCrate == aVmeCrate){
            int hvCrate = [[seg objectForKey:@"kHVCrate"]intValue];    //pull out the crate
            if(hvCrate<2){
               if([hvCrateObj[hvCrate] hvOnAnyChannel])return YES;
            }
        }
    }
        
    return NO;
}

- (void) setVmeCrateHVConstraint:(int)aVmeCrate state:(BOOL)aState
{
    //tricky .. we have to location the HV crates based on the hv map using the VME crate (group 0).
    //But we don't care about the Veto system (group 1).
    ORMPodCrateModel* hvCrateObj[2] = {nil,nil};
    hvCrateObj[0] = [[[NSApp delegate] document] findObjectWithFullID:@"ORMPodCrateModel,0"];
    hvCrateObj[1] = [[[NSApp delegate] document] findObjectWithFullID:@"ORMPodCrateModel,1"];
    
    ORSegmentGroup* group = [self segmentGroup:0];
    int n = [group numSegments];    //both DAQ and Veto on the same HV supply now
    int i;
    for(i=0;i<n;i++){
        ORDetectorSegment* seg =  [group segment:i];        //get a segment from the group
		int vmeCrate = [[seg objectForKey:@"kVME"] intValue];           //pull out the crate
        if(vmeCrate == aVmeCrate){
            int hvCrate = [[seg objectForKey:@"kHVCrate"]intValue];    //pull out the crate
            int hvCard  = [[seg objectForKey:@"kHVCard"]intValue];     //pull out the card
            if(hvCrate<2){
                if(aState) {
                    [[hvCrateObj[hvCrate] cardInSlot:hvCard] addHvConstraint:@"MJD Vac" reason:[NSString stringWithFormat:@"HV (%d) Card (%d) mapped to VME %d and Vacuum Is Bad or Vacuum system is not communicating",hvCrate,hvCard,aVmeCrate]];
                }
                else {
                    [[hvCrateObj[hvCrate] cardInSlot:hvCard] removeHvConstraint:@"MJD Vac"];
                    [rampHVAlarm[aVmeCrate] setAcknowledged:NO];
                }
            }
        }
    }
}

- (void) rampDownHV:(int)aCrate vac:(int)aVacSystem
{
    if(!rampHVAlarm[aVacSystem]){
        rampHVAlarm[aVacSystem] = [[ORAlarm alloc] initWithName:[NSString stringWithFormat:@"Panic HV (Vac %c)",'A'+aVacSystem] severity:(kEmergencyAlarm)];
        [rampHVAlarm[aVacSystem] setSticky:NO];
        [rampHVAlarm[aVacSystem] setHelpString:[NSString stringWithFormat:@"HV was ramped down on Module %d because Vac %c failed interlocks\nThe alarm can be cleared by acknowledging it.",aCrate+1, 'A'+aVacSystem]];
        NSLogColor([NSColor redColor], @"HV was ramped down on Module %d because Vac %c failed interlocks\n",aCrate+1,
                   'A'+aVacSystem);
    }
    
    if(![rampHVAlarm[aVacSystem] acknowledged]){
       [rampHVAlarm[aVacSystem] postAlarm];
    }
    
    if(aVacSystem==0 && ignorePanicOnA)return;
    if(aVacSystem==1 && ignorePanicOnB)return;
    
    //tricky .. we have to location the HV crates based on the hv map using the VME crate (group 0).
    //But we don't care about the Veto system (group 1).
    ORMPodCrateModel* hvCrateObj[2] = {nil,nil};
    hvCrateObj[0] = [[[NSApp delegate] document] findObjectWithFullID:@"ORMPodCrateModel,0"];
    hvCrateObj[1] = [[[NSApp delegate] document] findObjectWithFullID:@"ORMPodCrateModel,1"];
    
    ORSegmentGroup* group = [self segmentGroup:0];
    //both DAQ and Veto on the same HV supply now
    int n = [group numSegments];
    int i;
    for(i=0;i<n;i++){
        ORDetectorSegment* seg = [group segment:i];                    //get a segment from the group
		int vmeCrate = [[seg objectForKey:@"kVME"] intValue];           //pull out the crate
        if(vmeCrate == aCrate){
            int hvCrate   = [[seg objectForKey:@"kHVCrate"]intValue];     //pull out the crate
            int hvCard    = [[seg objectForKey:@"kHVCard"]intValue];     //pull out the card
            if(hvCrate<2){
                [[hvCrateObj[hvCrate] cardInSlot:hvCard] panicAllChannels];
            }
        }
    }
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setIgnorePanicOnB:[decoder decodeBoolForKey:@"ignorePanicOnB"]];
    [self setIgnorePanicOnA:[decoder decodeBoolForKey:@"ignorePanicOnA"]];
    [self setViewType:[decoder decodeIntForKey:@"viewType"]];
    int i;
    for(i=0;i<2;i++){
        scriptModel[i] = [[OROpSequence alloc] initWithDelegate:self idIndex:i];
        [scriptModel[i] setSteps:[self scriptSteps:i]];
    }
    pollTime  = [decoder decodeIntForKey:	@"pollTime"];
    stringMap = [[decoder decodeObjectForKey:@"stringMap"] retain];

	[self validateStringMap];
    [self setDetectorStringPositions];
	[[self undoManager] enableUndoRegistration];

    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:ignorePanicOnB forKey:@"ignorePanicOnB"];
    [encoder encodeBool:ignorePanicOnA forKey:@"ignorePanicOnA"];
    [encoder encodeInt:viewType     forKey: @"viewType"];
	[encoder encodeInt:pollTime		forKey: @"pollTime"];
    [encoder encodeObject:stringMap	forKey: @"stringMap"];
}

- (NSString*) reformatSelectionString:(NSString*)aString forSet:(int)aSet
{
	if([aString length] == 0)return @"Not Mapped";
	if(aSet==0){
        NSString* finalString = @"";
        NSArray* parts = [aString componentsSeparatedByString:@"\n"];
        
        NSString* gainType = [self getValueForPartStartingWith: @" GainType"   parts:parts];
        if([gainType length]==0)return @"Not Mapped";
        if([gainType intValue]==0)gainType = @"Low Gain";
        else gainType = @"Hi Gain";
 
        NSString* detType = [self getValueForPartStartingWith: @" DetectorType"   parts:parts];
        if([detType length]==0)return @"Not Mapped";
        if([detType intValue]==0)    detType = @" BeGe";
        else if([detType intValue]==2)detType = @" Enriched";
        else detType = @"";

        
        finalString = [finalString stringByAppendingFormat: @"%@\n",[parts objectAtIndex:0]];
        finalString = [finalString stringByAppendingFormat: @"%@%@\n",[self getPartStartingWith: @" DetectorName"   parts:parts],detType];
        finalString = [finalString stringByAppendingFormat: @"%@\n",[self getPartStartingWith: @" VME"       parts:parts]];
        finalString = [finalString stringByAppendingFormat: @"%@\n",[self getPartStartingWith: @" CardSlot"  parts:parts]];
        finalString = [finalString stringByAppendingFormat: @"%@ (%@)\n",[self getPartStartingWith: @" Channel"   parts:parts],gainType];
        
        finalString = [finalString stringByAppendingFormat: @"%@\n",[self getPartStartingWith: @" PreAmpChan"   parts:parts]];

        finalString = [ finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith: @" HVCrate"  parts:parts]];
        finalString = [finalString stringByAppendingFormat: @"%@\n",[self getPartStartingWith: @" HVCard"   parts:parts]];
        finalString = [finalString stringByAppendingFormat: @"%@\n",[self getPartStartingWith: @" HVChan"   parts:parts]];

        
        finalString = [finalString stringByAppendingFormat: @"%@\n",[self getPartStartingWith: @" Threshold" parts:parts]];
        
        return finalString;
    }
    else if(aSet==1){
        NSString* finalString = @"";
        NSArray* parts = [aString componentsSeparatedByString:@"\n"];
        if([parts count]<6)return @"Not Mapped";
        
        finalString = [finalString stringByAppendingFormat:@"%@\n",[parts objectAtIndex:0]];
        finalString = [finalString stringByAppendingFormat: @"%@\n",[self getPartStartingWith: @" Segment"   parts:parts]];
        finalString = [ finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith: @" VME"       parts:parts]       ];
        finalString = [finalString stringByAppendingFormat: @"%@\n",[self getPartStartingWith: @" CardSlot"  parts:parts]];
        finalString = [finalString stringByAppendingFormat: @"%@\n",[self getPartStartingWith: @" Channel"   parts:parts]];
 
        finalString = [ finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith: @" HVCrate" parts:parts]];
        finalString = [finalString stringByAppendingFormat: @"%@\n",[self getPartStartingWith: @" HVCard"  parts:parts]];
        finalString = [finalString stringByAppendingFormat: @"%@\n",[self getPartStartingWith: @" HVChan"  parts:parts]];
        
        finalString = [finalString stringByAppendingFormat: @"%@\n",[self getPartStartingWith: @" Threshold" parts:parts]];

        return finalString;
    }
    else return @"Not Mapped";
}

- (NSString*) getPartStartingWith:(NSString*)aLabel parts:(NSArray*)parts
{
	for(id aLine in parts){
		if([aLine rangeOfString:aLabel].location != NSNotFound) return aLine;
	}
	return @"";
}

- (NSString*) getValueForPartStartingWith:(NSString*)aLabel parts:(NSArray*)parts
{
	for(id aLine in parts){
		if([aLine rangeOfString:aLabel].location != NSNotFound){
            NSArray* subParts = [aLine componentsSeparatedByString:@":"];
            if([subParts count]>=2){
                return [subParts objectAtIndex:1];
            }
        }
	}
	return @"";
}

- (void) readAuxFiles:(NSString*)aPath
{
	aPath = MJDStringMapFile([aPath stringByDeletingPathExtension]);
    
	NSFileManager* fm = [NSFileManager defaultManager];
	if([fm fileExistsAtPath:aPath]){
		NSArray* lines  = [self linesInFile:aPath];
		for(id aLine in lines){
			if([aLine length] && [aLine characterAtIndex:0] != '#'){ //skip comments
				NSArray* parts =  [aLine componentsSeparatedByString:@","];
				if([parts count]>=3){
                    
                    if([[parts objectAtIndex:0] rangeOfString:@"S"].location != NSNotFound)continue;
                    
					int index = [[parts objectAtIndex:0] intValue];
					if(index<14){
						NSMutableDictionary* dict = [stringMap objectAtIndex:index];
						[dict setObject:[parts objectAtIndex:0] forKey:@"kStringNum"];
						[dict setObject:[parts objectAtIndex:1] forKey:@"kDet1"];
						[dict setObject:[parts objectAtIndex:2] forKey:@"kDet2"];
						[dict setObject:[parts objectAtIndex:3] forKey:@"kDet3"];
						[dict setObject:[parts objectAtIndex:4] forKey:@"kDet4"];
						[dict setObject:[parts objectAtIndex:5] forKey:@"kDet5"];
					}
				}
			}
		}
	}
}

- (void) saveAuxFiles:(NSString*)aPath
{
	aPath = MJDStringMapFile([aPath stringByDeletingPathExtension]);
	NSFileManager*   fm       = [NSFileManager defaultManager];
	if([fm fileExistsAtPath: aPath])[fm removeItemAtPath:aPath error:nil];
	NSData* data = [[self mapFileAsString] dataUsingEncoding:NSASCIIStringEncoding];
	[fm createFileAtPath:aPath contents:data attributes:nil];
}

- (NSString*) mapFileAsString
{
   	NSMutableString* stringRep = [NSMutableString string];
    [stringRep appendFormat:@"String,Det1,Det2,Det3,Det4,Det5\n"];
	for(id item in stringMap)[stringRep appendFormat:@"%@,%@,%@,%@,%@,%@\n",
                              [item objectForKey:@"kStringNum"],
                              [item objectForKey:@"kDet1"],
                              [item objectForKey:@"kDet2"],
                              [item objectForKey:@"kDet3"],
                              [item objectForKey:@"kDet4"],
                              [item objectForKey:@"kDet5"]
                              ];
    [stringRep deleteCharactersInRange:NSMakeRange([stringRep length]-1,1)];
    return stringRep;
}

#pragma mark ¥¥¥String Map Access Methods
- (id) stringMap:(int)i objectForKey:(id)aKey
{
	if(i>=0 && i<kMaxNumStrings){
		return [[stringMap objectAtIndex:i] objectForKey:aKey];
	}
	else return @"";
}

- (BOOL) validateDetector:(int)aDetectorIndex
{
    int numSegments = [self numberSegmentsInGroup:0];
    if(aDetectorIndex>=0 && aDetectorIndex<numSegments){
        ORSegmentGroup* segmentGroup = [self segmentGroup:0];
        NSDictionary* params = [[segmentGroup segment:aDetectorIndex]params];
        if(!params)return NO;
        NSString* aCrate = [params objectForKey:@"kVME"];
        if([aCrate length]==0 || [aCrate rangeOfString:@"-"].location!=NSNotFound)return NO;

        NSString* aCard = [params objectForKey:@"kCardSlot"];
        if([aCard length]==0 || [aCard rangeOfString:@"-"].location!=NSNotFound)return NO;
                                 
         NSString* aChannel = [params objectForKey:@"kChannel"];
         if([aChannel length]==0 || [aChannel rangeOfString:@"-"].location!=NSNotFound)return NO;

        NSString* aName = [params objectForKey:@"kDetectorName"];
        if([aName length]==0 || [aName rangeOfString:@"-"].location!=NSNotFound)return NO;

        return YES;
    }
    
    return NO;
}

- (void) stringMap:(int)i setObject:(id)anObject forKey:(id)aKey
{
	if(i>=0 && i<kMaxNumStrings){
		id entry = [stringMap objectAtIndex:i];
		id oldValue = [self stringMap:i objectForKey:aKey];
		if(oldValue)[[[self undoManager] prepareWithInvocationTarget:self] stringMap:i setObject:oldValue forKey:aKey];
		[entry setObject:anObject forKey:aKey];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORMJDAuxTablesChanged object:self userInfo:nil];
		
	}
}

#pragma mark ¥¥¥CardHolding Protocol
- (int) maxNumberOfObjects              { return 2; }
- (int) objWidth                        { return 50; }	//In this case, this is really the obj height.
- (int) groupSeparation                 { return 0; }
- (NSString*) nameForSlot:(int)aSlot    { return [NSString stringWithFormat:@"Slot %d",aSlot]; }
- (int) slotForObj:(id)anObj            { return [anObj tag]; }
- (int) numberSlotsNeededFor:(id)anObj  { return 1;           }
- (int) slotAtPoint:(NSPoint)aPoint     { return floor(((int)aPoint.y)/[self objWidth]); }
- (NSPoint) pointForSlot:(int)aSlot     { return NSMakePoint(0,aSlot*[self objWidth]); }

- (NSRange) legalSlotsForObj:(id)anObj
{
	if([anObj isKindOfClass:NSClassFromString(@"ORRemoteSocketModel")])			return NSMakeRange(0,2);
    else return NSMakeRange(0,0);
}

- (BOOL) slot:(int)aSlot excludedFor:(id)anObj
{
	if([anObj isKindOfClass:NSClassFromString(@"ORRemoteSocketModel")])	return NO;
    else return YES;
}

- (void) place:(id)anObj intoSlot:(int)aSlot
{
    [anObj setTag:aSlot];
	NSPoint slotPoint = [self pointForSlot:aSlot];
	[anObj moveTo:slotPoint];
}

- (void) openDialogForComponent:(int)i
{
	for(OrcaObject* anObj in [self orcaObjects]){
		if([anObj tag] == i){
			[anObj makeMainController];
			break;
		}
	}
}


//
// ScriptSteps
//
// returns the array of steps used in the ScriptQueue.
//
- (NSArray*) scriptSteps:(int) index
{
    //assume that index is both the index of the Vac system (A,B) and the VME crate (module0,1)
    //steps are executed in order, but may be skipped under certain conditions
	NSMutableArray *steps = [NSMutableArray array];
    
    ORRemoteSocketModel* remObj = [self remoteSocket:index];
    NSString*               ip  = [remObj remoteHost];
    
    //---------------------ping machine---------------------
    [steps addObject: [ORShellStep shellStepWithCommandLine: @"/sbin/ping",@"-c",@"1",@"-t",@"1",@"-q",ip,nil]];
	[[steps lastObject] setTrimNewlines:YES];
	[[steps lastObject] setErrorStringErrorPattern:  @".+"];
    [[steps lastObject] setOutputStringErrorPattern: @".* 100.0%.*"];
	[[steps lastObject] setOutputStateKey:           @"vacSystemPingOK"];
	[[steps lastObject] setSuccessTitle:             @"Ping: OK"];
	[[steps lastObject] setErrorTitle:               @"Ping: Failed"];
	[[steps lastObject] setPersistentStorageObj:scriptModel[index] accessKey:[NSString stringWithFormat:@"Ping%d",index]];
	[[steps lastObject] setNumAllowedErrors:5];
	[[steps lastObject] setTitle:                    [NSString stringWithFormat:@"Ping: CryoVac%c",'A'+index]];
    //----------------------------------------------------------

    //---------------------check if HV is on---------------------
    [steps addObject: [ORInvocationStep invocation: [NSInvocation invocationWithTarget:self
                                                                              selector:@selector(anyHvOnVMECrate:)
                                                                       retainArguments:NO, (NSUInteger)index]]];
    [[steps lastObject] setOutputStringErrorPattern: @"0"];
	[[steps lastObject] setSuccessTitle:@"HV On"];
	[[steps lastObject] setErrorTitle:  @"HV Off"];
    
	[[steps lastObject] setOutputStateKey:@"HVOn"];
	[[steps lastObject] setTitle:@"Check HV Bias"];
    //----------------------------------------------------------

    //-------set the bias condition in the Vac system-----------
    //can only execute if the vac system was pinged successfully
    //the command sent is based on the HV state from the kHVOnId step
    [steps addObject: [ORRemoteSocketStep remoteSocket: remObj
                                      commandSelection: [ScriptValue scriptValueWithKey:@"HVOn"]
                                              commands: @"[ORMJDVacuumModel,1 setDetectorsBiased:0];", //HVOn == NO run this
                                                        @"[ORMJDVacuumModel,1 setDetectorsBiased:1];", //HVOn == YES run this
                                                        nil]];
	[[steps lastObject] setPersistentStorageObj:scriptModel[index] accessKey:[NSString stringWithFormat:@"SetVacHVState%d",index]];
	[[steps lastObject] setNumAllowedErrors:5];

    
    [[steps lastObject] addSkipCondition:   @"vacSystemPingOK" value: @"-1"]; //skip if ping is in warning state
    [[steps lastObject] addAndCondition:    @"vacSystemPingOK" value: @"1"];
	[[steps lastObject] setErrorTitle:      @"No Comm To Vac"];
	[[steps lastObject] setTitle:           @"Send HV --> Vac System"];
    //----------------------------------------------------------
    
    //-----------------check vacuuum conditions-----------------    
    //can only execute if the vac system was pinged successfully
    [steps addObject: [ORRemoteSocketStep remoteSocket: remObj
                                      commandSelection: nil
                                              commands: @"shouldUnbias = [ORMJDVacuumModel,1 shouldUnbiasDetector];",
                                                        @"okToBias     = [ORMJDVacuumModel,1 okToBiasDetector];",
                                                        [NSString stringWithFormat:@"[ORMJDVacuumModel,1 setHvUpdateTime:%d];",pollTime],
                                                        nil]];

    [[steps lastObject] setPersistentStorageObj:scriptModel[index] accessKey:[NSString stringWithFormat:@"CheckVacState%d",index]];
	[[steps lastObject] setNumAllowedErrors:5];

    [[steps lastObject] addSkipCondition: @"vacSystemPingOK" value: @"-1"]; //skip if ping is in warning state
    [[steps lastObject] addAndCondition:  @"vacSystemPingOK" value: @"1"]; 

    //this step state is error free ONLY if the following values are met.
	[[steps lastObject] require:          @"shouldUnbias" value:@"0"];
	[[steps lastObject] require:          @"okToBias"     value:@"1"];
    [[steps lastObject] setOutputStateKey:@"OKForHV"];

	[[steps lastObject] setSuccessTitle:@"Vac: OK"];
	[[steps lastObject] setErrorTitle:  @"Vac: BAD or No Comm"];
	[[steps lastObject] setTitle:       [NSString stringWithFormat:@"Check CryoVac%c",'A'+index]];
    //----------------------------------------------------------

    //---------------------Ramp Down HV---------------------
    [steps addObject: [ORInvocationStep invocation: [NSInvocation invocationWithTarget:self
                                                                              selector:@selector(rampDownHV:vac:)
                                                                       retainArguments:NO,
                                                                            (NSUInteger)0,
                                                                            (NSUInteger)index]]];

    //if Vac system ping failed OR not OK for HV AND HV is On then the invocation will run
    [[steps lastObject] addSkipCondition: @"vacSystemPingOK" value: @"-1"]; //skip if ping is in warning state
    
    [[steps lastObject] addOrCondition:  @"vacSystemPingOK" value: @"0"];
    [[steps lastObject] addOrCondition:  @"OKForHV"         value: @"0"];
    [[steps lastObject] addAndCondition: @"HVOn"            value: @"1"];

	[[steps lastObject] setSuccessTitle:    @"Started Ramp Down"];
	[[steps lastObject] setOutputStateKey:  @"HVRamped"];
    NSString* rampDownTitle = @"Ramp Down HV";
	if(index ==0){
        if([self ignorePanicOnA])rampDownTitle = @"HV Action Ignored";
    }
    else {
        if([self ignorePanicOnB])rampDownTitle = @"HV Action Ignored";
    }
    [[steps lastObject] setTitle: rampDownTitle];
    //----------------------------------------------------------
    
    //---------------------add Constrain HV---------------------
    [steps addObject: [ORInvocationStep invocation: [NSInvocation invocationWithTarget:self
                                                                              selector:@selector(setVmeCrateHVConstraint:state:)
                                                                       retainArguments:YES,
                                                                            (NSUInteger)index,
                                                                            (NSUInteger)1]]];
            
    //if Vac system ping failed OR not OK for HV AND HV is Off then the invocation will run and add a constraint on the HV system
    [[steps lastObject] addOrCondition:  @"vacSystemPingOK"  value: @"0"];
    [[steps lastObject] addOrCondition:  @"OKForHV"          value: @"0"];
    [[steps lastObject] addAndCondition: @"HVOn"             value: @"0"];

	[[steps lastObject] setTitle:         @"Add HV Constraints"];
    [[steps lastObject] setOutputStateKey:@"AddedHVContraint"];
    //----------------------------------------------------------

    //---------------------remove Constrain HV---------------------
    [steps addObject: [ORInvocationStep invocation: [NSInvocation invocationWithTarget:self
                                                                              selector:@selector(setVmeCrateHVConstraint:state:)
                                                                       retainArguments:YES,
                                                     (NSUInteger)index,
                                                     (NSUInteger)0]]];
    
    //if Vac system ping succeeded OR OK for HV then the invocation will run and remove constraint on the HV system
    [[steps lastObject] addAndCondition: @"vacSystemPingOK"  value: @"1"];
    [[steps lastObject] addAndCondition: @"OKForHV"          value: @"1"];
    
	[[steps lastObject] setTitle:   @"Remove HV Constraints"];
    //----------------------------------------------------------

	return steps;
}
- (void) setDetectorStringPositions
{
    //first must reset all positions
    ORSegmentGroup* segmentGroup = [self segmentGroup:0];
    int numSegments = [self numberSegmentsInGroup:0];
    int i;
    for(i = 0; i<numSegments; i++){
        [segmentGroup setSegment:i object:[NSNumber numberWithInt:999] forKey:@"kStringNum"];
        [segmentGroup setSegment:i object:[NSNumber numberWithInt:999] forKey:@"kPosition"];
    }
    
    for(i=0;i<14;i++){
        int j;
        for(j=0;j<5;j++){
            NSString* detectorNum = [self stringMap:i objectForKey:[NSString stringWithFormat:@"kDet%d",j+1]];
            if([detectorNum rangeOfString:@"-"].location == NSNotFound && [detectorNum length]!=0){
                int detIndex = [detectorNum intValue];
                [segmentGroup setSegment:detIndex*2 object:[NSNumber numberWithInt:i] forKey:@"kStringNum"];
                [segmentGroup setSegment:detIndex*2 object:[NSNumber numberWithInt:j] forKey:@"kPosition"];
            }
        }
    }
}

@end

@implementation MajoranaModel (private)
- (void) checkConstraints
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkConstraints) object:nil];
    int i;
    for(i=0;i<2;i++){
        if([self remoteSocket:i])[scriptModel[i] start];
    }
    if(pollTime)[self performSelector:@selector(checkConstraints) withObject:nil afterDelay:pollTime*60];
}

- (void) validateStringMap
{
	if(!stringMap){
		stringMap = [[NSMutableArray array] retain];
		int i;
		for(i=0;i<14;i++){
			[stringMap addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
							   [NSNumber numberWithInt:i], @"kStringNum",
							      @"-",						 @"kDet1",
                                  @"-",						 @"kDet2",
                                  @"-",						 @"kDet3",
                                  @"-",						 @"kDet4",
                                  @"-",						 @"kDet5",
                                  nil]];
		}
	}
}


- (NSArray*) linesInFile:(NSString*)aPath
{
	NSString* contents = [NSString stringWithContentsOfFile:[aPath stringByExpandingTildeInPath] encoding:NSASCIIStringEncoding error:nil];
	contents = [[contents componentsSeparatedByString:@"\r"] componentsJoinedByString:@"\n"];
	contents = [[contents componentsSeparatedByString:@"\n\n"] componentsJoinedByString:@"\n"];
    return [contents componentsSeparatedByString:@"\n"];
}

@end

