//
//  ORLogicPatternModel.m
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
#import "ORLogicPatternModel.h"

NSString* ORLogicPatternChanged = @"ORLogicPatternChanged";
NSString* ORLogicPatternMaskChanged	= @"ORLogicPatternMaskChanged";

@implementation ORLogicPatternModel

#pragma mark ¥¥¥Initialization
- (BOOL) isInputObject  {return YES;}
- (BOOL) isOutputObject {return NO;}
- (void) setUpImage
{
	NSImage* aCachedImage = [NSImage imageNamed:@"LogicPattern"];
	NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
	[i lockFocus];
	[aCachedImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
	NSAttributedString* n = [[NSAttributedString alloc] 
							 initWithString:[NSString stringWithFormat:@"0x%08x",[self pattern]] 
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
    return  [aGuardian conformsToProtocol:NSProtocolFromString(@"TriggerLogicIn")];
}

- (void) makeMainController
{
    [self linkToController:@"ORLogicPatternController"];
}

-(void) makeConnectors
{	
	NSPoint loc = NSMakePoint([self frame].size.width - kConnectorSize,[self frame].size.height/2 - kConnectorSize/2 );
	ORConnector* aConnector = [[ORConnector alloc] initAt:loc withGuardian:self withObjectLink:self];
	[[self connectors] setObject:aConnector forKey:@"Output1"];
	[ aConnector setConnectorType: 'TLO ' ];
	[ aConnector addRestrictedConnectionType: 'TLI ' ]; //can only connect to processor inputs
	[aConnector release];
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"Logic Pattern %d",[self uniqueIdNumber]];
}

- (unsigned long) pattern
{
	return pattern;
}

- (void) setPattern:(unsigned long)aPattern
{
	[[[self undoManager] prepareWithInvocationTarget:self] setPattern:pattern];
    pattern = aPattern;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLogicPatternChanged object:self];
}	
- (unsigned long) patternMask
{
	return patternMask;
}
- (void) setPatternMask:(unsigned long)aPatternMask;
{	
	[[[self undoManager] prepareWithInvocationTarget:self] setPatternMask:patternMask];
    patternMask = aPatternMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLogicPatternMaskChanged object:self];

}

- (BOOL) evalWithDelegate:(id)anObj
{
	return ([anObj inputLogicValue]&patternMask) == pattern;
}

- (void) reset
{
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setPattern:[decoder decodeInt32ForKey:@"Pattern"]];
    [self setPatternMask:[decoder decodeInt32ForKey:@"PatternMask"]];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt32:pattern forKey:@"Pattern"];
    [encoder encodeInt32:patternMask forKey:@"PatternMask"];
}

@end


