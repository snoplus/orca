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
- (void) makePipes:(VacuumPipeInfo*)pipeList num:(int)numItems goodColor:(NSColor*)aGoodColor badColor:(NSColor*)aBadColor;
- (void) makeGateValves:(VacuumGVInfo*)pipeList num:(int)numItems;
- (void) makeStaticLabels:(VacuumStaticLabelInfo*)labelItems num:(int)numItems;
- (void) makeDynamicLabels:(VacuumDynamicLabelInfo*)labelItems num:(int)numItems;
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

- (int) stateOfRegion:(int)aTag
{
	switch(aTag){
		case 0: return YES;
		case 1: return NO;
		case 2: return YES;
		case 3: return NO;
		case 4: return NO;
		case 5: return NO;
		case 6: return NO;
		case 7: return NO;
		case 8: return NO; //N2 Supply Side
		case 9: return YES;
		case 10: return YES;
			
			
		default: return NO;
	}
}

- (int) stateOfGateValve:(int)aTag
{
	return [[self gateValve:aTag] state];
}

- (NSArray*) pipesForRegion:(int)aTag
{
	return [[partDictionary objectForKey:@"Regions"] objectForKey:[NSNumber numberWithInt:aTag]];
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
	
#define kNumVacPipes		43
	VacuumPipeInfo vacPipeList[kNumVacPipes] = {
		//region 0 pipes
		{ kVacVPipe,  0,	 50,			 200+kPipeRadius,	50,					450 }, 
		{ kVacHPipe,  0,	 50+kPipeRadius, 400,				150+kPipeRadius,	400 },
		{ kVacVPipe,  0, 100,			 400-kPipeRadius,	100,				300 },
		//region 1 pipes
		{ kVacVPipe,  1, 500,			  150,				500,				250 },
		{ kVacHPipe,  1, 150,			  400,				300,				400 },
		{ kVacHPipe,  1, 150,			  200,				500-kPipeRadius,	200 },
		{ kVacVPipe,  1, 240,			  200+kPipeRadius,	240,				400-kPipeRadius },
		{ kVacVPipe,  1, 240,			  400+kPipeRadius,	240,				420 },
		{ kVacVPipe,  1, 200,			  400+kPipeRadius,	200,				450 },
		//region 2 pipes
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
		//region 4 is done separately for cryo so a diff color can be used.
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
		//region 6 pipes
		{ kVacVPipe,  6, 500,			  250,				500,				350 },
		{ kVacHPipe,  6, 460,			  300,				500-kPipeRadius,	300 },
		//region 7 pipes (N2 side)
		{ kVacHPipe,  7, 250,			  80,				280,				80 },
	};
		
#define kNumStaticVacLabelItems	7
	VacuumStaticLabelInfo staticLabelItems[kNumStaticVacLabelItems] = {
		{kVacStaticLabel,  8, @"Dry N2\nSupply",	150,  60,	250, 100},
		{kVacStaticLabel, 10, @"Turbo",				20,	 260,	80,	 290},
		{kVacStaticLabel, 10, @"Vacuum\nSentry",	20,	 220,	80,	 250},
		{kVacStaticLabel, 10, @"Diaphragm\nPump",	20,	 180,	80,	 210},
		{kVacStaticLabel, 10, @"RGA",				220, 420,	260, 440},
		{kVacStaticLabel, 10, @"NEG Pump",			400, 290,	460, 310},
		{kVacStaticLabel, 10, @"Cryo Pump",			570, 155,	630, 185},
	};	
	
#define kNumDynamicVacLabelItems	5
	VacuumDynamicLabelInfo dynamicLabelItems[kNumDynamicVacLabelItems] = {
		{kVacDynamicLabel, 0, @"PKR G1",	20,	 450,	80,	 490},
		{kVacDynamicLabel, 1, @"PKR G2",	170, 450,	230, 490},
		{kVacDynamicLabel, 2, @"PKR G3",	370, 450,	430, 490},
		{kVacDynamicLabel, 3, @"PKR G4",	620, 280,	680, 320},
		{kVacDynamicLabel, 4, @"Baratron",	330, 520,	390, 550},
	};	
	
#define kNumCryoPipes		9
	VacuumPipeInfo cryoPipes[kNumCryoPipes] = {
		//region 9 pipes
		{ kVacBox,	  4, 470,			  570,				530,				620 },
		{ kVacBox,	  4, 270,			  570,				330,				620 },
		{ kVacCorner, 4, 500,			  525,				kNA,				kNA },
		{ kVacCorner, 4, 650,			  525,				kNA,				kNA },
		{ kVacHPipe,  4, 500+kPipeRadius, 525,				650-kPipeRadius,	525 },
		{ kVacVPipe,  4, 500,			  525+kPipeRadius,	500,				570 },
		{ kVacHPipe,  4, 330,			  600,				400,				600 },
		{ kVacHPipe,  4, 400,			  600,				470,				600 },
		{ kVacVPipe,  4, 360,			  550,				360,				600-kPipeRadius },
	};
		
	
#define kNumVacLines 10
	VacuumLineInfo vacLines[kNumVacLines] = {
		{kVacLine, 150,400,150,430},  //V1
		{kVacLine, 300,400,300,430},  //V2
		{kVacLine, 600,350,620,350},  //V3
		{kVacLine, 450,350,500,350},  //V4
		{kVacLine, 450,250,500,250},  //V5
		{kVacLine, 450,150,500,150},  //V6
	
		{kVacLine, 100,300,120,300},  //Bellows
		{kVacLine, 150,200,150,230},  //Bellows
		{kVacLine, 550,70,600,70},  //Bellows
		{kVacLine, 650,70,700,70},  //Bellows
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
		
		{kVacVGateV, 10,	@"Burst",		kManualOnly,	300, 300,	2,kUpToAir,	kControlNone},	//burst
		{kVacVGateV, 11,	@"N2 Manual",	kManualOnly,	280, 80,	5,kUpToAir,	kControlNone},	//Manual N2 supply
		{kVacVGateV, 12,	@"PRV",			kManualOnly,	620, 100,	3,kUpToAir,	kControlNone},	//PRV
		{kVacVGateV, 13,	@"PRV",			kManualOnly,	300, 350,	2,kUpToAir,	kControlNone},	//PRV
		{kVacVGateV, 14,	@"C1",			kManualOnly,    400, 600,	4,4,		kControlNone},	//Manual only
	};
	
	
	NSColor* cryoColor = [NSColor colorWithCalibratedRed:.6 green:.6 blue:1 alpha:1];
	NSColor* badVacColor = [NSColor colorWithCalibratedRed:1 green:.4 blue:.4 alpha:1];
	
	[self makeLines:vacLines					num:kNumVacLines];
	[self makePipes:vacPipeList					num:kNumVacPipes	goodColor:[NSColor greenColor] badColor:badVacColor];
	[self makePipes:cryoPipes					num:kNumCryoPipes	goodColor:cryoColor badColor:badVacColor];
	[self makeGateValves:gvList					num:kNumVacGVs];
	[self makeStaticLabels:staticLabelItems		num:kNumStaticVacLabelItems];
	[self makeDynamicLabels:dynamicLabelItems	num:kNumDynamicVacLabelItems];
}

- (void) makePipes:(VacuumPipeInfo*)pipeList num:(int)numItems goodColor:(NSColor*)aGoodColor badColor:(NSColor*)aBadColor
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
		if(aGoodColor)	aPipe.goodColor = aGoodColor;
		if(aBadColor)	aPipe.badColor = aBadColor;
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
}


@end
