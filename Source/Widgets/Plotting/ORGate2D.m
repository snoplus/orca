//
//  ORGate2D.m
//  Orca
//
//  Created by Mark Howe on 2/16/08.
//  Copyright 2008 CENPA, University of Washington. All rights reserved.
//
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

#import "ORGate2D.h"
#import "ORPlotter2D.h"
#import "ORGateKey.h"
#import "ORGateGroup.h"
#import "ORAxis.h"
#import "ORCurve2D.h"

@implementation ORGate2D
- (id) initForCurve:(ORCurve2D*)aCurve
{
	self = [self init];
	mCurve = aCurve;
	return self;
}

- (id) init
{
	self = [super init];
	[self setPoints:[NSMutableArray array]];
	[points addObject: [ORPoint point:NSMakePoint(50,50)]];
	[points addObject: [ORPoint point:NSMakePoint(50,100)]];
	[points addObject: [ORPoint point:NSMakePoint(100,100)]];
	[points addObject: [ORPoint point:NSMakePoint(100,50)]];
	drawControlPoints = NO;
	return self;
}

- (void) dealloc
{
	[points dealloc];
	[theGatePath dealloc];
	[super dealloc];
}

- (NSArray*)points
{
	return points;
}

- (void) setPoints:(NSMutableArray*)somePoints
{
	[somePoints retain];
	[points release];
	points = somePoints;
}

- (void) drawGateInPlot:(ORPlotter2D*)aPlot
{
	if([points count]){
		ORAxis* yAxis = [aPlot yScale];
        ORAxis* xAxis = [aPlot xScale];

		if(cmdKeyIsDown || drawControlPoints){
			[points makeObjectsPerformSelector:@selector(drawPointInPlot:) withObject:aPlot];
		}
		
		[theGatePath release];
		
		theGatePath = [[NSBezierPath bezierPath] retain];
		
		int n = [points count];
		int i;


		NSPoint aPoint = [[points objectAtIndex:0] xyPosition];
		NSPoint aConvertedPoint1 = NSMakePoint([xAxis getPixAbs:aPoint.x],
											   [yAxis getPixAbs:aPoint.y]);
	
		[theGatePath moveToPoint:aConvertedPoint1];

		for(i=1;i<n;i++){
			NSPoint aPoint = [[points objectAtIndex:i] xyPosition];
			NSPoint aConvertedPoint = NSMakePoint([xAxis getPixAbs:aPoint.x],
													   [yAxis getPixAbs:aPoint.y]);
			[theGatePath lineToPoint:aConvertedPoint];
		}
		[theGatePath lineToPoint:aConvertedPoint1];


		[[NSColor redColor] set];
		[theGatePath setLineWidth:1];
		[theGatePath stroke];
	}
}

- (void) mouseDown:(NSEvent*)theEvent plotter:(ORPlotter2D*)aPlotter
{
	if(drawControlPoints || cmdKeyIsDown) {
		NSPoint localPoint = [aPlotter convertPoint:[theEvent locationInWindow] fromView:nil];
		NSEnumerator* e = [points objectEnumerator];
		ORPoint* aPoint;
		mouseIsDown = YES;
		dragWholePath = NO;
		while(aPoint = [e nextObject]){
		
			float x = [[aPlotter xScale] getPixAbs:[aPoint xyPosition].x];
			float y = [[aPlotter yScale] getPixAbs:[aPoint xyPosition].y];
			NSRect pointframe = NSMakeRect(x-kPointSize/2,y-kPointSize/2, kPointSize,kPointSize);

			if(NSPointInRect(localPoint ,pointframe)){
				selectedPoint = aPoint;
				if(cmdKeyIsDown){
					ORPoint* p = [[ORPoint alloc] initWithPoint:[selectedPoint xyPosition]];
					[points insertObject:p atIndex:[points indexOfObject: selectedPoint]+1];
					selectedPoint = p;
					[p release];
				}
			}
		}
		
		if(!selectedPoint){
			if([theGatePath containsPoint:localPoint]){
				dragStartPoint.y = [[aPlotter yScale] getValAbs:localPoint.y];
				dragStartPoint.x = [[aPlotter xScale] getValAbs:localPoint.x];

				dragWholePath = YES;
			}
		}
		
		[aPlotter setNeedsDisplay:YES];	
	}
}

- (void) mouseDragged:(NSEvent*)theEvent plotter:(ORPlotter2D*)aPlotter;
{

	NSPoint localPoint = [aPlotter convertPoint:[theEvent locationInWindow] fromView:nil];
	localPoint.y = [[aPlotter yScale] getValAbs:localPoint.y];
	localPoint.x = [[aPlotter xScale] getValAbs:localPoint.x];
	if(selectedPoint){
		[selectedPoint setXyPosition:localPoint];
	}
	else if(dragWholePath){
		NSEnumerator* e = [points objectEnumerator];
		ORPoint* aPoint;
		float deltaX = localPoint.x - dragStartPoint.x;
		float deltaY = localPoint.y - dragStartPoint.y;
		while(aPoint = [e nextObject]){
			if(aPoint != selectedPoint){
				float x = [aPoint xyPosition].x + deltaX;
				float y = [aPoint xyPosition].y + deltaY;
				[aPoint setXyPosition:NSMakePoint(x,y)];
			}
		}
		dragStartPoint = localPoint;
	}

	[theGatePath release];
	theGatePath = nil;
	[aPlotter setNeedsDisplay:YES];	
}

