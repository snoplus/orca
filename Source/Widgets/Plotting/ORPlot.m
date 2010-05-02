//
//  ORPlot.m
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
//University of Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORPlot.h"
#import "ORPlotView.h"
#import "ORAxis.h"
#import "ORPlotAttributeStrings.h"

@implementation ORPlot
- (id) initWithTag:(int)aTag andDataSource:(id)aDataSource
{
    if ( self = [super init] ) {
        [self setDataSource:aDataSource];
        [self setTag:aTag];
		[self setDefaults];
    }
    return self;
}

- (id) initWithTag:(int)aTag { return [self initWithTag:aTag andDataSource:nil]; }
- (id) init					 { return [self initWithTag:0]; }

- (void) dealloc
{
	[attributes release];
	[symbolNormal release];
	[symbolLight release];
    [super dealloc];
}

- (void) setUpSymbol
{	
	NSImage* aSymbol = [[NSImage alloc] initWithSize:NSMakeSize(kSymbolSize,kSymbolSize)];
	[aSymbol lockFocus];
	[[self lineColor] set];
	[NSBezierPath setDefaultLineWidth:1];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(0,kSymbolSize/2) toPoint:NSMakePoint(kSymbolSize-1,kSymbolSize/2)];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(kSymbolSize/2,0) toPoint:NSMakePoint(kSymbolSize/2,kSymbolSize-1)];
	[aSymbol unlockFocus];
	[self setSymbolNormal:aSymbol];
	[aSymbol release];
	
	aSymbol = [[NSImage alloc] initWithSize:NSMakeSize(kSymbolSize,kSymbolSize)];
	[aSymbol lockFocus];
	[[[self lineColor] highlightWithLevel:.5]set];
	[NSBezierPath setDefaultLineWidth:1];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(0,kSymbolSize/2) toPoint:NSMakePoint(kSymbolSize-1,kSymbolSize/2)];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(kSymbolSize/2,0) toPoint:NSMakePoint(kSymbolSize/2,kSymbolSize-1)];
	[aSymbol unlockFocus];
	[self setSymbolLight:aSymbol];
	[aSymbol release];
	
}

- (void) setTag:(int)aTag
{
	tag = aTag;
}

- (int)tag									{ return tag; }
- (id) dataSource							{ return dataSource; }
- (BOOL) dataSourceIsSetupToAllowDrawing	{ return dataSource!=nil; }
- (NSMutableDictionary *)attributes			{ return attributes;  }

- (void) setDataSource:(id)ds
{
	if( ![ds respondsToSelector:@selector(numberPointsInPlot:)] || 
	   ![ds respondsToSelector:@selector(plotter:index:x:y:)]){
		ds = nil;
	}
	dataSource = ds;
}
- (void) setPlotView:(ORPlotView*)aPlotView
{
	//this is like a delegate.. don't retain.
	plotView = aPlotView;
}

- (void) setDefaults
{
    if(!attributes){
        [self setAttributes:[NSMutableDictionary dictionary]];
        [self setLineColor:[NSColor redColor]];
        [self setUseConstantColor:NO];
        [self setLineWidth:0.75];
        [self setShowLine:YES];
        [self setShowSymbols:NO];
    }
}

- (void)setAttributes:(NSMutableDictionary *)anAttributes 
{
    [anAttributes retain];
    [attributes release];
    attributes = anAttributes;
}

#pragma mark ***Attributes
- (void) setUseConstantColor:(BOOL)aState
{
    [attributes setObject:[NSNumber numberWithBool:aState] forKey:ORPlotUseConstantColor];
}

- (BOOL) useConstantColor
{
	return [[attributes objectForKey:ORPlotUseConstantColor] boolValue];
}

- (void) setShowLine:(BOOL)aState
{
    [attributes setObject:[NSNumber numberWithBool:aState] forKey:ORPlotShowLine];
}

- (BOOL) showLine
{
	return [[attributes objectForKey:ORPlotShowLine] boolValue];
}
- (void) setShowSymbols:(BOOL)aState
{
    [attributes setObject:[NSNumber numberWithBool:aState] forKey:ORPlotShowSymbols];
}

- (BOOL) showSymbols
{
	return [[attributes objectForKey:ORPlotShowSymbols] boolValue];
}

- (void) setLineColor:(NSColor *)aColor
{
    [attributes setObject:[NSArchiver archivedDataWithRootObject:aColor] forKey:ORPlotLineColor];
	[self setUpSymbol];
}

- (NSColor*) lineColor
{
	NSData* d = [attributes objectForKey:ORPlotLineColor];
	if(!d) return [NSColor redColor];
    else   return [NSUnarchiver unarchiveObjectWithData:d];
}

- (void) setLineWidth:(float)aWidth
{
    [attributes setObject:[NSNumber numberWithFloat:aWidth] forKey:ORPlotLineWidth];
	[self setUpSymbol];
}

