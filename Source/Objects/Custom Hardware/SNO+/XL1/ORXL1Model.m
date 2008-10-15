//
//  ORXL1Model.m
//  Orca
//
//  Created by Mark Howe on Tue, Apr 30, 2008.
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
#import "ORXL1Model.h"
#import "ORXL2Model.h"
#import "ORCrate.h"
#import "ORSNOCard.h"

@implementation ORXL1Model

#pragma mark •••Initialization
-(void)dealloc
{
    [connectorName release];
    [connector release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"XL1Card"]];
}

- (BOOL) solitaryInViewObject
{
	return YES;
}

- (void) makeConnectors
{
    //make and cache our connector. However this connector will be 'owned' by another object (the crate)
    //so we don't add it to our list of connectors. It will be added to the true owner later.
    [self setConnector: [[[ORConnector alloc] initAt:NSZeroPoint withGuardian:self withObjectLink:self] autorelease]];
        
	[ [self connector] setConnectorType: 'XL1O' ];
	[ [self connector] addRestrictedConnectionType: 'XL2I' ]; //can only connect to XL2I inputs
}

- (NSString*) connectorName
{
    return connectorName;
}
- (void) setConnectorName:(NSString*)aName
{
    [aName retain];
    [connectorName release];
    connectorName = aName;
    
}

- (id) getXL1
{
	return self;
}

- (void) setCrateNumbers
{
	//we'll drop in here if any of the XL1/2 connections change -- this is initiated from the XL2s only or we'll get an infinite loop
	ORXL2Model* nextXL2 = [connector connectedObject];
	[nextXL2 setCrateNumber:0];
}

- (ORConnector*) connector
{
    return connector;
}

- (void) setConnector:(ORConnector*)aConnector
{
    [aConnector retain];
    [connector release];
    connector = aConnector;
}

- (void) setSlot:(int)aSlot
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSlot:[self slot]];
    [self setTag:aSlot];
    [self guardian:guardian positionConnectorsForCard:self];
    
    [[NSNotificationCenter defaultCenter]
			postNotificationName:ORSNOCardSlotChanged
                          object: self];
}

- (void) positionConnector:(ORConnector*)aConnector
{
    NSRect aFrame = [aConnector localFrame];
    float x =  20 + [self slot] * 16 * .62 + 2;
    float y =  25;
    aFrame.origin = NSMakePoint(x,y);
    [aConnector setLocalFrame:aFrame];
}


- (void) setGuardian:(id)aGuardian
{
    
    id oldGuardian = guardian;
    [super setGuardian:aGuardian];
    
    if(oldGuardian != aGuardian){
        [oldGuardian removeDisplayOf:connector];
    }
    
    [aGuardian assumeDisplayOf:connector];
    [self guardian:aGuardian positionConnectorsForCard:self];
}

- (void) guardian:(id)aGuardian positionConnectorsForCard:(id)aCard
{
    [aGuardian positionConnector:connector forCard:self];
}

- (void) guardianRemovingDisplayOfConnectors:(id)aGuardian
{
    [aGuardian removeDisplayOf:connector];
}

- (void) guardianAssumingDisplayOfConnectors:(id)aGuardian
{
    [aGuardian assumeDisplayOf:connector];
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setConnectorName:[decoder decodeObjectForKey:@"connectorName"]];
    [self setConnector:[decoder decodeObjectForKey:@"connector"]];
	[self setSlot:[decoder decodeIntForKey:@"slot"]];
    
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:[self connectorName] forKey:@"connectorName"];
    [encoder encodeObject:[self connector] forKey:@"connector"];
    [encoder encodeInt:[self slot] forKey:@"slot"];
}

@end
