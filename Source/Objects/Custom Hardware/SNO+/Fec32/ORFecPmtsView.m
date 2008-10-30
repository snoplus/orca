//
//  ORFecPmtsView.m
//  Orca
//
//  Created by Mark Howe on 10/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
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

#import "ORFecPmtsView.h"
#import "OrcaObjectController.h"
#import "ORFec32Model.h"

@implementation ORFecPmtsView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void) dealloc
{
	int i;
	for(i=0;i<32;i++){
		[topPath[i] release];
		[bodyPath[i] release];
		[clickPath[i] release];
	}
	[super dealloc];
}

- (void)awakeFromNib
{
	//have to make sure that the card view is on top
	[anchorView retain];
	[anchorView removeFromSuperview];
	[self addSubview:anchorView];
	[anchorView release];
}

- (BOOL) acceptsFirstMouse
{
	return NO;
}

- (void)drawRect:(NSRect)rect 
{
	NSRect anchorFrame = [anchorView frame];
	float dc_height = 39;
	float separation = 80; 
	float x1,x2,y1,y2,deltaX1,deltaX2,deltaY1,deltaY2;
	int i;
	
	x1 = anchorFrame.origin.x;
	y1 = anchorFrame.origin.y;
	deltaX1 = (anchorFrame.size.width)/8.;
	x2 = anchorFrame.origin.x - 20;
	y2 = y1  - separation;
	deltaX2 = (anchorFrame.size.width*3.5)/8.;
	//0 - 7 (bottom)
	ORFec32Model* model = [controller model];
	NSArray* daughterCards = [model orcaObjects];
	ORCard* aCard;
	NSEnumerator* e = [daughterCards objectEnumerator];
	BOOL cardPresent[4] = {0,0,0,0};
	while(aCard = [e nextObject]){
		cardPresent[[aCard slot]] = YES;
	}
	
	if(cardPresent[0])for(i=0;i<8;i++){	
		[NSBezierPath strokeLineFromPoint:NSMakePoint(x1,y1) toPoint:NSMakePoint(x2,y2)];
		[self drawSwitch:7-i at:NSMakePoint(x2,y2) direction:90];
		[self drawPMT:7-i at:NSMakePoint(x2,y2-18) direction:90];
		x1 += deltaX1;
		x2 += deltaX2;
	}
	
	//8 - 15 (bottom left)
	x1 = anchorFrame.origin.x;
	y1 = anchorFrame.origin.y + dc_height/2;
	x2 = anchorFrame.origin.x - 55;
	y2 = y1 - dc_height/2 - separation;
	deltaY1 = (dc_height)/8.;
	deltaY2 = (dc_height*4.6)/8.;
	if(cardPresent[1])for(i=0;i<8;i++){	
		[NSBezierPath strokeLineFromPoint:NSMakePoint(x1,y1) toPoint:NSMakePoint(x2,y2)];
		[self drawSwitch:8+i at:NSMakePoint(x2,y2) direction:0];
		[self drawPMT:8+i at:NSMakePoint(x2-18,y2) direction:0];
		y1 += deltaY1;
		y2 += deltaY2;
	}
	
	//16 - 23 (top left)
	x1 = anchorFrame.origin.x;
	y1 = anchorFrame.origin.y + anchorFrame.size.height - dc_height/2;
	x2 = anchorFrame.origin.x - 55;
	y2 = y1 + dc_height/2 + separation;
	if(cardPresent[2])	for(i=0;i<8;i++){	
		[NSBezierPath strokeLineFromPoint:NSMakePoint(x1,y1) toPoint:NSMakePoint(x2,y2)];
		[self drawSwitch:23-i at:NSMakePoint(x2,y2) direction:0];
		[self drawPMT:23-i at:NSMakePoint(x2-18,y2) direction:0];
		y1 -= deltaY1;
		y2 -= deltaY2;
	}
	
	//24 - 31 (top)
	x1 = anchorFrame.origin.x;
	y1 = anchorFrame.origin.y + anchorFrame.size.height+2;
	x2 = anchorFrame.origin.x-20;
	y2 = y1 + separation;
	if(cardPresent[3])for(i=0;i<8;i++){	
		[self drawSwitch:24+i at:NSMakePoint(x2,y2) direction:-90];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(x1,y1) toPoint:NSMakePoint(x2,y2)];
		[self drawPMT:24+i at:NSMakePoint(x2,y2+18) direction:-90];
		x1 += deltaX1;
		x2 += deltaX2;
	}
	
}

