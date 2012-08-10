//
//  ORMJDVacuumModel.m
//  Orca
//
//  Created by Mark Howe on Tues Mar 27, 2012.
//  Copyright © 2012 CENPA, University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
#pragma mark •••Imported Files
#import "ORMJDVacuumModel.h"
#import "ORMJDVacuumView.h"
#import "ORProcessModel.h"
#import "ORAdcModel.h"
#import "ORAdcProcessing.h"
#import "ORMks660BModel.h"
#import "ORRGA300Model.h"
#import "ORTM700Model.h"
#import "ORTPG256AModel.h"
#import "ORCP8CryopumpModel.h"
#import "ORAlarm.h"

@interface ORMJDVacuumModel (private)
- (void) makeParts;
- (void) makeLines:(VacuumLineStruct*)lineItems num:(int)numItems;
- (void) makePipes:(VacuumPipeStruct*)pipeList num:(int)numItems;
- (void) makeGateValves:(VacuumGVStruct*)pipeList num:(int)numItems;
- (void) makeStaticLabels:(VacuumStaticLabelStruct*)labelItems num:(int)numItems;
- (void) makeDynamicLabels:(VacuumDynamicLabelStruct*)labelItems num:(int)numItems;
- (void) colorRegionsConnectedTo:(int)aRegion withColor:(NSColor*)aColor;
- (void) recursizelyColorRegionsConnectedTo:(int)aRegion withColor:(NSColor*)aColor;
- (void) resetVisitationFlag;
- (void) addConstraintName:(NSString*)aName reason:(NSString*)aReason toGateValve:(id)aGateValve;
- (void) removeConstraintName:(NSString*)aName fromGateValve:(id)aGateValve;

- (void) onAllGateValvesremoveConstraintName:(NSString*)aConstraintName;
- (void) checkAllConstraints;
- (void) deferredConstraintCheck;
- (void) checkTurboRelatedConstraints:(ORTM700Model*) turbo;
- (void) checkCryoPumpRelatedConstraints:(ORCP8CryopumpModel*) cryoPump;
- (void) checkRGARelatedConstraints:(ORRGA300Model*) rga;
- (void) checkPressureConstraints;
- (void) checkDetectorConstraints;
- (double) valueForRegion:(int)aRegion;
- (ORVacuumValueLabel*) regionValueObj:(int)aRegion;
- (BOOL) valueValidForRegion:(int)aRegion;
- (BOOL) region:(int)aRegion valueHigherThan:(double)aValue;

- (ORMks660BModel*)    findBaratron;
- (ORRGA300Model*)     findRGA;
- (ORTM700Model*)      findTurboPump;
- (ORTPG256AModel*)    findPressureGauge;
- (ORCP8CryopumpModel*) findCryoPump;
- (id)findObject:(NSString*)aClassName;

@end


NSString* ORMJDVacuumModelVetoMaskChanged           = @"ORMJDVacuumModelVetoMaskChanged";
NSString* ORMJDVacuumModelShowGridChanged           = @"ORMJDVacuumModelShowGridChanged";
NSString* ORMJCVacuumLock                           = @"ORMJCVacuumLock";
NSString* ORMJDVacuumModelShouldUnbiasDetectorChanged = @"ORMJDVacuumModelShouldUnbiasDetectorChanged";
NSString* ORMJDVacuumModelOkToBiasDetectorChanged   = @"ORMJDVacuumModelOkToBiasDetectorChanged";
NSString* ORMJDVacuumModelDetectorsBiasedChanged    = @"ORMJDVacuumModelDetectorsBiasedChanged";
NSString* ORMJDVacuumModelConstraintsChanged		= @"ORMJDVacuumModelConstraintsChanged";

@implementation ORMJDVacuumModel

#pragma mark •••initialization
- (void) wakeUp
{
    [super wakeUp];
	[self registerNotificationObservers];
}

- (void) sleep
{
    [super sleep];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[parts release];
	[partDictionary release];
	[adcMapArray release];
	[valueDictionary release];
	[orcaClosedCryoPumpValveAlarm clearAlarm];
	[orcaClosedCryoPumpValveAlarm release];
	[orcaClosedCF6TempAlarm clearAlarm];
	[orcaClosedCF6TempAlarm release];
	[super dealloc];
}


- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"MJDVacuum.tif"]];
}

- (NSString*) helpURL
{
	return nil;
}

- (void) makeMainController
{
    [self linkToController:@"ORMJDVacuumController"];
}

- (void) addObjects:(NSArray*)someObjects
{
	[super addObjects:someObjects];
	[self checkAllConstraints];
}

- (void) removeObjects:(NSArray*)someObjects
{
	[super removeObjects:someObjects];
	[self checkAllConstraints];
}

- (void) registerNotificationObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	//we need to know about a specific set of events in order to handle the constraints
	ORMks660BModel* baratron = [self findBaratron];
	if(baratron){
		[notifyCenter addObserver : self
						 selector : @selector(baratronChanged:)
							 name : ORMks660BPressureChanged
						   object : baratron];

		[notifyCenter addObserver : self
						 selector : @selector(baratronChanged:)
							 name : ORSerialPortWithQueueModelIsValidChanged
						   object : baratron];
	}
	
	ORTM700Model* turbo = [self findTurboPump];
	if(turbo){
		[notifyCenter addObserver : self
						 selector : @selector(turboChanged:)
							 name : ORTM700ModelStationPowerChanged
						   object : turbo];
		
		[notifyCenter addObserver : self
						 selector : @selector(turboChanged:)
							 name : ORSerialPortWithQueueModelIsValidChanged
						   object : turbo];
	}
	
	ORTPG256AModel* pressureGauge = [self findPressureGauge];
	if(pressureGauge){
		[notifyCenter addObserver : self
						 selector : @selector(pressureGaugeChanged:)
							 name : ORTPG256APressureChanged
						   object : pressureGauge];
		
		[notifyCenter addObserver : self
						 selector : @selector(pressureGaugeChanged:)
							 name : ORSerialPortWithQueueModelIsValidChanged
						   object : pressureGauge];
	}

	ORCP8CryopumpModel* cryoPump = [self findCryoPump];
	if(cryoPump){
		[notifyCenter addObserver : self
						 selector : @selector(cryoPumpChanged:)
							 name : ORCP8CryopumpModelPumpStatusChanged
						   object : cryoPump];
		
		[notifyCenter addObserver : self
						 selector : @selector(cryoPumpChanged:)
							 name : ORSerialPortWithQueueModelIsValidChanged
						   object : cryoPump];

		[notifyCenter addObserver : self
						 selector : @selector(cryoPumpChanged:)
							 name : ORCP8CryopumpModelSecondStageTempChanged
						   object : cryoPump];
		
	}
	
	ORRGA300Model* rga = [self findRGA];
	if(rga){
		[notifyCenter addObserver : self
						 selector : @selector(rgaChanged:)
							 name : ORRGA300ModelIonizerFilamentCurrentRBChanged
						   object : rga];
		
		[notifyCenter addObserver : self
						 selector : @selector(rgaChanged:)
							 name : ORSerialPortWithQueueModelIsValidChanged
						   object : rga];
	}
	
	[notifyCenter addObserver : self
                     selector : @selector(stateChanged:)
                         name : ORVacuumPartChanged
						object: self];
	
	[notifyCenter addObserver : self
                     selector : @selector(portClosedAfterTimeout:)
                         name : ORSerialPortWithQueueModelPortClosedAfterTimeout
						object: nil];
	
	
	
}

- (void) portClosedAfterTimeout:(NSNotification*)aNote
{
	if([aNote object] && [aNote object] == [self findCryoPump]){
		//the serial port was closed by ORCA after a timeout. Need to close the GateValve to the cryostat
		ORVacuumGateValve* gv = [self gateValve:3];
		if([gv isOpen]){
			[self closeGateValve:3];
			NSLog(@"ORCA closed the gatevalve between the cryopump and the cryostat because of a serial port timeout\n");
			if(!orcaClosedCryoPumpValveAlarm){
				NSString* alarmName = [NSString stringWithFormat:@"ORCA Closed %@",[gv label]];
				orcaClosedCryoPumpValveAlarm = [[ORAlarm alloc] initWithName:alarmName severity:kHardwareAlarm];
				[orcaClosedCryoPumpValveAlarm setHelpString:@"ORCA closed the valve because of a serial port timeout on the cryopump. Acknowledging this alarm will clear it."];
				[orcaClosedCryoPumpValveAlarm setSticky:NO];
			}
			[orcaClosedCryoPumpValveAlarm postAlarm];
		}
	}
}

- (void) baratronChanged:(NSNotification*)aNote
{
	ORMks660BModel* baratron = [aNote object];
	ORVacuumValueLabel* aRegionlabel = [self regionValueObj:kRegionBaratron];
	[aRegionlabel setValue:[baratron pressure]];
	[aRegionlabel setIsValid:[baratron isValid]];
}

