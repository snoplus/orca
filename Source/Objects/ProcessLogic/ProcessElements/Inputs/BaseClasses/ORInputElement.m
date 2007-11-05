//
//  ORInputElement.m
//  Orca
//
//  Created by Mark Howe on 11/25/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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


#import "ORInputElement.h"
#import "ORProcessInConnector.h"
#import "ORProcessOutConnector.h"
#import "ORProcessModel.h"
#import "ORProcessThread.h"

NSString* ORInputElementInConnection     = @"ORInputElementInConnection";
NSString* ORInputElementOutConnection  = @"ORInputElementOutConnection";

@implementation ORInputElement
- (NSString*) description:(NSString*)prefix
{
    NSString* s = [super description:prefix];
    id obj = [self objectConnectedTo:ORInputElementInConnection];
    NSString* nextPrefix = [prefix stringByAppendingString:@"  "];
    NSString* noConnectionString = [NSString stringWithFormat:@"%@--",nextPrefix];
    return [NSString stringWithFormat:@"%@\n%@%@",s,prefix,obj?[obj description:nextPrefix]:noConnectionString];
}

- (void) doCmdClick:(id)sender
{
    if([guardian inTestMode]){
        int currentState = [self state];
        [self setState:!currentState];
    }
}

-(void)makeConnectors
{
    ORProcessInConnector* inConnector = [[ORProcessInConnector alloc] initAt:NSMakePoint(0,10) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:inConnector forKey:ORInputElementInConnection];
    [ inConnector setConnectorType: 'LP1 ' ];
    [ inConnector addRestrictedConnectionType: 'LP2 ' ]; //can only connect to processor outputs
    [inConnector release];
    
    
    ORProcessOutConnector* outConnector = [[ORProcessOutConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,10) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:outConnector forKey:ORInputElementOutConnection];
    [ outConnector setConnectorType: 'LP2 ' ];
    [ outConnector addRestrictedConnectionType: 'LP1 ' ]; //can only connect to processor inputs
    [outConnector release];
}

- (void) processIsStarting
{
    [super processIsStarting];
    id obj = [self objectConnectedTo:ORInputElementInConnection];
    [obj processIsStarting];
    [ORProcessThread registerInputObject:self];
}

- (void) processIsStopping
{
    [super processIsStopping];
    id obj = [self objectConnectedTo:ORInputElementInConnection];
    [obj processIsStopping];
}
- (int) connectedObjState
{
	return connectedObjState;

}

//--------------------------------
//runs in the process logic thread
- (int) eval
{
	id obj = [self objectConnectedTo:ORInputElementInConnection];
	if(!alreadyEvaluated){
		if(![guardian inTestMode] && hwObject!=nil){
			[self setState:[hwObject processValue:bit]];
		}
		if(obj) connectedObjState =  [obj eval];
	}
	int theState = [self state];
	if(!obj)		  [self setEvaluatedState:theState];
	else {
		if(!theState) [self setEvaluatedState: theState];
		else		  [self setEvaluatedState: connectedObjState];
	}
	return evaluatedState;
}
//--------------------------------
@end
