//
//  ORVacuumParts.m
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

#import "ORVacuumParts.h"
#import "ORAlarm.h"

NSString* ORVacuumPartChanged = @"ORVacuumPartChanged";
//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@implementation ORVacuumPart
@synthesize dataSource,partTag,state,value,visited;
- (id) initWithDelegate:(id)aDelegate partTag:(int)aTag
{
	self = [super init];
	self.partTag = aTag;
	if([aDelegate respondsToSelector:@selector(addPart:)] && [aDelegate respondsToSelector:@selector(colorRegions)]){
		self.dataSource = aDelegate;
		self.state   = 0;
		self.value   = 0.0;
		self.visited = NO;
		[aDelegate addPart:self];
	}
	return self;
}

- (void) normalize { /*do nothing subclasses must override*/ }
- (void) draw { }
- (void) setState:(int)aState
{
	if(aState != state){
		state = aState;
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORVacuumPartChanged object:dataSource];
	}
}
- (void) setValue:(float)aValue
{
	if(fabs(aValue-value) > 1.0E-8){
		value = aValue;
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORVacuumPartChanged object:dataSource];
	}
	
}

@end

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@implementation ORVacuumPipe
@synthesize startPt,endPt,regionColor;
- (id) initWithDelegate:(id)aDelegate partTag:(int)aTag startPt:(NSPoint)aStartPt endPt:(NSPoint)anEndPt
{
	self = [super initWithDelegate:aDelegate partTag:aTag];
	self.startPt		 = aStartPt;
	self.endPt			 = anEndPt;
	self.regionColor = [NSColor lightGrayColor]; //default
	[self normalize];
	return self;
}

- (void) dealloc
{
	self.regionColor = nil;
	[super dealloc];
}

- (void) setRegionColor:(NSColor*)aColor
{
	if(![aColor isEqual: regionColor]){
		[aColor retain];
		[regionColor release];
		regionColor = aColor;
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORVacuumPartChanged object:dataSource];
	}
	
}

- (void) draw 
{ 
	if([dataSource showGrid]){
		NSAttributedString* s = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d",partTag]
																 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																			 [NSColor blackColor],NSForegroundColorAttributeName,
																			 [NSFont fontWithName:@"Geneva" size:9],NSFontAttributeName,
																			 nil]] autorelease]; 
		NSSize size = [s size]; 
		float x_pos = (endPt.x - startPt.x)/2. - size.width/2.;
		float y_pos = (endPt.y - startPt.y)/2. - size.height/2.;
		
		[s drawAtPoint:NSMakePoint(startPt.x + x_pos, startPt.y + y_pos)];
	}
}

@end


//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@implementation ORVacuumHPipe
- (void) normalize 
{ 
	NSPoint p1  = NSMakePoint(MIN(startPt.x,endPt.x),startPt.y);
	NSPoint p2  = NSMakePoint(MAX(startPt.x,endPt.x),startPt.y);
	startPt = p1;
	endPt   = p2;
}

- (void) draw 
{
	[PIPECOLOR set];
	float length = endPt.x - startPt.x;
	[NSBezierPath fillRect:NSMakeRect(startPt.x,startPt.y-kPipeRadius,length,kPipeDiameter)];
	[regionColor set];
	[NSBezierPath fillRect:NSMakeRect(startPt.x-kPipeThickness,startPt.y-kPipeRadius+kPipeThickness,length+2*kPipeThickness,kPipeDiameter-2*kPipeThickness)];
	[[NSColor blackColor] set];
	[super draw];
}
@end

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@implementation ORVacuumBigHPipe
- (void) draw 
{
	[PIPECOLOR set];
	float length = endPt.x - startPt.x;
	[NSBezierPath fillRect:NSMakeRect(startPt.x,startPt.y-2*kPipeRadius,length,2*kPipeDiameter)];
	[regionColor set];
	[NSBezierPath fillRect:NSMakeRect(startPt.x-kPipeThickness,startPt.y-2*kPipeRadius+kPipeThickness,length+2*kPipeThickness,2*kPipeDiameter-2*kPipeThickness)];
	[[NSColor blackColor] set];
	[super draw];
}
@end
//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@implementation ORVacuumVPipe
- (void) normalize 
{ 
	NSPoint p1  = NSMakePoint(startPt.x,MIN(startPt.y,endPt.y));
	NSPoint p2  = NSMakePoint(startPt.x,MAX(startPt.y,endPt.y));
	startPt = p1;
	endPt   = p2;
}

