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

@interface ORMJDVacuumModel (private)
- (void) makeParts;
- (void) makeLines:(VacuumLineInfo*)lineItems num:(int)numItems;
- (void) makePipes:(VacuumPipeInfo*)pipeList num:(int)numItems;
- (void) makeGateValves:(VacuumGVInfo*)pipeList num:(int)numItems;
- (void) makeStaticLabels:(VacuumStaticLabelInfo*)labelItems num:(int)numItems;
- (void) makeDynamicLabels:(VacuumDynamicLabelInfo*)labelItems num:(int)numItems;
- (void) colorRegionsConnectedTo:(int)aRegion withColor:(NSColor*)aColor;
- (void) recursizelyColorRegionsConnectedTo:(int)aRegion withColor:(NSColor*)aColor;
- (void) resetVisitationFlag;
@end


NSString* ORMJDVacuumModelShowGridChanged = @"ORMJDVacuumModelShowGridChanged";

@implementation ORMJDVacuumModel

#pragma mark •••initialization

- (void) dealloc
{
	[parts release];
	[partDictionary release];
	[adcMapArray release];
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

#pragma mark ***Accessors

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
	
	[[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:showGrid	forKey: @"showGrid"];
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
			[gateValves addObject:aGateValve];
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

- (NSArray*) dynamicLabels
{
	return [partDictionary objectForKey:@"DynamicLabels"];
}

- (NSString*) dynamicLabel:(int)region
{
	NSArray* labels = [partDictionary objectForKey:@"DynamicLabels"];
	if(region < [labels count]) {
		ORVacuumDynamicLabel* theLabel = [labels objectAtIndex:region];
		float theValue = [theLabel value];
		return [NSString stringWithFormat:@"%.2E",theValue];
	}
	else return @"No Value Available";
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
	NSArray* allLabels = [self staticLabels];
	int count = 0;
	for(ORVacuumStaticLabel* aLabel in allLabels){
		int region = [aLabel partTag];
		if([aColor isEqual:[self colorOfRegion:region]]){
			[theRegions appendFormat:@"%@%@,",count!=0?@" ":@"",[[aLabel label] stringByReplacingOccurrencesOfString:@"\n" withString:@" "]];
			count++;
		}
	}
	
	//special case: the cryostat has no label
	if([aColor isEqual:[self colorOfRegion:2]])[theRegions appendString:@" Cryostat,"];
	
	if([theRegions hasSuffix:@","]) return [theRegions substringToIndex:[theRegions length]-1];
	else return theRegions;
	
}

#pragma mark ***AdcProcessor Protocol
- (void)processIsStarting
{
}

- (void)processIsStopping
{
}

- (void) startProcessCycle
{
}

- (void) endProcessCycle
{
}

- (double) setProcessAdc:(int)channel value:(double)aValue isLow:(BOOL*)isLow isHigh:(BOOL*)isHigh
{
	NSArray* adcValues = [self dynamicLabels];
	if(channel<[adcValues count]){
		ORVacuumDynamicLabel* theLabel = [adcValues objectAtIndex:channel];
		BOOL pressureIsOK = aValue<2.5;
		*isLow  = aValue<2.5; //replace with true limits......
		*isHigh = aValue>0;
		[theLabel setValue:aValue];
		[theLabel setState:pressureIsOK];
		NSArray* pipes = [self pipesForRegion:[theLabel partTag]];
		for(ORVacuumPipe* aPipe in pipes){
			[aPipe setState:[theLabel state]];
		}
	}
	else {
		*isLow  = NO;
		*isHigh = NO;
	}
	return aValue;
}

- (BOOL) setProcessBit:(int)channel value:(int)value
{
	ORVacuumGateValve* gv = [self gateValve:(int)channel];
	if([gv controlType] == kControlOnly){
		if(value==1)[gv setState:kGVClosed];
		else		[gv setState:kGVOpen];
	}
	else {
		if(value==3)		[gv setState:kGVChanging];
		else if(value==1)	[gv setState:kGVOpen];
		else if(value==2)	[gv setState:kGVClosed];
		else                [gv setState:kGVImpossible];
	}
	return value;
}

- (NSString*) processingTitle
{
	return @"MJD Vac";
}

@end


@implementation ORMJDVacuumModel (private)
- (void) makeParts
{
	
#define kNumVacPipes		52
	VacuumPipeInfo vacPipeList[kNumVacPipes] = {
		//region 0 pipes
		{ kVacVPipe,  0, 50,			 200+kPipeRadius,	50,					450 }, 
		{ kVacHPipe,  0, 50+kPipeRadius, 400,				150+kPipeRadius,	400 },
		{ kVacVPipe,  0, 100,			 400-kPipeRadius,	100,				300 },
		//region 1 pipes
		{ kVacVPipe,  1, 500,			  150,				500,				250 },
		{ kVacHPipe,  1, 150,			  400,				300,				400 },
		{ kVacHPipe,  1, 150,			  200,				500-kPipeRadius,	200 },
		{ kVacVPipe,  1, 240,			  200+kPipeRadius,	240,				400-kPipeRadius },
		{ kVacVPipe,  1, 240,			  400+kPipeRadius,	240,				420 },
		{ kVacVPipe,  1, 200,			  400+kPipeRadius,	200,				450 },
		//region 2 pipes (cyrostat)
		{ kVacBox,	  2, 475,			  500,				525,				550 },
		{ kVacBox,	  2, 600,			  450,				680,				560 },
		{ kVacBigHPipe,2,525,			  525,		        600,				525 },
		{ kVacCorner, 2, 700,			  400,				kNA,				kNA },
		{ kVacVPipe,  2, 700,			   70,				700,				400-kPipeRadius },
		{ kVacHPipe,  2, 300,			  400,				700-kPipeRadius,	400 },
		{ kVacVPipe,  2, 600,			  350,				600,				400-kPipeRadius },
		{ kVacVPipe,  2, 500,			  350,				500,				400-kPipeRadius },
		{ kVacCorner, 2, 350,			  300,				kNA,				kNA },
		{ kVacVPipe,  2, 350,			  300+kPipeRadius,	350,				400-kPipeRadius },
		{ kVacHPipe,  2, 300,			  300,				350-kPipeRadius,	300 },
		{ kVacHPipe,  2, 300,			  350,				350-kPipeRadius,	350 },
		{ kVacVPipe,  2, 400,			  400+kPipeRadius,	400,				450 },
		{ kVacVPipe,  2, 500,			  400+kPipeRadius,	500,				500 },
		//region 3 pipes
		{ kVacVPipe,  3, 600,			  170,				600,				350 },
		{ kVacHPipe,  3, 600+kPipeRadius, 300,				620,				300 },
		{ kVacCorner, 3, 500,			  100,				kNA,				kNA },
		{ kVacVPipe,  3, 500,			  100+kPipeRadius,	500,				150 },
		{ kVacVPipe,  3, 600,			  70,				600,				170 },
		{ kVacHPipe,  3, 500+kPipeRadius, 100,				600-kPipeRadius,	100 },
		{ kVacHPipe,  3, 600+kPipeRadius, 100,				620,				100 },
		//region 4 pipes
		{ kVacBox,	  4, 470,			  570,				530,				620 },
		{ kVacBox,	  4, 270,			  570,				330,				620 },
		{ kVacCorner, 4, 500,			  525,				kNA,				kNA },
		{ kVacCorner, 4, 650,			  525,				kNA,				kNA },
		{ kVacHPipe,  4, 500+kPipeRadius, 525,				650-kPipeRadius,	525 },
		{ kVacVPipe,  4, 500,			  525+kPipeRadius,	500,				570 },
		{ kVacHPipe,  4, 330,			  600,				400,				600 },
		{ kVacHPipe,  4, 400,			  600,				470,				600 },
		{ kVacVPipe,  4, 360,			  550,				360,				600-kPipeRadius },
		//region 5 pipes
		{ kVacCorner, 5, 100,			  30,				kNA,				kNA },
		{ kVacCorner, 5, 700,			  30,				kNA,				kNA },
		{ kVacVPipe,  5, 100,			  30+kPipeRadius,	100,				300 },
		{ kVacHPipe,  5, 100+kPipeRadius, 30,				700-kPipeRadius,	30 },
		{ kVacHPipe,  5, 100+kPipeRadius, 200,				150,				200 },
		{ kVacVPipe,  5, 700,			  30+kPipeRadius,	700,				70 },
		{ kVacVPipe,  5, 600,			  30+kPipeRadius,	600,				70 },
		{ kVacCorner, 5, 300,			  80,				kNA,				kNA },
		{ kVacVPipe,  5, 300,			  30+kPipeRadius,	300,				80-kPipeRadius },
		{ kVacHPipe,  5, 280,			  80,				300-kPipeRadius,	80 },
		{ kVacHPipe,  5, 250,			  80,				280,				80 },
		//region 6 pipes
		{ kVacVPipe,  6, 500,			  250,				500,				350 },
		{ kVacHPipe,  6, 460,			  300,				500-kPipeRadius,	300 },
	};
		
#define kNumStaticVacLabelItems	7
	VacuumStaticLabelInfo staticLabelItems[kNumStaticVacLabelItems] = {
		{kVacStaticLabel, 0, @"Turbo",			20,	 260,	80,	 290},
		{kVacStaticLabel, 0, @"Vacuum\nSentry",	20,	 220,	80,	 250},
		{kVacStaticLabel, 0, @"Diaphragm\nPump",20,	 180,	80,	 210},
		{kVacStaticLabel, 1, @"RGA",			220, 420,	260, 440},
		{kVacStaticLabel, 3, @"Cryo Pump",		570, 155,	630, 185},
		{kVacStaticLabel, 5, @"Dry N2\nSupply",	150,  60,	250, 100},
		{kVacStaticLabel, 6, @"NEG Pump",		400, 285,	460, 315},
	};	
	
#define kNumDynamicVacLabelItems	5
	//the parttags are equal to the index numbers are equal to the region
	VacuumDynamicLabelInfo dynamicLabelItems[kNumDynamicVacLabelItems] = {
		{kVacDynamicLabel, 0, @"PKR G1",	20,	 450,	80,	 490},
		{kVacDynamicLabel, 1, @"PKR G2",	170, 450,	230, 490},
		{kVacDynamicLabel, 2, @"PKR G3",	370, 450,	430, 490},
		{kVacDynamicLabel, 3, @"PKR G4",	620, 280,	680, 320},
		{kVacDynamicLabel, 4, @"Baratron",	330, 520,	390, 550},
	};	
			
	
#define kNumVacLines 10
	VacuumLineInfo vacLines[kNumVacLines] = {
		{kVacLine, 150,400,150,420},  //V1
		{kVacLine, 300,400,300,420},  //V2
		{kVacLine, 600,350,620,350},  //V3
		{kVacLine, 480,350,500,350},  //V4
		{kVacLine, 480,250,500,250},  //V5
		{kVacLine, 480,150,500,150},  //V6
	
		{kVacLine, 100,300,120,300},  //Bellows
		{kVacLine, 150,200,150,220},  //Bellows
		{kVacLine, 580,70,600,70},  //Bellows
		{kVacLine, 680,70,700,70},  //Bellows
	};

#define kNumVacGVs			15
	VacuumGVInfo gvList[kNumVacGVs] = {
		{kVacVGateV, 0,		@"V1",			k2BitReadBack,	150, 400,	0,1,	kControlAbove},	//V1. Control + read back
		{kVacVGateV, 1,		@"V2",			k2BitReadBack,	300, 400,	1,2,	kControlAbove},	//V2. Control + read back
		{kVacHGateV, 2,		@"V3",			k2BitReadBack,	600, 350,	2,3,	kControlRight},	//V3. Control + read back
		{kVacHGateV, 3,		@"V4",			k2BitReadBack,	500, 350,	2,6,	kControlLeft},	//V4. Control + read back
		{kVacHGateV, 4,		@"V5",			k2BitReadBack,	500, 250,	1,6,	kControlLeft},	//V5. Control + read back
		{kVacHGateV, 5,		@"V6",			k2BitReadBack,	500, 150,	1,3,	kControlLeft},   //V6. Control + read back
		
		{kVacVGateV, 6,		@"B1",			kControlOnly,	150, 200,	1,5,	kControlAbove},	//Control only
		{kVacHGateV, 7,		@"B2",			kControlOnly,	100, 300,	0,5,	kControlRight},	//Control only
		{kVacHGateV, 8,		@"B3",			kControlOnly,	600, 70,	3,5,	kControlLeft},	//Control only 
		{kVacHGateV, 9,		@"B4",			kControlOnly,	700, 70,	2,5,	kControlLeft},	//Control only 
		
		{kVacVGateV, 10,	@"Burst",		kManualOnlyShowClosed,		300, 300,	2,kUpToAir,	kControlNone},	//burst
		{kVacVGateV, 11,	@"N2 Manual",	kManualOnlyShowChanging,	280, 80,	5,kUpToAir,	kControlNone},	//Manual N2 supply
		{kVacVGateV, 12,	@"PRV",			kManualOnlyShowClosed,		620, 100,	3,kUpToAir,	kControlNone},	//PRV
		{kVacVGateV, 13,	@"PRV",			kManualOnlyShowClosed,		300, 350,	2,kUpToAir,	kControlNone},	//PRV
		{kVacVGateV, 14,	@"C1",			kManualOnlyShowChanging,	400, 600,	4,4,		kControlNone},	//Manual only
	};
	
	[self makeLines:vacLines					num:kNumVacLines];
	[self makePipes:vacPipeList					num:kNumVacPipes];
	[self makeGateValves:gvList					num:kNumVacGVs];
	[self makeStaticLabels:staticLabelItems		num:kNumStaticVacLabelItems];
	[self makeDynamicLabels:dynamicLabelItems	num:kNumDynamicVacLabelItems];
}

- (void) makePipes:(VacuumPipeInfo*)pipeList num:(int)numItems
{
	int i;
	for(i=0;i<numItems;i++){
		ORVacuumPipe* aPipe = nil;
		switch(pipeList[i].type){
			case kVacCorner:
				aPipe = [[[ORVacuumCPipe alloc] initWithDelegate:self partTag:pipeList[i].partTag at:NSMakePoint(pipeList[i].x1, pipeList[i].y1)] autorelease];
				break;
				
			case kVacVPipe:
				aPipe = [[[ORVacuumVPipe alloc] initWithDelegate:self partTag:pipeList[i].partTag startPt:NSMakePoint(pipeList[i].x1, pipeList[i].y1) endPt:NSMakePoint(pipeList[i].x2, pipeList[i].y2)] autorelease];
				break;
				
			case kVacHPipe:
				aPipe = [[[ORVacuumHPipe alloc] initWithDelegate:self partTag:pipeList[i].partTag startPt:NSMakePoint(pipeList[i].x1, pipeList[i].y1) endPt:NSMakePoint(pipeList[i].x2, pipeList[i].y2)] autorelease];
				break;
				
			case kVacBigHPipe:
				aPipe = [[[ORVacuumBigHPipe alloc] initWithDelegate:self partTag:pipeList[i].partTag startPt:NSMakePoint(pipeList[i].x1, pipeList[i].y1) endPt:NSMakePoint(pipeList[i].x2, pipeList[i].y2)] autorelease];
				break;
				
			case kVacBox:
				aPipe = [[[ORVacuumBox alloc] initWithDelegate:self partTag:pipeList[i].partTag bounds:NSMakeRect(pipeList[i].x1, pipeList[i].y1,pipeList[i].x2-pipeList[i].x1,pipeList[i].y2-pipeList[i].y1)] autorelease];
				break;
		}
	}
}

- (void) makeGateValves:(VacuumGVInfo*)gvList num:(int)numItems
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
- (void) makeStaticLabels:(VacuumStaticLabelInfo*)labelItems num:(int)numItems
{
	int i;
	for(i=0;i<numItems;i++){
		NSRect theBounds = NSMakeRect(labelItems[i].x1,labelItems[i].y1,labelItems[i].x2-labelItems[i].x1,labelItems[i].y2-labelItems[i].y1);
		[[ORVacuumStaticLabel alloc] initWithDelegate:self partTag: labelItems[i].partTag label:labelItems[i].label bounds:theBounds];
	}
}

- (void) makeDynamicLabels:(VacuumDynamicLabelInfo*)labelItems num:(int)numItems
{
	int i;
	for(i=0;i<numItems;i++){
		NSRect theBounds = NSMakeRect(labelItems[i].x1,labelItems[i].y1,labelItems[i].x2-labelItems[i].x1,labelItems[i].y2-labelItems[i].y1);
		[[ORVacuumDynamicLabel alloc] initWithDelegate:self partTag: labelItems[i].partTag label:labelItems[i].label bounds:theBounds];
	}
}

- (void) makeLines:(VacuumLineInfo*)lineItems num:(int)numItems
{
	int i;
	for(i=0;i<numItems;i++){
		[[ORVacuumLine alloc] initWithDelegate:self partTag:0 startPt:NSMakePoint(lineItems[i].x1, lineItems[i].y1) endPt:NSMakePoint(lineItems[i].x2, lineItems[i].y2)];
	}
}



- (void) colorRegions
{
	#define kNumberPriorityRegions 7
	int regionPriority[kNumberPriorityRegions] = {4,6,1,0,3,2,5}; //lowest to highest
					
	NSColor* regionColor[kNumberPriorityRegions] = {
		[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.7 alpha:1.0], //Region 0 Turbo
		[NSColor colorWithCalibratedRed:1.0 green:0.7 blue:1.0 alpha:1.0], //Region 1 RGA
		[NSColor colorWithCalibratedRed:0.8 green:0.8 blue:1.0 alpha:1.0], //Region 2 Cryostat
		[NSColor colorWithCalibratedRed:0.7 green:1.0 blue:0.7 alpha:1.0], //Region 3 Cryo pump
		[NSColor colorWithCalibratedRed:0.6 green:0.6 blue:1.0 alpha:1.0], //Region 4 Thermosyphon
		[NSColor colorWithCalibratedRed:1.0 green:0.5 blue:0.5 alpha:1.0], //Region 5 N2
		[NSColor colorWithCalibratedRed:0.8 green:0.8 blue:0.4 alpha:1.0], //Region 6 NEG Pump
	};
	int i;
	for(i=0;i<kNumberPriorityRegions;i++){
		int region = regionPriority[i];
		[self colorRegionsConnectedTo:region withColor:regionColor[region]];
	}
	
	NSArray* staticLabels = [self staticLabels];
	for(ORVacuumStaticLabel* aLabel in staticLabels){
		int region = [aLabel partTag];
		if(region<kNumberPriorityRegions){
			[aLabel setControlColor:regionColor[region]];
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
	//this routine is called recursively, so do not reset the colorizationflag in this routine.
	NSArray* pipes = [self pipesForRegion:aRegion];
	for(id aPipe in pipes){
		if([aPipe visited])return;
		[aPipe setRegionColor:aColor];
		[aPipe setVisited:YES];
	}
	NSArray* gateValves = [self gateValvesConnectedTo:(int)aRegion];
	for(id aGateValve in gateValves){
		int state = [aGateValve state];
		if(state>0 && state!=kGVClosed){
			if([aGateValve connectingRegion1]!=aRegion)[self recursizelyColorRegionsConnectedTo:[aGateValve connectingRegion1] withColor:aColor];
			if([aGateValve connectingRegion2]!=aRegion)[self recursizelyColorRegionsConnectedTo:[aGateValve connectingRegion2] withColor:aColor];
		}
	}
}

- (void) resetVisitationFlag
{
	for(id aPart in parts)[aPart setVisited:NO];
}

- (void) addPart:(id)aPart
{
	//the parts array contains all parts
	if(!parts)parts = [[NSMutableArray array] retain];
	[parts addObject:aPart];
	
	//we keep a separate dicionary of various categories of parts for convenience
	if(!partDictionary){
		partDictionary = [[NSMutableDictionary dictionary] retain];
		[partDictionary setObject:[NSMutableDictionary dictionary] forKey:@"Regions"];
		[partDictionary setObject:[NSMutableArray array] forKey:@"GateValves"];		
		[partDictionary setObject:[NSMutableArray array] forKey:@"DynamicLabels"];		
		[partDictionary setObject:[NSMutableArray array] forKey:@"StaticLabels"];		
	}
	NSNumber* thePartKey = [NSNumber numberWithInt:[aPart partTag]];
	if([aPart isKindOfClass:NSClassFromString(@"ORVacuumPipe")]){
		NSMutableArray* aRegionArray = [[partDictionary objectForKey:@"Regions"] objectForKey:thePartKey];
		if(!aRegionArray)aRegionArray = [NSMutableArray array];
		[aRegionArray addObject:aPart];
		[[partDictionary objectForKey:@"Regions"] setObject:aRegionArray forKey:thePartKey];
	}
	else if([aPart isKindOfClass:NSClassFromString(@"ORVacuumGateValve")]){
		[[partDictionary objectForKey:@"GateValves"] addObject:aPart];
	}
	else if([aPart isKindOfClass:NSClassFromString(@"ORVacuumDynamicLabel")]){
		[[partDictionary objectForKey:@"DynamicLabels"] addObject:aPart];
	}
	else if([aPart isKindOfClass:NSClassFromString(@"ORVacuumStaticLabel")]){
		[[partDictionary objectForKey:@"StaticLabels"] addObject:aPart];
	}
}


@end