- (void) turboChanged:(NSNotification*)aNote
{
	ORTM700Model* turboPump = [aNote object];
    ORVacuumStatusLabel* turboRegionObj = [statusDictionary objectForKey:[NSNumber numberWithInt:kRegionAboveTurbo]];
	[turboRegionObj setIsValid:[turboPump isValid]];
	[turboRegionObj setStatusLabel:[turboPump auxStatusString:0]];	

	[self checkTurboRelatedConstraints:turboPump];
}

- (void) pressureGaugeChanged:(NSNotification*)aNote
{
	ORTPG256AModel* pressureGauge = [aNote object];
	int chan = [[[aNote userInfo] objectForKey:@"Channel"]intValue];
	int componentTag = [pressureGauge tag];
	int aRegion;
	for(aRegion=0;aRegion<kNumberRegions;aRegion++){
		ORVacuumValueLabel*  aLabel = [self regionValueObj:aRegion]; 
		if([aLabel channel ] == chan && [aLabel component] == componentTag){
			[aLabel setIsValid:[pressureGauge isValid]]; 
			[aLabel setValue:[pressureGauge pressure:[aLabel channel]]]; 
		}
	}
	//special case... if the cryo roughing valve is open set the diaphram pump pressure to the cryopump region
	//other wise set it to 2 Torr
	ORVacuumGateValve* gv = [self gateValve:5];
	ORVacuumValueLabel* aRegionlabel = [self regionValueObj:kRegionDiaphramPump];
	if([gv isClosed]){
		[aRegionlabel setValue:2.0];
		[aRegionlabel setIsValid:YES];
	}
	[self checkPressureConstraints];
	[self checkDetectorConstraints];
}

- (void) cryoPumpChanged:(NSNotification*)aNote
{
	ORCP8CryopumpModel* cryopump = [aNote object];
	ORVacuumStatusLabel* cryoRegionObj = [statusDictionary objectForKey:[NSNumber numberWithInt:kRegionCryoPump]];
	[cryoRegionObj setIsValid:[cryopump isValid]];
	[cryoRegionObj setStatusLabel:[cryopump auxStatusString:0]];	
	[self checkCryoPumpRelatedConstraints:cryopump];
	[self checkPressureConstraints];
}

- (void) rgaChanged:(NSNotification*)aNote
{
	ORRGA300Model* rga = [aNote object];
	ORVacuumStatusLabel* rgaRegionObj = [statusDictionary objectForKey:[NSNumber numberWithInt:kRegionRGA]];
	[rgaRegionObj setIsValid:[rga isValid]];
	[rgaRegionObj setStatusLabel:[rga auxStatusString:0]];	
	[self checkRGARelatedConstraints:rga];
}

- (void) stateChanged:(NSNotification*)aNote
{
	[self  checkAllConstraints];
}

#pragma mark ***Accessors
- (BOOL) shouldUnbiasDetector	
{ 
	return [continuedBiasConstraints count] != 0;
}
- (BOOL) okToBiasDetector		
{
	return [okToBiasConstraints count] == 0;
}
- (BOOL) detectorsBiased		{ return detectorsBiased; }

- (void) setDetectorsBiased:(BOOL)aState
{
	if(detectorsBiased!=aState){
		detectorsBiased = aState;
		[self checkDetectorConstraints];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORMJDVacuumModelDetectorsBiasedChanged object:self];
	}
}

- (unsigned long) vetoMask
{
    return vetoMask;
}

- (void) setVetoMask:(unsigned long)aVetoMask
{
	if(vetoMask != aVetoMask){
		vetoMask = aVetoMask;
		NSArray* gateValves = [self gateValves];
		for(ORVacuumGateValve* aGateValve in gateValves){
			int tag = [aGateValve partTag];
			if(vetoMask & (0x1<<tag))aGateValve.vetoed = YES;
			else aGateValve.vetoed = NO;
		}
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORMJDVacuumModelVetoMaskChanged object:self];
	}
}

- (BOOL) showGrid
{
    return showGrid;
}

- (void) setShowGrid:(BOOL)aShowGrid
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShowGrid:showGrid];
    showGrid = aShowGrid;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDVacuumModelShowGridChanged object:self];
}

- (void) toggleGrid
{
	[self setShowGrid:!showGrid];
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
	[self setShowGrid:	[decoder decodeBoolForKey:	@"showGrid"]];
	
	[self makeParts];
	[self registerNotificationObservers];
	
	[[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:showGrid					forKey: @"showGrid"];
}

- (NSArray*) parts
{
	return parts;
}

- (NSArray*) gateValvesConnectedTo:(int)aRegion
{
	NSMutableArray* gateValves	= [NSMutableArray array];
	NSArray* allGateValves		= [self gateValves];
	for(id aGateValve in allGateValves){
		if([aGateValve connectingRegion1] == aRegion || [aGateValve connectingRegion2] == aRegion){
			if([aGateValve controlType] != kManualOnlyShowClosed && [aGateValve controlType] != kManualOnlyShowChanging){
				[gateValves addObject:aGateValve];
			}
		}
	}
	return gateValves;
}

- (int) stateOfGateValve:(int)aTag
{
	return [[self gateValve:aTag] state];
}

- (NSArray*) pipesForRegion:(int)aTag
{
	return [[partDictionary objectForKey:@"Regions"] objectForKey:[NSNumber numberWithInt:aTag]];
}

- (ORVacuumPipe*) onePipeFromRegion:(int)aTag
{
	NSArray* pipes = [[partDictionary objectForKey:@"Regions"] objectForKey:[NSNumber numberWithInt:aTag]];
	if([pipes count])return [pipes objectAtIndex:0];
	else return nil;
}

- (NSArray*) gateValves
{
	return [partDictionary objectForKey:@"GateValves"];
}

- (ORVacuumGateValve*) gateValve:(int)index
{
	NSArray* gateValues = [partDictionary objectForKey:@"GateValves"];
	if(index<[gateValues count]){
		return [[partDictionary objectForKey:@"GateValves"] objectAtIndex:index];
	}
	else return nil;
}

- (NSArray*) valueLabels
{
	return [partDictionary objectForKey:@"ValueLabels"];
}

- (NSArray*) statusLabels
{
	return [partDictionary objectForKey:@"StatusLabels"];
}

- (NSString*) valueLabel:(int)region
{
	NSArray* labels = [partDictionary objectForKey:@"ValueLabels"];
	for(ORVacuumValueLabel* theLabel in labels){
		if(theLabel.regionTag == region)return [theLabel displayString];
	}
	return @"No Value Available";
}

- (NSString*) statusLabel:(int)region
{
	NSArray* labels = [partDictionary objectForKey:@"StatusLabels"];
	for(ORVacuumStatusLabel* theLabel in labels){
		if(theLabel.regionTag == region)return [theLabel displayString];
	}
	return @"No Value Available";
}


- (NSArray*) staticLabels
{
	return [partDictionary objectForKey:@"StaticLabels"];
}

- (NSColor*) colorOfRegion:(int)aRegion
{
	return [[self onePipeFromRegion:aRegion] regionColor];
}

- (NSString*) namesOfRegionsWithColor:(NSColor*)aColor
{
	NSMutableString* theRegions = [NSMutableString string];
	int i;
	for(i=0;i<8;i++){
		if([aColor isEqual:[self colorOfRegion:i]]){
			[theRegions appendFormat:@"%@%@,",i!=0?@" ":@"",[self regionName:i]];
		}
	}
	
	if([theRegions hasSuffix:@","]) return [theRegions substringToIndex:[theRegions length]-1];
	else return theRegions;
}

#pragma mark ***AdcProcessor Protocol
- (void) processIsStarting
{
	[self setVetoMask:0xffffffff];
	involvedInProcess = YES;
}

- (void) processIsStopping
{
	[self setVetoMask:0xffffffff];
	involvedInProcess = NO;
}

- (void) startProcessCycle
{
}

- (void) endProcessCycle
{
}

- (double) setProcessAdc:(int)channel value:(double)aValue isLow:(BOOL*)isLow isHigh:(BOOL*)isHigh
{
	return 0.0;
}

- (BOOL) setProcessBit:(int)channel value:(int)value
{
	ORVacuumGateValve* gv = [self gateValve:(int)channel];
	if([gv controlType] == k1BitReadBack){
		if(value==1)[gv setState:kGVClosed];
		else		[gv setState:kGVOpen];
	}
	else {
		if(value==3)		[gv setState:kGVChanging];
		else if(value==1)	[gv setState:kGVOpen];
		else if(value==2)	[gv setState:kGVClosed];
		else                [gv setState:kGVImpossible];
	}
	
	//special case... if the cryo roughing valve is open set the diaphram pump pressure to the cryopump region
	//other wise set it to 1 Torr
	if(channel == 5){
		ORVacuumValueLabel* aRegionlabel = [self regionValueObj:kRegionDiaphramPump];
		if([gv isOpen]) [aRegionlabel setValue:[self valueForRegion:kRegionCryoPump]];
		else		    [aRegionlabel setValue:2.0];
		[aRegionlabel setIsValid:[aRegionlabel isValid]];
	}

	return value;
}

- (NSString*) processingTitle
{
	return [NSString stringWithFormat:@"MJD Vac,%lu",[self uniqueIdNumber]];
}

- (void) mapChannel:(int)aChannel toHWObject:(NSString*)objIdentifier hwChannel:(int)hwChannel;
{
	ORVacuumGateValve* aGateValve = [self gateValve:aChannel];
	aGateValve.controlObj		  = objIdentifier;
	aGateValve.controlChannel	  = hwChannel;
}

- (void) unMapChannel:(int)aChannel fromHWObject:(NSString*)objIdentifier hwChannel:(int)aHWChannel;
{
	ORVacuumGateValve* aGateValve = [self gateValve:aChannel];
	aGateValve.controlObj		  = nil;
}

- (void) vetoChangesOnChannel:(int)aChannel state:(BOOL)aState
{
	if(aChannel>=0 && aChannel<32){
		unsigned long newMask = vetoMask;
		if(aState) newMask |= (0x1<<aChannel);
		else newMask &= ~(0x1<<aChannel);
		if(newMask != vetoMask)[self setVetoMask:newMask];
	}
}

#pragma mark •••CardHolding Protocol
- (int) maxNumberOfObjects	{ return 5; }	//default
- (int) objWidth			{ return 80; }	//default
- (int) groupSeparation		{ return 0; }	//default
- (NSString*) nameForSlot:(int)aSlot	
{ 
    return [NSString stringWithFormat:@"Slot %d",aSlot]; 
}

- (NSRange) legalSlotsForObj:(id)anObj
{
	if([anObj isKindOfClass:NSClassFromString(@"ORTM700Model")])			return NSMakeRange(0,1);
	else if([anObj isKindOfClass:NSClassFromString(@"ORRGA300Model")])		return NSMakeRange(1,1);
	else if([anObj isKindOfClass:NSClassFromString(@"ORCP8CryopumpModel")]) return NSMakeRange(2,1);
	else if([anObj isKindOfClass:NSClassFromString(@"ORTPG256AModel")])		return NSMakeRange(3,1);
	else if([anObj isKindOfClass:NSClassFromString(@"ORMks660BModel")])		return NSMakeRange(4,1);
		else return NSMakeRange(0,0);
}

- (BOOL) slot:(int)aSlot excludedFor:(id)anObj 
{ 
	if(aSlot == 0      && [anObj isKindOfClass:NSClassFromString(@"ORTM700Model")])		  return NO;
	else if(aSlot == 1 && [anObj isKindOfClass:NSClassFromString(@"ORRGA300Model")])	  return NO;
	else if(aSlot == 2 && [anObj isKindOfClass:NSClassFromString(@"ORCP8CryopumpModel")]) return NO;
	else if(aSlot == 3 && [anObj isKindOfClass:NSClassFromString(@"ORTPG256AModel")])	  return NO;
	else if(aSlot == 4 && [anObj isKindOfClass:NSClassFromString(@"ORMks660BModel")])     return NO;
    else return YES;
}

- (int) slotAtPoint:(NSPoint)aPoint 
{
	return floor(((int)aPoint.y)/[self objWidth]);
}

- (NSPoint) pointForSlot:(int)aSlot 
{
	return NSMakePoint(0,aSlot*[self objWidth]);
}

- (void) place:(id)anObj intoSlot:(int)aSlot
{
    [anObj setTag:aSlot];
	NSPoint slotPoint = [self pointForSlot:aSlot];
	[anObj moveTo:slotPoint];
}

- (int) slotForObj:(id)anObj
{
    return [anObj tag];
}

- (int) numberSlotsNeededFor:(id)anObj
{
	return 1;
}

- (void) openDialogForComponent:(int)i
{
	for(OrcaObject* anObj in [self orcaObjects]){
		if([anObj tag] == i){
			[anObj makeMainController];
			break;
		}
	}
}

- (NSString*) regionName:(int)i
{
	switch(i){
		case kRegionAboveTurbo:		return @"Above Turbo";
		case kRegionRGA:			return @"RGA";
		case kRegionCryostat:		return @"Cryostat";
		case kRegionCryoPump:		return @"CryoPump";
		case kRegionBaratron:		return @"Baratron";
		case kRegionDryN2:			return @"Dry N2";
		case kRegionNegPump:		return @"Neg Pump";
		case kRegionDiaphramPump:	return @"Diaphram Pump";
		case kRegionBelowTurbo:		return @"Below Turbo";
		default: return nil;
	}
}

#pragma mark •••Constraints
- (void) addOkToBiasConstraints:(NSString*)aName reason:(NSString*)aReason
{
	if(!okToBiasConstraints)okToBiasConstraints = [[NSMutableDictionary dictionary] retain];
	[okToBiasConstraints setObject:aReason forKey:aName];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMJDVacuumModelConstraintsChanged object:self];
	
}

