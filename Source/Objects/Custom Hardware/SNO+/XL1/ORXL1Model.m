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
#import "ORSNOCrateModel.h"
#import "ORSNOCard.h"

NSString* ORXilinxFileChanged			= @"ORXilinxFileChanged";
NSString* ORFecAdcClockChanged			= @"ORFecAdcClockChanged";
NSString* ORFecSequencerClockChanged	= @"ORFecSequencerClockChanged";
NSString* ORFecMemoryClockChanged		= @"ORFecMemoryClockChanged";
NSString* ORFecAlowedErrorsChanged		= @"ORFecAlowedErrorsChanged";
NSString* ORXL1Lock						= @"ORXL1Lock";

@implementation ORXL1Model

#pragma mark •••Initialization

- (void) dealloc
{
    [connectorName release];
    [connector release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"XL1Card"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORXL1Controller"];
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
	id nextXL2 = [connector connectedObject];
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

- (id) adapter
{
	id anAdapter = [[self guardian] adapter];
	if(anAdapter)return anAdapter;
	else [NSException raise:@"No PCI/VME adapter" format:@"Check a PCI/VME adapter is in place and connected to the Mac.\n"];
	return nil;

	return [[self guardian] adapter];
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
 
- (void) awakeAfterDocumentLoaded
{
	int i;
	for(i=0;i<kNumFecMonitorAdcs; i++){
		adcAllowedError[i] = kAllowedFecMonitorError;
	}
}

- (NSString*) xilinxFile 
{
	return xilinxFile;
}
- (void)setXilinxFile:(NSString*)aFilePath;
{
	if(!aFilePath)aFilePath = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setXilinxFile:xilinxFile];
	
	[aFilePath retain];
	[xilinxFile release];
	xilinxFile = aFilePath;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXilinxFileChanged object:self];
}

- (float) adcClock
{
	return adcClock;
}
- (void) setAdcClock:(float)aValue;
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAdcClock:adcClock];
	
	adcClock = aValue;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFecAdcClockChanged object:self];
}

- (float) sequencerClock
{
	return sequencerClock;
}
- (void) setSequencerClock:(float)aValue;
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSequencerClock:sequencerClock];
	
	sequencerClock = aValue;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFecSequencerClockChanged object:self];
}

- (float) memoryClock
{
	return memoryClock;
}
- (void) setMemoryClock:(float)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMemoryClock:memoryClock];
	
	memoryClock = aValue;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFecMemoryClockChanged object:self];
}

- (float) adcAllowedError:(short)anIndex
{
	return adcAllowedError[anIndex];
}

- (void) setAdcAllowedError:(short)anIndex withValue:(float)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAdcAllowedError:anIndex withValue:adcAllowedError[anIndex]];
	
	adcAllowedError[anIndex] = aValue;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFecAlowedErrorsChanged object:self];
}


#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setConnectorName:	[decoder decodeObjectForKey:@"connectorName"]];
    [self setConnector:		[decoder decodeObjectForKey:@"connector"]];
	[self setSlot:			[decoder decodeIntForKey:@"slot"]];
	[self setXilinxFile:	[decoder decodeObjectForKey: @"xilinxFile"]];
    [self setAdcClock:		[decoder decodeFloatForKey: @"adcClock"]];
    [self setSequencerClock:[decoder decodeFloatForKey: @"sequencerClock"]];
    [self setMemoryClock:	[decoder decodeFloatForKey: @"memoryClock"]];
	int i;
	for(i=0;i<kNumFecMonitorAdcs;i++){
		[self setAdcAllowedError:i withValue: [decoder decodeFloatForKey: [NSString stringWithFormat:@"adcAllowedError%d",i]]];
	}	
    
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:[self connectorName]	forKey:@"connectorName"];
    [encoder encodeObject:[self connector]		forKey:@"connector"];
    [encoder encodeInt:[self slot]				forKey:@"slot"];
	[encoder encodeObject:xilinxFile			forKey:@"xilinxFile"];
	[encoder encodeFloat:adcClock				forKey:@"adcClock"];
	[encoder encodeFloat:sequencerClock			forKey:@"sequencerClock"];
	int i;
	for(i=0;i<kNumFecMonitorAdcs;i++){
		[encoder encodeFloat:adcAllowedError[i] forKey:[NSString stringWithFormat:@"adcAllowedError%d",i]];
	}	
}

#pragma mark •••Hardware Access

- (void) writeHardwareRegister:(unsigned long) regAddress value:(unsigned long) aValue
{
	[[self adapter] writeLongBlock:&aValue
              atAddress:regAddress
             numToWrite:1
             withAddMod:0x29
          usingAddSpace:0x01];
}

- (unsigned long) readHardwareRegister:(unsigned long) regAddress
{
	unsigned long aValue = 0;
	[[self adapter] readLongBlock:&aValue
              atAddress:regAddress
             numToRead:1
             withAddMod:0x29
          usingAddSpace:0x01];
	
	return aValue;
}
@end
