//
//  ORExperimentModel.m
//  Orca
//
//  Created by Mark Howe on 12/18/06.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
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


#import "ORExperimentModel.h"
#import "ORAxis.h"
#import "ORDataPacket.h"
#import "ORTimeRate.h"
#import "ORDataTypeAssigner.h"
#import "ORRunModel.h"
#import "ORDetectorSegment.h"
#import "ORSegmentGroup.h"

NSString* ORExperimentModelShowNamesChanged = @"ORExperimentModelShowNamesChanged";
NSString* ExperimentModelDisplayTypeChanged				 = @"ExperimentModelDisplayTypeChanged";
NSString* ExperimentModelSelectionStringChanged			 = @"ExperimentModelSelectionStringChanged";
NSString* ExperimentHardwareCheckChangedNotification     = @"ExperimentHardwareCheckChangedNotification";
NSString* ExperimentCardCheckChangedNotification         = @"ExperimentCardCheckChangedNotification";
NSString* ExperimentCaptureDateChangedNotification       = @"ExperimentCaptureDateChangedNotification";
NSString* ExperimentDisplayUpdatedNeeded			 	 = @"ExperimentDisplayUpdatedNeeded";
NSString* ExperimentCollectedRates						 = @"ExperimentCollectedRates";
NSString* ExperimentDisplayHistogramsUpdated			 = @"ExperimentDisplayHistogramsUpdated";
NSString* ExperimentModelSelectionChanged				 = @"ExperimentModelSelectionChanged";


@interface ORExperimentModel (private)
- (void) checkCardOld:(NSDictionary*)oldCardRecord new:(NSDictionary*)newCardRecord  check:(SEL)checkSelector exclude:(NSSet*)exclusionSet;
- (void) delayedHistogram;
@end

@implementation ORExperimentModel
#pragma mark •••Initialization
- (id) init
{
    self = [super init];
	[self makeSegmentGroups];			    
    return self;
}

-(void)dealloc
{	
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[segmentGroups release];
	[selectionString release];
        
    [failedHardwareCheckAlarm clearAlarm];
    [failedHardwareCheckAlarm release];
 
	[failedCardCheckAlarm clearAlarm];
    [failedCardCheckAlarm release];
   
    [captureDate release];
    [problemArray release];

    [super dealloc];
}

- (void) sleep
{
    [super sleep];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(collectRates) object:nil];
        
}

- (void) awakeAfterDocumentLoaded
{
	[segmentGroups makeObjectsPerformSelector:@selector(awakeAfterDocumentLoaded)];
}

- (BOOL) solitaryObject
{
    return YES;
}

- (void) addGroup:(ORSegmentGroup*)aGroup
{
	if(!segmentGroups)segmentGroups = [[NSMutableArray array] retain];
	if(![segmentGroups containsObject:aGroup]){
		[segmentGroups addObject:aGroup];
	}
}

#pragma mark •••Group Methods
- (void) registerForRates
{
	[segmentGroups makeObjectsPerformSelector:@selector(registerForRates)];
}


- (void) collectRatesFromAllGroups
{
	if([self guardian]){
		[segmentGroups makeObjectsPerformSelector:@selector(collectRates)];
	}
}

- (void) clearSegmentErrors 
{
	[segmentGroups makeObjectsPerformSelector:@selector(clearSegmentErrors)];
}

- (ORSegmentGroup*) segmentGroup:(int)aSet
{
	if(aSet>=0 && aSet < [segmentGroups count]){
		return [segmentGroups objectAtIndex:aSet];
	}
	else return nil;
}

- (void) selectedSet:(int)aSet segment:(int)index
{
	if(aSet>=0 && aSet < [segmentGroups count]){
		ORSegmentGroup* aGroup = [segmentGroups objectAtIndex:aSet];
		[self setSelectionString:[aGroup selectedSegementInfo:index]];	
		[self setSomethingSelected:YES];
	}
	else {
		[self setSomethingSelected:NO];
		[self setSelectionString:@"<Nothing Selected>"];	
	}
}

- (void) showDialogForSet:(int)aSet segment:(int)index
{ 
	if(aSet>=0 && aSet < [segmentGroups count]){
		ORSegmentGroup* aGroup = [segmentGroups objectAtIndex:aSet];
		[aGroup showDialogForSegment:index];
	}
}

- (void) showDataSetForSet:(int)aSet segment:(int)index
{ 
	//not implemented... up to subclasses to define
}


- (void) histogram
{
	[segmentGroups makeObjectsPerformSelector:@selector(histogram)];
}