- (void) removeOkToBiasConstraints:(NSString*)aName
{
	[okToBiasConstraints removeObjectForKey:aName];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMJDVacuumModelConstraintsChanged object:self];
}

- (void) addContinuedBiasConstraints:(NSString*)aName reason:(NSString*)aReason
{
	if(!continuedBiasConstraints)continuedBiasConstraints = [[NSMutableDictionary dictionary] retain];
	[continuedBiasConstraints setObject:aReason forKey:aName];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMJDVacuumModelConstraintsChanged object:self];
}

- (void) removeContinuedBiasConstraints:(NSString*)aName
{
	[continuedBiasConstraints removeObjectForKey:aName];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMJDVacuumModelConstraintsChanged object:self];
}

- (NSDictionary*) okToBiasConstraints
{
	return okToBiasConstraints;
}

- (NSDictionary*) continuedBiasConstraints
{
	return continuedBiasConstraints;
}


@end


@implementation ORMJDVacuumModel (private)
- (ORMks660BModel*)     findBaratron		{ return [self findObject:@"ORMks660BModel"];     }
- (ORRGA300Model*)      findRGA				{ return [self findObject:@"ORRGA300Model"];      }
- (ORTM700Model*)       findTurboPump		{ return [self findObject:@"ORTM700Model"];       }
- (ORTPG256AModel*)     findPressureGauge   { return [self findObject:@"ORTPG256AModel"];     }
- (ORCP8CryopumpModel*) findCryoPump		{ return [self findObject:@"ORCP8CryopumpModel"]; }

- (id) findObject:(NSString*)aClassName
{
	for(OrcaObject* anObj in [self orcaObjects]){
		if([anObj isKindOfClass:NSClassFromString(aClassName)])return anObj;
	}
	return nil;
}


