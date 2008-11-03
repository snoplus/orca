//
//  ORCrate.m
//  Orca
//
//  Created by Mark Howe on Fri Nov 22 2002.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORCrate.h"
#import "ORCard.h"
#import "ORGTIDGenerator.h"

#pragma mark ¥¥¥Notification Strings
NSString* ORCrateAdapterChangedNotification = @"ORCrateAdapterChangedNotification";
NSString* ORCrateAdapterConnector		    = @"ORCrateAdapterConnector";
NSString* ORCrateModelShowLabelsChanged		= @"ORCrateModelShowLabelsChanged";
NSString* ORCrateModelCrateNumberChanged	= @"ORCrateModelCrateNumberChanged";

@implementation ORCrate

#pragma mark ¥¥¥initialization

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[cardRates release];
    [cratePowerAlarm clearAlarm];
    [cratePowerAlarm release];
	[super dealloc];
}

- (void) wakeUp
{
    if(![self aWake]){
        [self performSelector:@selector(pollCratePower) withObject:nil afterDelay:0.5];
		[self setUpImage];
    }
    [super wakeUp];
}

- (void) sleep
{
    [super sleep];
   // [cratePowerAlarm clearAlarm];
   // [cratePowerAlarm release];
   // cratePowerAlarm = nil;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (NSString*) crateAdapterConnectorKey
{
	return ORCrateAdapterConnector;
}

- (void) makeConnectors
{	
	ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint([self x]+kConnectorSize,[self y] ) withGuardian:self withObjectLink:self];
	[[self connectors] setObject:aConnector forKey:[self crateAdapterConnectorKey]];
	[aConnector release];
}

- (void) setUniqueIdNumber:(unsigned long)anIdNumber
{
	[super setUniqueIdNumber:anIdNumber];
	[self setCrateNumber:anIdNumber-1];
}

#pragma mark ¥¥¥Accessors
- (id) adapter
{
	return adapter;
}

- (void) setAdapter:(id)anAdapter
{
	[[[self undoManager] prepareWithInvocationTarget:self] setAdapter:[self adapter]];
    
	[anAdapter retain];
	[adapter release];
	adapter = anAdapter;
    
	[[[self connectors] objectForKey:[self crateAdapterConnectorKey]] setObjectLink: adapter];
	
	[[NSNotificationCenter defaultCenter]
		postNotificationName:ORCrateAdapterChangedNotification
                      object:self];
    
}
- (BOOL) showLabels
{
	return showLabels;
}

- (void) setShowLabels:(BOOL)aState
{
	[[[self undoManager] prepareWithInvocationTarget:self] setShowLabels:showLabels];
    
	showLabels = aState;
    	
	[[NSNotificationCenter defaultCenter]
		postNotificationName:ORCrateModelShowLabelsChanged
                      object:self];
}

- (id) controllerCard
{
	return [self objectConnectedTo:[self crateAdapterConnectorKey]];
}

- (NSDictionary*) cardRates
{
	return cardRates;
}
- (void) setCardRates:(NSMutableDictionary*)newCardRates
{
	[cardRates autorelease];
	cardRates=[newCardRates retain];
}



- (void) doNoPowerAlert:(NSException*)exception action:(NSString*)message
{
    NSLogColor([NSColor redColor],@"****** Check Crate Power and Cable ******\n");
    NSRunAlertPanel([exception name], @"%@\nFailed: <%@>", @"OK", nil, nil,exception,message);
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(viewChanged:)
                         name : ORGroupObjectsAdded
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(viewChanged:)
                         name : ORGroupObjectsRemoved
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(childChanged:)
                         name : OROrcaObjectMoved
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(childChanged:)
                         name : OROrcaObjectImageChanged
                       object : nil];
    
    [notifyCenter addObserver: self
                     selector: @selector(runStarted:)
                         name: ORRunStartedNotification
                       object: nil];
    
    [notifyCenter addObserver: self
                     selector: @selector(runAboutToStart:)
                         name: ORRunAboutToStartNotification
                       object: nil];
    
    
    [notifyCenter addObserver: self
                     selector: @selector(runAboutToStop:)
                         name: ORRunAboutToStopNotification
                       object: nil];
    

    [notifyCenter addObserver : self
                     selector : @selector(adapterChanged:)
                         name : ORCrateAdapterChangedNotification
                       object : nil];

}

- (void) runAboutToStart:(NSNotification*)aNote
{
	//subclasses can override
}

- (void) runStarted:(NSNotification*)aNote
{
	//subclasses can override
}

