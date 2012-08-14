//
//  ORMJDTestCryostat.m
//  Orca
//
//  Created by Mark Howe on Mon Aug 13, 2012.
//  Copyright ¬© 2012 CENPA, University of North Carolina. All rights reserved.
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
#import "ORMJDTestCryostat.h"
#import "ORMJDVacuumView.h"
#import "ORProcessModel.h"
#import "ORAdcModel.h"
#import "ORAdcProcessing.h"
#import "ORTPG256AModel.h"

@interface ORMJDTestCryostat (private)
- (void) _makeParts;
- (void) makePipes:(VacuumPipeStruct*)pipeList num:(int)numItems;
- (void) makeGateValves:(VacuumGVStruct*)pipeList num:(int)numItems;
- (void) makeStaticLabels:(VacuumStaticLabelStruct*)labelItems num:(int)numItems;
- (void) makeDynamicLabels:(VacuumDynamicLabelStruct*)labelItems num:(int)numItems;
- (void) colorRegionsConnectedTo:(int)aRegion withColor:(NSColor*)aColor;
- (void) recursizelyColorRegionsConnectedTo:(int)aRegion withColor:(NSColor*)aColor;
- (void) resetVisitationFlag;

- (double) valueForRegion:(int)aRegion;
- (ORVacuumValueLabel*) regionValueObj:(int)aRegion;
- (BOOL) valueValidForRegion:(int)aRegion;
- (BOOL) region:(int)aRegion valueHigherThan:(double)aValue;

- (ORTPG256AModel*)    findPressureGauge;
- (id)findObject:(NSString*)aClassName;

@end

@implementation ORMJDTestCryostat

#pragma mark •••initialization
- (void) setDelegate:(id)aDelegate
{
	delegate = aDelegate;
}
- (id) model { return self; }
- (BOOL) showGrid {return [delegate showGrid];}

- (void) wakeUp
{
	[self registerNotificationObservers];
}

- (void) sleep
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[parts release];
	[partDictionary release];
	[valueDictionary release];
	[super dealloc];
}

- (void) registerNotificationObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	//we need to know about a specific set of events in order to handle the constraints
	
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
}


#pragma mark ***Accessors

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
	
	[self registerNotificationObservers];
	
    return self;
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
	involvedInProcess = YES;
}

- (void) processIsStopping
{
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

- (NSString*) processingTitle
{
	return [NSString stringWithFormat:@"MJD Test Cryo"];
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
	/*
	for(OrcaObject* anObj in [self orcaObjects]){
		if([anObj tag] == i){
			[anObj makeMainController];
			break;
		}
	}
	 */
}

- (NSString*) regionName:(int)i
{
	switch(i){
		default: return nil;
	}
}

- (void) makeParts
{
	[self _makeParts];
}

@end


@implementation ORMJDTestCryostat (private)
- (ORTPG256AModel*)     findPressureGauge   { return [self findObject:@"ORTPG256AModel"];     }

- (id) findObject:(NSString*)aClassName
{
//	for(OrcaObject* anObj in [NSApp delegate] ){
//		if([anObj isKindOfClass:NSClassFromString(aClassName)])return anObj;
//	}
	return nil;
}


- (void) _makeParts
{
#define kNumVacPipes		6
	VacuumPipeStruct vacPipeList[kNumVacPipes] = {
		//region 0 pipes
		{ kVacBox,	  kRegionCryostat, 60,			  100,			140,				180 },
		{ kVacVPipe,  kRegionCryostat, 100,				50,			100,				100 }, 
		{ kVacHPipe,  kRegionCryostat, 65,				75,			100-kPipeRadius,	75 }, 
		
		//region 1 pipes
		{ kVacVPipe,  kRegionBelowCryo, 100,			0,			100,				50 }, 
		{ kVacHPipe,  kRegionBelowCryo, 100+kPipeRadius,	30,			120,				30}, 
		{ kVacHPipe,  kRegionBelowCryo, 120,				30,			140,				30 }, 

	};
	
#define kNumStaticLabelItems	1
	VacuumStaticLabelStruct staticLabelItems[kNumStaticLabelItems] = {
		{kVacStaticLabel, kRegionDryN2,			@"NEG\nPump",	135,  15,	195, 45},
	};	
	
#define kNumStatusItems	1
	VacuumDynamicLabelStruct dynamicLabelItems[kNumStatusItems] = {
		//type,	region, component, channel
		{kVacPressureItem, kRegionBelowCryo,	3, 0,  @"PKR G1",	5, 60,	65, 90},
	};	
		
#define kNumVacGVs			3
	VacuumGVStruct gvList[kNumVacGVs] = {
		{kVacHGateV, 0,	@"V1",			kManualOnlyShowChanging,	100, 5,	kRegionDryN2,		kRegionAboveTurbo,		kControlNone},	//Manual N2 supply
		{kVacHGateV, 1,	@"V2",			kManualOnlyShowChanging,	100, 50,	kRegionDryN2,		kRegionAboveTurbo,		kControlNone},	//Manual N2 supply
		{kVacVGateV, 2,	@"V3",			kManualOnlyShowChanging,	120, 30,	kRegionDryN2,		kRegionAboveTurbo,		kControlNone},	//Manual N2 supply
	};
	
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

- (BOOL) region:(int)aRegion valueHigherThan:(double)aValue
{
	return [[self regionValueObj:aRegion] valueHigherThan:aValue];
}

- (BOOL) valueValidForRegion:(int)aRegion
{
	return [[self regionValueObj:aRegion] isValid];
}

- (double) valueForRegion:(int)aRegion
{	
	return [[self regionValueObj:aRegion] value];
}

- (ORVacuumValueLabel*) regionValueObj:(int)aRegion
{
	return [valueDictionary objectForKey:[NSNumber numberWithInt:aRegion]];
}
- (void) openDialogForComponent:(int)i
{
}

- (BOOL) regionColor:(int)r1 sameAsRegion:(int)r2
{
	NSColor* c1	= [self colorOfRegion:r1];
	NSColor* c2	= [self colorOfRegion:r2];
	return [c1 isEqual:c2];
}
			 
@end
