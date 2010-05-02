//
//  ORTimeSeriesPlot.m
//  Orca
//
//  Created by Mark Howe on 2/20/10.
//  Copyright 2010 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of  
//Washington at the Center for Experimental Nuclear Physics and 
//Astrophysics (CENPA) sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Washington reserve all rights in the program. Neither the authors,
//University of1DHisto Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORTimeSeriesPlot.h"
#import "ORPlotView.h"
#import "ORTimeLine.h"
#import "ORPlotAttributeStrings.h"

@implementation ORTimeSeriesPlot

#pragma mark ***Data Source Setup
- (void) setDataSource:(id)ds
{
	if( ![ds respondsToSelector:@selector(numberPointsInPlot:)] || 
	    ![ds respondsToSelector:@selector(plotterStartTime:)]   ||
	    ![ds respondsToSelector:@selector(plotter:index:x:y:)]) {
		ds = nil;
	}
	dataSource = ds;
}

#pragma mark ***Drawing
- (void) drawData
{

	ORAxis*    mXScale = [plotView xScale];
	ORAxis*    mYScale = [plotView yScale];
	
	int numPoints = [dataSource numberPointsInPlot:self];
    if(numPoints == 0) return;
			
    NSTimeInterval startTime = [dataSource plotterStartTime:self];
	[(ORTimeLine*)mXScale setStartTime: startTime];
    NSBezierPath* theDataPath = [NSBezierPath bezierPath];
    
	BOOL aLog = [mYScale isLog];
	BOOL aInt = [mYScale integer];
	double aMinPad = [mYScale minPad];
	
	int i;
	double xValue;
	double yValue;    
	for (i=0; i<numPoints;++i) {
		[dataSource plotter:self index:i x:&xValue y:&yValue];
		float y = [mYScale getPixAbsFast:yValue log:aLog integer:aInt minPad:aMinPad];
		float x = [mXScale getPixAbs:(double)(xValue - startTime)];
		if(i==0)[theDataPath moveToPoint:NSMakePoint(x,y)];
		else [theDataPath lineToPoint:NSMakePoint(x,y)];
	}
	
	if([self useConstantColor] || [plotView topPlot] == self)	[[self lineColor] set];
	else [[[self lineColor] highlightWithLevel:.5]set];

	[theDataPath setLineWidth:[self lineWidth]];
	[theDataPath stroke];
}

- (void) drawExtras 
{		
	
	float height = [plotView bounds].size.height;
	float width  = [plotView bounds].size.width;
	NSFont* font = [NSFont systemFontOfSize:12.0];
	NSDictionary* attrsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName,[NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:.8],NSBackgroundColorAttributeName,nil];
	
	if([plotView commandKeyIsDown] && showCursorPosition){
		int numPoints = [dataSource numberPointsInPlot:self];
				 
		ORAxis*    mXScale = [plotView xScale];
		ORAxis*    mYScale = [plotView yScale];
		double xValue;
		double yValue;    
		NSTimeInterval startTime = [dataSource plotterStartTime:self];
		int index = cursorPosition.x;
		[dataSource plotter:self index:index x:&xValue y:&yValue];
		double y = [mYScale getPixAbs:yValue];
		double x = [mXScale getPixAbs:(double)(xValue - startTime)];
		
		[[NSColor blackColor] set];
		[NSBezierPath setDefaultLineWidth:.75];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(x,0) toPoint:NSMakePoint(x,height)];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(0,y) toPoint:NSMakePoint(width,y)];
		
		if(index>=0 && index<numPoints){
			NSCalendarDate* date = [NSCalendarDate dateWithTimeIntervalSince1970:(NSTimeInterval)(index+ startTime)];
			[date setCalendarFormat:@"%m/%d/%y %H:%M:%S"];
			NSString* cursorPositionString = [NSString stringWithFormat:@"Time:%@   y:%.3f  ",date,cursorPosition.x<numPoints?cursorPosition.y:0.0];
			NSAttributedString* s = [[NSAttributedString alloc] initWithString:cursorPositionString attributes:attrsDictionary];
			NSSize labelSize = [s size];
			[s drawAtPoint:NSMakePoint(width - labelSize.width - 10,height-labelSize.height-5)];
			[s release];
		}		
	}
}

#pragma mark ***Conversions
- (void) showCrossHairsForEvent:(NSEvent*)theEvent
{
	NSPoint plotPoint = [self convertFromWindowToPlot:[theEvent locationInWindow]];
	int index = plotPoint.x;
	double x;
	double y;
	[dataSource plotter:self index:index x:&x y:&y];
	x = index;
	
	showCursorPosition = YES;
	cursorPosition = NSMakePoint(x,y);
	[plotView setNeedsDisplay:YES];	
}

@end					