- (void) draw 
{
	[PIPECOLOR set];
	float length = endPt.y - startPt.y;
	[NSBezierPath fillRect:NSMakeRect(startPt.x-kPipeRadius,startPt.y,kPipeDiameter,length)];
	[regionColor set];
	[NSBezierPath fillRect:NSMakeRect(startPt.x-kPipeRadius+kPipeThickness,startPt.y-kPipeThickness,kPipeDiameter-2*kPipeThickness,length+2*kPipeThickness)];
	[[NSColor blackColor] set];
	[super draw];
}
@end


//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@implementation ORVacuumCPipe
@synthesize location;
- (id) initWithDelegate:(id)aDelegate partTag:(int)aTag at:(NSPoint)aPoint
{
	self = [super initWithDelegate:aDelegate partTag:aTag];
	self.location = aPoint;
	self.regionColor = [NSColor lightGrayColor]; //default
	return self;			
}

- (void) draw 
{
	[PIPECOLOR set];
	[NSBezierPath fillRect:NSMakeRect(location.x-kPipeRadius,location.y-kPipeRadius,kPipeDiameter,kPipeDiameter)];
	[regionColor set];
	[NSBezierPath fillRect:NSMakeRect(location.x-kPipeRadius+kPipeThickness,location.y-kPipeRadius+kPipeThickness,kPipeDiameter-2*kPipeThickness,kPipeDiameter-2*kPipeThickness)];
	[[NSColor blackColor] set];
	[super draw];
}
@end

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@implementation ORVacuumBox
@synthesize bounds;
- (id) initWithDelegate:(id)aDelegate partTag:(int)aTag bounds:(NSRect)aRect
{
	self = [super initWithDelegate:aDelegate partTag:aTag];
	self.bounds = aRect;
	self.regionColor = [NSColor lightGrayColor]; //default
	return self;			
}

- (void) draw 
{
	[PIPECOLOR set];
	[NSBezierPath fillRect:bounds];
	[regionColor set];
	[NSBezierPath fillRect:NSInsetRect(bounds, kPipeThickness, kPipeThickness)];
	[[NSColor blackColor] set];
	[super draw];
}
@end


//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@implementation ORVacuumGateValve
@synthesize location,connectingRegion1,connectingRegion2,controlPreference,label,controlType,valveAlarm;
@synthesize controlObj,controlChannel,vetoed,commandedState;

- (id) initWithDelegate:(id)aDelegate partTag:(int)aTag label:(NSString*)aLabel controlType:(int)aControlType at:(NSPoint)aPoint connectingRegion1:(int)aRegion1 connectingRegion2:(int)aRegion2
{
	self = [super initWithDelegate:aDelegate partTag:aTag];
	self.location			= aPoint;
	self.connectingRegion1	= aRegion1;
	self.connectingRegion2	= aRegion2;
	self.label				= aLabel;
	self.controlType		= aControlType;
	firstTime = YES;
	return self;
}
		
- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
	self.label		= nil;
	[valveAlarm clearAlarm];
	self.valveAlarm = nil;
	[super dealloc];
}

- (void) setVetoed:(BOOL)aState
{
	vetoed = aState;
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORVacuumPartChanged object:dataSource];
}

- (void) setCommandedState:(int)aState
{
	commandedState = aState;
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
	[self checkState];
}

- (void) checkState
{
	if(commandedState == kGVNoCommandedState){
		[self performSelectorOnMainThread:@selector(clearAlarmState) withObject:nil waitUntilDone:NO];
	}
	else {
		if(commandedState == kGVCommandOpen && state == kGVOpen){
			[self performSelectorOnMainThread:@selector(clearAlarmState) withObject:nil waitUntilDone:NO];
		}
		else if(commandedState == kGVCommandClosed && state == kGVClosed){
			[self performSelectorOnMainThread:@selector(clearAlarmState) withObject:nil waitUntilDone:NO];
		}
		else {
			[self performSelectorOnMainThread:@selector(startStuckValveTimer) withObject:nil waitUntilDone:NO];
		}
	}
}

