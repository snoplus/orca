//
//  SNOMonitoringView.h
//  Orca
//
//  Created by Mark Howe on Tue Apr 20, 2010.
//  Copyright (c) 2010  University of North Carolina. All rights reserved.
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

#import "SNOModel.h"
#import "SNOMonitoringView.h"
#import "ORColorScale.h"
#import "ORSegmentGroup.h"
#import "ORDetectorSegment.h"


@interface SNOMonitoringView (private)
- (void) makeAllSegments;
@end

@implementation SNOMonitoringView
- (void) setViewType:(int)aViewType
{
	viewType = aViewType;
}

- (void) drawRect:(NSRect)rect
{
	if(viewType == kUseCrateView){
		
		float x;
		float y;
		float dx = [self bounds].size.width/21.;
		float dy = [self bounds].size.height/8;
		[[NSColor blackColor] set];
		[NSBezierPath fillRect:[self bounds]];
		[[NSColor whiteColor] set];
		NSBezierPath* thePath = [NSBezierPath bezierPath];
		for(x=0;x<[self bounds].size.width;x+=dx){
			[thePath moveToPoint:NSMakePoint(x,0)];
			[thePath lineToPoint:NSMakePoint(x,[self bounds].size.height)];
		}
		for(y=0;y<=[self bounds].size.height;y+=dy){
			[thePath moveToPoint:NSMakePoint(0,y)];
			[thePath lineToPoint:NSMakePoint([self bounds].size.width,y)];
		}
		[thePath moveToPoint:NSMakePoint([self bounds].size.width,0)];
		[thePath lineToPoint:NSMakePoint([self bounds].size.width,[self bounds].size.height)];
		[thePath stroke];
		 
	}
	[super drawRect:rect];
}

- (NSColor*) getColorForSet:(int)setIndex value:(unsigned long)aValue
{
	return [focalPlaneColorScale getColorForValue:aValue];
}

- (void) upArrow
{
	selectedPath++;
	if(selectedSet == 0) selectedPath %= kNumTubes;
}

- (void) downArrow
{
	selectedPath--;
	if(selectedSet == 0){
		if(selectedPath < 0) selectedPath = kNumTubes-1;
	}

}

@end
@implementation MajoranaDetectorView (private)
- (void) makeAllSegments
{
	//float xc = [self bounds].size.width/2;
	//float yc = [self bounds].size.height/2;
	
	[super makeAllSegments];
	
	if(viewType == kUseCrateView){
		float dx = [self bounds].size.width/21.;
		float dy = [self bounds].size.height/8;
		NSMutableArray* segmentPaths = [NSMutableArray arrayWithCapacity:kNumTubes];
		NSMutableArray* errorPaths   = [NSMutableArray arrayWithCapacity:kNumTubes];
		ORSegmentGroup* aGroup = [delegate segmentGroup:0];
		int i;
		int n = [aGroup numSegments];
		for(i=0;i<n;i++){
			ORDetectorSegment* aSegment = [aGroup segment:i];
			int cardSlot = [aSegment cardSlot]-1;
			int channel = [aSegment channel];
			if(channel < 0){
				cardSlot = -1; //we have to make the segment, but we'll draw off screen when not mapped
			}
			NSRect channelRect = NSMakeRect(cardSlot*dx,[self bounds].size.height - channel*dy,dx,dy);
			[segmentPaths addObject:[NSBezierPath bezierPathWithRect:channelRect]];
			[errorPaths addObject:[NSBezierPath bezierPathWithRect:NSInsetRect(channelRect, 4, 4)]];
		}
		
		[segmentPathSet addObject:segmentPaths];
		[errorPathSet addObject:errorPaths];
 
	}
	
	else if(viewType == kUsePSUPView) {		
		
		NSMutableArray* segmentPaths = [NSMutableArray arrayWithCapacity:kNumTubes];
		NSMutableArray* errorPaths   = [NSMutableArray arrayWithCapacity:kNumTubes];
		
		float height = [self bounds].size.height;
//		float width = [self bounds].size.height;
		float detWidth = 35;
		float detHeight = detWidth*.5;
		int det;
		float x = 20;
		int mod;
		for(mod=0;mod<2;mod++){
			int col;
			x=20;
			for(col=0;col<7;col++){
				float y = (height-detHeight-10) - 5*mod*(detHeight+5) - mod*15;
				for(det=0;det<5;det++){
					NSRect r = NSMakeRect(x,y,detWidth,detHeight);
					[segmentPaths   addObject:[NSBezierPath bezierPathWithRect:r]];
					[errorPaths   addObject:[NSBezierPath bezierPathWithRect:NSInsetRect(r, -5, -5)]];
					y -= detHeight+5;
				}
				x += detWidth+5;
			}
		}
		
		//store into the whole set
		[segmentPathSet addObject:segmentPaths];
		[errorPathSet addObject:errorPaths];
		
		[self setNeedsDisplay:YES];
	}
}

- (void) upArrow
{
	selectedPath++;
	if(selectedSet == 0) selectedPath %= kNumTubes;
}

- (void) downArrow
{
	selectedPath--;
	if(selectedSet == 0){
		if(selectedPath < 0) selectedPath = kNumTubes-1;
	}
	
}
@end
