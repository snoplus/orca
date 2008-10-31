//
//  ORFec32Model.h
//  Orca
//
//  Created by Mark Howe on Wed Oct 15,2008.
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
#import "ORFec32Model.h"

NSString* ORFec32ModelShowVoltsChanged = @"ORFec32ModelShowVoltsChanged";
NSString* ORFec32ModelCommentsChanged = @"ORFec32ModelCommentsChanged";
NSString* ORFecCmosChanged	= @"ORFecCmosChanged";
NSString* ORFecVResChanged	= @"ORFecVResChanged";
NSString* ORFecHVRefChanged = @"ORFecHVRefChanged";
NSString* ORFecLock			= @"ORFecLock";
	
@implementation ORFec32Model

#pragma mark •••Initialization
- (id) init //designated initializer
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];

    [[self undoManager] enableUndoRegistration];
    
    return self;
}
- (void) dealloc
{
    [comments release];
    [super dealloc];
}

#pragma mark ***Accessors

- (BOOL) showVolts
{
    return showVolts;
}

- (void) setShowVolts:(BOOL)aShowVolts
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShowVolts:showVolts];
    
    showVolts = aShowVolts;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORFec32ModelShowVoltsChanged object:self];
}

- (NSString*) comments
{
    return comments;
}

- (void) setComments:(NSString*)aComments
{
	if(!aComments) aComments = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setComments:comments];
    
    [comments autorelease];
    comments = [aComments copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORFec32ModelCommentsChanged object:self];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"Fec32Card"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORFec32Controller"];
}
- (unsigned char) cmos:(short)anIndex
{
	return cmos[anIndex];
}

- (void) setCmos:(short)anIndex withValue:(unsigned char)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCmos:anIndex withValue:cmos[anIndex]];
	cmos[anIndex] = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFecCmosChanged object:self];
}

- (float) vRes
{
	return vRes;
}

- (void) setVRes:(float)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setVRes:vRes];
	vRes = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFecVResChanged object:self];
}

- (float) hVRef
{
	return hVRef;
}

- (void) setHVRef:(float)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHVRef:hVRef];
	hVRef = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFecHVRefChanged object:self];
}

#pragma mark Converted Data Methods
- (void) setCmosVoltage:(short)n withValue:(float) value
{
	if(value>kCmosMax)		value = kCmosMax;
	else if(value<kCmosMin)	value = kCmosMin;
	
	[self setCmos:n withValue:255.0*(value-kCmosMin)/(kCmosMax-kCmosMin)+0.5];
}

- (float) cmosVoltage:(short) n
{
	return ((kCmosMax-kCmosMin)/255.0)*cmos[n]+kCmosMin;
}

- (void) setVResVoltage:(float) value
{
	if(value>kVResMax)		value = kVResMax;
	else if(value<kVResMin)	value = kVResMin;
	[self setVRes:255.0*(value-kVResMin)/(kVResMax-kVResMin)+0.5];
}

- (float) vResVoltage
{
	return ((kVResMax-kVResMin)/255.0)*vRes+kVResMin;
}

- (void) setHVRefVoltage:(float) value
{
	if(value>kHVRefMax)		 value = kHVRefMax;
	else if(value<kHVRefMin) value = kHVRefMin;
	[self setHVRef:(255.0*(value-kHVRefMin)/(kHVRefMax-kHVRefMin)+0.5)];
}

- (float) hVRefVoltage
{
	return ((kHVRefMax-kHVRefMin)/255.0)*hVRef+kHVRefMin;
}

#pragma mark •••Archival
- (id) initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];

    [self setShowVolts:	[decoder decodeBoolForKey:  @"showVolts"]];
    [self setComments:	[decoder decodeObjectForKey:@"comments"]];
    [self setVRes:		[decoder decodeFloatForKey: @"vRes"]];
    [self setHVRef:		[decoder decodeFloatForKey: @"hVRef"]];
	int i;
	for(i=0;i<6;i++){
		[self setCmos:i withValue: [decoder decodeFloatForKey: [NSString stringWithFormat:@"cmos%d",i]]];
	}	
	
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
	[super encodeWithCoder:encoder];
	
	[encoder encodeBool:showVolts	forKey:@"showVolts"];
	[encoder encodeObject:comments	forKey:@"comments"];
	[encoder encodeFloat:vRes		forKey:@"vRes"];
	[encoder encodeFloat:hVRef		forKey:@"hVRef"];
	int i;
	for(i=0;i<6;i++){
		[encoder encodeFloat:cmos[i] forKey:[NSString stringWithFormat:@"cmos%d",i]];
	}	
}

@end
