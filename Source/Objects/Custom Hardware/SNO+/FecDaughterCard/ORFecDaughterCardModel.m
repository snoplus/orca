//
//  ORFecDaughterCardModel.cp
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
#import "ORFecDaughterCardModel.h"
#import "ORFec32Model.h"
#import "ORSNOConstants.h"


NSString* ORDCModelCommentsChanged			= @"ORDCModelCommentsChanged";
NSString* ORDCModelShowVoltsChanged			= @"ORDCModelShowVoltsChanged";
NSString* ORDCModelSetAllCmosChanged		= @"ORDCModelSetAllCmosChanged";
NSString* ORDCModelCmosRegShownChanged		= @"ORDCModelCmosRegShownChanged";
NSString* ORDCModelRp1Changed				= @"ORDCModelRp1Changed";
NSString* ORDCModelRp2Changed				= @"ORDCModelRp2Changed";
NSString* ORDCModelVliChanged				= @"ORDCModelVliChanged";
NSString* ORDCModelVsiChanged				= @"ORDCModelVsiChanged";
NSString* ORDCModelVtChanged				= @"ORDCModelVtChanged";
NSString* ORDCModelVbChanged				= @"ORDCModelVbChanged";
NSString* ORDCModelNs100widthChanged		= @"ORDCModelNs100widthChanged";
NSString* ORDCModelNs20widthChanged			= @"ORDCModelNs20widthChanged";
NSString* ORDCModelNs20delayChanged			= @"ORDCModelNs20delayChanged";
NSString* ORDCModelTac0trimChanged			= @"ORDCModelTac0trimChanged";
NSString* ORDCModelTac1trimChanged			= @"ORDCModelTac1trimChanged";

@implementation ORFecDaughterCardModel

#pragma mark •••Initialization
- (id) init //designated initializer
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
	[self loadDefaultValues];
    [[self undoManager] enableUndoRegistration];
    return self;
}

-(void)dealloc
{
    [comments release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"FecDaughterCard"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORFecDaughterCardController"];
}

- (Class) guardianClass 
{
	return NSClassFromString(@"ORFec32Model");
}

#pragma mark •••Accessors
- (int) globalCardNumber
{
	return ([[guardian guardian ] crateNumber] * 16) + ([guardian stationNumber] * 4) + [self slot];	
}

- (NSComparisonResult) globalCardNumberCompare:(id)aCard
{
	return [self globalCardNumber] - [aCard globalCardNumber];
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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDCModelCommentsChanged object:self];
}

- (void) setSlot:(int)aSlot
{
	[super setSlot:aSlot];
	[[self guardian] objectCountChanged];
}

- (BOOL) showVolts
{
    return showVolts;
}

- (void) setShowVolts:(BOOL)aShowVolts
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShowVolts:showVolts];
    showVolts = aShowVolts;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDCModelShowVoltsChanged object:self];
}

- (BOOL) setAllCmos
{
    return setAllCmos;
}

- (void) setSetAllCmos:(BOOL)aSetAllCmos
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSetAllCmos:setAllCmos];
    setAllCmos = aSetAllCmos;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDCModelSetAllCmosChanged object:self];
}

- (short) cmosRegShown
{
    return cmosRegShown;
}

- (void) setCmosRegShown:(short)aCmosRegShown
{
	if(aCmosRegShown<0)aCmosRegShown = 7;
	if(aCmosRegShown>7)aCmosRegShown = 0;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setCmosRegShown:cmosRegShown];
    cmosRegShown = aCmosRegShown;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDCModelCmosRegShownChanged object:self];
}

- (unsigned char) rp1:(short)anIndex
{
	return rp1[anIndex];
}

- (void) setRp1:(short)anIndex withValue:(unsigned char)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRp1:anIndex withValue:rp1[anIndex]];
    rp1[anIndex] = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDCModelRp1Changed object:self];
}

- (unsigned char) rp2:(short)anIndex
{
	return rp2[anIndex];
}

- (void) setRp2:(short)anIndex withValue:(unsigned char)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRp2:anIndex withValue:rp2[anIndex]];
    rp2[anIndex] = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDCModelRp2Changed object:self];
}

- (unsigned char) vli:(short)anIndex
{
	return vli[anIndex];
}

- (void) setVli:(short)anIndex withValue:(unsigned char)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setVli:anIndex withValue:vli[anIndex]];
    vli[anIndex] = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDCModelVliChanged object:self];
}

