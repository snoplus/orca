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
#import "ORAxis.h"


@interface MajoranaDetectorView (private)
- (void) makeAllSegments;
- (void) makeDetectors;
- (void) makeVeto;
- (void) drawLabels;
@end

@implementation MajoranaDetectorView

- (void) dealloc
{
    [detectorOutlines release];
    int i;
    for(i=0;i<14;i++){
        [stringLabel[i] release];
    }
    [stringLabelAttributes release];
    [super dealloc];
}

- (void) awakeFromNib
{
	[[detectorColorScale colorAxis] setLabel:@"Detectors"];
	[[vetoColorScale colorAxis] setLabel:@"Veto"];
	[[vetoColorScale colorAxis] setOppositePosition:YES];
	[detectorColorScale setExcludeZero:YES];
	[vetoColorScale setExcludeZero:YES];
}
- (void) setViewType:(int)aViewType
{
	viewType = aViewType;
}
- (BOOL) isOpaque {return YES;}
- (void) makeCrateImage
{
    if(!crateImage){
        crateImage = [[NSImage imageNamed:@"Vme64Crate"] copy];
        NSSize imageSize = [crateImage size];
        [crateImage setSize:NSMakeSize(imageSize.width*.7,imageSize.height*.7)];
    }
}

#define kCrateInsideX        85
#define kCrateInsideY        35
#define kCrateSeparation     20
#define kCrateInsideWidth   237
#define kCrateInsideHeight   85


- (void) drawRect:(NSRect)rect
{
    [[NSColor colorWithCalibratedRed:.88 green:.88 blue:.88 alpha:1] set];
    [NSBezierPath fillRect:rect];
    

	if(viewType == kUseCrateView){
        [self makeCrateImage];
 		NSFont* font = [NSFont systemFontOfSize:9.0];
		NSDictionary* attrsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName,[NSColor blackColor],NSForegroundColorAttributeName,nil];
       int crate;
        for(crate=0;crate<2;crate++){
            float yOffset;
            if(crate==0) yOffset = 50;
            else yOffset = 50+[crateImage imageRect].size.height+20;
            NSRect destRect = NSMakeRect(70,yOffset,[crateImage imageRect].size.width,[crateImage imageRect].size.height);
            [crateImage drawInRect:destRect fromRect:[crateImage imageRect] operation:NSCompositeSourceOver fraction:1.0];
            
            [[NSColor blackColor]set];
            NSRect inside = NSMakeRect(kCrateInsideX,yOffset+kCrateInsideY,kCrateInsideWidth,kCrateInsideHeight);
            [NSBezierPath fillRect:inside];
            
            [[NSColor grayColor]set];
            float dx = inside.size.width/21.;
            //float dy = inside.size.height/10.;
            [NSBezierPath setDefaultLineWidth:.5];
            int i;
            for(i=0;i<21;i++){
                [NSBezierPath strokeLineFromPoint:NSMakePoint(inside.origin.x+i*dx,inside.origin.y) toPoint:NSMakePoint(inside.origin.x+i*dx,inside.origin.y + inside.size.height)];
            }
            
            NSAttributedString* s = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Crate %d",crate] attributes:attrsDictionary];
            float sw = [s size].width;
            [s drawAtPoint:NSMakePoint(kCrateInsideX+kCrateInsideWidth/2-sw/2,yOffset+kCrateInsideY+kCrateInsideHeight+1)];
            [s release];
        }
	}
    else if(viewType == kUseDetectorView){
        [[NSColor darkGrayColor]set];
        for(id aDetector in detectorOutlines){
            [aDetector fill];
        }
        [self drawLabels];
    }

    [super drawRect:rect];
    

}

- (NSColor*) getColorForSet:(int)setIndex value:(unsigned long)aValue
{
	if(setIndex==0) return [detectorColorScale getColorForValue:aValue];
	else            return [vetoColorScale getColorForValue:aValue];
}

- (void) downArrow
{
    int n = [detectorOutlines count]*2;
    if(n==0)return;
	selectedPath++;
	if(selectedSet == 0) selectedPath %= n;
}

- (void) upArrow
{
    int n = [detectorOutlines count]*2;
    if(n<1)return;
	selectedPath--;
	if(selectedSet == 0){
		if(selectedPath < 0) selectedPath = n-1;
	}

}

