//
//  ORVacuumParts.h
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

@class ORAlarm;

typedef struct  {
	int type;
	int partTag;
	float x1,y1,x2,y2;
} VacuumPipeInfo;

typedef struct  {
	int type;
	int partTag;
	NSString* label;
	int controlType;
	float x1,y1;
	int r1,r2;
	int conPref;
} VacuumGVInfo;

typedef struct  {
	int type;
	int partTag;
	NSString* label;
	float x1,y1,x2,y2;
} VacuumStaticLabelInfo;

typedef struct  {
	int type;
	int partTag;
	NSString* label;
	float x1,y1,x2,y2;
} VacuumDynamicLabelInfo;

typedef struct  {
	int type;
	float x1,y1,x2,y2;
} VacuumLineInfo;

#define kNA		 -1
#define kUpToAir -2

#define kVacCorner		0
#define kVacHPipe		1
#define kVacVPipe		2
#define kVacBox			3
#define kVacBigHPipe	4

#define kVacHGateV		5
#define kVacVGateV		6
#define kVacStaticLabel 7
#define kVacDynamicLabel 8
#define kVacLine		9
#define kGVControl		10

#define kGVImpossible				0
#define kGVOpen					    1
#define	kGVClosed					2	
#define kGVChanging					3


#define PIPECOLOR [NSColor darkGrayColor]
#define kPipeDiameter				12
#define kPipeRadius					(kPipeDiameter/2.)
#define kPipeThickness				2
#define kGateValveWidth				4
#define kGateValveHousingWidth		(kGateValveWidth + (3*kPipeThickness))
//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@interface ORVacuumPart : NSObject
{
	id dataSource;
	int partTag;
	int state;
	float value;
	BOOL visited;
}
- (id) initWithDelegate:(id)aDelegate partTag:(int)aTag;
- (void) normalize; 
- (void) draw;
- (void) setState:(int)aState;
- (void) setValue:(float)aState;
@property (nonatomic,assign) id dataSource;
@property (nonatomic,assign) int partTag;
@property (nonatomic,assign) BOOL visited;
@property (assign) int state;
@property (assign) float value;
@end

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@interface ORVacuumPipe : ORVacuumPart
{
	NSPoint startPt;
	NSPoint endPt;
	NSColor* regionColor;
}
@property (nonatomic,assign) NSPoint startPt;
@property (nonatomic,assign) NSPoint endPt;
@property (retain) NSColor* regionColor;
- (id) initWithDelegate:(id)aDelegate partTag:(int)aTag startPt:(NSPoint)aStartPt endPt:(NSPoint)anEndPt;
@end

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@interface ORVacuumHPipe		: ORVacuumPipe  { } @end;
@interface ORVacuumVPipe		: ORVacuumPipe  { } @end;
@interface ORVacuumBigHPipe		: ORVacuumHPipe { } @end;

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@interface ORVacuumCPipe		: ORVacuumPipe
{ 	
	NSPoint location;
} 
@property (nonatomic,assign) NSPoint location;
- (id) initWithDelegate:(id)aDelegate partTag:(int)aTag at:(NSPoint)aPoint;
@end

@interface ORVacuumBox		: ORVacuumPipe
{ 	
	NSRect bounds;
} 
@property (nonatomic,assign) NSRect bounds;
- (id) initWithDelegate:(id)aDelegate partTag:(int)aTag bounds:(NSRect)aRect;
@end

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@interface ORVacuumStaticLabel : ORVacuumPart
{
	NSString* label;
	NSRect	  bounds;
	NSGradient* gradient;
	NSColor* controlColor;
}
- (id) initWithDelegate:(id)aDelegate partTag:(int)aTag label:(NSString*)label bounds:(NSRect)aRect;
@property (nonatomic,assign) NSRect bounds;
@property (nonatomic,retain) NSGradient* gradient;
@property (nonatomic,retain) NSColor* controlColor;
@property (nonatomic,copy) NSString* label;
@end
//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@interface ORVacuumDynamicLabel : ORVacuumStaticLabel{}@end

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
#define kControlAbove 1
#define kControlBelow 2
#define kControlRight 3
#define kControlLeft  4
#define kControlNone  5

#define kManualOnlyShowClosed	  0
#define kManualOnlyShowChanging	  1
#define k2BitReadBack			  2
#define kControlOnly			  3

@interface ORVacuumGateValve : ORVacuumPart
{
	NSPoint location;
	NSString* label;
	int controlType;
	int connectingRegion1;
	int connectingRegion2;
	int	controlPreference;
	ORAlarm* valveAlarm;
	BOOL firstTime;
}
@property (nonatomic,copy)   NSString* label;
@property (nonatomic,assign) NSPoint   location;
@property (nonatomic,assign) int connectingRegion1;
@property (nonatomic,assign) int controlType;
@property (nonatomic,assign) int connectingRegion2;
@property (nonatomic,assign) int controlPreference;
@property (nonatomic,retain) ORAlarm* valveAlarm;

- (id) initWithDelegate:(id)aDelegate partTag:(int)aTag label:(NSString*)label controlType:(int)aControlType at:(NSPoint)aPoint connectingRegion1:(int)aRegion1 connectingRegion2:(int)aRegion2;
- (void) startStuckValveTimer;
- (void) clearAlarmState;
- (void) timeout;
@end

@interface ORVacuumVGateValve	: ORVacuumGateValve { } @end;
@interface ORVacuumHGateValve	: ORVacuumGateValve { } @end;

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@interface ORVacuumLine : ORVacuumPart
{
	NSPoint startPt;
	NSPoint endPt;	
}
- (id) initWithDelegate:(id)aDelegate partTag:(int)aTag startPt:(NSPoint)aStartPt endPt:(NSPoint)anEndPt;
@property (nonatomic,assign) NSPoint startPt;
@property (nonatomic,assign) NSPoint endPt;
@end

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@interface ORGateValveControl : ORVacuumPart
{
	NSPoint location;
}
@property (nonatomic,assign) NSPoint location;
- (id) initWithDelegate:(id)aDelegate partTag:(int)aTag at:(NSPoint)aPoint;
@end

extern NSString* ORVacuumPartChanged;


@interface NSObject (VacuumParts)
- (BOOL) showGrid;
- (void) addPart:(id)aPart;
- (void) colorRegions;
@end