- (void) makeParts
{
#define kNumVacPipes		59
	VacuumPipeStruct vacPipeList[kNumVacPipes] = {
		//region 0 pipes
		{ kVacVPipe,  kRegionAboveTurbo, 50,			 260,				50,					450 }, 
		{ kVacHPipe,  kRegionAboveTurbo, 50+kPipeRadius, 400,				180+kPipeRadius,	400 },
		{ kVacVPipe,  kRegionAboveTurbo, 150,			 400-kPipeRadius,	150,				300 },
		
		//region 1 pipes
		{ kVacCorner, kRegionRGA,		500,			  200,				kNA,				kNA },
		{ kVacVPipe,  kRegionRGA,		500,			  200+kPipeRadius,	 500,				250 },
		{ kVacHPipe,  kRegionRGA,		180,			  400,				350,				400 },
		{ kVacHPipe,  kRegionRGA,		200,			  200,				500-kPipeRadius,	200 },
		{ kVacVPipe,  kRegionRGA,		280,			  200+kPipeRadius,	280,				400-kPipeRadius },
		{ kVacVPipe,  kRegionRGA,		280,			  400+kPipeRadius,	280,				420 },
		{ kVacVPipe,  kRegionRGA,		230,			  400+kPipeRadius,	230,				450 },
		{ kVacHPipe,  kRegionRGA,		230,			  350,				280-kPipeRadius,	350 },
		
		//region 2 pipes (cyrostat)
		{ kVacBox,	   kRegionCryostat, 475,			  500,				525,				550 },
		{ kVacBox,	   kRegionCryostat, 600,			  435,				700,				550 },
		{ kVacBigHPipe, kRegionCryostat,525,			  525,		        600,				525 },
		{ kVacCorner,  kRegionCryostat, 700,			  400,				kNA,				kNA },
		{ kVacVPipe,   kRegionCryostat, 700,			   70,				700,				400-kPipeRadius },
		{ kVacHPipe,   kRegionCryostat, 350,			  400,				700-kPipeRadius,	400 },
		{ kVacVPipe,   kRegionCryostat, 600,			  350,				600,				400-kPipeRadius },
		{ kVacVPipe,   kRegionCryostat, 500,			  350,				500,				400-kPipeRadius },
		{ kVacCorner,  kRegionCryostat, 400,			  300,				kNA,				kNA },
		{ kVacVPipe,   kRegionCryostat, 400,			  300+kPipeRadius,	400,				400-kPipeRadius },
		{ kVacHPipe,   kRegionCryostat, 350,			  300,				400-kPipeRadius,	300 },
		{ kVacHPipe,   kRegionCryostat, 350,			  350,				400-kPipeRadius,	350 },
		{ kVacVPipe,   kRegionCryostat, 400,			  400+kPipeRadius,	400,				450 },
		{ kVacVPipe,   kRegionCryostat, 500,			  400+kPipeRadius,	500,				500 },
		//region 3 pipes
		{ kVacVPipe,  kRegionCryoPump,	600,			  230,				600,				350 },
		{ kVacHPipe,  kRegionCryoPump,	600+kPipeRadius, 300,				620,				300 },
		{ kVacVPipe,  kRegionCryoPump,	580,			  70,				580,				200 },
		{ kVacHPipe,  kRegionCryoPump,	530,			  150,				580-kPipeRadius,	150 },
		{ kVacCorner, kRegionCryoPump,	620,			  150,				kNA,				kNA },
		{ kVacVPipe,  kRegionCryoPump,	620,			  150+kPipeRadius,	620,				200 },
		{ kVacHPipe,  kRegionCryoPump,	620+kPipeRadius, 150,				640,				150 },
		//region 4 pipes
		{ kVacBox,	  kRegionBaratron,  470,			  570,				530,				620 },
		{ kVacBox,	  kRegionBaratron,  270,			  570,				330,				620 },
		{ kVacCorner, kRegionBaratron,  500,			  525,				kNA,				kNA },
		{ kVacCorner, kRegionBaratron,  680,			  525,				kNA,				kNA },
		{ kVacHPipe,  kRegionBaratron,  500+kPipeRadius,  525,				680-kPipeRadius,	525 },
		{ kVacVPipe,  kRegionBaratron,  500,			  525+kPipeRadius,	500,				570 },
		{ kVacHPipe,  kRegionBaratron,  330,			  600,				400,				600 },
		{ kVacHPipe,  kRegionBaratron,  400,			  600,				470,				600 },
		{ kVacVPipe,  kRegionBaratron,  360,			  550,				360,				600-kPipeRadius },
		//region 5 pipes
		{ kVacCorner, kRegionDryN2,		150,			  30,				kNA,				kNA },
		{ kVacCorner, kRegionDryN2,		700,			  30,				kNA,				kNA },
		{ kVacVPipe,  kRegionDryN2,		150,			  30+kPipeRadius,	150,				300 },
		{ kVacHPipe,  kRegionDryN2,		150+kPipeRadius, 30,				700-kPipeRadius,	30 },
		{ kVacHPipe,  kRegionDryN2,		150+kPipeRadius, 200,				200,				200 },
		{ kVacVPipe,  kRegionDryN2,		700,			  30+kPipeRadius,	700,				70 },
		{ kVacVPipe,  kRegionDryN2,		580,			  30+kPipeRadius,	580,				70 },
		{ kVacCorner, kRegionDryN2,		330,			  80,				kNA,				kNA },
		{ kVacVPipe,  kRegionDryN2,		330,			  30+kPipeRadius,	330,				80-kPipeRadius },
		{ kVacHPipe,  kRegionDryN2,		310,			  80,				330-kPipeRadius,	80 },
		{ kVacHPipe,  kRegionDryN2,		280,			  80,				310,				80 },
		{ kVacVPipe,  kRegionDryN2,		400,			  30+kPipeRadius,	400,				50 },

		//region 6 pipes
		{ kVacVPipe,  kRegionNegPump,	500,			  250,				500,				350 },
		{ kVacHPipe,  kRegionNegPump,	460,			  300,				500-kPipeRadius,	300 },
		//region 7 pipes
		{ kVacVPipe,  kRegionDiaphramPump, 50,			  100,				50,					200 }, 
		{ kVacHPipe,  kRegionDiaphramPump, 50+kPipeRadius,150,				530,				150 },
		{ kVacVPipe,  kRegionDiaphramPump, 400,			  130,				400,				150-kPipeRadius }, 
		//region 8 pipes
		{ kVacVPipe,  kRegionBelowTurbo, 50,			  200,				50,					260 }, 
		
	};
	
#define kNumStaticLabelItems	3
	VacuumStaticLabelStruct staticLabelItems[kNumStaticLabelItems] = {
		{kVacStaticLabel, kRegionDryN2,			@"Dry N2\nSupply",	200,  60,	280, 100},
		{kVacStaticLabel, kRegionNegPump,		@"NEG Pump",		420, 285,	480, 315},
		{kVacStaticLabel, kRegionDiaphramPump,	@"Diaphragm\nPump",	 20,  80,	 80, 110},
	};	
	
#define kNumStatusItems	10
	VacuumDynamicLabelStruct dynamicLabelItems[kNumStatusItems] = {
		//type,	region, component, channel
		{kVacStatusItem,   kRegionAboveTurbo,	0, 5,  @"Turbo",	20,	 242,	80,	 268},
		{kVacStatusItem,   kRegionRGA,			1, 6,  @"RGA",		260, 417,	300, 443},
		{kVacStatusItem,   kRegionCryoPump,		2, 7,  @"Cryo Pump",560, 200,	640, 230},
		{kVacPressureItem, kRegionAboveTurbo,	3, 0,  @"PKR G1",	20,	 450,	80,	 480},
		{kVacPressureItem, kRegionRGA,			3, 1,  @"PKR G2",	200, 450,	260, 480},
		{kVacPressureItem, kRegionCryostat,		3, 2,  @"PKR G3",	370, 450,	430, 480},
		{kVacPressureItem, kRegionCryoPump,		3, 3,  @"PKR G4",	620, 285,	680, 315},
		{kVacPressureItem, kRegionBaratron,		4, 0,  @"Baratron",	330, 520,	390, 550},
		{kVacPressureItem, kRegionDiaphramPump,	3, 3,  @"Assumed",	370, 100,	430, 130},
		{kVacPressureItem, kRegionDryN2,		99, 99,@"Assumed",	370, 50,	430, 80},
	};	
	
#define kNumVacLines 11 
	VacuumLineStruct vacLines[kNumVacLines] = {
		{kVacLine, 180,400,180,420},  //V1
		{kVacLine, 350,400,350,420},  //V2
		{kVacLine, 600,350,620,350},  //V3
		{kVacLine, 480,350,500,350},  //V4
		{kVacLine, 480,250,500,250},  //V5
		{kVacLine, 530,130,530,140},  //V6
		
		{kVacLine, 200,200,200,220},  //B1
		{kVacLine, 150,300,170,300},  //B2
		{kVacLine, 560,70,580,70},    //B3
		{kVacLine, 680,70,700,70},    //B4
		{kVacLine, 60,200,70,200},    //B5
	};
	
#define kNumVacGVs			18
	VacuumGVStruct gvList[kNumVacGVs] = {
		{kVacVGateV, 0,		@"V1",			k2BitReadBack,				180, 400,	kRegionAboveTurbo,	kRegionRGA,				kControlAbove},	//V1. Control + read back
		{kVacVGateV, 1,		@"V2",			k2BitReadBack,				350, 400,	kRegionRGA,			kRegionCryostat,		kControlAbove},	//V2. Control + read back
		{kVacHGateV, 2,		@"V3",			k2BitReadBack,				500, 350,	kRegionCryostat,	kRegionNegPump,			kControlLeft},	//V4. Control + read back
		{kVacHGateV, 3,		@"V4",			k2BitReadBack,				600, 350,	kRegionCryostat,	kRegionCryoPump,		kControlRight},	//V3. Control + read back
		{kVacHGateV, 4,		@"V5",			k2BitReadBack,				500, 250,	kRegionRGA,			kRegionNegPump,			kControlLeft},	//V5. Control + read back
		{kVacVGateV, 5,		@"Roughing",	k1BitReadBack,				530, 150,	kRegionDiaphramPump,kRegionCryoPump,		kControlBelow},   //V6. Control + read back
		
		{kVacVGateV, 6,		@"B1",			k1BitReadBack,				200, 200,	kRegionRGA,			kRegionDryN2,			kControlAbove},	//Control only
		{kVacHGateV, 7,		@"B2",			k1BitReadBack,				150, 300,	kRegionAboveTurbo,	kRegionDryN2,			kControlRight},	//Control only
		{kVacHGateV, 8,		@"Purge",		k1BitReadBack,				580, 70,	kRegionCryoPump,	kRegionDryN2,			kControlLeft},	//Control only 
		{kVacHGateV, 9,		@"B4",			k1BitReadBack,				700, 70,	kRegionCryostat,	kRegionDryN2,			kControlLeft},	//Control only 
		
		{kVacVGateV, 10,	@"Burst",		kManualOnlyShowClosed,		350, 300,	kRegionCryostat,	kUpToAir,				kControlNone},	//burst
		{kVacVGateV, 11,	@"N2 Manual",	kManualOnlyShowChanging,	310, 80,	kRegionDryN2,		kUpToAir,				kControlNone},	//Manual N2 supply
		{kVacVGateV, 12,	@"PRV",			kManualOnlyShowClosed,		640, 150,	kRegionCryoPump,	kUpToAir,				kControlNone},	//PRV
		{kVacVGateV, 13,	@"PRV",			kManualOnlyShowClosed,		350, 350,	kRegionCryostat,	kUpToAir,				kControlNone},	//PRV
		{kVacVGateV, 14,	@"C1",			kManualOnlyShowChanging,	400, 600,	kRegionBaratron,	kRegionBaratron,		kControlNone},	//Manual only
		{kVacHGateV, 15,	@"B5",			k1BitReadBack,				50, 200,	kRegionDiaphramPump,kRegionBelowTurbo,		kControlRight},	//future control
		{kVacHGateV, 16,	@"Turbo",		k1BitReadBack,				50, 260,	kRegionAboveTurbo,	kRegionBelowTurbo,		kControlNone},	//this is a virtual valve-- really the turbo on/off
		{kVacVGateV, 17,	@"PRV",			kManualOnlyShowClosed,		230, 350,	kRegionRGA,			kUpToAir,				kControlNone},	//PRV
	};
	
	[self makeLines:vacLines					num:kNumVacLines];
	[self makePipes:vacPipeList					num:kNumVacPipes];
	[self makeGateValves:gvList					num:kNumVacGVs];
	[self makeStaticLabels:staticLabelItems		num:kNumStaticLabelItems];
	[self makeDynamicLabels:dynamicLabelItems	num:kNumStatusItems];
}

