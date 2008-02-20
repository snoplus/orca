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

@implementation ORGate2D

- (id) init
{
	self = [super init];
	[self setPoints:[NSMutableArray array]];
	[points addObject: [ORPoint point:NSMakePoint(50,50)]];
	[points addObject: [ORPoint point:NSMakePoint(50,100)]];
	[points addObject: [ORPoint point:NSMakePoint(100,100)]];
	[points addObject: [ORPoint point:NSMakePoint(100,50)]];
	return self;
}

- (void) dealloc
{
	[points dealloc];
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
		NSBezierPath* aPath = [NSBezierPath bezierPath];
		
		int n = [points count];
		int i;
		if(cmdKeyIsDown){
			[points makeObjectsPerformSelector:@selector(drawPointInPlot:) withObject:aPlot];
		}


		NSPoint aPoint = [[points objectAtIndex:0] point];
		NSPoint aConvertedPoint1 = NSMakePoint([xAxis getPixAbs:aPoint.x],
											   [yAxis getPixAbs:aPoint.y]);
	
		[aPath moveToPoint:aConvertedPoint1];

		for(i=1;i<n;i++){
			aPoint = [[points objectAtIndex:i] point];
			NSPoint aConvertedPoint = NSMakePoint([xAxis getPixAbs:aPoint.x],
													   [yAxis getPixAbs:aPoint.y]);
			[aPath lineToPoint:aConvertedPoint];
		}
		[aPath lineToPoint:aConvertedPoint1];
		[[NSColor redColor] set];
		[aPath setLineWidth:1];
		[aPath stroke];
	}
}

- (void)	mouseDown:(NSEvent*)theEvent  plotter:(ORPlotter2D*)aPlotter
{
    if(displayGate){
        ORGateGroup* gateGroup = [[[NSApp delegate] document] gateGroup];
        cachedGate = [[gateGroup gateWithName:displayedGateName] gateKey];
        //remove our notifications to prevent conflicts while moving the mouse
        //[[NSNotificationCenter defaultCenter] removeObserver:self name:@"ORGateLowValueChangedNotification" object:nil];
        //[[NSNotificationCenter defaultCenter] removeObserver:self name:@"ORGateHighValueChangedNotification" object:nil];
    }

    NSPoint p = [aPlotter convertPoint:[theEvent locationInWindow] fromView:nil];
    if([aPlotter mouse:p inRect:[aPlotter bounds]]){
        //ORAxis* xScale = [aPlotter xScale];
       // int mouseChan = floor([xScale convertPoint:p.x]+.5);        
        if(([theEvent modifierFlags] & NSAlternateKeyMask) || (gate1 == 0 && gate2 == 0)){
        }
        else if(!([theEvent modifierFlags] & NSCommandKeyMask)){
           // if(fabs([xScale getPixAbs:startChan]-[xScale getPixAbs:[self gateMinChannel]])<3){
            //  }
           // else if(fabs([xScale getPixAbs:startChan]-[xScale getPixAbs:[self gateMaxChannel]])<3){
             //}
            //else if([xScale getPixAbs:startChan]>[xScale getPixAbs:[self gateMinChannel]] && [xScale getPixAbs:startChan]<[xScale getPixAbs:[self gateMaxChannel]]){
               // dragType = kCenterDrag;
            //}
            //else dragType = kNoDrag;
        }
       // else if(([theEvent modifierFlags] & NSCommandKeyMask) &&
        //        ([xScale getPixAbs:startChan]>=[xScale getPixAbs:[self gateMinChannel]] && [xScale getPixAbs:startChan]<=[xScale getPixAbs:[self gateMaxChannel]])){
            //dragType = kCenterDrag;
        //}
        //else dragType = kNoDrag;
        
        //if(dragType!=kNoDrag){
		//	[[NSCursor closedHandCursor] push];
		//}
        //[self setGateValid:YES];        
        //dragInProgress = YES;
        [aPlotter setNeedsDisplay:YES];
    }
}