- (float) lineWidth
{
	return [[attributes objectForKey:ORPlotLineWidth] floatValue];
}

- (NSImage*) symbolNormal
{
	return symbolNormal;
}

- (void) setSymbolNormal:(NSImage*)aSymbol
{
	[aSymbol retain];
	[symbolNormal release];
	symbolNormal = aSymbol;
}

- (NSImage*) symbolLight
{
	return symbolLight;
}

- (void) setSymbolLight:(NSImage*)aSymbol
{
	[aSymbol retain];
	[symbolLight release];
	symbolLight = aSymbol;
}

- (void) saveColor
{
	if(!savedColor) savedColor = [[self lineColor] retain];
}

- (void) restoreColor
{
	if(savedColor){
		[self setLineColor:savedColor];
		[savedColor release];
		savedColor = nil;
	}
}

#pragma mark ***Drawing
- (void) drawData
{
	if(!dataSource) return;
	
	int numPoints = [dataSource numberPointsInPlot:self];
	if(numPoints == 0) return;
	
	//cache some things that we'll use below
	ORAxis* mXScale = [plotView xScale];
	ORAxis* mYScale = [plotView yScale];
	BOOL aLog		= [mYScale isLog];
	BOOL aInt		= [mYScale integer];
	double aMinPad  = [mYScale minPad];
	double aMinPadx = [mXScale minPad];
	float x,y;
	
	//draw the data 
	int minX = MAX(0,roundToLong([mXScale minLimit]));
	int maxX = MIN(roundToLong([mXScale maxLimit]+1),numPoints);
	double xValue,yValue;
	[dataSource plotter:self index:minX x:&xValue y:&yValue];
	x  = [mXScale getPixAbs:minX];
	y  = [mYScale getPixAbs:yValue];
	
	NSBezierPath* theDataPath = [NSBezierPath bezierPath];
	[theDataPath moveToPoint:NSMakePoint(x,y)];
	
	long ix;
	for (ix=minX+1; ix<maxX;++ix) {	
		[dataSource plotter:self index:ix x:&xValue y:&yValue];
		x = [mXScale getPixAbsFast:ix log:NO integer:YES minPad:aMinPadx];
		y = [mYScale getPixAbsFast:yValue log:aLog integer:aInt minPad:aMinPad];
		[theDataPath lineToPoint:NSMakePoint(x,y)];
	}

	if([self useConstantColor] || [plotView topPlot] == self)	[[self lineColor] set];
	else [[[self lineColor] highlightWithLevel:.5]set];
	
	[theDataPath setLineWidth:[self lineWidth]];
	[theDataPath stroke];
}

- (void) drawExtras
{		
	NSAttributedString* s;
	NSSize labelSize;
	
	float height = [plotView bounds].size.height;
	float width  = [plotView bounds].size.width;
	NSDictionary* attrsDictionary = [plotView textAttributes];
	
	if([plotView commandKeyIsDown] && showCursorPosition){
		int numPoints = [dataSource numberPointsInPlot:self];
		
		float y = 0;
		if(cursorPosition.x < numPoints){
			double xValue,yValue;
			[dataSource plotter:self index:cursorPosition.x x:&xValue y:&yValue];
			y = [[plotView yScale] getPixAbs:yValue];
		}
		float x = [[plotView xScale] getPixAbs:cursorPosition.x];
		
		[[NSColor blackColor] set];
		[NSBezierPath setDefaultLineWidth:.75];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(x,0) toPoint:NSMakePoint(x,height)];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(0,y) toPoint:NSMakePoint(width,y)];

		NSString* cursorPositionString = [NSString stringWithFormat:@"x:%.0f y:%.0f",cursorPosition.x,cursorPosition.x<numPoints?y:0.0];
		s = [[NSAttributedString alloc] initWithString:cursorPositionString attributes:attrsDictionary];
		labelSize = [s size];
		[s drawAtPoint:NSMakePoint(width - labelSize.width - 10,height-labelSize.height-5)];
		[s release];
		
	}
}

- (void) resetCursorRects
{
}

#pragma mark ***Conversions
- (NSPoint) convertFromWindowToPlot:(NSPoint)aWindowLocation
{
	NSPoint p = [plotView convertPoint:aWindowLocation fromView:nil];
	NSPoint result;
	result.x = [[plotView xScale] getValAbs:p.x];
	result.y = [[plotView yScale] getValAbs:p.y];
	return result;
}

#pragma mark ***Event Handling
- (BOOL) redrawEvent:(NSNotification*)aNote
{
	return NO;
}

- (void) flagsChanged:(NSEvent *)theEvent
{
}

- (id) roi
{
	return nil;
}

- (void) keyDown:(NSEvent*)theEvent
{
	//tab will shift to next plot curve -- shift/tab goes backward.
	unsigned short keyCode = [theEvent keyCode];
    if(keyCode == 48){
        if([theEvent modifierFlags] & NSShiftKeyMask){
			[self lastComponent];
		}
        else {
			[self nextComponent];
		}
		[plotView setNeedsDisplay:YES];

	}
}