@end
@implementation MajoranaDetectorView (private)
- (void) makeAllSegments
{	
	[super makeAllSegments];
	
	if(viewType == kUseCrateView){
		float dx = kCrateInsideWidth/21.;
        int numSets = [delegate numberOfSegmentGroups];
        int set;
        for(set=0;set<numSets;set++){
            float dy;
            if(set==0)  dy= kCrateInsideHeight/10.;
            else        dy= kCrateInsideHeight/16.;
            NSMutableArray* segmentPaths = [NSMutableArray arrayWithCapacity:kNumDetectors];
            NSMutableArray* errorPaths   = [NSMutableArray arrayWithCapacity:kNumDetectors];

            ORSegmentGroup* aGroup = [delegate segmentGroup:set];
            int i;
            int n = [aGroup numSegments];
            for(i=0;i<n;i++){
                ORDetectorSegment* aSegment = [aGroup segment:i];
                int crate    = [[aSegment objectForKey:[aSegment mapEntry:[aSegment crateIndex] forKey:@"key"]] intValue];
                int cardSlot = [aSegment cardSlot];
                int channel  = [aSegment channel];
                if(channel < 0)cardSlot = -1; //we have to make the segment, but we'll draw off screen when not mapped
                
                float yOffset;
                if(cardSlot<0)yOffset = -50000;
                else {
                    if(crate==0) yOffset = 50+kCrateInsideY;
                    else yOffset = 50+[crateImage imageRect].size.height+kCrateSeparation+kCrateInsideY;
                }
                
                NSRect channelRect = NSMakeRect(kCrateInsideX+cardSlot*dx, yOffset + (channel*dy),dx,dy);
                
                [segmentPaths addObject:[NSBezierPath bezierPathWithRect:channelRect]];
                [errorPaths addObject:[NSBezierPath bezierPathWithRect:NSInsetRect(channelRect, 4, 4)]];
            }
            [segmentPathSet addObject:segmentPaths];
            [errorPathSet addObject:errorPaths];
        }
	}
	
	else if(viewType == kUseDetectorView) {
		[self makeDetectors];
		[self makeVeto];
	}
    [self setNeedsDisplay:YES];
}

- (void) drawLabels
{
    if(!stringLabelAttributes){
        NSFont* theFont = [NSFont fontWithName:@"Geneva" size:8];
        stringLabelAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
                                  theFont,NSFontAttributeName,
                                  [NSColor blueColor],NSForegroundColorAttributeName,
                                  nil] retain];
    }
    int i;
    float x = 65;
    float y = 373;
    for(i=0;i<7;i++){
        [stringLabel[i] drawAtPoint:NSMakePoint(x,y) withAttributes:stringLabelAttributes];
        x += 40;
    }
    x = 65;
    y = 251;
    for(i=7;i<14;i++){
        [stringLabel[i] drawAtPoint:NSMakePoint(x,y) withAttributes:stringLabelAttributes];
        x += 40;
        
    }
}


- (void) makeDetectors
{
    NSMutableArray* segmentPaths     = [NSMutableArray arrayWithCapacity:kNumDetectors];
    NSMutableArray* errorPaths       = [NSMutableArray arrayWithCapacity:kNumDetectors];
    [detectorOutlines release];
    detectorOutlines = [[NSMutableArray arrayWithCapacity:kNumDetectors] retain];
    
    float height = [self bounds].size.height;
    float detWidth = 30;
    float dh = detWidth/2.+2;
    float detSpacing = 5;
    
    ORSegmentGroup* aGroup = [delegate segmentGroup:0];
    int numSegments = [aGroup numSegments];

    //we have to make all segments. If a segment doesn't belong to a string, we will just put it offscreen.
    int stringNum;
    for(stringNum=0;stringNum<14;stringNum++){
        int detectorNum;
        
        float           y = height-60;
        if(stringNum>=7)y = height-182;
        float           x = 67 + stringNum%7 * 40;
        
        BOOL atLeastOne = NO;
        for(detectorNum=0;detectorNum<5;detectorNum++){
            
            float detHeight = dh;
            BOOL skip  = NO;
            
            NSString* sn = [delegate stringMap:stringNum objectForKey:[NSString stringWithFormat:@"kDet%d",detectorNum+1]];
            if([sn rangeOfString:@"-"].location != NSNotFound || [sn length] == 0){
                skip = YES;
            }
            
            int detIndex = [sn intValue]*2;
            if(detIndex > numSegments) continue;
            
            ORDetectorSegment* aSegment = [aGroup segment:detIndex];
            int type = [[aSegment objectForKey:@"kDetectorType"] intValue];
            if(type>0) detHeight = dh * 1.3;
            if(!skip){

                atLeastOne = YES;
                NSRect r = NSMakeRect(x,y-detHeight/2,detWidth,detHeight/2.);
                [segmentPaths addObject:[NSBezierPath bezierPathWithRect:r]];
                [errorPaths   addObject:[NSBezierPath bezierPathWithRect:NSInsetRect(r, -5, -5)]];
                
                r = NSMakeRect(x,y-detHeight,detWidth,detHeight/2.);
                [segmentPaths   addObject:[NSBezierPath bezierPathWithRect:r]];
                [errorPaths     addObject:[NSBezierPath bezierPathWithRect:NSInsetRect(r, -5, -5)]];
                
                r = NSMakeRect(x-2,y-detHeight-2,detWidth+4,detHeight+4);
                [detectorOutlines   addObject:[NSBezierPath bezierPathWithRect:r]];
            }
             y -= (detHeight + detSpacing);            

        }
        if(atLeastOne){
            [stringLabel[stringNum] autorelease];
            stringLabel[stringNum] = [[NSString stringWithFormat:@"Str%d,%d",stringNum/7+1,stringNum%7 + 1] retain];
        }
        else {
            [stringLabel[stringNum] release];
            stringLabel[stringNum] = nil;
        }
    }
    
    
    //store into the whole set
    [segmentPathSet addObject:segmentPaths];
    [errorPathSet addObject:errorPaths];
}