- (void) setSegmentErrorClassName:(NSString*)aClassName card:(int)card channel:(int)channel
{
	NSEnumerator* e = [segmentGroups objectEnumerator];
	ORSegmentGroup* aGroup;
	while(aGroup = [e nextObject]){
		[aGroup setSegmentErrorClassName:aClassName card:card channel:channel];
	}
}

- (void) initHardware
{
	NSMutableSet* allCards = [NSMutableSet set];
	NSEnumerator* e = [segmentGroups objectEnumerator];
	ORSegmentGroup* aGroup;
	while(aGroup = [e nextObject]){
		[allCards unionSet:[aGroup hwCards]];
	}

	@try {
		[allCards makeObjectsPerformSelector:@selector(initBoard)];
		NSLog(@"%@ Adc cards inited\n",[self className]);
	}
	@catch (NSException * e) {
		NSLogColor([NSColor redColor],@"%@ Adc cards init failed\n",[self className]);
	}
}


#pragma mark •••Subclass Responsibility
- (void) makeSegmentGroups{;} //subclasses must override
- (int)  maxNumSegments{ return 0;} //subclasses must override

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(runStatusChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
 }

- (void) runStatusChanged:(NSNotification*)aNote
{
    int running = [[[aNote userInfo] objectForKey:ORRunStatusValue] intValue];
    if(running == eRunStopped){
        //[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(collectRates) object:nil];
        //[[self detector] unregisterRates];
    }
    else {
        [self registerForRates];
        [self collectRates];
    }
}

- (void) collectRates
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(collectRates) object:nil];
	if([self guardian]){
		[self collectRatesFromAllGroups];
	
		[[NSNotificationCenter defaultCenter]
			postNotificationName:ExperimentCollectedRates
						object:self];

	}
	[self performSelector:@selector(collectRates) withObject:nil afterDelay:1.0];
}

#pragma mark •••Specific Dialog Lock Methods
- (NSString*) experimentMapLock 
{
	return @"ExperimentMapLock";
}
- (NSString*) experimentDetectorLock;
{
	return @"ExperimentDetectorLock";
}
- (NSString*) experimentDetailsLock;
{
	return @"ExperimentDetailsLock";
}

#pragma mark •••Accessors

- (BOOL) showNames
{
    return showNames;
}

- (void) setShowNames:(BOOL)aShowNames
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShowNames:showNames];
    
    showNames = aShowNames;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORExperimentModelShowNamesChanged object:self];
}

- (void) setSomethingSelected:(BOOL)aFlag
{
    somethingSelected = aFlag;

    [[NSNotificationCenter defaultCenter] postNotificationName:ExperimentModelSelectionChanged object:self];
}

- (BOOL) somethingSelected
{
	return somethingSelected;
}
- (int) displayType
{
    return displayType;
}

- (void) setDisplayType:(int)aDisplayType
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDisplayType:displayType];
    
    displayType = aDisplayType;

    [[NSNotificationCenter defaultCenter] postNotificationName:ExperimentModelDisplayTypeChanged object:self];
}


- (NSString*) selectionString
{
	if(!selectionString)return @"<nothing selected>";
    else return selectionString;
}

- (void) setSelectionString:(NSString*)aSelectionString
{
    [selectionString autorelease];
    selectionString = [aSelectionString copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ExperimentModelSelectionStringChanged object:self];
}

- (BOOL) replayMode
{
	return replayMode;
}

- (void) setReplayMode:(BOOL)aReplayMode
{
	replayMode = aReplayMode;
	//[[Prespectrometer sharedInstance] setReplayMode:aReplayMode];
}

- (int) hardwareCheck
{
    return hardwareCheck;
}

- (void) setHardwareCheck: (int) aState
{
    hardwareCheck = aState;
    [[NSNotificationCenter defaultCenter] 
        postNotificationName:ExperimentHardwareCheckChangedNotification
                      object:self];
    
    if(hardwareCheck==NO) {
		if(!failedHardwareCheckAlarm){
			failedHardwareCheckAlarm = [[ORAlarm alloc] initWithName:@"Hardware Check Failed" severity:kSetupAlarm];
			[failedHardwareCheckAlarm setSticky:YES];
		}
		[failedHardwareCheckAlarm setAcknowledged:NO];
		[failedHardwareCheckAlarm postAlarm];
        [failedHardwareCheckAlarm setHelpStringFromFile:@"HardwareCheckHelp"];
    }
    else {
        [failedHardwareCheckAlarm clearAlarm];
    }
    
}

- (int) cardCheck
{
    return cardCheck;
}