- (void) makePipes:( VacuumPipeStruct*)pipeList num:(int)numItems
{
	int i;
	for(i=0;i<numItems;i++){
		ORVacuumPipe* aPipe = nil;
		switch(pipeList[i].type){
			case kVacCorner:
				aPipe = [[[ORVacuumCPipe alloc] initWithDelegate:self regionTag:pipeList[i].regionTag at:NSMakePoint(pipeList[i].x1, pipeList[i].y1)] autorelease];
				break;
				
			case kVacVPipe:
				aPipe = [[[ORVacuumVPipe alloc] initWithDelegate:self regionTag:pipeList[i].regionTag startPt:NSMakePoint(pipeList[i].x1, pipeList[i].y1) endPt:NSMakePoint(pipeList[i].x2, pipeList[i].y2)] autorelease];
				break;
				
			case kVacHPipe:
				aPipe = [[[ORVacuumHPipe alloc] initWithDelegate:self regionTag:pipeList[i].regionTag startPt:NSMakePoint(pipeList[i].x1, pipeList[i].y1) endPt:NSMakePoint(pipeList[i].x2, pipeList[i].y2)] autorelease];
				break;
				
			case kVacBigHPipe:
				aPipe = [[[ORVacuumBigHPipe alloc] initWithDelegate:self regionTag:pipeList[i].regionTag startPt:NSMakePoint(pipeList[i].x1, pipeList[i].y1) endPt:NSMakePoint(pipeList[i].x2, pipeList[i].y2)] autorelease];
				break;
				
			case kVacBox:
				aPipe = [[[ORVacuumBox alloc] initWithDelegate:self regionTag:pipeList[i].regionTag bounds:NSMakeRect(pipeList[i].x1, pipeList[i].y1,pipeList[i].x2-pipeList[i].x1,pipeList[i].y2-pipeList[i].y1)] autorelease];
				break;
		}
	}
}

- (void) makeGateValves:( VacuumGVStruct*)gvList num:(int)numItems
{
	int i;
	for(i=0;i<numItems;i++){
		ORVacuumGateValve* gv= nil;
		switch(gvList[i].type){
			case kVacVGateV:
				gv = [[[ORVacuumVGateValve alloc] initWithDelegate:self partTag:gvList[i].partTag  label:gvList[i].label controlType:gvList[i].controlType at:NSMakePoint(gvList[i].x1, gvList[i].y1) connectingRegion1:gvList[i].r1 connectingRegion2:gvList[i].r2] autorelease];
				break;
				
			case kVacHGateV:
				gv = [[[ORVacuumHGateValve alloc] initWithDelegate:self partTag:gvList[i].partTag label:gvList[i].label controlType:gvList[i].controlType at:NSMakePoint(gvList[i].x1, gvList[i].y1) connectingRegion1:gvList[i].r1 connectingRegion2:gvList[i].r2] autorelease];
				break;
		}
		if(gv){
			gv.controlPreference = gvList[i].conPref;
		}
	}
}

- (void) makeStaticLabels:(VacuumStaticLabelStruct*)labelItems num:(int)numItems
{
	int i;
	for(i=0;i<numItems;i++){
		NSRect theBounds = NSMakeRect(labelItems[i].x1,labelItems[i].y1,labelItems[i].x2-labelItems[i].x1,labelItems[i].y2-labelItems[i].y1);
		ORVacuumStaticLabel* aLabel = [[ORVacuumStaticLabel alloc] initWithDelegate:self regionTag:labelItems[i].regionTag label:labelItems[i].label bounds:theBounds];
		[aLabel release];
	}
}

- (void)  makeDynamicLabels:(VacuumDynamicLabelStruct*)labelItems num:(int)numItems
{
	int i;
	for(i=0;i<numItems;i++){
		NSRect theBounds = NSMakeRect(labelItems[i].x1,labelItems[i].y1,labelItems[i].x2-labelItems[i].x1,labelItems[i].y2-labelItems[i].y1);
		if(labelItems[i].type == kVacPressureItem){
			[[[ORVacuumValueLabel alloc] initWithDelegate:self regionTag:labelItems[i].regionTag component:labelItems[i].component channel:labelItems[i].channel label:labelItems[i].label bounds:theBounds] autorelease];			
		}
		if(labelItems[i].type == kVacStatusItem){
			[[[ORVacuumStatusLabel alloc] initWithDelegate:self regionTag:labelItems[i].regionTag component:labelItems[i].component channel:labelItems[i].channel label:labelItems[i].label bounds:theBounds] autorelease];
		}
	}
	ORVacuumValueLabel* aLabel = [self regionValueObj:kRegionDryN2];
	[aLabel setIsValid:YES];
	[aLabel setValue:1.0E3];
}

- (void) makeLines:( VacuumLineStruct*)lineItems num:(int)numItems
{
	int i;
	for(i=0;i<numItems;i++){
		[[[ORVacuumLine alloc] initWithDelegate:self startPt:NSMakePoint(lineItems[i].x1, lineItems[i].y1) endPt:NSMakePoint(lineItems[i].x2, lineItems[i].y2)] autorelease];
	}
}

- (void) colorRegions
{
	#define kNumberPriorityRegions 9
	int regionPriority[kNumberPriorityRegions] = {4,6,1,0,3,8,7,2,5}; //lowest to highest
					
	NSColor* regionColor[kNumberPriorityRegions] = {
		[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.7 alpha:1.0], //Region 0 Above Turbo
		[NSColor colorWithCalibratedRed:1.0 green:0.7 blue:1.0 alpha:1.0], //Region 1 RGA
		[NSColor colorWithCalibratedRed:0.8 green:0.8 blue:1.0 alpha:1.0], //Region 2 Cryostat
		[NSColor colorWithCalibratedRed:0.7 green:1.0 blue:0.7 alpha:1.0], //Region 3 Cryo pump
		[NSColor colorWithCalibratedRed:0.6 green:0.6 blue:1.0 alpha:1.0], //Region 4 Thermosyphon
		[NSColor colorWithCalibratedRed:1.0 green:0.5 blue:0.5 alpha:1.0], //Region 5 N2
		[NSColor colorWithCalibratedRed:0.8 green:0.8 blue:0.4 alpha:1.0], //Region 6 NEG Pump
		[NSColor colorWithCalibratedRed:0.4 green:0.6 blue:0.7 alpha:1.0], //Region 7 Diaphragm pump
		[NSColor colorWithCalibratedRed:0.5 green:0.9 blue:0.3 alpha:1.0], //Region 8 Below Turbo
	};
	int i;
	for(i=0;i<kNumberPriorityRegions;i++){
		int region = regionPriority[i];
		[self colorRegionsConnectedTo:region withColor:regionColor[region]];
	}
	
	NSArray* staticLabels = [self staticLabels];
	for(ORVacuumStaticLabel* aLabel in staticLabels){
		int region = [aLabel regionTag];
		if(region<kNumberPriorityRegions){
			[aLabel setControlColor:regionColor[region]];
		}
	}
	
	NSArray* statusLabels = [self statusLabels];
	for(ORVacuumStatusLabel* aLabel in statusLabels){
		int regionTag = [aLabel regionTag];
		if(regionTag<kNumberPriorityRegions){
			[aLabel setControlColor:regionColor[regionTag]];
		}
	}
}

- (void) colorRegionsConnectedTo:(int)aRegion withColor:(NSColor*)aColor
{
	[self resetVisitationFlag];
	[self recursizelyColorRegionsConnectedTo:aRegion withColor:aColor];
}

