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

#import "MajoranaModel.h"
#import "MajoranaDetectorView.h"
#import "ORColorScale.h"
#import "ORSegmentGroup.h"
#import "ORDetectorSegment.h"


@interface MajoranaDetectorView (private)
- (void) makeAllSegments;
@end

@implementation MajoranaDetectorView
- (void) setViewType:(int)aViewType
{
	viewType = aViewType;
}

- (void) makeCrateImage
{
    if(!crateImage){
        crateImage = [[NSImage imageNamed:@"Vme64Crate"] copy];
        NSSize imageSize = [crateImage size];
        [crateImage setSize:NSMakeSize(imageSize.width*.7,imageSize.height*.7)];
    }
}

#define kCrateInsideX        45
#define kCrateInsideY        35
#define kCrateSeparation     20
#define kCrateInsideWidth   237
#define kCrateInsideHeight   85


- (void) drawRect:(NSRect)rect
{
	if(viewType == kUseCrateView){
        int crate;
        for(crate=0;crate<2;crate++){
            float yOffset;
            if(crate==0) yOffset = 0;
            else yOffset = [crateImage imageRect].size.height+20;
            NSRect destRect = NSMakeRect(30,yOffset,[crateImage imageRect].size.width,[crateImage imageRect].size.height);
            [crateImage drawInRect:destRect fromRect:[crateImage imageRect] operation:NSCompositeSourceOver fraction:1.0];
            
            [[NSColor blackColor]set];
            NSRect inside = NSMakeRect(kCrateInsideX,yOffset+kCrateInsideY,kCrateInsideWidth,kCrateInsideHeight);
            [NSBezierPath fillRect:inside];
            
            [[NSColor grayColor]set];
            float dx = inside.size.width/21.;
            float dy = inside.size.height/8.;
            [NSBezierPath setDefaultLineWidth:.5];
            int i;
            for(i=0;i<21;i++){
                [NSBezierPath strokeLineFromPoint:NSMakePoint(inside.origin.x+i*dx,inside.origin.y) toPoint:NSMakePoint(inside.origin.x+i*dx,inside.origin.y + inside.size.height)];
            }
            
            for(i=0;i<8;i++){
                [NSBezierPath strokeLineFromPoint:NSMakePoint(inside.origin.x,inside.origin.y+i*dy) toPoint:NSMakePoint(inside.origin.x + inside.size.width,inside.origin.y+i*dy)];
            }
            
            
        }

		 
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
		float dx = kCrateInsideWidth/21.;
		float dy = kCrateInsideHeight/8.;
		NSMutableArray* segmentPaths = [NSMutableArray arrayWithCapacity:kNumTubes];
		NSMutableArray* errorPaths   = [NSMutableArray arrayWithCapacity:kNumTubes];
		ORSegmentGroup* aGroup = [delegate segmentGroup:0];
		int i;
		int n = [aGroup numSegments];
		for(i=0;i<n;i++){
			ORDetectorSegment* aSegment = [aGroup segment:i];
            int crate    = [[aSegment objectForKey:[aSegment mapEntry:[aSegment crateIndex] forKey:@"key"]] intValue];
			int cardSlot = [aSegment cardSlot];
			int channel  = [aSegment channel];
			if(channel < 0)cardSlot = -1; //we have to make the segment, but we'll draw off screen when not mapped
            float yOffset;
            if(crate==0) yOffset = kCrateInsideY;
            else yOffset = [crateImage imageRect].size.height+kCrateSeparation+kCrateInsideY;
            
			NSRect channelRect = NSMakeRect(kCrateInsideX+cardSlot*dx, yOffset + (channel*dy),dx,dy);
            
			[segmentPaths addObject:[NSBezierPath bezierPathWithRect:channelRect]];
			[errorPaths addObject:[NSBezierPath bezierPathWithRect:NSInsetRect(channelRect, 4, 4)]];
		}
		
		[segmentPathSet addObject:segmentPaths];
		[errorPathSet addObject:errorPaths];
	}
	
	else if(viewType == kUseTubeView) {		
		
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