- (void) setState:(int)aState
{
	if(aState != state || firstTime){
		state = aState;
		
		[dataSource colorRegions];
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORVacuumPartChanged object:dataSource];
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
		
		[self checkState];
		firstTime = NO;
	}
}

- (void) startStuckValveTimer
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
	[self performSelector:@selector(timeout) withObject:nil afterDelay:10];
}

- (void) clearAlarmState
{
	[valveAlarm clearAlarm];
	self.valveAlarm = nil;
}

- (void) timeout
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
	if(!valveAlarm){
		NSString* s = [NSString stringWithFormat:@"%@ Valve Alarm",self.label];
		ORAlarm* anAlarm = [[ORAlarm alloc] initWithName:s severity:kHardwareAlarm];
		self.valveAlarm = anAlarm;
		[anAlarm release];
		[valveAlarm setSticky:YES];
		[valveAlarm setHelpString:@"This valve is either stuck or the command state does not match the actual state."];
	}
	[valveAlarm postAlarm];
}

@end

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@implementation ORVacuumVGateValve

- (void) draw 
{
	[PIPECOLOR set];
	[NSBezierPath fillRect:NSMakeRect(location.x-kGateValveHousingWidth/2.,location.y+kPipeRadius,kGateValveHousingWidth,2*kPipeThickness)]; //above pipe part
	[NSBezierPath fillRect:NSMakeRect(location.x-kGateValveHousingWidth/2.,location.y-kPipeRadius-2*kPipeThickness,kGateValveHousingWidth,2*kPipeThickness)]; //below pipe part
	[[NSColor blackColor] set];	
	
	int theState;
	if(controlType == kManualOnlyShowClosed)	  theState   = kGVClosed;
	else if(controlType == kManualOnlyShowChanging) theState = kGVChanging;
	else {
		if(self.vetoed)[[NSColor redColor] set];
		theState = state;
	}
	
	[NSBezierPath fillRect:NSMakeRect(location.x-kPipeThickness,location.y-kPipeRadius-kPipeThickness,2*kPipeThickness,2*kPipeThickness)];
	[NSBezierPath fillRect:NSMakeRect(location.x-kPipeThickness,location.y+kPipeRadius-kPipeThickness,2*kPipeThickness,2*kPipeThickness)];
	
	switch(theState){
		case kGVOpen: break; //open
		case kGVClosed: //closed
			[NSBezierPath setDefaultLineWidth:2*kPipeThickness];
			[NSBezierPath strokeLineFromPoint:NSMakePoint(location.x,location.y-kPipeRadius) toPoint:NSMakePoint(location.x,location.y+kPipeRadius)];
			[NSBezierPath setDefaultLineWidth:0];
			break;
		default:
			{
				NSBezierPath* aPath = [NSBezierPath bezierPath];
				const float pattern[2] = {1.0,1.0};
				[aPath setLineWidth:2*kPipeThickness];
				[aPath setLineDash:pattern count:2 phase:0];
				[aPath moveToPoint:NSMakePoint(location.x,location.y-kPipeRadius)];
				[aPath lineToPoint:NSMakePoint(location.x,location.y+kPipeRadius)];
				[aPath stroke];
			}
			break;
	}
	if([dataSource showGrid]){
		NSAttributedString* s = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d",partTag]
																 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																			 [NSColor blackColor],NSForegroundColorAttributeName,
																			 [NSFont fontWithName:@"Geneva" size:9],NSFontAttributeName,
																			 nil]] autorelease]; 
		float x_pos = kGateValveHousingWidth/2.;
		float y_pos = kPipeRadius + 2*kPipeThickness;
		
		[s drawAtPoint:NSMakePoint(location.x + x_pos+2, location.y + y_pos - 3)];
	}
	[[NSColor blackColor] set];
}

