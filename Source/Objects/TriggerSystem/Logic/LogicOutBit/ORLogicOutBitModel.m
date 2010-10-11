//
//  ORIOLogicOutBitModel.m
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
#import "ORLogicOutBitModel.h"

NSString* ORLogicOutBitChanged = @"ORLogicOutBitChanged";


@implementation ORLogicOutBitModel

#pragma mark ¥¥¥Initialization
- (void) setUpImage
{
	NSImage* aCachedImage = [NSImage imageNamed:@"LogicOutBit"];
	NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
	[i lockFocus];
	[aCachedImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
	NSAttributedString* n = [[NSAttributedString alloc] 
							 initWithString:[NSString stringWithFormat:@"%d",[self bit]] 
							 attributes:[NSDictionary dictionaryWithObject:[NSFont labelFontOfSize:12] forKey:NSFontAttributeName]];
	
	[n drawAtPoint:NSMakePoint(2,5)];
	[n release];
	[i unlockFocus];		
	[self setImage:i];
	[i release];
	
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:OROrcaObjectImageChanged
	 object:self];
}

- (BOOL) acceptsGuardian: (OrcaObject *)aGuardian
{
    return  [aGuardian isMemberOfClass:NSClassFromString(@"ORIP408Model")];
}
- (void) makeMainController
{
    [self linkToController:@"ORLogicOutBitController"];
}

-(void) makeConnectors
{	
	NSPoint loc = NSMakePoint(0,[self frame].size.height - kConnectorSize );
	ORConnector* aConnector = [[ORConnector alloc] initAt:loc withGuardian:self withObjectLink:self];
	[[self connectors] setObject:aConnector forKey:@"Bit"];
	[ aConnector setConnectorType: 'TLI ' ];
	[ aConnector addRestrictedConnectionType: 'TLO ' ]; //can only connect to processor inputs
	[aConnector release];
}

- (Class) guardianClass   { return NSClassFromString(@"ORIP408Model"); }


- (NSString*) identifier
{
    return [NSString stringWithFormat:@"Logic Out %d",[self uniqueIdNumber]];
}

- (unsigned short) bit
{
	return bit;
}

- (void) setBit:(unsigned short)aBit
{
	[[[self undoManager] prepareWithInvocationTarget:self] setBit:bit];
    bit = aBit;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLogicOutBitChanged object:self];
}	

- (BOOL) value
{
	return value;
}

- (BOOL) eval
{
	value = [[self objectConnectedTo:@"Bit"] eval];
	return value;
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setBit:[decoder decodeIntForKey:@"Bit"]];
    
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:bit forKey:@"Bit"];
    
}


@end


