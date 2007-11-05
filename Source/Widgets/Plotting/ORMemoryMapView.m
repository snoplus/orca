//
//  ORMemoryMapView.m
//  Orca
//
//  Created by Mark Howe on 3/30/06.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
//

#import "ORMemoryMapView.h"
#import "ORAxis.h"
#import "ORMemoryMap.h"
#import "ORMemoryArea.h"

@implementation ORMemoryMapView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    return self;
}

- (IBAction) resetLimits:(id)sender
{
    [mYScale setMinLimit:0];
    [mYScale setMaxLimit:0xffffffff];
    [mYScale setMinimumRange:100];
    [mYScale setRngLow:0 withHigh:0xffffffff];
	[self setNeedsDisplay:YES];
}

- (IBAction) autoScale:(id)sender
{
	float low  = [[mDataSource memoryMap] lowValue];
	float high = [[mDataSource memoryMap] highValue];
    [mYScale setMinLimit:0];
    [mYScale setMaxLimit:0xffffffff];
    [mYScale setMinimumRange:100];
    [mYScale setRngLow:low withHigh:high];
	[self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)rect 
{
    NSRect bounds = [self bounds];
    [[NSColor lightGrayColor] set];
    [NSBezierPath fillRect:bounds];
    [[NSColor darkGrayColor] set];
    [NSBezierPath strokeRect:bounds];
	
	double aMinPad = [mYScale minPad];

	ORMemoryMap* theFullMap = [mDataSource memoryMap];
	
	float minY =[mYScale getPixAbsFast:[mYScale minValue] log:NO integer:NO minPad:aMinPad];
	float maxY =[mYScale getPixAbsFast:[mYScale maxValue] log:NO integer:NO minPad:aMinPad];
	
	int numberOfMemoryMaps = [theFullMap count];
	int index;
	for(index = 0;index<numberOfMemoryMaps;index++){

		ORMemoryArea* theArea = [theFullMap memoryArea:index];
		float yLow  = [mYScale getPixAbsFast:[theArea lowValue] log:NO integer:YES minPad:aMinPad];
		float yHigh = [mYScale getPixAbsFast:[theArea highValue] log:NO integer:YES minPad:aMinPad];

		//check bounds. if total out-of-bounds ignore.
		if(yHigh<minY)continue;
		if(yLow>maxY)continue;
		
		//if element is partially out-of-bounds adjust the size.
		if(yHigh>maxY)yHigh = maxY;
		if(yLow<minY) yLow   = minY;
		float delta = yHigh - yLow;
		
		if(delta <=1){
			[[NSColor redColor] set];
			[NSBezierPath strokeLineFromPoint:NSMakePoint(0,yLow) toPoint:NSMakePoint([self bounds].size.width,yLow)];
		}
		else {
			[[NSColor colorWithCalibratedRed:1 green:0 blue:0 alpha:.5] set];
			[NSBezierPath fillRect:NSMakeRect(0,yLow ,[self bounds].size.width,delta)];

			if(delta > 9){
				NSString* theName	  = [NSString stringWithFormat:@"%@ 0x%0x",[theArea name],[theArea lowValue]]; 			
				NSAttributedString* label = [[[NSAttributedString alloc] initWithString:theName
																 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																	 [NSColor blackColor],NSForegroundColorAttributeName,
																	 [NSFont fontWithName:@"Geneva" size:9],NSFontAttributeName,
																	 nil]] autorelease]; 

				NSSize theTextBounds = [label size];
				[label drawAtPoint:NSMakePoint(10,yLow+delta/2-theTextBounds.height/2)];
			}
		}
	}
}

@end