@end

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@implementation ORVacuumHGateValve
- (void) draw 
{
	[PIPECOLOR set];
	[NSBezierPath fillRect:NSMakeRect(location.x-kPipeRadius - 2*kPipeThickness,location.y-kGateValveHousingWidth/2.,2*kPipeThickness,kGateValveHousingWidth)]; //left of pipe part
	[NSBezierPath fillRect:NSMakeRect(location.x+kPipeRadius,location.y-kGateValveHousingWidth/2.,2*kPipeThickness,kGateValveHousingWidth)]; //below pipe part

	int theState;
	[[NSColor blackColor] set];	
	if(controlType == kManualOnlyShowClosed)	  theState = kGVClosed;
	else if(controlType == kManualOnlyShowChanging) theState = kGVChanging;
	else {
		if(self.vetoed)[[NSColor redColor] set];
		theState = state;
	}
	
	[NSBezierPath fillRect:NSMakeRect(location.x-kPipeRadius-kPipeThickness,location.y-kPipeThickness,2*kPipeThickness,2*kPipeThickness)];
	[NSBezierPath fillRect:NSMakeRect(location.x+kPipeRadius-kPipeThickness,location.y-kPipeThickness,2*kPipeThickness,2*kPipeThickness)];

	switch(theState){
		case kGVOpen: break; //open
		case kGVClosed: //closed
			[NSBezierPath setDefaultLineWidth:2*kPipeThickness];
			[NSBezierPath strokeLineFromPoint:NSMakePoint(location.x-kPipeRadius,location.y) toPoint:NSMakePoint(location.x+kPipeRadius,location.y)];
			[NSBezierPath setDefaultLineWidth:0];
			break;
		default:
		{
			NSBezierPath* aPath = [NSBezierPath bezierPath];
			const float pattern[2] = {1.0,1.0};
			[aPath setLineWidth:2*kPipeThickness];
			[aPath setLineDash:pattern count:2 phase:0];
			[aPath moveToPoint:NSMakePoint(location.x-kPipeRadius,location.y)];
			[aPath lineToPoint:NSMakePoint(location.x+kPipeRadius,location.y)];
			[aPath stroke];
		}
			break;
	}
	if([dataSource showGrid]){
		NSAttributedString* s = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d",partTag]
																 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																			 [NSColor blackColor],NSForegroundColorAttributeName,
																			 [NSFont fontWithName:@"Geneva" size:9],NSFontAttributeName,
																			 nil]] autorelease]; 
		float x_pos = kPipeRadius + 2*kPipeThickness;
		float y_pos = kGateValveHousingWidth/2.;
		
		[s drawAtPoint:NSMakePoint(location.x + x_pos, location.y + y_pos)];
	}
	[[NSColor blackColor] set];
}
@end

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@implementation ORVacuumStaticLabel
@synthesize label,bounds,gradient,controlColor,drawBox;
- (id) initWithDelegate:(id)aDelegate partTag:(int)aTag label:(NSString*)aLabel bounds:(NSRect)aRect
{
	self = [super initWithDelegate:aDelegate partTag:aTag];
	self.bounds       = aRect;
	self.label        = aLabel;
	self.drawBox	  = YES;
	self.controlColor = [NSColor colorWithCalibratedRed:.75 green:.75 blue:.75 alpha:1];
	return self;
}

- (void) dealloc
{
	self.label			= nil;
	self.gradient		= nil;
	self.controlColor	= nil;
	[super dealloc];
}

- (void) setControlColor:(NSColor*)aColor
{
	self.gradient		= nil;
	[aColor retain];
	[controlColor release];
	controlColor = aColor;

	float red,green,blue,alpha;
		
	[controlColor getRed:&red green:&green blue:&blue alpha:&alpha];
	red = MIN(1.0,red*1.5);
	green = MIN(1.0,green*1.5);
	blue = MIN(1.0,blue*1.5);
	NSColor* endingColor = [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:1];
	self.gradient = [[NSGradient alloc] initWithStartingColor:controlColor endingColor:endingColor];
	
}

