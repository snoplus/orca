//
//  SNOPModel.m
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
#import "SNOPModel.h"
#import "SNOPController.h"
#import "ORSegmentGroup.h"

NSString* ORSNOPModelViewTypeChanged	= @"ORSNOPModelViewTypeChanged";
static NSString* SNOPDbConnector	= @"SNOPDbConnector";
NSString* ORSNOPModelMorcaIsVerboseChanged = @"ORSNOPModelMorcaIsVerboseChanged";
NSString* ORSNOPModelMorcaIsWithinRunChanged = @"ORSNOPModelMorcaIsWithinRunChanged";
NSString* ORSNOPModelMorcaUpdateTimeChanged = @"ORSNOPModelMorcaUpdateTimeChanged";
NSString* ORSNOPModelMorcaPortChanged = @"ORSNOPModelMorcaPortChanged";
NSString* ORSNOPModelMorcaStatusChanged = @"ORSNOPModelMorcaStatusChanged";
NSString* ORSNOPModelMorcaUserNameChanged = @"ORSNOPModelMorcaUserNameChanged";
NSString* ORSNOPModelMorcaPasswordChanged = @"ORSNOPModelMorcaPasswordChanged";
NSString* ORSNOPModelMorcaDBNameChanged = @"ORSNOPModelMorcaDBNameChanged";
NSString* ORSNOPModelMorcaIPAddressChanged = @"ORSNOPModelMorcaIPAddressChanged";
NSString* ORSNOPModelMorcaIsUpdatingChanged = @"ORSNOPModelMorcaIsUpdatingChanged";

@implementation SNOPModel

#pragma mark ¥¥¥Initialization

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"SNOP"]];
}

- (void) makeMainController
{
    [self linkToController:@"SNOPController"];
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:SNOPDbConnector];
    [aConnector setOffColor:[NSColor brownColor]];
    [aConnector setOnColor:[NSColor magentaColor]];
	[ aConnector setConnectorType: 'DB O' ];
	[ aConnector addRestrictedConnectionType: 'DB I' ]; //can only connect to DB outputs
    [aConnector release];
}

- (void) dealloc
{
    [morcaUserName release];
    [morcaPassword release];
    [morcaDBName release];
    [morcaIPAddress release];
    if (morcaStatus) [morcaStatus release];
    
    [super dealloc];
}

//- (NSString*) helpURL
//{
//	return @"SNO/Index.html";
//}

#pragma mark ¥¥¥Accessors
- (NSString*) morcaUserName
{
    return morcaUserName;
}

- (void) setMorcaUserName:(NSString *)aMorcaUserName
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMorcaUserName:morcaUserName];
    [morcaUserName autorelease];
    morcaUserName = [aMorcaUserName copy];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelMorcaUserNameChanged object:self];
}

- (NSString*) morcaPassword
{
    return morcaPassword;
}

- (void) setMorcaPassword:(NSString *)aMorcaPassword
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMorcaPassword:morcaPassword];
    [morcaPassword autorelease];
    morcaPassword = [aMorcaPassword copy];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelMorcaPasswordChanged object:self];        
}

- (NSString*) morcaDBName
{
    return morcaDBName;
}

- (void) setMorcaDBName:(NSString *)aMorcaDBName
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMorcaDBName:morcaDBName];
    [morcaDBName autorelease];
    morcaDBName = [aMorcaDBName copy];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelMorcaDBNameChanged object:self];        
}

- (NSString*) morcaIPAddress
{
    return morcaIPAddress;
}

- (void) setMorcaIPAddress:(NSString *)aMorcaIPAddress
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMorcaIPAddress:morcaIPAddress];
    [morcaIPAddress autorelease];
    morcaIPAddress = [aMorcaIPAddress copy];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelMorcaIPAddressChanged object:self];        
}

- (unsigned int) morcaPort;
{
    return morcaPort;
}

- (void) setMorcaPort:(unsigned int)aMorcaPort
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMorcaPort:aMorcaPort];
    morcaPort = aMorcaPort;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelMorcaPortChanged object:self];        
}

- (unsigned int) morcaUpdateTime;
{
    return morcaUpdateTime;
}

- (void) setMorcaUpdateTime:(unsigned int)aMorcaUpdateTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMorcaUpdateTime:morcaUpdateTime];
    morcaUpdateTime = aMorcaUpdateTime;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelMorcaUpdateTimeChanged object:self];        
}

- (BOOL) morcaIsVerbose
{
    return morcaIsVerbose;
}

- (void) setMorcaIsVerbose:(BOOL)aMorcaIsVerbose
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMorcaIsVerbose:morcaIsVerbose];
    morcaIsVerbose = aMorcaIsVerbose;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelMorcaIsVerboseChanged object:self];        
}

- (BOOL) morcaIsWithinRun
{
    return morcaIsWithinRun;
}

- (void) setMorcaIsWithinRun:(BOOL)aMorcaIsWithinRun
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMorcaIsWithinRun:morcaIsWithinRun];
    morcaIsWithinRun = aMorcaIsWithinRun;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelMorcaIsWithinRunChanged object:self];        
}

- (BOOL) morcaIsUpdating
{
    return morcaIsUpdating;
}

- (void) setMorcaIsUpdating:(BOOL)aMorcaIsUpdating
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMorcaIsUpdating:morcaIsUpdating];
    morcaIsUpdating = aMorcaIsUpdating;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelMorcaIsUpdatingChanged object:self];        
}

