//
//  ORSPDTRelayModel.m
//  Orca
//
//  Created by Mark Howe on Sat Nov 18 2005.
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
#import "ORSPDTRelayModel.h"
#import "ORProcessModel.h"
#import "ORProcessOutConnector.h"

NSString* ORSPDTRelayOutOffConnection  = @"ORSPDTRelayOutOffConnection";

@implementation ORSPDTRelayModel

#pragma mark ¥¥¥Initialization

-(void)dealloc
{
    [offNub release];
    [super dealloc];
}

- (void) setUpImage
{
    if([self state]) [self setImage:[NSImage imageNamed:@"SPDTRelayOn"]];
    else             [self setImage:[NSImage imageNamed:@"SPDTRelayOff"]];
    [self addOverLay];
}

- (void) makeMainController
{
    [self linkToController:@"ORSPDTRelayController"];
}

-(void)makeConnectors
{
    [super makeConnectors];

    ORProcessOutConnector* aConnector = [[ORProcessOutConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,[self frame].size.height-kConnectorSize) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORSPDTRelayOutOffConnection];
    [ aConnector setConnectorType: 'LP2 ' ];
    [ aConnector addRestrictedConnectionType: 'LP1 ' ]; //can only connect to processor inputs
    [aConnector release];

}

- (NSString*) elementName
{
	return @"SPDT Input relay";
}

- (void) setUpNubs
{
    if(!offNub)offNub = [[ORSPDTRelayOff alloc] init];
    [offNub setGuardian:self];
    ORConnector* aConnector = [[self connectors] objectForKey: ORSPDTRelayOutOffConnection];
    [aConnector setObjectLink:offNub];
}

@end

//the 'OFF' nub
@implementation ORSPDTRelayOff

- (int) eval
{
	[guardian eval];
	int theState = [guardian state];
	if(![guardian objectConnectedTo:ORInputElementInConnection])[self setEvaluatedState: !theState];
	else {
		if(theState) [self setEvaluatedState:0];
		else		 [self setEvaluatedState:[guardian connectedObjState]];
	}
	return evaluatedState;
}

- (int) evaluatedState
{
	return evaluatedState;
}

- (void) setEvaluatedState:(int)value
{
	@synchronized (self){
		if(value != evaluatedState){
			evaluatedState = value;
			[guardian performSelectorOnMainThread:@selector(postStateChange) withObject:nil waitUntilDone:NO];
		}
	}
}

@end