- (void) runAboutToStop:(NSNotification*)aNote
{
	//subclasses can override
}

- (void) adapterChanged:(NSNotification*)aNote
{
	//subclasses can override
}


- (void) viewChanged:(NSNotification*)aNotification
{
    [self sortCards];
    [self setUpImage];
}

- (void) childChanged:(NSNotification*)aNotification
{
    if([[aNotification object] guardian]== self){
        [self sortCards];
        [self setUpImage];
    }
}

- (int)tag
{
    return crateNumber;
}

- (int) crateNumber
{
    return crateNumber;
}

- (void) setCrateNumber: (unsigned int) aCrateNumber
{
    crateNumber = aCrateNumber;
	[self setTag:crateNumber];
	[[NSNotificationCenter defaultCenter]
		postNotificationName:ORCrateModelCrateNumberChanged
                      object:self];


}

- (NSComparisonResult) crateNumberCompare:(id)aCard
{
	return [self crateNumber] - [aCard crateNumber];
}

- (void) sortCards
{
	[[self orcaObjects] sortUsingSelector:@selector(slotCompare:)];
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"%@ %d",[self className],[self tag]];
}

- (BOOL) powerOff
{
	return powerOff;
}

- (void)setPowerOff:(BOOL)state
{
    if(state != powerOff){
        powerOff = state;
        [self viewChanged:nil];
        [[NSNotificationCenter defaultCenter]
                postNotificationName:ORForceRedraw
                              object:self];
    }
}

- (void) pollCratePower
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollCratePower) object:nil];
    NS_DURING
        //if(![[ORGlobal sharedInstance] runInProgress]){
        [[self controllerCard] checkCratePower];
        //}
    NS_HANDLER
    NS_ENDHANDLER
    [self performSelector:@selector(pollCratePower) withObject:nil afterDelay:10];
}

- (void) checkCratePower
{
}

- (NSComparisonResult)sortCompare:(OrcaObject*)anObj
{
    return [self tag] - [anObj tag];
}

- (void) positionConnector:(ORConnector*)aConnector forCard:(id)aCard
{
	[aCard positionConnector:aConnector];
}

- (unsigned long) requestGTID
{
    unsigned long aGTID = 0;
    NSArray* gtidGenerators = [self collectObjectsConformingTo:@protocol(ORGTIDGenerator)];
    if([gtidGenerators count]){
        id gtidGenerator = [gtidGenerators objectAtIndex:0];
        aGTID = [gtidGenerator requestGTID];
    }
    return aGTID;
}

- (void) connected
{
}

- (void) disconnected
{
}


#pragma mark ¥¥¥Archival
- (NSString*) adapterArchiveKey
{
	return @"Crate Adapter";
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
	[[self undoManager] disableUndoRegistration];
    
	[self setAdapter:[decoder decodeObjectForKey:[self adapterArchiveKey]]];
    [self setShowLabels:[decoder decodeBoolForKey:@"showLabels"]];
	[[self undoManager] enableUndoRegistration];
	
	[self registerNotificationObservers];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	[encoder encodeObject:adapter forKey:[self adapterArchiveKey]];
	[encoder encodeBool:showLabels forKey:@"showLabels"];
}

- (void) addObjectInfoToArray:(NSMutableArray*)anArray
{
	//find the slot number base, i.e. CAMAC starts at 1, VME starts at 0
	int cardStart = 0;
	NSEnumerator* e = [[self orcaObjects] objectEnumerator];
	id anObj;
	while(anObj = [e nextObject]){
		if([anObj isKindOfClass:NSClassFromString(@"ORCard")]){
			cardStart = [anObj tagBase];
			break;
		}
	}

	NSMutableDictionary* dictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
											[NSNumber numberWithInt:[self crateNumber]], @"CrateNumber",
											[self className],	@"ClassName",
											[NSNumber numberWithInt:cardStart],	@"FirstSlot",nil];

	NSArray* cards = [self collectObjectsOfClass:NSClassFromString(@"ORCard")];
	if([cards count]){
		NSMutableArray* cardArray = [NSMutableArray array];
		int i;
		for(i=0;i<[cards count];i++){
			ORCard* aCard = [cards objectAtIndex:i];
			if([aCard guardian] == self){
				[aCard addObjectInfoToArray:cardArray];
			}
		}
		if([cardArray count]){
			[dictionary setObject:cardArray forKey:@"Cards"];
		}
	}


	[anArray addObject:dictionary];
}

@end
