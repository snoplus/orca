//
//  ORTGate.m
//  Orca
//
//  Created by Mark Howe on 10/6/10.
//  Copyright  © 2009 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Physics and 
//Astrophysics Department sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark ¥¥¥Imported Files
#import "ORTGates.h"
#import "ORLogicInBitModel.h"

@implementation ORTGate

#pragma mark ¥¥¥Initialization
- (void) reset
{
	alreadyEvaluated = NO;
	[[self objectConnectedTo:@"Input1"] reset];
	[[self objectConnectedTo:@"Input2"] reset];
}

- (BOOL) acceptsGuardian: (OrcaObject *)aGuardian
{
    return  [aGuardian isMemberOfClass:NSClassFromString(@"ORIP408Model")];
}

- (NSString*) identifier
{ 
	return [NSString stringWithFormat:@"%@ %d",[[self className] substringFromIndex:3], [self uniqueIdNumber]]; 
}

-(void) makeConnectors
{	
	ORConnector* inConnector = [[ORConnector alloc] initAt:NSMakePoint(3,2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:inConnector forKey:@"Input1"];
    [ inConnector setConnectorType: 'TLI ' ];
    [ inConnector addRestrictedConnectionType: 'TLO ' ]; //can only connect to logic outputs
    [inConnector release];
	
    inConnector = [[ORConnector alloc] initAt:NSMakePoint(3,[self frame].size.height-kConnectorSize-2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:inConnector forKey:@"Input2"];
    [ inConnector setConnectorType: 'TLI ' ];
    [ inConnector addRestrictedConnectionType: 'TLO ' ]; //can only connect to logic outputs
    [inConnector release];
	
    ORConnector* outConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize-3,[self frame].size.height/2 - kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:outConnector forKey:@"Output"];
    [ outConnector setConnectorType: 'TLO ' ];
    [ outConnector addRestrictedConnectionType: 'TLI ' ]; //can only connect to logic inputs
    [outConnector release];
}

- (BOOL) hasDialog					{ return NO; }
- (BOOL) evalWithDelegate:(id)anObj { return NO; }

@end

//-------------------------------------------------------------
@implementation ORTAndGate
- (void) setUpImage			{ [self setImage:[NSImage imageNamed:@"AndGate"]]; }
- (BOOL) evalWithDelegate:(id)anObj
{
	BOOL value1 = [[self objectConnectedTo:@"Input1"] evalWithDelegate:anObj];
	BOOL value2 = [[self objectConnectedTo:@"Input2"] evalWithDelegate:anObj];
	return value1 & value2;
}
@end

//-------------------------------------------------------------
@implementation ORTNandGate
- (void) setUpImage					{ [self setImage:[NSImage imageNamed:@"NandGate"]]; }
- (BOOL) evalWithDelegate:(id)anObj	{ return ![super evalWithDelegate:anObj]; }
@end

//-------------------------------------------------------------
@implementation ORTOrGate
#pragma mark ¥¥¥Initialization
- (void) setUpImage		 { [self setImage:[NSImage imageNamed:@"ORGate"]]; }
- (BOOL) evalWithDelegate:(id)anObj
{
	BOOL value1 = [[self objectConnectedTo:@"Input1"] evalWithDelegate:anObj];
	BOOL value2 = [[self objectConnectedTo:@"Input2"] evalWithDelegate:anObj];
	return value1 | value2;
}
@end

//-------------------------------------------------------------
@implementation ORTXorGate
- (void) setUpImage		 { [self setImage:[NSImage imageNamed:@"XorGate"]]; }
- (BOOL) evalWithDelegate:(id)anObj
{
	BOOL value1 = [[self objectConnectedTo:@"Input1"] evalWithDelegate:anObj];
	BOOL value2 = [[self objectConnectedTo:@"Input2"] evalWithDelegate:anObj];
	return value1 ^ value2;
}
@end

//-------------------------------------------------------------
@implementation ORTNorGate
- (void) setUpImage					{ [self setImage:[NSImage imageNamed:@"NorGate"]]; }
- (BOOL) evalWithDelegate:(id)anObj	{ return ![self evalWithDelegate:anObj]; }
@end

//-------------------------------------------------------------
@implementation ORTJoiner
#pragma mark ¥¥¥Initialization
- (void) setUpImage		 { [self setImage:[NSImage imageNamed:@"LogicJoin"]]; }
- (void) makeConnectors
{	
	ORConnector* inConnector = [[ORConnector alloc] initAt:NSMakePoint(0,0) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:inConnector forKey:@"Input1"];
    [ inConnector setConnectorType: 'TLI ' ];
    [ inConnector addRestrictedConnectionType: 'TLO ' ]; //can only connect to logic outputs
    [inConnector release];
	
    inConnector = [[ORConnector alloc] initAt:NSMakePoint(0,[self frame].size.height-kConnectorSize) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:inConnector forKey:@"Input2"];
    [ inConnector setConnectorType: 'TLI ' ];
    [ inConnector addRestrictedConnectionType: 'TLO ' ]; //can only connect to logic outputs
    [inConnector release];
	
    ORConnector* outConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,[self frame].size.height/2 - kConnectorSize/2+1) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:outConnector forKey:@"Output"];
    [ outConnector setConnectorType: 'TLO ' ];
    [ outConnector addRestrictedConnectionType: 'TLI ' ]; //can only connect to logic inputs
    [outConnector release];
}