- (void) recursizelyColorRegionsConnectedTo:(int)aRegion withColor:(NSColor*)aColor
{
	//this routine is called recursively, so do not reset the visitation flag in this routine.
	NSArray* pipes = [self pipesForRegion:aRegion];
	for(id aPipe in pipes){
		if([aPipe visited])return;
		[aPipe setRegionColor:aColor];
		[aPipe setVisited:YES];
	}
	NSArray* gateValves = [self gateValvesConnectedTo:(int)aRegion];
	for(id aGateValve in gateValves){
		if([aGateValve isOpen]){
			int r1 = [aGateValve connectingRegion1];
			int r2 = [aGateValve connectingRegion2];
			if(r1!=aRegion){
				[self recursizelyColorRegionsConnectedTo:r1 withColor:aColor];
			}
			if(r2!=aRegion){
				[self recursizelyColorRegionsConnectedTo:r2 withColor:aColor];
			}
		}
	}
}

- (void) resetVisitationFlag
{
	for(id aPart in parts)[aPart setVisited:NO];
}

- (void) addPart:(id)aPart
{
	if(!aPart)return;
	
	//the parts array contains all parts
	if(!parts)parts = [[NSMutableArray array] retain];
	[parts addObject:aPart];
	
	//we keep a separate dicionary of various categories of parts for convenience
	if(!partDictionary){
		partDictionary = [[NSMutableDictionary dictionary] retain];
		[partDictionary setObject:[NSMutableDictionary dictionary] forKey:@"Regions"];
		[partDictionary setObject:[NSMutableArray array] forKey:@"GateValves"];		
		[partDictionary setObject:[NSMutableArray array] forKey:@"ValueLabels"];		
		[partDictionary setObject:[NSMutableArray array] forKey:@"StatusLabels"];		
		[partDictionary setObject:[NSMutableArray array] forKey:@"StaticLabels"];		
	}
	if(!valueDictionary){
		valueDictionary = [[NSMutableDictionary dictionary] retain];
	}
	if(!statusDictionary){
		statusDictionary = [[NSMutableDictionary dictionary] retain];
	}
	
	NSNumber* thePartKey = [NSNumber numberWithInt:[aPart regionTag]];
	if([aPart isKindOfClass:NSClassFromString(@"ORVacuumPipe")]){
		NSMutableArray* aRegionArray = [[partDictionary objectForKey:@"Regions"] objectForKey:thePartKey];
		if(!aRegionArray)aRegionArray = [NSMutableArray array];
		[aRegionArray addObject:aPart];
		[[partDictionary objectForKey:@"Regions"] setObject:aRegionArray forKey:thePartKey];
	}
	else if([aPart isKindOfClass:NSClassFromString(@"ORVacuumGateValve")]){
		[[partDictionary objectForKey:@"GateValves"] addObject:aPart];
	}
	else if([aPart isKindOfClass:NSClassFromString(@"ORVacuumValueLabel")]){
		[[partDictionary objectForKey:@"ValueLabels"] addObject:aPart];
		[valueDictionary setObject:aPart forKey:[NSNumber numberWithInt:[aPart regionTag]]];
	}
	else if([aPart isKindOfClass:NSClassFromString(@"ORVacuumStatusLabel")]){
		[[partDictionary objectForKey:@"StatusLabels"] addObject:aPart];
		[statusDictionary setObject:aPart forKey:[NSNumber numberWithInt:[aPart regionTag]]];
	}
	else if([aPart isKindOfClass:NSClassFromString(@"ORVacuumStaticLabel")]){
		[[partDictionary objectForKey:@"StaticLabels"] addObject:aPart];
	}
}

- (void) closeGateValve:(int)aGateValveTag
{
	if((vetoMask & (0x1<<aGateValveTag)) == 0 ){
		ORVacuumGateValve* aGateValve = [self gateValve:aGateValveTag];
		id aController = [self findGateValveControlObj:aGateValve];
		[aController setOutputBit:aGateValve.controlChannel value:0];
		[aGateValve setCommandedState:kGVCommandClosed];
	}
}

- (void) openGateValve:(int)aGateValveTag
{
	if((vetoMask & (0x1<<aGateValveTag)) == 0 ){
		ORVacuumGateValve* aGateValve = [self gateValve:aGateValveTag];
		id aController = [self findGateValveControlObj:aGateValve];
		[aController setOutputBit:aGateValve.controlChannel value:1];
		[aGateValve setCommandedState:kGVCommandOpen];
	}
}

- (id) findGateValveControlObj:(ORVacuumGateValve*)aGateValve
{
	NSArray* objs = [[self document] collectObjectsConformingTo:@protocol(ORBitProcessing)];
	NSString* objLabel	= aGateValve.controlObj;
	
	for(id anObj in objs){
		if([[anObj processingTitle] isEqualToString:objLabel]){
			return anObj;
		}
	}
	return nil;
}

- (BOOL) region:(int)aRegion valueHigherThan:(double)aValue
{
	if(aRegion == kRegionNegPump){
		if([[self gateValve:2] isOpen])		 return [[self regionValueObj:kRegionCryostat] valueHigherThan:aValue];
		else if([[self gateValve:4] isOpen]) return [[self regionValueObj:kRegionRGA] valueHigherThan:aValue];
		else return 0.0;
	}
	else return [[self regionValueObj:aRegion] valueHigherThan:aValue];
}

- (BOOL) valueValidForRegion:(int)aRegion
{
	if(aRegion == kRegionNegPump)return YES;
	else return [[self regionValueObj:aRegion] isValid];
}

- (double) valueForRegion:(int)aRegion
{	
	if(aRegion == kRegionNegPump){
		if([[self gateValve:2] isOpen])		 return [self valueForRegion:kRegionCryostat];
		else if([[self gateValve:4] isOpen]) return [self valueForRegion:kRegionRGA];
		else return 0.0;
	}
	else return [[self regionValueObj:aRegion] value];
}

- (ORVacuumValueLabel*) regionValueObj:(int)aRegion
{
	return [valueDictionary objectForKey:[NSNumber numberWithInt:aRegion]];
}
- (id) component:(int)aComponentTag
{
	for(OrcaObject* anObj in [self orcaObjects]){
		if([anObj tag] == aComponentTag)return anObj;
	}
	return nil;
}

- (BOOL) regionColor:(int)r1 sameAsRegion:(int)r2
{
	NSColor* c1	= [self colorOfRegion:r1];
	NSColor* c2	= [self colorOfRegion:r2];
	return [c1 isEqual:c2];
}
			 
- (void) onAllGateValvesremoveConstraintName:(NSString*)aConstraintName
{
	for(ORVacuumGateValve* aGateValve in [self gateValves]){
		[self removeConstraintName:aConstraintName fromGateValve:aGateValve];
	}
}

- (void)  checkAllConstraints
{
	if(!constraintCheckScheduled){
		constraintCheckScheduled = YES;
		[self performSelector:@selector(deferredConstraintCheck) withObject:nil afterDelay:.5];
	}
}
- (void) deferredConstraintCheck
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(deferredConstraintCheck) object:nil];
	[self checkTurboRelatedConstraints:[self findTurboPump]];
	[self checkRGARelatedConstraints:  [self findRGA]];
	[self checkCryoPumpRelatedConstraints:[self findCryoPump]];
	[self checkPressureConstraints];
	[self checkDetectorConstraints];
	constraintCheckScheduled = NO;
}