- (void) drawSwitch:(int)index at:(NSPoint)switchPoint direction:(float)angle
{
	NSPoint switchClosedPoints[2] = {
		{0,0},
		{-20,0}
	};
	
	NSPoint switchOpenPoints[2] = {
		{-5,7},
		{-20,0}
	};
	
	NSAffineTransform* rotationTransform = [NSAffineTransform transform];
	[rotationTransform rotateByDegrees:angle]; 

	NSAffineTransform* translationTransform = [NSAffineTransform transform];
	[translationTransform translateXBy:switchPoint.x yBy:switchPoint.y];

	//make a rect that we can click on and store it once
	if(!clickPath[index]){
		clickPath[index] = [[NSBezierPath bezierPathWithRect:NSMakeRect(-20,-8,20,16)] retain];
		[clickPath[index] transformUsingAffineTransform:rotationTransform];
		[clickPath[index] transformUsingAffineTransform:translationTransform];
	}

	[translationTransform concat];
	
		
	[[NSColor blackColor] set];
	NSBezierPath* right = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(-2,-2,4,4)];
	[right transformUsingAffineTransform:rotationTransform];
	[right fill];
	
	NSBezierPath* left = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(-20,-2,4,4)];
	[left transformUsingAffineTransform:rotationTransform];
	[left fill];

	NSBezierPath* sw = [NSBezierPath bezierPath];
	if(index%2) [sw appendBezierPathWithPoints:switchClosedPoints count:2];
	else			 [sw appendBezierPathWithPoints:switchOpenPoints   count:2];
	[sw transformUsingAffineTransform:rotationTransform];
	[sw stroke];
		

	[translationTransform invert];
	[translationTransform concat];

}

- (void) drawPMT:(int)index at:(NSPoint)neckPoint direction:(float)angle
{
	NSPoint pmtBody[6] = {
		{-15,-10},
		{-5,-3},
		{0,-3},
		{0,3},
		{-5,3},
		{-15,10}
	};
	
	
 	NSAffineTransform* translationTransform = [NSAffineTransform transform];
	[translationTransform translateXBy:neckPoint.x yBy:neckPoint.y];
	[translationTransform scaleXBy:.8 yBy:.8];
	[translationTransform concat];
	
	NSAffineTransform* rotationTransform = [NSAffineTransform transform];
	[rotationTransform rotateByDegrees:angle]; 
		
	if(!topPath[index]){
		topPath[index] = [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(-23,-10,15,20)] retain];
		[topPath[index] transformUsingAffineTransform:rotationTransform];
	}
	
	[[NSColor whiteColor] set];
	[topPath[index] fill];
	[[NSColor blackColor] set];
	[topPath[index] stroke];
	
	if(!bodyPath[index]){
		bodyPath[index] = [[NSBezierPath bezierPath] retain];
		[bodyPath[index] appendBezierPathWithPoints:pmtBody count:6];
		[bodyPath[index] closePath];
		[bodyPath[index] transformUsingAffineTransform:rotationTransform];
	}
	
	[[NSColor redColor] set];
	[bodyPath[index] fill];
	
	[[NSColor blackColor] set];
	[bodyPath[index] stroke];
	[translationTransform invert];
	[translationTransform concat];
}

- (void)mouseUp:(NSEvent *)theEvent;
{
	NSPoint aPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];

	int i;
	for(i=0;i<32;i++){
		if(/*cardPresent[i/8] &&*/ [clickPath[i] containsPoint:aPoint]){
			NSLog(@"got it on %d\n",i);
			//TBD -- pass an action back to controller that pmt switch is hit.
			break;
		}
	}
}

@end