- (void) setCardCheck: (int) aState
{
    cardCheck = aState;
    [[NSNotificationCenter defaultCenter]
         postNotificationName:ExperimentCardCheckChangedNotification
                       object:self];
    
    if(cardCheck==NO) {
		if(!failedCardCheckAlarm){
			failedCardCheckAlarm = [[ORAlarm alloc] initWithName:@"Card Check Failed" severity:kSetupAlarm];
			[failedCardCheckAlarm setSticky:YES];
		}
		[failedCardCheckAlarm setAcknowledged:NO];
		[failedCardCheckAlarm postAlarm];
        [failedCardCheckAlarm setHelpStringFromFile:@"CardCheckHelp"];
    }
    else {
        [failedCardCheckAlarm clearAlarm];
    }
}

- (void) setCardCheckFailed
{
    [self setCardCheck:NO];
}

- (void) setHardwareCheckFailed
{
    [self setHardwareCheck:NO];
}

- (NSDate *) captureDate
{
    return captureDate; 
}

- (void) setCaptureDate: (NSDate *) aCaptureDate
{
    [aCaptureDate retain];
    [captureDate release];
    captureDate = aCaptureDate;
    
    [[NSNotificationCenter defaultCenter] 
        postNotificationName:ExperimentCaptureDateChangedNotification
                      object:self];
    
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setShowNames:[decoder decodeBoolForKey:@"ORExperimentModelShowNames"]];
    [self setDisplayType:[decoder decodeIntForKey:   @"ExperimentModelDisplayType"]];	
    [self setCaptureDate:[decoder decodeObjectForKey:@"ExperimentCaptureDate"]];
	segmentGroups = [[decoder decodeObjectForKey:	 @"ExperimentSegmentGroups"] retain];
    [[self undoManager] enableUndoRegistration];
    
    [self setHardwareCheck:2]; //unknown
    [self setCardCheck:2];

    [self registerNotificationObservers];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:showNames forKey:@"ORExperimentModelShowNames"];
    [encoder encodeInt:displayType forKey:   @"ExperimentModelDisplayType"];
    [encoder encodeObject:captureDate forKey:@"ExperimentCaptureDate"];
    [encoder encodeObject:segmentGroups forKey:@"ExperimentSegmentGroups"];
}

- (NSMutableDictionary*) captureState
{
    NSMutableDictionary* stateDictionary = [NSMutableDictionary dictionary];
    [[self document] addParametersToDictionary: stateDictionary];
    [stateDictionary writeToFile:[[self capturePListsFile] stringByExpandingTildeInPath] atomically:YES];
    
    [self setHardwareCheck:YES];
    [self setCardCheck:YES];
    [self setCaptureDate:[NSDate date]];
    return stateDictionary;
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)aDictionary
{
    NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];
        
    [aDictionary setObject:objDictionary forKey:@"ExperimentModel"];
    return aDictionary;
}

- (NSString*) capturePListsFile
{
	return [NSString stringWithFormat:@"~/Library/Preferences/edu.washington.npl.orca.capture.%@.plist",[self className]];
}


#pragma mark •••Work Methods
- (void) compileHistograms
{
	if(!scheduledToHistogram){
		[self performSelector:@selector(delayedHistogram) withObject:nil afterDelay:1];
		scheduledToHistogram = YES;
	}
}