- (void) checkTurboRelatedConstraints:(ORTM700Model*) turbo
{
	BOOL turboIsOn;
	if(![turbo isValid]) turboIsOn = YES;
	else turboIsOn = [turbo stationPower];
	//
	if(turboIsOn){
		for(ORVacuumGateValve* aGateValve in [self gateValves]){
			//---------------------------------------------------------------------------
			//Opening valve will expose turbo pump to potentially damaging pressures.
			if([aGateValve isClosed]){
				int side1				= [aGateValve connectingRegion1];
				int side2				= [aGateValve connectingRegion2];
				BOOL side1High			= [self region:side1 valueHigherThan:1.0E-1];
				BOOL side2High			= [self region:side2 valueHigherThan:1.0E-1];
				
				if([self regionColor:side1 sameAsRegion:side2]){
					[self removeConstraintName:kTurboOnPressureConstraint fromGateValve:aGateValve];
				}
				else if([self regionColor:side1 sameAsRegion:kRegionAboveTurbo] && side2High ){
					[self addConstraintName:kTurboOnPressureConstraint reason:kTurboOnPressureConstraintReason toGateValve:aGateValve];
				}
				else if([self regionColor:side1 sameAsRegion:kRegionBelowTurbo] && side2High){
					[self addConstraintName:kTurboOnPressureConstraint reason:kTurboOnPressureConstraintReason toGateValve:aGateValve];
				}
				else if([self regionColor:side2 sameAsRegion:kRegionAboveTurbo] && side1High){
					[self addConstraintName:kTurboOnPressureConstraint reason:kTurboOnPressureConstraintReason toGateValve:aGateValve];
				}
				else if([self regionColor:side2 sameAsRegion:kRegionBelowTurbo] && side1High){
					[self addConstraintName:kTurboOnPressureConstraint reason:kTurboOnPressureConstraintReason toGateValve:aGateValve];
				}
				else [self removeConstraintName:kTurboOnPressureConstraint  fromGateValve:aGateValve];
			}
			else [self removeConstraintName:kTurboOnPressureConstraint  fromGateValve:aGateValve];
		}
		
		//---------------------------------------------------------------------------
		//the next constraints involve the vacSentry and the cryoRoughing valve
		ORVacuumGateValve* vacSentryValve    = [self gateValve:15];
		ORVacuumGateValve* cryoRoughingValve = [self gateValve:5];
		BOOL PKRG2PressureHigh				 = [self region:kRegionCryoPump valueHigherThan:2];

		//---------------------------------------------------------------------------
		//Opening cryopump roughing valve could expose turbo pump to potentially damaging pressures.
		if([vacSentryValve isOpen] && [cryoRoughingValve isClosed]){
			[self addConstraintName:kTurboOnSentryOpenConstraint reason:kTurboOnSentryOpenConstraintReason toGateValve:cryoRoughingValve];
		}
		else {
			[self removeConstraintName:kTurboOnSentryOpenConstraint fromGateValve:cryoRoughingValve];
		}
		
		//---------------------------------------------------------------------------
		//Opening vacuum sentry could expose turbo pump to potentially damaging pressures.
		if([vacSentryValve isClosed] && [cryoRoughingValve isOpen] && PKRG2PressureHigh){
			[self addConstraintName:kTurboOnCryoRoughingOpenG4HighConstraint reason:kTurboOnCryoRoughingOpenG4HighReason toGateValve:vacSentryValve];
		}
		else {
			[self removeConstraintName:kTurboOnCryoRoughingOpenG4HighConstraint fromGateValve:vacSentryValve];
		}
	}
	else {
		[self onAllGateValvesremoveConstraintName: kTurboOnPressureConstraint];
	}	
}

- (void) addConstraintName:(NSString*)aName reason:(NSString*)aReason toGateValve:(id)aGateValve
{
	[aGateValve addConstraintName:aName reason:aReason];
	if([aGateValve partTag] == 8)		[[self findCryoPump] addPurgeConstraint:aName reason:aReason];
	else if([aGateValve partTag] == 5)	[[self findCryoPump] addRoughingConstraint:aName reason:aReason];
}

- (void) removeConstraintName:(NSString*)aName fromGateValve:(id)aGateValve
{
	[aGateValve removeConstraintName:aName];
	if([aGateValve partTag] == 8)		[[self findCryoPump] removePurgeConstraint:aName];
	else if([aGateValve partTag] == 5)	[[self findCryoPump] removeRoughingConstraint:aName];
}


- (void) checkCryoPumpRelatedConstraints:(ORCP8CryopumpModel*) cryoPump
{
	ORVacuumGateValve* cryoRoughingValve = [self gateValve:5];
	ORVacuumGateValve* cryoPurgeValve    = [self gateValve:8];
	ORVacuumGateValve* CF6Valve			 = [self gateValve:3];
	ORVacuumStatusLabel* cryoRegionObj = [statusDictionary objectForKey:[NSNumber numberWithInt:kRegionCryoPump]];

	BOOL cryoPumpEnabled;
	if(![cryoPump isValid]) cryoPumpEnabled = YES;
	else cryoPumpEnabled = [cryoPump pumpStatus];
		
	//---------------------------------------------------------------------------
	//Opening purge or roughing valve could cause excessive gas condensation on cryo pump.
	if(cryoPumpEnabled){
		if([cryoRoughingValve isClosed]) [self addConstraintName:kCryoCondensationConstraint reason:kCryoCondensationReason toGateValve:cryoRoughingValve];
		else							 [self removeConstraintName:kCryoCondensationConstraint fromGateValve:cryoRoughingValve];
		
		if([cryoPurgeValve isClosed])    [self	addConstraintName:kCryoCondensationConstraint reason:kCryoCondensationReason toGateValve:cryoPurgeValve];
		else							 [self  removeConstraintName:kCryoCondensationConstraint fromGateValve:cryoPurgeValve];
	}
	else {
		[self removeConstraintName:kCryoCondensationConstraint fromGateValve:cryoPurgeValve];
		[self removeConstraintName:kCryoCondensationConstraint fromGateValve:cryoRoughingValve];
		[cryoPump removePumpOnConstraint:kRgaOnOpenToCryoConstraint];
		[cryoRegionObj removeConstraintName:kRgaOnOpenToCryoConstraint];
	}
	
	if([cryoRoughingValve isOpen] && !cryoPumpEnabled){
		[cryoPump addPumpOnConstraint:kRoughingValveOpenCryoConstraint reason:kRoughingValveOpenCryoReason];
		[cryoRegionObj addConstraintName:kRoughingValveOpenCryoConstraint reason:kRoughingValveOpenCryoReason];
	}
	else {
		[cryoPump removePumpOnConstraint:kRoughingValveOpenCryoConstraint];
		[cryoRegionObj removeConstraintName:kRoughingValveOpenCryoConstraint];
	}

	//---------------------------------------------------------------------------
	//Turning Cryopump OFF will expose system to cryo pump evaporation.
	if([CF6Valve isOpen] && cryoPumpEnabled){
		[cryoPump addPumpOffConstraint:k6CFValveOpenCryoConstraint reason:k6CFValveOpenCryoReason];
		[cryoRegionObj addConstraintName:k6CFValveOpenCryoConstraint reason:k6CFValveOpenCryoReason];
	}
	else {
		[cryoPump removePumpOffConstraint:k6CFValveOpenCryoConstraint];
		[cryoRegionObj removeConstraintName:k6CFValveOpenCryoConstraint];
	}
	
	//---------------------------------------------------------------------------
	//If Cryopump is OFF forbid connection of cryopump to detector region
	//loop over all valves if one side is cryo and one side is detector, then put in constraint
	for(ORVacuumGateValve* aGateValve in [self gateValves]){
		if([aGateValve isClosed] && !cryoPumpEnabled){
			int side1				= [aGateValve connectingRegion1];
			int side2				= [aGateValve connectingRegion2];
			
			if([self regionColor:side1 sameAsRegion:side2]){
				[self removeConstraintName:kCryoOffDetectorConstraint fromGateValve:aGateValve];
			}
			else if([self regionColor:side1 sameAsRegion:kRegionCryostat] ){
				[self addConstraintName:kCryoOffDetectorConstraint reason:kCryoOffDetectorReason toGateValve:aGateValve];
			}
			else [self removeConstraintName:kCryoOffDetectorConstraint  fromGateValve:aGateValve];
		}
		else [self removeConstraintName:kCryoOffDetectorConstraint  fromGateValve:aGateValve];
	}
	
	//---------------------------------------------------------------------------
	//If Cryopump temp is >20K close the CF6 valve
	float secondStateTempHigh = [cryoPump secondStageTemp]>20;
	if(!cryoPumpEnabled || secondStateTempHigh){
		if([CF6Valve isOpen]){
			[self closeGateValve:3];
			NSLog(@"ORCA closed the gatevalve between cryopump and cryostat because cryopump >20K or temperature is unknown\n");
			if(!orcaClosedCF6TempAlarm){
				NSString* alarmName = [NSString stringWithFormat:@"ORCA Closed %@",[CF6Valve label]];
				orcaClosedCF6TempAlarm = [[ORAlarm alloc] initWithName:alarmName severity:kHardwareAlarm];
				[orcaClosedCF6TempAlarm setHelpString:@"ORCA closed the valve because cryopump temp >20K or unknown. Acknowledging this alarm will clear it."];
				[orcaClosedCF6TempAlarm setSticky:NO];
			}
			[orcaClosedCF6TempAlarm postAlarm];
		}
	}	
}

