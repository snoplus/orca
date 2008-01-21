//
//  ORFilterModel.m
//  Orca
//
//  Created by Mark Howe on Mon Nov 18 2002.
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


#pragma mark •••Imported Files
#import "ORFilterModel.h"
#import "ORDataPacket.h"

static NSString* ORFilterInConnector 		= @"Filter In Connector";
static NSString* ORFilterOutConnector 		= @"Filter Out Connector";

NSString* ORFilterLock                      = @"ORFilterLock";

@implementation ORFilterModel

#pragma mark •••Initialization

- (id) init //designated initializer
{
	self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    [[self undoManager] enableUndoRegistration];
        
	return self;
}

-(void)dealloc
{
    [super dealloc];
}

- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"Filter"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORFilterController"];
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint(0,[self frame].size.height/2 - kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORFilterInConnector];
    [aConnector release];

    aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width-kConnectorSize,[self frame].size.height/2 - kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORFilterOutConnector];
    [aConnector release];
    
}

#pragma mark •••Accessors

#pragma mark •••Data Handling
- (void) processData:(ORDataPacket*)someData userInfo:(NSDictionary*)userInfo
{
	//pass it on
	id theNextObject = [self objectConnectedTo:ORFilterOutConnector];
	[theNextObject processData:someData userInfo:userInfo];
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{		
	dataHeader = [[aDataPacket headerAsData] retain];
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
}

- (void) closeOutRun:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	[dataHeader release];
	dataHeader = nil;
}


#pragma mark •••Archival

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
}


@end