//a highly hardcoded config checker. Assumes things like only one crate, ect.
- (BOOL) preRunChecks
{
	[self clearSegmentErrors];
	
    NSMutableDictionary* newDictionary  = [[self document] addParametersToDictionary: [NSMutableDictionary dictionary]];
    NSDictionary* oldDictionary         = [NSDictionary dictionaryWithContentsOfFile:[[self capturePListsFile] stringByExpandingTildeInPath]];
    
    [problemArray release];
    problemArray = [[NSMutableArray array]retain];
    // --crate presence must be same
    // --number of cards must match
    // --slots must match
    
    //init the checks to 'unknown'
    [self setHardwareCheck:2];
    [self setCardCheck:2];
    
    NSDictionary* newCrateDictionary = [newDictionary objectForKey:@"crate 0"];
    NSDictionary* oldCrateDictionary = [oldDictionary objectForKey:@"crate 0"];
    if(!newCrateDictionary  && oldCrateDictionary){
        [self setHardwareCheck:NO];
        [problemArray addObject:@"Crate has been removed\n"];
    }
    if(!oldCrateDictionary  && newCrateDictionary){
        [self setHardwareCheck:NO];
        [problemArray addObject:@"Crate has been added\n"];
    }
    if(newCrateDictionary && oldCrateDictionary && ![[newCrateDictionary objectForKey:@"count"] isEqualToNumber:[oldCrateDictionary objectForKey:@"count"]]){
        [self setHardwareCheck:NO];
        [problemArray addObject:@"Card count is different\n"];
    }
    
    //first scan for the cards    
    NSArray* newCardKeys = [newCrateDictionary allKeys];        
    NSArray* oldCardKeys = [oldCrateDictionary allKeys];
    NSEnumerator* eNew =  [newCardKeys objectEnumerator];
    id newCardKey;
    while( newCardKey = [eNew nextObject]){ 
        //loop over all cards, comparing old card records to new ones.
        id newCardRecord = [newCrateDictionary objectForKey:newCardKey];
        if(![[newCardRecord class] isSubclassOfClass:NSClassFromString(@"NSDictionary")])continue;
        NSEnumerator* eOld =  [oldCardKeys objectEnumerator];
        id oldCardKey;
        //grab some objects that we'll use more than once below
		NSString* slotKey = @"slot";
		if( ![newCardRecord objectForKey:slotKey]) slotKey = @"station";             
        NSNumber* newSlot           = [newCardRecord objectForKey:slotKey];

        while( oldCardKey = [eOld nextObject]){ 
            id oldCardRecord = [oldCrateDictionary objectForKey:oldCardKey];
            if(![[oldCardRecord class] isSubclassOfClass:NSClassFromString(@"NSDictionary")])continue;
			NSNumber* oldSlot           = [oldCardRecord objectForKey:slotKey];

            if(newSlot && oldSlot && [newSlot isEqualToNumber:oldSlot]){
				[self checkCardOld:oldCardRecord new:newCardRecord   check:@selector(setCardCheckFailed) exclude:[NSSet setWithObjects:@"thresholdAdcs",nil]];
                //found a card so we are done.
                break;
			}
        }
    }
    
    BOOL passed = YES;
    if(hardwareCheck == 2) [self setHardwareCheck:YES];
    else if(hardwareCheck == 0){
        NSLogColor([NSColor redColor],@"Failed Hardware Config Check\n");
        passed = NO;
    }
    
    if(cardCheck == 2)[self setCardCheck:YES];
    else if(cardCheck == 0){
        NSLogColor([NSColor redColor],@"Failed Shaper Config Check\n");
        passed = NO;
    }
            
    if(passed)NSLog(@"Passed Configuration Checks\n");
    else {
        NSEnumerator* e = [problemArray objectEnumerator];
        id s;
        if([problemArray count]){
            NSLog(@"Configuration Check Problem Summary\n");
            while(s = [e nextObject]) NSLog(s);
            NSLog(@"\n");
        }
    }
	[[NSNotificationCenter defaultCenter] postNotificationName:ExperimentDisplayUpdatedNeeded object:self];

    return passed;
}

- (void) printProblemSummary
{
    [self preRunChecks];
}

@end

@implementation ORExperimentModel (private)
- (void) checkCardOld:(NSDictionary*)oldRecord new:(NSDictionary*)newRecord  check:(SEL)checkSelector exclude:(NSSet*)exclusionSet
{
    NSEnumerator* e = [oldRecord keyEnumerator];
    id aKey;
	NSString* slotKey = @"slot";
	if(![oldRecord objectForKey:slotKey])slotKey = @"station";
	BOOL segmentErrorNoted = NO;
    while(aKey = [e nextObject]){
        if(![exclusionSet containsObject:aKey]){
			id oldValues = [oldRecord objectForKey:aKey];
			id newValues =  [newRecord objectForKey:aKey];
            if(![oldValues isEqualTo:newValues]){
                [self performSelector:checkSelector];
                [problemArray addObject:[NSString stringWithFormat:@"%@ slot %@ changed.\n",
                    [oldRecord objectForKey:@"Class Name"],
                    [oldRecord objectForKey:slotKey], aKey]];
                
                [problemArray addObject:[NSString stringWithFormat:@"%@ (at least one changed):\noldValues:%@\nnewValues:%@\n",aKey,oldValues,newValues]];
				
				if(!segmentErrorNoted){
					segmentErrorNoted = YES;
					int numChannels = [newValues count];
					int channel;
					for(channel = 0;channel<numChannels;channel++){
						id newValue = [newValues objectAtIndex:channel];
						id oldValue = [oldValues objectAtIndex:channel];
						if(![newValue  isEqualTo: oldValue ]){
							int card = [[oldRecord objectForKey:slotKey] intValue];
							[self setSegmentErrorClassName:[oldRecord objectForKey:@"Class Name"] card:card channel:channel];
						}
					}
				}
            }
        }
    }
}

- (void) delayedHistogram
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedHistogram) object:nil];
	[self histogram];

	scheduledToHistogram = NO;

    [[NSNotificationCenter defaultCenter]
        postNotificationName:ExperimentDisplayHistogramsUpdated
                      object:self];

}


@end