- (void) mouseUp:(NSEvent*)theEvent plotter:(ORPlotter2D*)aPlotter
{
	
	mouseIsDown = NO;
	NSPoint localPoint = [aPlotter convertPoint:[theEvent locationInWindow] fromView:nil];
	if(selectedPoint){


		localPoint.y = [[aPlotter yScale] getValAbs:localPoint.y];
		localPoint.x = [[aPlotter xScale] getValAbs:localPoint.x];
		[selectedPoint setXyPosition:localPoint];

		NSPoint theSelectedPoint = NSMakePoint([[aPlotter xScale] getPixAbs:[selectedPoint xyPosition].x],[[aPlotter yScale] getPixAbs:[selectedPoint xyPosition].y]);
		NSEnumerator* e = [points objectEnumerator];
		ORPoint* aPoint;
		while(aPoint = [e nextObject]){
			if(aPoint != selectedPoint){
				float x = [[aPlotter xScale] getPixAbs:[aPoint xyPosition].x];
				float y = [[aPlotter yScale] getPixAbs:[aPoint xyPosition].y];
				NSRect pointframe = NSMakeRect(x-kPointSize/2,y-kPointSize/2, kPointSize,kPointSize);
				if(NSPointInRect(theSelectedPoint ,pointframe)){
					if([points count]>3)[points removeObject:aPoint];
					break;
				}
			}
		}
	}

	dragWholePath = NO;
	selectedPoint = nil;

	[theGatePath release];
	theGatePath = nil;
	
	[aPlotter setNeedsDisplay:YES];	
}

- (void)flagsChanged:(NSEvent *)theEvent plotter:(ORPlotter2D*)aPlotter
{
	cmdKeyIsDown = ([theEvent modifierFlags] & NSCommandKeyMask)!=0;
	if(cmdKeyIsDown)drawControlPoints = !drawControlPoints;
	[aPlotter setNeedsDisplay:YES];

}

- (void) analyzePlot:(ORPlotter2D*)aPlot
{
    long		sumVal;
 
    if(theGatePath /*&& analyze*/){
  
		NSBezierPath* channelPath = [NSBezierPath bezierPath];
		
		int n = [points count];
		int i;

		if(n){
			//make a path that is in the channel coords		
			[channelPath moveToPoint:[[points objectAtIndex:0] xyPosition]];
			for(i=1;i<n;i++)[channelPath lineToPoint:[[points objectAtIndex:i] xyPosition]];
			[channelPath lineToPoint:[[points objectAtIndex:0] xyPosition]];
			[channelPath closePath];
						
			id mDataSource = [aPlot dataSource];
			int dataSet = [mCurve dataSetID];
			unsigned short numBinsPerSide;
			unsigned long* data = [mDataSource plotter:aPlot dataSet:dataSet numberBinsPerSide:&numBinsPerSide];
		
			sumVal  = 0;
			
			NSRect gateBounds = [channelPath bounds];
			long xStart = gateBounds.origin.x;
			long yStart = gateBounds.origin.y;
			long xEnd   = gateBounds.origin.x + gateBounds.size.width;
			long yEnd   = gateBounds.origin.y + gateBounds.size.height;
			long x,y;
			for (y=yStart; y<yEnd; ++y) {
				for (x=xStart; x<xEnd; ++x) {
					if([channelPath containsPoint:NSMakePoint(x,y)]){
						unsigned long z = data[x + y*numBinsPerSide];
						sumVal += z;
					}
				}
			}
			NSLog(@"sum: %d\n",sumVal);
		}
    }
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    if([coder allowsKeyedCoding]){
		[coder encodeObject:points forKey:@"points"];
    }
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if([coder allowsKeyedCoding]){
		[self setPoints:[coder decodeObjectForKey:@"points"]];    
    }
    return self;
}

@end

@implementation ORPoint

NSString* ORPointChanged = @"ORPointChanged";

+ (id) point:(NSPoint)aPoint
{
	return [[[ORPoint alloc] initWithPoint:aPoint] autorelease];
}

- (id) initWithPoint:(NSPoint)aPoint
{
	[super init];
	[self setXyPosition:aPoint];
	return self;
}

- (NSPoint) xyPosition
{
	return xyPosition;
}

- (void) setXyPosition:(NSPoint)aPoint
{
	xyPosition = aPoint;
}
- (void) drawPointInPlot:(ORPlotter2D*)aPlotter
{
	NSPoint aConvertedPoint = NSMakePoint([[aPlotter xScale] getPixAbs:xyPosition.x],
										  [[aPlotter yScale] getPixAbs:xyPosition.y]);
	NSRect r = NSMakeRect(aConvertedPoint.x-3,aConvertedPoint.y-kPointSize/2,kPointSize,kPointSize);
	[[NSColor yellowColor] set];
	[NSBezierPath fillRect:r];
	[[NSColor blackColor] set];
	[NSBezierPath strokeRect:r];
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
	
	xyPosition.x = [decoder decodeFloatForKey:@"x"];
	xyPosition.y = [decoder decodeFloatForKey:@"y"];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{

    [encoder encodeFloat:xyPosition.x forKey:@"x"];
    [encoder encodeFloat:xyPosition.y forKey:@"y"];
}

@end