@end

//-------------------------------------------------------------
@implementation ORTSplitter
#pragma mark ¥¥¥Initialization
- (void) setUpImage		 { [self setImage:[NSImage imageNamed:@"LogicSplit"]]; }
- (void) makeConnectors
{	
	ORConnector* inConnector = [[ORConnector alloc] initAt:NSMakePoint(0,[self frame].size.height/2-kConnectorSize/2+1) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:inConnector forKey:@"Input1"];
    [ inConnector setConnectorType: 'TLI ' ];
    [ inConnector addRestrictedConnectionType: 'TLO ' ]; //can only connect to logic outputs
    [inConnector release];
	
    ORConnector*  outConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,[self frame].size.height-kConnectorSize) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:outConnector forKey:@"Output1"];
    [ outConnector setConnectorType: 'TLO ' ];
    [ outConnector addRestrictedConnectionType: 'TLI ' ]; //can only connect to logic inputs
    [outConnector release];
	
    outConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,0) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:outConnector forKey:@"Output2"];
    [ outConnector setConnectorType: 'TLO ' ];
    [ outConnector addRestrictedConnectionType: 'TLI ' ]; //can only connect to logic inputs
    [outConnector release];
}
- (BOOL) evalWithDelegate:(id)anObj
{
	//no sense in evaluating twice, so do some logic
	if(alreadyEvaluated)	alreadyEvaluated = NO;
	else {
		state = [[self objectConnectedTo:@"Input1"] evalWithDelegate:anObj];
		alreadyEvaluated = YES;
	}
	return state;
}
	
@end

//-------------------------------------------------------------
@implementation ORTHiLatch
#pragma mark ¥¥¥Initialization
- (void) setUpImage		 { [self setImage:[NSImage imageNamed:@"HighLatch"]]; }
- (void) reset
{
	lastState = NO;
	[super reset];
}
- (void) makeConnectors
{	
	ORConnector* inConnector = [[ORConnector alloc] initAt:NSMakePoint(0,[self frame].size.height/2-kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:inConnector forKey:@"Input1"];
    [ inConnector setConnectorType: 'TLI ' ];
    [ inConnector addRestrictedConnectionType: 'TLO ' ]; //can only connect to logic outputs
    [inConnector release];
	
    ORConnector* outConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,[self frame].size.height/2-kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:outConnector forKey:@"Output1"];
    [ outConnector setConnectorType: 'TLO ' ];
    [ outConnector addRestrictedConnectionType: 'TLI ' ]; //can only connect to logic inputs
    [outConnector release];	
}

- (BOOL) evalWithDelegate:(id)anObj
{
	BOOL lowToHiTransition = NO;
	BOOL state = [[self objectConnectedTo:@"Input1"] evalWithDelegate:anObj];
	if(state != lastState){
		if(lastState == NO && state == YES)lowToHiTransition = YES;
	}
	lastState = state;
	return lowToHiTransition;
}

@end

//-------------------------------------------------------------
@implementation ORTInverter
#pragma mark ¥¥¥Initialization
- (void) setUpImage		 { [self setImage:[NSImage imageNamed:@"Inverter"]]; }
- (void) makeConnectors
{	
	ORConnector* inConnector = [[ORConnector alloc] initAt:NSMakePoint(0,[self frame].size.height/2-kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:inConnector forKey:@"Input1"];
    [ inConnector setConnectorType: 'TLI ' ];
    [ inConnector addRestrictedConnectionType: 'TLO ' ]; //can only connect to logic outputs
    [inConnector release];
	
    ORConnector* outConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,[self frame].size.height/2-kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:outConnector forKey:@"Output1"];
    [ outConnector setConnectorType: 'TLO ' ];
    [ outConnector addRestrictedConnectionType: 'TLI ' ]; //can only connect to logic inputs
    [outConnector release];	
}

- (BOOL) evalWithDelegate:(id)anObj
{
	return ![[self objectConnectedTo:@"Input1"] evalWithDelegate:anObj];
}

@end


