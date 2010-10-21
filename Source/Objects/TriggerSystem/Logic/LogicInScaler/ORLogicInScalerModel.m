//
//  ORLogicInScalerModel.m
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
#import "ORLogicInScalerModel.h"

NSString* ORLogicInScalerChanged = @"ORLogicInScalerChanged";

@implementation ORLogicInScalerModel

#pragma mark ¥¥¥Initialization
- (void) setUpImage
{
	NSImage* aCachedImage = [NSImage imageNamed:@"LogicInScaler"];
	NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
	[i lockFocus];
	[aCachedImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
	NSAttributedString* n = [[NSAttributedString alloc] 
							 initWithString:[NSString stringWithFormat:@"%2d",[self channel]] 
							 attributes:[NSDictionary dictionaryWithObject:[NSFont labelFontOfSize:12] forKey:NSFontAttributeName]];
	
	[n drawAtPoint:NSMakePoint(7,4)];
	[n release];
	[i unlockFocus];		
	[self setImage:i];
	[i release];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:OROrcaObjectImageChanged object:self];
}

- (BOOL) acceptsGuardian: (OrcaObject *)aGuardian
{
    return  [aGuardian conformsToProtocol:NSProtocolFromString(@"TriggerControllingScaler")];
}

- (void) makeMainController
{
    [self linkToController:@"ORLogicInScalerController"];
}

-(void) makeConnectors
{	
	NSPoint loc = NSMakePoint([self frame].size.width - kConnectorSize,[self frame].size.height/2 - kConnectorSize/2 );
	ORConnector* aConnector = [[ORConnector alloc] initAt:loc withGuardian:self withObjectLink:self];
	[[self connectors] setObject:aConnector forKey:@"Bit"];
	[ aConnector setConnectorType: 'TLO ' ];
	[ aConnector addRestrictedConnectionType: 'TLI ' ]; //can only connect to processor inputs
	[aConnector release];
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"Logic In %d",[self uniqueIdNumber]];
}

- (unsigned short) channel
{
	return channel;
}

- (void) setChannel:(unsigned short)aChannel
{
	[[[self undoManager] prepareWithInvocationTarget:self] setChannel:channel];
    channel = aChannel;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLogicInScalerChanged object:self];
}	

- (BOOL) evalWithDelegate:(id)anObj
{
	BOOL changed = NO;
	if(!firstTime){
		unsigned long theScalerValue = [anObj counts:channel];
		if(theScalerValue != lastScalerValue){
			changed = YES;
		}
		lastScalerValue = theScalerValue;
	}
	else {
		lastScalerValue = [anObj counts:channel];
		firstTime = NO;
	}
	return changed;
}

- (void) reset
{
	firstTime = YES;
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setChannel:[decoder decodeIntForKey:@"Channel"]];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:channel forKey:@"Channel"];
}

@end