- (unsigned char) vsi:(short)anIndex
{
	return vsi[anIndex];
}

- (void) setVsi:(short)anIndex withValue:(unsigned char)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setVsi:anIndex withValue:vsi[anIndex]];
    vsi[anIndex] = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDCModelVsiChanged object:self];
}

- (unsigned char) vt:(short)anIndex
{
	return vt[anIndex];
}

- (void) setVt:(short)anIndex withValue:(unsigned char)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setVt:anIndex withValue:vt[anIndex]];
    vt[anIndex] = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDCModelVtChanged object:self];
}

- (unsigned char) vb:(short)anIndex
{
	return vb[anIndex];
}

- (unsigned char) vb:(short)ch egain:(short)gain
{
	return vb[ch + (gain?8:0)];
}

- (void) setVb:(short)anIndex withValue:(unsigned char)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setVb:anIndex withValue:vb[anIndex]];
    vb[anIndex] = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDCModelVbChanged object:self];
}

- (unsigned char) ns100width:(short)anIndex
{
	return ns100width[anIndex];
}

- (void) setNs100width:(short)anIndex withValue:(unsigned char)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNs100width:anIndex withValue:ns100width[anIndex]];
    ns100width[anIndex] = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDCModelNs100widthChanged object:self];
}

- (unsigned char) ns20width:(short)anIndex
{
	return ns20width[anIndex];
}

- (void) setNs20width:(short)anIndex withValue:(unsigned char)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNs20width:anIndex withValue:ns20width[anIndex]];
    ns20width[anIndex] = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDCModelNs20widthChanged object:self];
}

- (unsigned char) ns20delay:(short)anIndex
{
	return ns20delay[anIndex];
}
- (void) setNs20delay:(short)anIndex withValue:(unsigned char)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNs20delay:anIndex withValue:ns20delay[anIndex]];
    ns20delay[anIndex] = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDCModelNs20delayChanged object:self];
}

- (unsigned char) tac0trim:(short)anIndex
{
	return tac0trim[anIndex];
}

- (void) setTac0trim:(short)anIndex withValue:(unsigned char)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTac0trim:anIndex withValue:tac0trim[anIndex]];
    tac0trim[anIndex] = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDCModelTac0trimChanged object:self];
}

- (unsigned char) tac1trim:(short)anIndex
{
	return tac1trim[anIndex];
}
- (void) setTac1trim:(short)anIndex withValue:(unsigned char)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTac1trim:anIndex withValue:tac1trim[anIndex]];
    tac1trim[anIndex] = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDCModelTac1trimChanged object:self];
}

#pragma mark ====Converter Methods
- (void) setRp1Voltage:(short)n withValue:(float)value
{
	[self setRp1:n withValue:255.0*(value-kRp1Min)/(kRp1Max-kRp1Min)+0.5];
}

- (float) rp1Voltage:(short) n
{
	return ((kRp1Max-kRp1Min)/255.0)*rp1[n]+kRp1Min;
}

- (void) setRp2Voltage:(short)n withValue:(float)value
{
	[self setRp2:n withValue:255.0*(value-kRp2Min)/(kRp2Max-kRp2Min)+0.5];
}

- (float) rp2Voltage:(short) n
{
	return ((kRp2Max-kRp2Min)/255.0)*rp2[n]+kRp2Min;
}

- (void) setVliVoltage:(short)n withValue:(float)value
{
	[self setVli:n withValue:255.0*(value-kVliMin)/(kVliMax-kVliMin)+0.5];
}

- (float) vliVoltage:(short) n
{
	return ((kVliMax-kVliMin)/255.0)*vli[n]+kVliMin;
}

- (void) setVsiVoltage:(short)n withValue:(float)value
{
	[self setVsi:n withValue:255.0*(value-kVsiMin)/(kVsiMax-kVsiMin)+0.5];
}

- (float) vsiVoltage:(short) n
{
	return ((kVsiMax-kVsiMin)/255.0)*vsi[n]+kVsiMin;
}

- (void) setVtVoltage:(short)n withValue:(float)value
{
	[self setVt:n withValue:255.0*(value-kVtMin)/(kVtMax-kVtMin)+0.5];
}

- (float) vtVoltage:(short) n
{
	return ((kVtMax-kVtMin)/255.0)*vt[n]+kVtMin;
}