- (void) makeVeto
{
    NSMutableArray* segmentPaths = [NSMutableArray arrayWithCapacity:kNumVetoSegments];
    NSMutableArray* errorPaths   = [NSMutableArray arrayWithCapacity:kNumVetoSegments];

    float height = [self bounds].size.height;
    float width = [self bounds].size.width;
    int i;
    
    //Overfloor panel #1
    float y = 10;
    float w = 12;
    float x = 10;
    for(i=0;i<6;i++){
        NSRect r = NSMakeRect(x,y,w*6,w);
        y+=w;
        [segmentPaths addObject:[NSBezierPath bezierPathWithRect:r]];
        [errorPaths   addObject:[NSBezierPath bezierPathWithRect:NSInsetRect(r, -2, -2)]];
    }
    //Overfloor panel #2
    x = w*6+30;
    y = 10;
    for(i=0;i<6;i++){
        NSRect r = NSMakeRect(x,y,w,w*6);
        x+=w;
        [segmentPaths addObject:[NSBezierPath bezierPathWithRect:r]];
        [errorPaths   addObject:[NSBezierPath bezierPathWithRect:NSInsetRect(r, -2, -2)]];
    }

    //Top panels
    w = 18;
    x = width - 10 - w * 4;
    y = 10;
    for(i=0;i<4;i++){
        NSRect r = NSMakeRect(x,y,w*4,w);
        y+=w;
        [segmentPaths addObject:[NSBezierPath bezierPathWithRect:r]];
        [errorPaths   addObject:[NSBezierPath bezierPathWithRect:NSInsetRect(r, -2, -2)]];
    }

    //Outer Panel1 (left side)
    //Inner Panel1
    x = 10;
    float h = 235;
    w = 10;
    y = 145;
    for(i=0;i<4;i++){
        NSRect r = NSMakeRect(x,y,w,h);
        x += w;
        if(i==1)x+=5;
        [segmentPaths addObject:[NSBezierPath bezierPathWithRect:r]];
        [errorPaths   addObject:[NSBezierPath bezierPathWithRect:NSInsetRect(r, -2, -2)]];
    }
    
    
    //Outer Panel2
    //Inner Panel2
    x = 10 + 40 + 15;
    w = 10;
    y = 140 - 40 - 5;
    h = 275;
    for(i=0;i<4;i++){
        NSRect r = NSMakeRect(x,y,h,w);
        y += w;
        if(i==1)y+=5;
        [segmentPaths addObject:[NSBezierPath bezierPathWithRect:r]];
        [errorPaths   addObject:[NSBezierPath bezierPathWithRect:NSInsetRect(r, -2, -2)]];
    }
   
    //Outer Panel3
    //Inner Panel3
    w = 10;
    y = 145;
    x = width-5-w;
    h = 235;
    for(i=0;i<4;i++){
        NSRect r = NSMakeRect(x,y,w,h);
        x -= w;
        if(i==1)x-=5;
        [segmentPaths addObject:[NSBezierPath bezierPathWithRect:r]];
        [errorPaths   addObject:[NSBezierPath bezierPathWithRect:NSInsetRect(r, -2, -2)]];
    }
    
    //Outer Panel4 (top in view)
    //Inner Panel4
    x = 10 + 40 + 15;
    w = 10;
    y = height - 11;
    h = 275;
    for(i=0;i<4;i++){
        NSRect r = NSMakeRect(x,y,h,w);
        y -= w;
        if(i==1)y-=5;
        [segmentPaths addObject:[NSBezierPath bezierPathWithRect:r]];
        [errorPaths   addObject:[NSBezierPath bezierPathWithRect:NSInsetRect(r, -2, -2)]];
    }
    //store into the whole set
    [segmentPathSet addObject:segmentPaths];
    [errorPathSet addObject:errorPaths];
}

- (NSColor*) outlineColor:(int)aSet
{
    if(aSet==0) return [NSColor grayColor];
    else return[NSColor lightGrayColor];
}


@end
