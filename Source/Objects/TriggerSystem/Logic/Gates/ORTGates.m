//
//  ORTGate.m
//  Orca
//
//  Created by Mark Howe on 10/6/10.
//  Copyright  © 2009 University of North Carolina. All rights reserved.
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
#import "ORTGates.h"
#import "ORLogicInBitModel.h"

@implementation ORTGate

#pragma mark ¥¥¥Initialization
- (BOOL) acceptsGuardian: (OrcaObject *)aGuardian
{
    return  [aGuardian isMemberOfClass:NSClassFromString(@"ORIP408Model")];
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
    [outConnector release];}

- (Class) guardianClass   { return NSClassFromString(@"ORIP408Model"); }

- (BOOL) hasDialog
{
	return NO;
}

- (BOOL) eval
{
	return NO;
}

@end

//-------------------------------------------------------------
@implementation ORTAndGate
- (void) setUpImage			{ [self setImage:[NSImage imageNamed:@"AndGate"]]; }
- (NSString*) identifier	{ return [NSString stringWithFormat:@"And %d",[self uniqueIdNumber]]; }
- (BOOL) eval
{
	BOOL value1 = [[self objectConnectedTo:@"Input1"] bitValue];
	BOOL value2 = [[self objectConnectedTo:@"Input2"] bitValue];
	return value1 & value2;
}
@end

//-------------------------------------------------------------
@implementation ORTNandGate
- (void) setUpImage		 { [self setImage:[NSImage imageNamed:@"NandGate"]]; }
- (NSString*) identifier { return [NSString stringWithFormat:@"Nand %d",[self uniqueIdNumber]]; }
- (BOOL) eval			 { return ![super eval]; }
@end

//-------------------------------------------------------------
@implementation ORTOrGate
#pragma mark ¥¥¥Initialization
- (void) setUpImage		 { [self setImage:[NSImage imageNamed:@"ORGate"]]; }
- (NSString*) identifier { return [NSString stringWithFormat:@"Or %d",[self uniqueIdNumber]]; }

- (BOOL) eval
{
	BOOL value1 = [[self objectConnectedTo:@"Input1"] bitValue];
	BOOL value2 = [[self objectConnectedTo:@"Input2"] bitValue];
	return value1 | value2;
}
@end

//-------------------------------------------------------------
@implementation ORTXorGate
- (void) setUpImage		 { [self setImage:[NSImage imageNamed:@"XorGate"]]; }
- (NSString*) identifier { return [NSString stringWithFormat:@"XOrGate %d",[self uniqueIdNumber]]; }

- (BOOL) eval
{
	BOOL value1 = [[self objectConnectedTo:@"Input1"] bitValue];
	BOOL value2 = [[self objectConnectedTo:@"Input2"] bitValue];
	return value1 ^ value2;
}
@end

//-------------------------------------------------------------
@implementation ORTNorGate
- (void) setUpImage		 { [self setImage:[NSImage imageNamed:@"NorGate"]]; }
- (NSString*) identifier { return [NSString stringWithFormat:@"NorGate %d",[self uniqueIdNumber]]; }
- (BOOL) eval			 { return ![self eval]; }
@end