- (BOOL) mouseDown:(NSEvent*)theEvent
{
	if(([theEvent modifierFlags] & NSCommandKeyMask) && !([theEvent modifierFlags] & NSShiftKeyMask)) {		
		[NSCursor hide];
		[self showCrossHairsForEvent:theEvent];
	}
	return NO;
}

- (void) mouseDragged:(NSEvent*)theEvent
{
    [[plotView window] disableCursorRects];
	showCursorPosition	= NO;
	if([theEvent modifierFlags] & NSCommandKeyMask) {	
		[self showCrossHairsForEvent:theEvent];
	}
}

-(void)	mouseUp:(NSEvent*)theEvent
{
    [[plotView window] enableCursorRects];
	[NSCursor unhide];
	showCursorPosition	= NO;
	[plotView setNeedsDisplay:YES];
	[NSCursor pop];
}

- (void) showCrossHairsInForEvent:(NSEvent*)theEvent
{
	NSPoint plotPoint = [self convertFromWindowToPlot:[theEvent locationInWindow]];
	double x = plotPoint.x;
	double xValue,yValue;
	[dataSource plotter:self index:x x:&xValue y:&yValue];
	showCursorPosition = YES;
	cursorPosition = NSMakePoint(x,yValue);
	[plotView setNeedsDisplay:YES];
}

#pragma mark ***Scaling
- (long) maxValueChannelinXRangeFrom:(long)minChannel to:(long)maxChannel;
{
	int n  = [dataSource numberPointsInPlot:self];
	if(n!=0){
		double maxX = 0;
		double maxY = -9E9;
		
		 int i;
		 for (i=minChannel; i<maxChannel; ++i) {
			 double xValue,yValue;
			 [dataSource plotter:self index:i x:&xValue y:&yValue];
			 if (yValue > maxY) {
				 maxY = yValue;
				 maxX = i;
			 }
		 }
		return maxX;
	}
	else return 0;
}

- (void) getyMin:(double*)aYMin yMax:(double*)aYMax;
{
	int n  = [dataSource numberPointsInPlot:self];
	if(n!=0){
		double minY = 9E9;
		double maxY = -9E9;

		int i;
		for (i=0; i<n; ++i) {
			double xValue,yValue;
			[dataSource plotter:self index:i x:&xValue y:&yValue];
			maxY = MAX(maxY,yValue);
			minY = MIN(minY,yValue);
		}
		*aYMin = minY;
		*aYMax = maxY;
	}
	else {
		*aYMin = 0;
		*aYMax = 0;
	}
}

- (void) getxMin:(double*)aXMin xMax:(double*)aXMax;
{
	int n  = [dataSource numberPointsInPlot:self];
	if(n!=0){
		double minX = 9E9;
		double maxX = -9E9;
		int i;
		BOOL gotOne = NO;
		for (i=0; i<n; ++i) {
			double xValue,yValue;
			[dataSource plotter:self index:i x:&xValue y:&yValue];
			if(yValue!=0){
				minX = i;
				gotOne = YES;
				break;
			}
		}
		
		for (i=n-1; i>=0; --i) {
			double xValue,yValue;
			[dataSource plotter:self index:i x:&xValue y:&yValue];
			if(yValue!=0){
				maxX = i;
				gotOne = YES;
				break;
			}
		}
		if(gotOne){
			*aXMin = minX;
			*aXMax = maxX;
		}
		else {
			*aXMin = 0;
			*aXMax = 0;
		}
	}
	else {
		*aXMin = 0;
		*aXMax = 0;
	}
}

- (float) getzMax
{
	return 0;
}

- (void) logLin { [[plotView yScale] setLog:![[plotView yScale] isLog]]; }

#pragma mark ***Component Switching
- (BOOL) nextComponent
{
	return YES;
}

- (BOOL) lastComponent
{
	return YES;
}

- (BOOL) canScaleY
{
	return YES;
}
- (BOOL) canScaleX
{
	return YES;
}
- (BOOL) canScaleZ
{
	return YES;
}

- (long) numberPoints
{
	return [dataSource numberPointsInPlot:self];
}

- (NSString*) valueAsStringAtPoint:(long)i
{		
	double xValue,yValue;
	[dataSource plotter:self index:i x:&xValue y:&yValue];
	return [NSString stringWithFormat:@"%f",yValue]; 
}

- (void) showCrossHairsForEvent:(NSEvent*)theEvent
{
	NSPoint plotPoint = [self convertFromWindowToPlot:[theEvent locationInWindow]];
	double x = plotPoint.x;
	double xValue,yValue;
	[dataSource plotter:self index:x x:&xValue y:&yValue];
	showCursorPosition = YES;
	cursorPosition = NSMakePoint(x,yValue);
	[plotView setNeedsDisplay:YES];
}

@end