- (void) setVbVoltage:(short)n withValue:(float)value
{
	[self setVb:n withValue:255.0*(value-kVbMin)/(kVbMax-kVbMin)+0.5];
}

- (float) vbVoltage:(short) n
{
	return ((kVbMax-kVbMin)/255.0)*vb[n]+kVbMin;
}


- (void) loadDefaultValues
{
	int i;
	for(i=0;i<2;i++){
		[self setRp1:i withValue:115];
		[self setRp2:i withValue:135];
		[self setVli:i withValue:120];
		[self setVsi:i withValue:120];
	}
	for(i=0;i<8;i++){
		[self setVt:i withValue:255];
	}
	for(i=0;i<16;i++){
		[self setVb:i withValue:160]; 
	}
	
	for(i=0;i<8;i++){
		[self setNs100width:i withValue:126]; 
		[self setNs20width:i withValue:32]; 
		[self setNs20delay:i withValue:2]; 
		[self setTac0trim:i withValue:0]; 
		[self setTac1trim:i withValue:0]; 
	}
}

#pragma mark •••Archival
- (id) initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setComments:		[decoder decodeObjectForKey:@"comments"]];
    [self setShowVolts:		[decoder decodeBoolForKey:@"showVolts"]];
	[self setSetAllCmos:	[decoder decodeBoolForKey:@"setAllCmos"]];
	[self setCmosRegShown:	[decoder decodeIntForKey:@"cmosRegShown"]];
	int i;
	for(i=0;i<2;i++){
		[self setRp1:i withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"rp1_%d",i]]];
		[self setRp2:i withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"rp2_%d",i]]];
		[self setVli:i withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"vli_%d",i]]];
		[self setVsi:i withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"vsi_%d",i]]];
	}
 	for(i=0;i<8;i++){
		[self setVt:i withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"vt_%d",i]]];
		[self setNs100width:i withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"select100nsTrigger_%d",i]]];
		[self setNs100width:i withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"ns100width_%d",i]]];
		[self setNs20width:i withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"ns20width_%d",i]]];
		[self setNs20delay:i withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"ns20delay_%d",i]]];
		[self setTac0trim:i withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"tac0trim_%d",i]]];
		[self setTac1trim:i withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"tac1trim_%d",i]]];
	}
 	for(i=0;i<16;i++){
		[self setVb:i withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"vb_%d",i]]];
	}
	[[self undoManager] enableUndoRegistration];
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	[encoder encodeObject:comments	forKey:@"comments"];
	[encoder encodeBool:showVolts	forKey:@"showVolts"];
	[encoder encodeBool:setAllCmos	forKey:@"setAllCmos"];
	[encoder encodeInt:cmosRegShown forKey:@"cmosRegShown"];
	int i;
	for(i=0;i<2;i++){
		[encoder encodeInt:rp1[i] forKey:[NSString stringWithFormat:@"rp1_%d",i]];
		[encoder encodeInt:rp2[i] forKey:[NSString stringWithFormat:@"rp2_%d",i]];
		[encoder encodeInt:vli[i] forKey:[NSString stringWithFormat:@"vli_%d",i]];
		[encoder encodeInt:vsi[i] forKey:[NSString stringWithFormat:@"vsi_%d",i]];
	}
 	for(i=0;i<8;i++){
		[encoder encodeInt:vt[i] forKey:[NSString stringWithFormat:@"vt_%d",i]];
		[encoder encodeInt:ns100width[i] forKey:[NSString stringWithFormat:@"ns100width_%d",i]];
		[encoder encodeInt:ns20width[i] forKey:[NSString stringWithFormat:@"ns20width_%d",i]];
		[encoder encodeInt:ns20delay[i] forKey:[NSString stringWithFormat:@"ns20delay_%d",i]];
		[encoder encodeInt:tac0trim[i] forKey:[NSString stringWithFormat:@"tac0trim_%d",i]];
		[encoder encodeInt:tac1trim[i] forKey:[NSString stringWithFormat:@"tac1trim_%d",i]];
	}
 	for(i=0;i<16;i++){
		[encoder encodeInt:vb[i] forKey:[NSString stringWithFormat:@"vb_%d",i]];
	}
}

- (void) readBoardIds
{
	@try {
		[self setBoardID:[[self guardian] performBoardIDRead:DC_BOARD0_ID_INDEX + [self slot]]];
	}
	@catch(NSException* localException) {
		[self setBoardID:@"0000"];
	}
}

@end


