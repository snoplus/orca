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

#import "nTPCPadPlaneView.h"
#import "ORColorScale.h"
#import "nTPCConstants.h"
#import "ORExperimentModel.h"
#import "ORDetectorView.h"
#import "ORSegmentGroup.h"

#define highlightLineWidth 2

@implementation nTPCPadPlaneView

- (void) loadPixelCoords
{
	NSBundle* mainBundle = [NSBundle mainBundle];
	NSString* path       = [mainBundle pathForResource: @"nTPCPadPositions" ofType: @"txt"];
	float h = [self bounds].size.height;
	float w = [self bounds].size.width;
	float midX = w/2.;
	float midY = h/2.;
	float scale_factor = 1.6; //adhoc scale factor
	int i,j,k;
	for(i=0;i<3;i++){
		for(j=0;j<55;j++){
			for(k=0;k<55;k++){
				pixel[i][j][k] = NSZeroPoint;
			}
		}
	}
		
	if([[NSFileManager defaultManager] fileExistsAtPath:path]){
		NSString* contents = [NSString stringWithContentsOfFile:path encoding:NSASCIIStringEncoding error:nil];
		NSArray* lines = [contents componentsSeparatedByString:@"\n"];
		int lastWire = -1;
		int k = 0;
		for(id aLine in lines){
			NSArray* parts = [aLine componentsSeparatedByString:@","];
			if([parts count] == 4) {
				int group	= [[parts objectAtIndex:0] intValue];
				int wire	= [[parts objectAtIndex:1] intValue];
				float x		= [[parts objectAtIndex:2] floatValue];
				float y		= [[parts objectAtIndex:3] floatValue];
				if(group>=0 && group<3 && wire>=0 && wire<55){
					pixel[group][wire][k++] = NSMakePoint(scale_factor*x+midX,scale_factor*y+midY);
					if(lastWire==-1)lastWire = wire;
					if(wire != lastWire){
						lastWire = wire;
						k=0;
					}
				}
			}
		}
	}
	coordsLoaded = YES;
}

- (void) makeAllSegments
{
	if(!coordsLoaded)[self loadPixelCoords];
	
	[super makeAllSegments];
		
	int i,j,k;
	for(i=0;i<3;i++){
		NSMutableArray* segmentPaths = [NSMutableArray arrayWithCapacity:kNumPadPlaneWires];
		for(j=0;j<kNumPadPlaneWires;j++){
			NSMutableArray* dupPaths = [NSMutableArray arrayWithCapacity:kNumPadPlaneWires];
			for(k=0;k<kNumPadPlaneWires;k++){
				NSPoint aPixel = pixel[i][j][k];
				if(aPixel.x == 0 && aPixel.y ==0) break;
				NSBezierPath* aPath = [NSBezierPath bezierPathWithRect:NSMakeRect(aPixel.x-1,aPixel.y-1,2,2)];
				[dupPaths addObject:aPath];
			}
			[segmentPaths addObject:dupPaths];		
		}
		//store into the whole set
		[segmentPathSet addObject:segmentPaths];
	}
}

- (NSColor*) getColorForSet:(int)setIndex value:(unsigned long)aValue
{
	return [colorScale getColorForValue:aValue];
}

- (void)drawRect:(NSRect)rect
{
	int displayType = [delegate displayType];
	int setIndex;
	int numSets = [segmentPathSet count];

	for(setIndex = 0;setIndex<numSets;setIndex++){
		int segmentIndex;
		NSArray* arrayOfSegmentPaths = [segmentPathSet objectAtIndex:setIndex];
		int numSegments = [arrayOfSegmentPaths count];
		ORSegmentGroup* segmentGroup = [delegate segmentGroup:setIndex];
		for(segmentIndex = 0;segmentIndex<numSegments;segmentIndex++){
			NSArray* dupPaths = [arrayOfSegmentPaths objectAtIndex:segmentIndex];
			for(id segmentPath in dupPaths){
				NSColor* displayColor = nil;
				if([segmentGroup hwPresent:segmentIndex]){
					if([segmentGroup online:segmentIndex]){
						float displayValue;
						switch(displayType){
							case kDisplayEvents:	 displayValue = [segmentGroup getPartOfEvent:segmentIndex];	break;
							case kDisplayThresholds: displayValue = [segmentGroup getThreshold:segmentIndex];	break;
							case kDisplayGains:		 displayValue = [segmentGroup getGain:segmentIndex];		break;
							default:				 displayValue = [segmentGroup getRate:segmentIndex];		break;
						}
						if(displayValue){
							if(displayType != kDisplayEvents){
								displayColor = [self getColorForSet:setIndex value:(int)displayValue];
							}
							else {
								if(displayValue)displayColor = [NSColor blackColor];
							}
						}
				}
				else [[NSColor whiteColor] set];
				}
				else [[NSColor blackColor] set];
				if(displayColor){
					[displayColor set];
					[segmentPath fill];
				}
			}
		}
		
	}
			
	//the the highlighted segment
	if(selectedSet>=0 && selectedPath>=0){	
		NSArray* arrayOfSegmentPaths = [segmentPathSet objectAtIndex:selectedSet];
		NSArray* dupPaths = [arrayOfSegmentPaths objectAtIndex:selectedSet];
		for(id segmentPath in dupPaths){
			[segmentPath setLineWidth:1];
			[[NSColor colorWithCalibratedRed:.7 green:.2 blue:.2 alpha:1] set];
			[segmentPath stroke];
		}
	}
	
	[[NSColor blackColor] set];
	[NSBezierPath strokeRect:[self bounds]];

} 

- (void) mouseDown:(NSEvent*)anEvent
{
    NSPoint localPoint = [self convertPoint:[anEvent locationInWindow] fromView:nil];
	selectedSet  = -1;
	selectedPath = -1;
	
	int setIndex;
	for(setIndex = 0;setIndex<[segmentPathSet count];setIndex++){
		int segmentIndex;
		NSArray* arrayOfPaths = [segmentPathSet objectAtIndex:setIndex];
		for(segmentIndex = 0;segmentIndex<[arrayOfPaths count];segmentIndex++){
			NSArray* dupPaths = [arrayOfPaths objectAtIndex:segmentIndex];
			for(id aPath in dupPaths){
				if([aPath containsPoint:localPoint]){
					selectedSet  = setIndex;
					selectedPath = segmentIndex;
				}
			}
		}
	}
	[delegate selectedSet:selectedSet segment:selectedPath];
	if(selectedSet>=0 && selectedPath>=0 && [anEvent clickCount] >= 2){
		if([anEvent modifierFlags] & NSCommandKeyMask){
			[delegate showDataSetForSet:selectedSet segment:selectedPath];
		}
		else {
			[delegate showDialogForSet:selectedSet segment:selectedPath];
		}
	}
	[self setNeedsDisplay:YES];
}


@end