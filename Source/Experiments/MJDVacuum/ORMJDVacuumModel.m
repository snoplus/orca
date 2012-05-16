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


NSString* ORMJDVacuumModelVetoMaskChanged = @"ORMJDVacuumModelVetoMaskChanged";
NSString* ORMJDVacuumModelShowGridChanged = @"ORMJDVacuumModelShowGridChanged";
NSString* ORMJCVacuumLock				  = @"ORMJCVacuumLock";

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

- (unsigned long) vetoMask
{
    return vetoMask;
}

- (void) setVetoMask:(unsigned long)aVetoMask
{
    vetoMask = aVetoMask;
	NSArray* gateValves = [self gateValves];
	for(ORVacuumGateValve* aGateValve in gateValves){
		int tag = [aGateValve partTag];
		if(vetoMask & (0x1<<tag))aGateValve.vetoed = YES;
		else aGateValve.vetoed = NO;
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDVacuumModelVetoMaskChanged object:self];
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

	NSArray* staticLabelDialogLinks	 = [decoder decodeObjectForKey:	@"staticLabelDialogLinks"];
	int i=0;
	NSArray* allLabels = [self staticLabels];
	for(ORVacuumStaticLabel* aLabel in allLabels){
		if(i < [staticLabelDialogLinks count]){
			aLabel.dialogIdentifier = [staticLabelDialogLinks objectAtIndex:i];
			i++;
		}
	}

	NSArray* dynamicLabelDialogLinks	 = [decoder decodeObjectForKey:	@"dynamicLabelDialogLinks"];
	i=0;
	allLabels = [self dynamicLabels];
	for(ORVacuumDynamicLabel* aLabel in allLabels){
		if(i < [dynamicLabelDialogLinks count]){
			aLabel.dialogIdentifier = [dynamicLabelDialogLinks objectAtIndex:i];
			i++;
		}
	}
	
	[[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:showGrid					forKey: @"showGrid"];
	
	
	NSMutableArray* staticLabelDialogLinks	 = [NSMutableArray array];
	NSArray* allLabels = [self staticLabels];
	int i=0;
	for(ORVacuumStaticLabel* aLabel in allLabels){
		if([aLabel.dialogIdentifier length]>0){
			[staticLabelDialogLinks addObject:aLabel.dialogIdentifier];
		}
		else {
			[staticLabelDialogLinks addObject:@""];
		}
	}
	[encoder encodeObject:staticLabelDialogLinks	forKey: @"staticLabelDialogLinks"];

	
	NSMutableArray* dynamicLabelDialogLinks	 = [NSMutableArray array];
	i=0;
	allLabels = [self dynamicLabels];
	for(ORVacuumDynamicLabel* aLabel in allLabels){
		if([aLabel.dialogIdentifier length]>0){
			[dynamicLabelDialogLinks addObject:aLabel.dialogIdentifier];
		}
		else {
			[dynamicLabelDialogLinks addObject:@""];
		}
	}
    [encoder encodeObject:dynamicLabelDialogLinks	forKey: @"dynamicLabelDialogLinks"];
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
	[self setVetoMask:0xffffffff];
}

- (void)processIsStopping
{
	[self setVetoMask:0xffffffff];
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
	return value;
}

- (NSString*) processingTitle
{
	return [NSString stringWithFormat:@"MJD Vac,%d",[self uniqueIdNumber]];
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

@end


@implementation ORMJDVacuumModel (private)
- (void) makeParts
{
	
#define kNumVacPipes		57
	VacuumPipeInfo vacPipeList[kNumVacPipes] = {
		//region 0 pipes
		{ kVacVPipe,  0, 50,			 260,				50,					450 }, 
		{ kVacHPipe,  0, 50+kPipeRadius, 400,				180+kPipeRadius,	400 },
		{ kVacVPipe,  0, 150,			 400-kPipeRadius,	150,				300 },
		//region 1 pipes
		{ kVacCorner, 1, 500,			  200,				kNA,				kNA },
		{ kVacVPipe,  1, 500,			  200+kPipeRadius,	 500,				250 },
		{ kVacHPipe,  1, 180,			  400,				350,				400 },
		{ kVacHPipe,  1, 200,			  200,				500-kPipeRadius,	200 },
		{ kVacVPipe,  1, 280,			  200+kPipeRadius,	280,				400-kPipeRadius },
		{ kVacVPipe,  1, 280,			  400+kPipeRadius,	280,				420 },
		{ kVacVPipe,  1, 230,			  400+kPipeRadius,	230,				450 },
		{ kVacHPipe,  1, 230,			  350,				280-kPipeRadius,	350 },
		//region 2 pipes (cyrostat)
		{ kVacBox,	  2, 475,			  500,				525,				550 },
		{ kVacBox,	  2, 600,			  450,				680,				560 },
		{ kVacBigHPipe,2,525,			  525,		        600,				525 },
		{ kVacCorner, 2, 700,			  400,				kNA,				kNA },
		{ kVacVPipe,  2, 700,			   70,				700,				400-kPipeRadius },
		{ kVacHPipe,  2, 350,			  400,				700-kPipeRadius,	400 },
		{ kVacVPipe,  2, 600,			  350,				600,				400-kPipeRadius },
		{ kVacVPipe,  2, 500,			  350,				500,				400-kPipeRadius },
		{ kVacCorner, 2, 400,			  300,				kNA,				kNA },
		{ kVacVPipe,  2, 400,			  300+kPipeRadius,	400,				400-kPipeRadius },
		{ kVacHPipe,  2, 350,			  300,				400-kPipeRadius,	300 },
		{ kVacHPipe,  2, 350,			  350,				400-kPipeRadius,	350 },
		{ kVacVPipe,  2, 400,			  400+kPipeRadius,	400,				450 },
		{ kVacVPipe,  2, 500,			  400+kPipeRadius,	500,				500 },
		//region 3 pipes
		{ kVacVPipe,  3, 600,			  230,				600,				350 },
		{ kVacHPipe,  3, 600+kPipeRadius, 300,				620,				300 },
		{ kVacVPipe,  3, 580,			  70,				580,				200 },
		{ kVacHPipe,  3, 530,			  150,				580-kPipeRadius,	150 },
		{ kVacCorner, 3, 620,			  150,				kNA,				kNA },
		{ kVacVPipe,  3, 620,			  150+kPipeRadius,	620,				200 },
		{ kVacHPipe,  3, 620+kPipeRadius, 150,				640,				150 },
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
		{ kVacCorner, 5, 150,			  30,				kNA,				kNA },
		{ kVacCorner, 5, 700,			  30,				kNA,				kNA },
		{ kVacVPipe,  5, 150,			  30+kPipeRadius,	150,				300 },
		{ kVacHPipe,  5, 150+kPipeRadius, 30,				700-kPipeRadius,	30 },
		{ kVacHPipe,  5, 150+kPipeRadius, 200,				200,				200 },
		{ kVacVPipe,  5, 700,			  30+kPipeRadius,	700,				70 },
		{ kVacVPipe,  5, 580,			  30+kPipeRadius,	580,				70 },
		{ kVacCorner, 5, 350,			  80,				kNA,				kNA },
		{ kVacVPipe,  5, 350,			  30+kPipeRadius,	350,				80-kPipeRadius },
		{ kVacHPipe,  5, 330,			  80,				350-kPipeRadius,	80 },
		{ kVacHPipe,  5, 300,			  80,				330,				80 },
		//region 6 pipes
		{ kVacVPipe,  6, 500,			  250,				500,				350 },
		{ kVacHPipe,  6, 460,			  300,				500-kPipeRadius,	300 },
		//region 7 pipes
		{ kVacVPipe,  7, 50,			 100,				50,					200 }, 
		{ kVacHPipe,  7, 50+kPipeRadius,  150,				530,				150 },
		//region 8 pipes
		{ kVacVPipe,  8, 50,			 200,				50,					260 }, 

	};
		
#define kNumStaticVacLabelItems	18
	VacuumStaticLabelInfo staticLabelItems[kNumStaticVacLabelItems] = {
		//the parttags are equal to the index numbers of the regions
		{kVacStaticLabel, 0, @"Turbo",			20,	 245,	80,	 265, YES},
		{kVacStaticLabel, 1, @"RGA",			260, 420,	300, 440, YES},
		{kVacStaticLabel, 3, @"Cryo Pump",		560, 200,	640, 230, YES},
		{kVacStaticLabel, 5, @"Dry N2\nSupply",	200,  60,	300, 100, YES},
		{kVacStaticLabel, 6, @"NEG Pump",		420, 285,	480, 315, YES},
		{kVacStaticLabel, 7, @"Diaphragm\nPump",20,	 80,	80,	 110, YES},
		{kVacStaticLabel, 8, @"Below Turbo",	 0,	  0,	 0,	   0, NO},
		
		{kVacStaticLabel, 99, @"V1",			175, 375,	185, 385, NO},
		{kVacStaticLabel, 99, @"V2",			335, 375,	365, 385, NO},
		{kVacStaticLabel, 99, @"V3",			515, 345,	525, 355, NO},
		{kVacStaticLabel, 99, @"V4",			575, 345,	585, 355, NO},
		{kVacStaticLabel, 99, @"V5",			515, 245,	525, 255, NO},
		{kVacStaticLabel, 99, @"Roughing",		485, 165,	530, 175, NO},
		
		{kVacStaticLabel, 99, @"B1",			195, 175,	205, 185, NO},
		{kVacStaticLabel, 99, @"B2",			120, 295,	135, 305, NO},
		{kVacStaticLabel, 99, @"Purge",			550,  45,	560,  55, NO},
		{kVacStaticLabel, 99, @"B4",			680,  45,	690,  55, NO},
		{kVacStaticLabel, 99, @"B5",			25,  195,	35,  205, NO},

	};	
	
#define kNumDynamicVacLabelItems	5
	VacuumDynamicLabelInfo dynamicLabelItems[kNumDynamicVacLabelItems] = {
		{kVacDynamicLabel, 0, @"PKR G1",	20,	 450,	80,	 490},
		{kVacDynamicLabel, 1, @"PKR G2",	200, 450,	260, 490},
		{kVacDynamicLabel, 2, @"PKR G3",	370, 450,	430, 490},
		{kVacDynamicLabel, 3, @"PKR G4",	620, 280,	680, 320},
		{kVacDynamicLabel, 4, @"Baratron",	330, 520,	390, 550},
	};	
			
	
#define kNumVacLines 11
	VacuumLineInfo vacLines[kNumVacLines] = {
		{kVacLine, 180,400,180,420},  //V1
		{kVacLine, 350,400,350,420},  //V2
		{kVacLine, 600,350,620,350},  //V3
		{kVacLine, 480,350,500,350},  //V4
		{kVacLine, 480,250,500,250},  //V5
		{kVacLine, 530,130,530,140},  //V6
	
		{kVacLine, 200,200,200,220},  //B1
		{kVacLine, 150,300,170,300},  //B2
		{kVacLine, 560,70,580,70},  //B3
		{kVacLine, 680,70,700,70},  //B4
		{kVacLine, 60,200,70,200},  //B5
	};

#define kNumVacGVs			18
	VacuumGVInfo gvList[kNumVacGVs] = {
		{kVacVGateV, 0,		@"V1",			k2BitReadBack,	180, 400,	0,1,	kControlAbove},	//V1. Control + read back
		{kVacVGateV, 1,		@"V2",			k2BitReadBack,	350, 400,	1,2,	kControlAbove},	//V2. Control + read back
		{kVacHGateV, 2,		@"V3",			k2BitReadBack,	500, 350,	2,6,	kControlLeft},	//V4. Control + read back
		{kVacHGateV, 3,		@"V4",			k2BitReadBack,	600, 350,	2,3,	kControlRight},	//V3. Control + read back
		{kVacHGateV, 4,		@"V5",			k2BitReadBack,	500, 250,	1,6,	kControlLeft},	//V5. Control + read back
		{kVacVGateV, 5,		@"Roughing",	k1BitReadBack,	530, 150,	7,3,	kControlBelow},   //V6. Control + read back
		
		{kVacVGateV, 6,		@"B1",			k1BitReadBack,	200, 200,	1,5,	kControlAbove},	//Control only
		{kVacHGateV, 7,		@"B2",			k1BitReadBack,	150, 300,	0,5,	kControlRight},	//Control only
		{kVacHGateV, 8,		@"Purge",			k1BitReadBack,	580, 70,	3,5,	kControlLeft},	//Control only 
		{kVacHGateV, 9,		@"B4",			k1BitReadBack,	700, 70,	2,5,	kControlLeft},	//Control only 
		
		{kVacVGateV, 10,	@"Burst",		kManualOnlyShowClosed,		350, 300,	2,kUpToAir,	kControlNone},	//burst
		{kVacVGateV, 11,	@"N2 Manual",	kManualOnlyShowChanging,	330, 80,	5,kUpToAir,	kControlNone},	//Manual N2 supply
		{kVacVGateV, 12,	@"PRV",			kManualOnlyShowClosed,		640, 150,	3,kUpToAir,	kControlNone},	//PRV
		{kVacVGateV, 13,	@"PRV",			kManualOnlyShowClosed,		350, 350,	2,kUpToAir,	kControlNone},	//PRV
		{kVacVGateV, 14,	@"C1",			kManualOnlyShowChanging,	400, 600,	4,4,		kControlNone},	//Manual only
		{kVacHGateV, 15,	@"B5",			k1BitReadBack,				50, 200,	7,8,		kControlRight},	//future control
		{kVacHGateV, 16,	@"Turbo",		k1BitReadBack,				50, 260,	0,8,		kControlNone},	//this is a virtual valve-- really the turbo on/off
		{kVacVGateV, 17,	@"PRV",			kManualOnlyShowClosed,		230, 350,	1,kUpToAir,	kControlNone},	//PRV
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
		ORVacuumStaticLabel* aLabel = [[ORVacuumStaticLabel alloc] initWithDelegate:self partTag: labelItems[i].partTag label:labelItems[i].label bounds:theBounds];
		aLabel.drawBox = labelItems[i].drawBox;
		[aLabel release];
	}
}

- (void) makeDynamicLabels:(VacuumDynamicLabelInfo*)labelItems num:(int)numItems
{
	int i;
	for(i=0;i<numItems;i++){
		NSRect theBounds = NSMakeRect(labelItems[i].x1,labelItems[i].y1,labelItems[i].x2-labelItems[i].x1,labelItems[i].y2-labelItems[i].y1);
		[[[ORVacuumDynamicLabel alloc] initWithDelegate:self partTag: labelItems[i].partTag label:labelItems[i].label bounds:theBounds] autorelease];
	}
}

- (void) makeLines:(VacuumLineInfo*)lineItems num:(int)numItems
{
	int i;
	for(i=0;i<numItems;i++){
		[[[ORVacuumLine alloc] initWithDelegate:self partTag:0 startPt:NSMakePoint(lineItems[i].x1, lineItems[i].y1) endPt:NSMakePoint(lineItems[i].x2, lineItems[i].y2)] autorelease];
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
	//this routine is called recursively, so do not reset the visitation flag in this routine.
	NSArray* pipes = [self pipesForRegion:aRegion];
	for(id aPipe in pipes){
		if([aPipe visited])return;
		[aPipe setRegionColor:aColor];
		[aPipe setVisited:YES];
	}
	NSArray* gateValves = [self gateValvesConnectedTo:(int)aRegion];
	for(id aGateValve in gateValves){
		int state = [aGateValve state];
		if(state!=kGVClosed){
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
@end