- (void) checkRGARelatedConstraints:(ORRGA300Model*) rga
{
	BOOL rgaIsOn;
	if(![rga isValid]) rgaIsOn = YES;
	else rgaIsOn = [rga filamentIsOn];
	
	ORVacuumStatusLabel* turboRegionObj	= [statusDictionary objectForKey:[NSNumber numberWithInt:kRegionAboveTurbo]];
	ORVacuumStatusLabel* cryoRegionObj	= [statusDictionary objectForKey:[NSNumber numberWithInt:kRegionCryoPump]];
	ORCP8CryopumpModel*  cryoPump		= [self findCryoPump];
	ORTM700Model*		 turboPump		= [self findTurboPump];
	//Do the gatevalves first
	if(rgaIsOn){
		//---------------------------------------------------------------------------
		//Opening valve will expose RGA to potentially damaging pressures.
		for(ORVacuumGateValve* aGateValve in [self gateValves]){
			//check kRgaOnConstraint
			if([aGateValve isClosed]){
				int side1				= [aGateValve connectingRegion1];
				int side2				= [aGateValve connectingRegion2];
				BOOL side1High			= [self region:side1 valueHigherThan:1.0E-5];
				BOOL side2High			= [self region:side2 valueHigherThan:1.0E-5];
				
				if([self regionColor:side1 sameAsRegion:side2]){
					[aGateValve removeConstraintName:kRgaOnConstraint];
				}
				else if([self regionColor:side1 sameAsRegion:kRegionRGA] && side2High ){
					[self addConstraintName:kRgaOnConstraint reason:kRgaConstraintReason toGateValve:aGateValve];
				}
				else if([self regionColor:side2 sameAsRegion:kRegionRGA] && side1High){
					[self addConstraintName:kRgaOnConstraint reason:kRgaConstraintReason toGateValve:aGateValve];
				}
				else [self removeConstraintName:kRgaOnConstraint fromGateValve:aGateValve];
			}
			else [self removeConstraintName:kRgaOnConstraint fromGateValve:aGateValve];
		}
		
		//---------------------------------------------------------------------------
		//Turning cryopump OFF will expose RGA to potentially damaging pressures
		if([self regionColor:kRegionRGA sameAsRegion:kRegionCryoPump]){
			[cryoPump addPumpOffConstraint:kRgaOnOpenToCryoConstraint reason:kRgaOnOpenToCryoReason];
			[cryoRegionObj addConstraintName:kRgaOnOpenToCryoConstraint reason:kRgaOnOpenToCryoReason];
		}
		else {
			[cryoPump removePumpOffConstraint:kRgaOnOpenToCryoConstraint];
			[cryoRegionObj removeConstraintName:kRgaOnOpenToCryoConstraint];
		}
		
		//---------------------------------------------------------------------------
		//Turning Turbopump OFF would expose RGA filament to potentially damaging pressures
		if([self regionColor:kRegionRGA sameAsRegion:kRegionAboveTurbo]){
			[turboPump addPumpOffConstraint:kRgaOnOpenToTurboConstraint reason:kRgaOnOpenToTurboReason];
			[turboRegionObj addConstraintName:kRgaOnOpenToTurboConstraint reason:kRgaOnOpenToTurboReason];
		}
		else {
			[turboPump removePumpOffConstraint:kRgaOnOpenToTurboConstraint];
			[turboRegionObj removeConstraintName:kRgaOnOpenToTurboConstraint];
		}
		//---------------------------------------------------------------------------
	}
	else {
		[self onAllGateValvesremoveConstraintName: kRgaOnConstraint];
		[cryoPump removePumpOffConstraint:kRgaOnOpenToCryoConstraint];
		[cryoRegionObj removeConstraintName:kRgaOnOpenToCryoConstraint];
		
		[turboPump removePumpOffConstraint:kRgaOnOpenToTurboConstraint];
		[turboRegionObj removeConstraintName:kRgaOnOpenToTurboConstraint];
	}	
}

- (void) checkPressureConstraints
{
	ORCP8CryopumpModel* cryopump = [self findCryoPump];
	ORRGA300Model*	    rga		 = [self findRGA];
	
	BOOL cryoIsOn;
	if(![cryopump isValid]) cryoIsOn = YES;
	else cryoIsOn = [cryopump pumpStatus];
	
	ORVacuumStatusLabel* cryoRegionObj = [statusDictionary objectForKey:[NSNumber numberWithInt:kRegionCryoPump]];
	BOOL  cryoPressureIsHigh = [self region:kRegionCryoPump valueHigherThan:2.0E0];
	
	//---------------------------------------------------------------------------
	//Turning Cryopump ON could cause excessive gas condensation on cryo pump
	if(!cryoIsOn &&  cryoPressureIsHigh){
		[cryoRegionObj addConstraintName:kPressureTooHighForCryoConstraint reason:kPressureTooHighForCryoReason];
		[cryopump addPumpOnConstraint:kPressureTooHighForCryoConstraint reason:kPressureTooHighForCryoReason];
	}
	else {
		[cryoRegionObj removeConstraintName:kPressureTooHighForCryoConstraint];
		[cryopump removePumpOnConstraint:kPressureTooHighForCryoConstraint];
	}
	
	//---------------------------------------------------------------------------
	ORVacuumStatusLabel* rgaRegionObj	= [statusDictionary objectForKey:[NSNumber numberWithInt:kRegionRGA]];
	//PKR G2>5E-6: Filament could be damaged.
	if([rga ionizerFilamentCurrentRB]==0 && [self region:kRegionRGA valueHigherThan:5E-6]){
		[rga addFilamentConstraint:kRgaFilamentConstraint reason:kRgaFilamentReason];
		[rgaRegionObj addConstraintName:kRgaFilamentConstraint reason:kRgaFilamentReason];
	}
	else {
		[rga removeFilamentConstraint:kRgaFilamentConstraint];
		[rgaRegionObj removeConstraintName:kRgaFilamentConstraint];
	}

	//---------------------------------------------------------------------------
	//PKR G2>5E-7: CEM could be damaged.
	if([rga electronMultiOption] && [rga elecMultHVBiasRB]==0 && [self region:kRegionRGA valueHigherThan:5E-7]){
		[rga addCEMConstraint:kRgaCEMConstraint reason:kRgaCEMReason];
		[rgaRegionObj addConstraintName:kRgaCEMConstraint reason:kRgaCEMReason];
	}
	else {
		[rga removeCEMConstraint:kRgaCEMConstraint];
		[rgaRegionObj removeConstraintName:kRgaCEMConstraint];
	}
	
}

- (void) checkDetectorConstraints
{
	//---------------------------------------------------------------------------
	//Detector Biased: Detector must be protected from regions with pressure higher than 1E-5
    if([self detectorsBiased]){
        for(ORVacuumGateValve* aGateValve in [self gateValves]){
            if([aGateValve isClosed]){
                int side1		= [aGateValve connectingRegion1];
                int side2		= [aGateValve connectingRegion2];
                BOOL side1High	= [self region:side1 valueHigherThan:1.0E-5];
                BOOL side2High	= [self region:side2 valueHigherThan:1.0E-5];
                
                if([self regionColor:side1 sameAsRegion:side2]){
                    [aGateValve removeConstraintName:kDetectorBiasedConstraint];
                }
                else if([self regionColor:side1 sameAsRegion:kRegionCryostat] && side2High ){
                    [self addConstraintName:kDetectorBiasedConstraint reason:kDetectorBiasedReason toGateValve:aGateValve];
                }
                else if([self regionColor:side2 sameAsRegion:kRegionCryostat] && side1High){
                    [self addConstraintName:kDetectorBiasedConstraint reason:kDetectorBiasedReason toGateValve:aGateValve];
                }
                else [self removeConstraintName:kDetectorBiasedConstraint fromGateValve:aGateValve];
            }
            else [self removeConstraintName:kDetectorBiasedConstraint fromGateValve:aGateValve];
        }
    }
    else [self onAllGateValvesremoveConstraintName:kDetectorBiasedConstraint];
	
	//---------------------------------------------------------------------------
	//PKR G3>1E-5: Should unbias, PKR G3>1E-6: Forbid biasing
	//baratron must be >1000Torr  and <2500Torr 
	//Note: the bias info can only get back to the DAQ via the DAQ system script
	double			cyrostatPress		= [self valueForRegion:kRegionCryostat];
	ORMks660BModel* baratron			= [self findBaratron];
	float			baratronPressure	= [baratron pressure];
	
	//baratron operational?
	if(baratronPressure >= 1000 && baratronPressure <= 2500){
		[self removeContinuedBiasConstraints:kBaratronTooHighConstraint];
		[self removeOkToBiasConstraints:kBaratronTooHighConstraint];
		[self removeContinuedBiasConstraints:kBaratronTooLowConstraint];
		[self removeOkToBiasConstraints:kBaratronTooLowConstraint];
	}
	else {
		//nope, not operational
		if(baratronPressure < 1000) {
			[self addContinuedBiasConstraints:kBaratronTooLowConstraint  reason:kBaratronTooLowReason];
			[self addOkToBiasConstraints:kBaratronTooLowConstraint  reason:kBaratronTooLowReason];
		}
		else if(baratronPressure > 2500)	{
			[self addContinuedBiasConstraints:kBaratronTooHighConstraint reason:kBaratronTooHighReason];
			[self addOkToBiasConstraints:kBaratronTooHighConstraint reason:kBaratronTooHighReason];
		}
	}
	
	//cryostat region pressure must be <1E-5 to stay biased
	if(cyrostatPress>1E-5)		[self addContinuedBiasConstraints:kG3WayHighConstraint  reason:kG3WayHighReason];
	else						[self removeContinuedBiasConstraints:kG3WayHighConstraint];
	
	//cryostat region pressure must be <1E-6 to allow biasing
	if(cyrostatPress>1E-6)		[self addOkToBiasConstraints:kG3HighConstraint  reason:kG3HighReason];
	else						[self removeOkToBiasConstraints:kG3HighConstraint];
	
	
}



@end