-(void)	mouseDragged:(NSEvent*)theEvent  plotter:(ORPlotter2D*)aPlotter
{
    [self doDrag:theEvent plotter:aPlotter];
}


-(void)	mouseUp:(NSEvent*)theEvent  plotter:(ORPlotter2D*)aPlotter
{
    [self doDrag:theEvent plotter:aPlotter];
    
    if(displayGate){
        //restore our registration for gate changes.
        
        //[self registerForGateChanges];
    }
    //dragInProgress = NO;
    cachedGate = nil;
}

- (void) doDrag:(NSEvent*)theEvent  plotter:(ORPlotter2D*)aPlotter
{
  /*  
    if(dragInProgress){
        ORAxis* xScale = [aPlotter xScale];
        NSPoint p = [aPlotter convertPoint:[theEvent locationInWindow] fromView:nil];
        int delta;
        int mouseChan = ceil([xScale convertPoint:p.x]+.5);
        switch(dragType){
            case kInitialDrag:
                gate2 = mouseChan;
                if(gate2<0)gate2=0;
                [self setGateMinChannel:MIN(gate1,gate2)];
                [self setGateMaxChannel:MAX(gate1,gate2)];
            break;
            
            case kMinDrag:
                gate2 = mouseChan;
                if(gate2<0)gate2=0;
                [self setGateMinChannel:MIN(gate1,gate2)];
                [self setGateMaxChannel:MAX(gate1,gate2)];
            break;
            
            case kMaxDrag:
                gate2 = mouseChan;
                if(gate2<0)gate2=0;
                [self setGateMinChannel:MIN(gate1,gate2)];
                [self setGateMaxChannel:MAX(gate1,gate2)];
            break;
            
            case kCenterDrag:
                delta = startChan-mouseChan;
                int new1 = gate1 - delta;
                int new2 = gate2 - delta;
                int w = abs(new1-new2-1);
                if(new1<0){
                    new1 = 0;
                    new2 = new1 + w;
                }
                else if(new2<0){
                    new2 = 0;
                    new1 = new2 + w;
                }
                else {
                    startChan = mouseChan;
                    gate1 = new1;
                    gate2 = new2;
                    [self setGateMinChannel:MIN(gate1,gate2)];
                    [self setGateMaxChannel:MAX(gate1,gate2)];
                }
            break;
        }

        if(displayGate && cachedGate){
            [cachedGate setLowAcceptValue:MIN(gate1,gate2)];
            [cachedGate setHighAcceptValue:MAX(gate1,gate2)];
        }
        
        [aPlotter setNeedsDisplay:YES];
        
    }
*/
}

- (void)flagsChanged:(NSEvent *)theEvent plotter:(ORPlotter2D*)aPlotter
{
	cmdKeyIsDown = ([theEvent modifierFlags] & NSCommandKeyMask)!=0;
	[aPlotter setNeedsDisplay:YES];

}

- (void) analyzePlot:(ORPlotter2D*)aPlot
{
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
	[self setPoint:aPoint];
	return self;
}

- (NSPoint) point
{
	return point;
}

- (void) setPoint:(NSPoint)aPoint
{
	point = aPoint;
}
- (void) drawPointInPlot:(ORPlotter2D*)aPlotter
{
	NSPoint aConvertedPoint = NSMakePoint([[aPlotter xScale] getPixAbs:point.x],
										  [[aPlotter yScale] getPixAbs:point.y]);
	NSRect r = NSMakeRect(aConvertedPoint.x-3,aConvertedPoint.y-3,6,6);
	[[NSColor yellowColor] set];
	[NSBezierPath fillRect:r];
	[[NSColor blackColor] set];
	[NSBezierPath strokeRect:r];
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
	
	point.x = [decoder decodeFloatForKey:@"x"];
	point.y = [decoder decodeFloatForKey:@"y"];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{

    [encoder encodeFloat:point.x forKey:@"x"];
    [encoder encodeFloat:point.y forKey:@"y"];
}

@end