- (NSString*) morcaStatus
{
    if (!morcaStatus) {
        return @"Status unknown";
    }
    return morcaStatus;
}

- (void) setMorcaStatus:(NSString*)aMorcaStatus
{
    if (morcaStatus) [morcaStatus autorelease];
    if (aMorcaStatus) morcaStatus = [aMorcaStatus copy];
    
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelMorcaStatusChanged object:self];        
}

#pragma mark ¥¥¥Segment Group Methods
- (void) makeSegmentGroups
{
    ORSegmentGroup* group = [[ORSegmentGroup alloc] initWithName:@"SNO+ Detector" numSegments:kNumTubes mapEntries:[self initMapEntries:0]];
	[self addGroup:group];
	[group release];
}

- (int)  maxNumSegments
{
	return kNumTubes;
}

- (void) showDataSetForSet:(int)aSet segment:(int)index
{ 
	if(aSet>=0 && aSet < [segmentGroups count]){
		ORSegmentGroup* aGroup = [segmentGroups objectAtIndex:aSet];
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
					aDataSet = [histoObj objectForKeyArray:[NSMutableArray arrayWithObjects:@"SIS3302", @"Crate  0",
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
	
	return [NSString stringWithFormat:@"SIS3302,Energy,Crate %2d,Card %2d,Channel %2d",[crateName intValue],[cardName intValue],[chanName intValue]];
}
#pragma mark ¥¥¥Specific Dialog Lock Methods
- (NSString*) experimentMapLock
{
	return @"SNOPMapLock";
}

- (NSString*) experimentDetectorLock
{
	return @"SNOPDetectorLock";
}

- (NSString*) experimentDetailsLock	
{
	return @"SNOPDetailsLock";
}

- (void) setViewType:(int)aViewType
{
	[[[self undoManager] prepareWithInvocationTarget:self] setViewType:aViewType];
	viewType = aViewType;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelViewTypeChanged object:self userInfo:nil];
}

- (int) viewType
{
	return viewType;
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    
    [self setViewType:[decoder decodeIntForKey:@"viewType"]];
    [self setMorcaUserName:         [decoder decodeObjectForKey:@"ORSNOPModelMorcaUserName"]];
    [self setMorcaPassword:         [decoder decodeObjectForKey:@"ORSNOPModelMorcaPassword"]];
    [self setMorcaDBName:           [decoder decodeObjectForKey:@"ORSNOPModelMorcaDBName"]];
    [self setMorcaPort:             [decoder decodeIntForKey:@"ORSNOPModelMoraPort"]];
    [self setMorcaIPAddress:        [decoder decodeObjectForKey:@"ORSNOPModelMorcaIPAddress"]];
    [self setMorcaUpdateTime:       [decoder decodeIntForKey:@"ORSNOPModelMorcaUpdateTime"]];
    [self setMorcaIsVerbose:        [decoder decodeBoolForKey:@"ORSNOPModelMorcaIsVerbose"]];
    [self setMorcaIsWithinRun:      [decoder decodeBoolForKey:@"ORSNOPModelMorcaIsWithinRun"]];
    [self setMorcaIsUpdating:       [decoder decodeBoolForKey:@"ORSNOPModelMorcaIsUpdating"]];

    if (morcaIsUpdating == YES) [self setMorcaIsUpdating:NO];
	
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:viewType forKey:@"viewType"];
    [encoder encodeObject:morcaUserName     forKey:@"ORSNOPModelMorcaUserName"];
    [encoder encodeObject:morcaPassword     forKey:@"ORSNOPModelMorcaPassword"];
    [encoder encodeObject:morcaDBName       forKey:@"ORSNOPModelMorcaDBName"];
    [encoder encodeInt:morcaPort            forKey:@"ORSNOPModelMorcaPort"];
    [encoder encodeObject:morcaIPAddress    forKey:@"ORSNOPModelMorcaIPAddress"];
    [encoder encodeInt:morcaUpdateTime      forKey:@"ORSNOPModelMorcaUpdateTime"];
    [encoder encodeBool:morcaIsVerbose      forKey:@"ORSNOPModelMorcaIsVerbose"];
    [encoder encodeBool:morcaIsWithinRun    forKey:@"ORSNOPModelMorcaIsWithinRun"];
    [encoder encodeBool:morcaIsUpdating     forKey:@"ORSNOPModelMorcaIsUpdating"];
}

- (NSString*) reformatSelectionString:(NSString*)aString forSet:(int)aSet
{
	if([aString length] == 0)return @"Not Mapped";
	
	NSString* finalString = @"";
	NSArray* parts = [aString componentsSeparatedByString:@"\n"];
	finalString = [finalString stringByAppendingString:@"\n-----------------------\n"];
	finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Detector" parts:parts]];
	finalString = [finalString stringByAppendingString:@"-----------------------\n"];
	finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" CardSlot" parts:parts]];
	finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Channel" parts:parts]];
	finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Threshold" parts:parts]];
	finalString = [finalString stringByAppendingString:@"-----------------------\n"];
	return finalString;
}

- (NSString*) getPartStartingWith:(NSString*)aLabel parts:(NSArray*)parts
{
	for(id aLine in parts){
		if([aLine rangeOfString:aLabel].location != NSNotFound) return aLine;
	}
	return @"";
}

@end

