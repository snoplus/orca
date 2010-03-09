//
//  KatrinModel.m
//  Orca
//
//  Created by Mark Howe on Tue Jun 28 2005.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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
#import "KatrinModel.h"
#import "KatrinController.h"
#import "ORSegmentGroup.h"
#import "KatrinConstants.h"
#import "ORSocketClient.h"
#import "ORCommandCenter.h"

NSString* KatrinModelSlowControlIsConnectedChanged = @"KatrinModelSlowControlIsConnectedChanged";
NSString* KatrinModelSlowControlNameChanged			= @"KatrinModelSlowControlNameChanged";
NSString* ORKatrinModelViewTypeChanged				= @"ORKatrinModelViewTypeChanged";

static NSString* KatrinDbConnector		= @"KatrinDbConnector";

@implementation KatrinModel

#pragma mark ¥¥¥Initialization
- (void) wakeUp
{
	[super wakeUp];
	BOOL exists = [[ORCommandCenter sharedCommandCenter] clientWithNameExists:slowControlName];
	[self setSlowControlIsConnected: exists];

}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"katrin"]];
}

- (void) makeMainController
{
    [self linkToController:@"KatrinController"];
}

- (NSString*) helpURL
{
	return @"KATRIN/Index.html";
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - 35,2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:KatrinDbConnector];
    [aConnector setOffColor:[NSColor brownColor]];
	[aConnector setConnectorType: 'ADEO'];
	[aConnector addRestrictedConnectionType: 'ADEI']; //can only connect to DB Inputs
    [aConnector release];
}

- (void) registerNotificationObservers
{
	[super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(slowControlConnectionChanged:)
                         name : ORCommandClientsChangedNotification
                       object : nil];
	
}

- (void) slowControlConnectionChanged:(NSNotification*)aNote
{
	ORSocketClient* theClient = [[aNote userInfo] objectForKey:@"client"];
	if([[theClient name] isEqualToString:slowControlName]){
		BOOL exists = [[[ORCommandCenter sharedCommandCenter]clients] containsObject:theClient];
		[self setSlowControlIsConnected: [theClient isConnected] && exists];
	}
}

#pragma mark ¥¥¥Accessors
- (NSString*) slowControlName;
{
	if(!slowControlName)return @"";
	return slowControlName;
}

- (void) setSlowControlName:(NSString*)aName
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSlowControlName:slowControlName];
    
	[slowControlName autorelease];
    slowControlName = [aName copy];    
	
	BOOL exists = [[ORCommandCenter sharedCommandCenter] clientWithNameExists:slowControlName];
	[self setSlowControlIsConnected: exists];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:KatrinModelSlowControlNameChanged object:self];
	
}

- (BOOL) slowControlIsConnected
{
	return slowControlIsConnected;
}

- (void) setSlowControlIsConnected:(BOOL)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSlowControlIsConnected:slowControlIsConnected];
    
    slowControlIsConnected = aState;    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:KatrinModelSlowControlIsConnectedChanged object:self];
	
}


#pragma mark ¥¥¥Segment Group Methods
- (void) makeSegmentGroups
{
	
    ORSegmentGroup* group = [[ORSegmentGroup alloc] initWithName:@"Focal Plane" numSegments:kNumFocalPlaneSegments mapEntries:[self initMapEntries:0]];
	[self addGroup:group];
	[group release];
	
    group = [[ORSegmentGroup alloc] initWithName:@"Veto" numSegments:kNumVetoSegments mapEntries:[self initMapEntries:1]];
	[self addGroup:group];
	[group release];
}

- (NSMutableArray*) initMapEntries:(int)index
{
	if(index==1)return [super initMapEntries:0]; //default set
	else {
		NSMutableArray* mapEntries = [NSMutableArray array];
		[mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kSegmentNumber",	@"key", [NSNumber numberWithInt:0], @"sortType", nil]];
		[mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kCardSlot",		@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
		[mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kChannel",		@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
		[mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kName",			@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
		[mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kQuadrant",		@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
		[mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kCarouselSlot",	@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
		[mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kModuleAddress",	@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
		[mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kModuleChannel",	@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
		[mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kPreampSerial",	@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
		[mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kOSBSlot",		@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
		[mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kOSBChannel",	@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
		[mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kORBCard",		@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
		[mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kORBChannel",	@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
		return mapEntries;
	}
}

- (int)  maxNumSegments
{
	return kNumFocalPlaneSegments;
}


- (NSString*) reformatSelectionString:(NSString*)aString forSet:(int)aSet
{
	if(aSet == 0){
		//the focal plane
		NSString* finalString = @"";
		NSArray* parts = [aString componentsSeparatedByString:@"\n"];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Segment" parts:parts]];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Quadrant" parts:parts]];
		finalString = [finalString stringByAppendingString:@"-----------------------\n"];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" CardSlot" parts:parts]];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Channel" parts:parts]];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Threshold" parts:parts]];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Gain" parts:parts]];
		finalString = [finalString stringByAppendingString:@"-----------------------\n"];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" PreampSerial" parts:parts]];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" CarouselSlot" parts:parts]];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" ModuleAddress" parts:parts]];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" ModuleChannel" parts:parts]];
		finalString = [finalString stringByAppendingString:@"-----------------------\n"];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" OSBSlot" parts:parts]];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" OSBChannel" parts:parts]];
		finalString = [finalString stringByAppendingString:@"-----------------------\n"];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" ORBCard" parts:parts]];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" ORBChannel" parts:parts]];
		return finalString;
	}
	else {
		//the veto
		return aString;
	}
}

- (NSString*) getPartStartingWith:(NSString*)aLabel parts:(NSArray*)parts
{
	for(id aLine in parts){
		if([aLine rangeOfString:aLabel].location != NSNotFound) return aLine;
	}
	return @"";
}

#pragma mark ¥¥¥Specific Dialog Lock Methods
- (NSString*) experimentMapLock
{
	return @"KatrinMapLock";
}

- (NSString*) experimentDetectorLock
{
	return @"KatrinDetectorLock";
}

- (NSString*) experimentDetailsLock	
{
	return @"KatrinDetailsLock";
}

- (void) setViewType:(int)aViewType
{
	[[[self undoManager] prepareWithInvocationTarget:self] setViewType:aViewType];
	viewType = aViewType;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinModelViewTypeChanged object:self userInfo:nil];
}

- (int) viewType
{
	return viewType;
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setSlowControlName:[decoder decodeObjectForKey:@"slowControlName"]];
    [self setViewType:[decoder decodeIntForKey:@"viewType"]];
	[[self undoManager] enableUndoRegistration];

    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:slowControlName forKey:@"slowControlName"];
    [encoder encodeInt:viewType forKey:@"viewType"];
}


@end

