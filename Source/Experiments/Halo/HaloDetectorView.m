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

#import "HaloModel.h"
#import "HaloDetectorView.h"
#import "ORColorScale.h"
#import "ORSegmentGroup.h"
#import "ORDetectorSegment.h"


@interface HaloDetectorView (private)
- (void) makeAllSegments;
@end

@implementation HaloDetectorView
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
		float dy = [self bounds].size.height/24.;
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
@implementation HaloDetectorView (private)
- (void) makeAllSegments
{
	float xc = [self bounds].size.width/2;
	float yc = [self bounds].size.height/2;
	
	[super makeAllSegments];
	
	NSPoint centerPoint = NSMakePoint(xc,yc);

	if(viewType == kUseCrateView){
		float dx = [self bounds].size.width/21.;
		float dy = [self bounds].size.height/24.;
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
			NSRect channelRect = NSMakeRect(cardSlot*dx,channel*dy,dx,dy);
			[segmentPaths addObject:[NSBezierPath bezierPathWithRect:channelRect]];
			[errorPaths addObject:[NSBezierPath bezierPathWithRect:NSInsetRect(channelRect, 4, 4)]];
		}
		
		[segmentPathSet addObject:segmentPaths];
		[errorPathSet addObject:errorPaths];
 
	}
	
	else if(viewType == kUseTubeView) {		
		
		NSMutableArray* segmentPaths = [NSMutableArray arrayWithCapacity:kNumTubes];
		NSMutableArray* errorPaths   = [NSMutableArray arrayWithCapacity:kNumTubes];
		
		int bore;
		float height = [self bounds].size.height;
		float width = [self bounds].size.height;
		int evenColumnDelta = width  / 5;
		int oddColumnDelta  = width  / 4;
		int rowSpacing      = height / 7;
#define cellSize 30
		
		float xc = cellSize;
		float yc = height-cellSize+10;
		int row = 0;
		for(bore=0;bore<32;bore++){
			
			int t;
			float angle = 0;
			for(t=0;t<4;t++){
				float x = xc + 10 * cos(angle * 3.1415/180.);
				float y = yc + 10 * sin(angle * 3.1415/180.);
				angle += 90;
				NSRect r = NSMakeRect(20+x-5,y-5,10,10);
				r = NSOffsetRect(r, 0, 0);
				[segmentPaths addObject:[NSBezierPath bezierPathWithOvalInRect:r]];
				[errorPaths   addObject:[NSBezierPath bezierPathWithOvalInRect:NSInsetRect(r, -5, -5)]];
			}
			xc += evenColumnDelta;
			if(xc >= width){
				row++;
				if(row%2==0)xc = cellSize;
				else xc = 2*cellSize;
				yc -= rowSpacing;
			}
		}
		
		//store into the whole set
		[segmentPathSet addObject:segmentPaths];
		[errorPathSet addObject:errorPaths];
		
		[self setNeedsDisplay:YES];
	}
}



@end
