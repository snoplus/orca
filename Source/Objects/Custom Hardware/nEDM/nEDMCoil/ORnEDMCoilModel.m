//
//  ORnEDMCoilModel.m
//  Orca
//
//  Created by Michael Marino 15 Mar 2012 
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORnEDMCoilModel.h"
#import "ORTTCPX400DPModel.h"

NSString* ORnEDMCoilPollingActivityChanged = @"ORnEDMCoilPollingActivityChanged";
NSString* ORnEDMCoilPollingFrequencyChanged    = @"ORnEDMCoilPollingFrequencyChanged";

@interface ORnEDMCoilModel (private)
// Private interface
#pragma mark •••Running
- (void) _runProcess;
- (void) _stopRunning;
- (void) _startRunning;
- (void) _setUpRunning:(BOOL)verbose;

#pragma mark •••Read/Write
- (void) _readADCValues;
- (void) _calcPowerSupplyValues;
- (void) _syncPowerSupplyValues;
- (double) _fieldAtMagnetometer:(int)index;
- (void) _setCurrent:(double)current forSupply:(int)index;
@end

@implementation ORnEDMCoilModel (private)
- (void) _runProcess
{
    // The current calculation process
    @try { 
        [self _readADCValues];
        [self _calcPowerSupplyValues];
        [self _syncPowerSupplyValues];
    }
	@catch(NSException* localException) { 
		//catch this here to prevent it from falling thru, but nothing to do.
	}
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_runProcess) object:nil];
	if(pollingFrequency!=0){
		[self performSelector:@selector(_runProcess) withObject:nil afterDelay:pollingFrequency];
	} else {
        [self _stopRunning];
    }    

}

- (void) _readADCValues
{
    // Will read the current ADC values
}

- (void) _calcPowerSupplyValues;
{
    // Will calculate the desired power supply currents given.  Johannes, you should start here,
    // grabbing desired field values using [self _fieldAtMagnetometer:index]; and setting the 
    // current using [self _setCurrent:currentValue forSupply:index];
    
}

- (void) _syncPowerSupplyValues
{
    // Will write the saved power supply values to the hardware
}

- (double) _fieldAtMagnetometer:(int)index
{
    // Will return the field at a given magnetometer, this index will be mapped.
    return 0.0;
}

- (void) _setCurrent:(double)current forSupply:(int)index 
{
    // Will save the current for a given supply, currently this writes directly to the 
    // 0 channel on a given power supply.  Will be fixed.  
    [[objMap objectForKey:[NSNumber numberWithInt:index]] setWriteToSetCurrentLimit:current withOutput:0];
}

#pragma mark •••Running
- (void) _stopRunning
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_runProcess) object:nil];
	isRunning = NO;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORnEDMCoilPollingActivityChanged
	 object: self]; 
    NSLog(@"Stopping nEDM Coil Compensation processing.\n");
}

- (void) _startRunning
{
	[self _setUpRunning:YES];
}

- (void) _setUpRunning:(BOOL)verbose
{
	
	if(isRunning && pollingFrequency != 0)return;
    
    if(pollingFrequency!=0){  
		isRunning = YES;
        if(verbose) NSLog(@"Running nEDM Coil compensation at a rate of %.2f Hs.\n",pollingFrequency);
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_runProcess) object:nil];
        [self performSelector:@selector(_runProcess) withObject:self afterDelay:1./pollingFrequency];
        [self _runProcess];
    }
    else {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_runProcess) object:nil];
        if(verbose) NSLog(@"Not running nEDM Coil compensation, polling frequency set to 0\n");
    }
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORnEDMCoilPollingActivityChanged
	 object: self];
}

@end

@implementation ORnEDMCoilModel

#pragma mark •••initialization

- (id) init
{
    self = [super init];
    objMap = [[NSMutableDictionary dictionary] retain];
    return self;
}

- (void) dealloc
{
    [objMap release];
    [super dealloc];
}

- (void) makeConnectors
{	
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"nEDMCoil"]];
    // The following code might still be useful, hold on to it for the time being.  - M. Marino
}

- (void) makeMainController
{
    [self linkToController:@"ORnEDMCoilController"];
}

- (BOOL) isRunning
{
    return isRunning;
}

- (float) pollingFrequency
{
    return pollingFrequency;
}

- (void) setPollingFrequency:(float)aFrequency
{
    pollingFrequency = aFrequency;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORnEDMCoilPollingFrequencyChanged
	 object: self];
}

- (void) toggleRunState
{
    if (isRunning) [self _stopRunning];
    else [self _startRunning];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    //NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
}

#pragma mark •••ORGroup
- (void) objectCountChanged
{
    // Recalculate the obj map
    [objMap removeAllObjects];
    NSEnumerator* e = [self objectEnumerator];
    id anObject;
    while (anObject = [e nextObject]) {
        [objMap setObject:anObject forKey:[NSNumber numberWithInt:[anObject tag]]];
    }
}

- (int) rackNumber
{
	return [self uniqueIdNumber];
}

- (void) viewChanged:(NSNotification*)aNotification
{
    [self setUpImage];
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"nEDM Coil %d",[self rackNumber]];
}

- (NSComparisonResult)sortCompare:(OrcaObject*)anObj
{
    return [self uniqueIdNumber] - [anObj uniqueIdNumber];
}

#pragma mark •••CardHolding Protocol
#define objHeight 71
#define objectsInRow 2
- (int) maxNumberOfObjects	{ return 12; }	//default
- (int) objWidth			{ return 100; }	//default
- (int) groupSeparation		{ return 0; }	//default
- (NSString*) nameForSlot:(int)aSlot	
{ 
    return [NSString stringWithFormat:@"Slot %d",aSlot]; 
}

- (NSRange) legalSlotsForObj:(id)anObj
{
	return NSMakeRange(0,[self maxNumberOfObjects]);
}

- (BOOL) slot:(int)aSlot excludedFor:(id)anObj 
{ 
    return NO;
}

- (int)slotAtPoint:(NSPoint)aPoint 
{
	float y = aPoint.y;
    float x = aPoint.x;
	int objWidth = [self objWidth];
    int columnNumber = (int)x/objWidth;
	int rowNumber = (int)y/objHeight;
	
    if (rowNumber >= [self maxNumberOfObjects]/objectsInRow ||
        columnNumber >= objectsInRow) return -1;
    return rowNumber*objectsInRow + columnNumber;
}

- (NSPoint) pointForSlot:(int)aSlot 
{
    int rowNumber = aSlot/objectsInRow;
    int columnNumber = aSlot % objectsInRow;
    return NSMakePoint(columnNumber*[self objWidth],rowNumber*objHeight);
}

- (void) place:(id)aCard intoSlot:(int)aSlot
{
    [aCard setTag:aSlot];
	[aCard moveTo:[self pointForSlot:aSlot]];
}
- (int) slotForObj:(id)anObj
{
    return [anObj tag];
}
- (int) numberSlotsNeededFor:(id)anObj
{
	return [anObj numberSlotsUsed];
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];

    [self setPollingFrequency:[decoder decodeFloatForKey:@"kORnEDMCoilPollingFrequency"]];
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeFloat:pollingFrequency forKey:@"kORnEDMCoilPollingFrequency"];
}

@end