- (void) draw 
{
	if(drawBox){
		[[NSColor blackColor] set];
		[NSBezierPath strokeRect:bounds];
		[gradient drawInRect:bounds angle:90.];
	}
	
	if([label length]){
		
		[[NSColor blackColor] set];
		NSAttributedString* s = [[[NSAttributedString alloc] initWithString:label
																 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																			 [NSColor blackColor],NSForegroundColorAttributeName,
																			 [NSFont fontWithName:@"Geneva" size:10],NSFontAttributeName,
																			 nil]] autorelease]; 
		NSSize size = [s size];   
		float x_pos = (bounds.size.width - size.width) / 2; 
		float y_pos = (bounds.size.height - size.height) /2; 
		[s drawAtPoint:NSMakePoint(bounds.origin.x + x_pos, bounds.origin.y + y_pos)];
	}
	[[NSColor blackColor] set];
}
@end

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@implementation ORVacuumDynamicLabel
- (id) initWithDelegate:(id)aDelegate partTag:(int)aTag label:(NSString*)aLabel bounds:(NSRect)aRect
{
	self = [super initWithDelegate:aDelegate partTag:aTag label:aLabel bounds:aRect];
	self.controlColor = [NSColor colorWithCalibratedRed:.5 green:.75 blue:.5 alpha:1];
	return self;
}

- (void) draw 
{
	[[NSColor blackColor] set];
	[NSBezierPath strokeRect:bounds];
 	[gradient drawInRect:bounds angle:90.];
	
	if([label length]){
		
		NSAttributedString* s1 = [[[NSAttributedString alloc] initWithString:label
																 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																			 [NSColor blackColor],NSForegroundColorAttributeName,
																			 [NSFont fontWithName:@"Geneva" size:10],NSFontAttributeName,
																			 nil]] autorelease]; 
		NSSize size1 = [s1 size];   
		float x_pos = (bounds.size.width - size1.width) / 2; 
		float y_pos = bounds.size.height/2;
		[s1 drawAtPoint:NSMakePoint(bounds.origin.x + x_pos, bounds.origin.y + y_pos)];

		NSAttributedString* s2 = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%.2E",[self value]]
																 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																			 [NSColor blackColor],NSForegroundColorAttributeName,
																			 [NSFont fontWithName:@"Geneva" size:10],NSFontAttributeName,
																			 nil]] autorelease]; 
		
		NSSize size2 = [s2 size];   
		x_pos = (bounds.size.width - size2.width) / 2; 
		y_pos = (bounds.size.height/2 - size2.height); 
		[s2 drawAtPoint:NSMakePoint(bounds.origin.x + x_pos, bounds.origin.y + y_pos)];
		
	}
	
	if([dataSource showGrid]){
		NSAttributedString* s = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d",partTag]
																 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																			 [NSColor blackColor],NSForegroundColorAttributeName,
																			 [NSFont fontWithName:@"Geneva" size:9],NSFontAttributeName,
																			 nil]] autorelease]; 
		float x_pos = bounds.origin.x;
		float y_pos = bounds.origin.y + bounds.size.height;
		
		[s drawAtPoint:NSMakePoint(x_pos, y_pos)];
	}
	
	[[NSColor blackColor] set];
}
@end

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@implementation ORVacuumLine
@synthesize startPt,endPt;
- (id) initWithDelegate:(id)aDelegate partTag:(int)aTag startPt:(NSPoint)aStartPt endPt:(NSPoint)anEndPt
{
	self = [super initWithDelegate:aDelegate partTag:aTag];
	self.startPt	= aStartPt;
	self.endPt		= anEndPt;
	return self;
}

- (void) draw 
{
	[[NSColor blackColor] set];
	[NSBezierPath strokeLineFromPoint:startPt toPoint:endPt];
	[[NSColor blackColor] set];
}	
@end

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@implementation ORGateValveControl
@synthesize location;
- (id) initWithDelegate:(id)aDelegate partTag:(int)aTag at:(NSPoint)aPoint; 
{
	self = [super initWithDelegate:aDelegate partTag:aTag];
	self.location = aPoint;
	return self;
}

@end
