//
//  ORGretinaCntView.m
//  Orca
//
//  Created by Mark Howe on 1/25/13.
//  Copyright (c) 2013 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#import "ORGretinaCntView.h"
#import "ORGretina4MController.h"

#define kBugPad 10

@implementation ORGretinaCntView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
 		bugImage   = [[NSImage imageNamed:@"topBug"] retain];
        plotGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:1.0 alpha:1.0] endingColor:[NSColor colorWithCalibratedWhite:.75 alpha:1.0]];

        b               = [self bounds];
        b.origin.x      += kBugPad/2.;
        b.size.height   -= kBugPad;
        b.size.width    -= kBugPad;
	}
    return self;
}

- (void) dealloc
{
	[bugImage release];
	[plotGradient release];
	[super dealloc];
}

- (void) awakeFromNib
{
    [self loadLocalFields];
}

#pragma mark ¥¥¥Drawing
- (void)drawRect:(NSRect)rect 
{
	[plotGradient drawInRect:b angle:270.];

    if([self anythingSelected]){
        
        [self loadLocalFields];
        
        [[NSColor blackColor] set];
        [NSBezierPath setDefaultLineWidth:.5];

        //draw the flat top counter
        [bugImage drawAtPoint:NSMakePoint( flatTopBugX-kBugPad/2.,b.size.height) fromRect:[bugImage imageRect] operation:NSCompositeSourceOver fraction:1.0];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(flatTopBugX,0) toPoint:NSMakePoint(flatTopBugX,b.size.height)];
        
        //draw the post rising edge counter
        [bugImage drawAtPoint:NSMakePoint( postReBugX-kBugPad/2.,b.size.height) fromRect:[bugImage imageRect] operation:NSCompositeSourceOver fraction:1.0];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(postReBugX,0) toPoint:NSMakePoint(postReBugX,b.size.height)];
     
        //draw the pre rising edge counter
        [bugImage drawAtPoint:NSMakePoint( preReBugX-kBugPad/2.,b.size.height) fromRect:[bugImage imageRect] operation:NSCompositeSourceOver fraction:1.0];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(preReBugX,0) toPoint:NSMakePoint(preReBugX,b.size.height)];

        [NSBezierPath setDefaultLineWidth:2.];
        [[NSColor redColor] set];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(kBugPad/2., 10) toPoint:NSMakePoint(preReBugX, 10)];
     
        [[NSColor blueColor] set];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(preReBugX, 10) toPoint:NSMakePoint(postReBugX, 10)];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(postReBugX, 10) toPoint:NSMakePoint(postReBugX, 50)];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(postReBugX, 50) toPoint:NSMakePoint(flatTopBugX, 50)];

        [[NSColor redColor] set];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(flatTopBugX, 50) toPoint:NSMakePoint(b.size.width+kBugPad/2, 50)];

        [NSBezierPath setDefaultLineWidth:1.];
        [[NSColor blackColor] set];
        
        int postPlusPre   = [postReField intValue] + [preReField intValue];
        NSColor* reColor;
        if(postPlusPre<1024)reColor = [NSColor blackColor];
        else                reColor = [NSColor redColor];
        NSString* ps = [NSString stringWithFormat:@"%d",postPlusPre];
        
        NSFont* theFont = [NSFont fontWithName:@"Geneva" size:9];
        NSDictionary* theAttributes = [NSDictionary dictionaryWithObjectsAndKeys:theFont,NSFontAttributeName,reColor,NSForegroundColorAttributeName,nil];
        NSAttributedString* s = [[NSAttributedString alloc] initWithString:ps attributes:theAttributes];
        NSSize stringSize = [s size];
        float x = preReBugX + (flatTopBugX-preReBugX)/2. - stringSize.width/2.;
        [s drawAtPoint:NSMakePoint(x,b.size.height-stringSize.height)];
        [s release];

        NSString* bls = [NSString stringWithFormat:@"%d",baseline];
        theAttributes = [NSDictionary dictionaryWithObjectsAndKeys:theFont,NSFontAttributeName,[NSColor blackColor],NSForegroundColorAttributeName,nil];
        s = [[NSAttributedString alloc] initWithString:bls attributes:theAttributes];
        stringSize = [s size];
        x = MAX(kBugPad/2.,kBugPad/2. + (preReBugX-kBugPad/2.)/2. - stringSize.width/2.);
        [s drawAtPoint:NSMakePoint(x,b.size.height-stringSize.height)];
        [s release];

        NSString* fts = [NSString stringWithFormat:@"%d",[flatTopField intValue]];
        theAttributes = [NSDictionary dictionaryWithObjectsAndKeys:theFont,NSFontAttributeName,[NSColor blackColor],NSForegroundColorAttributeName,nil];
        s = [[NSAttributedString alloc] initWithString:fts attributes:theAttributes];
        stringSize = [s size];
        x = flatTopBugX + (b.size.width-flatTopBugX)/2. - stringSize.width/2.;
        if(x + stringSize.width/2 > b.size.width)x = b.size.width-stringSize.width;
        [s drawAtPoint:NSMakePoint(x,b.size.height-stringSize.height)];
        [s release];

    }
	[NSBezierPath strokeRect:b];
}

- (BOOL) anythingSelected
{
    int i;
    for(i=0;i<kNumGretina4MChannels;i++){
        if([[dataSource model]easySelected:i])return YES;
    }
    return NO;
}

- (void) initBugs
{
    int i;
    for(i=0;i<kNumGretina4MChannels;i++){
        if([[dataSource model]easySelected:i]){
            int ftCnt       = [[dataSource model] ftCnt:i];
            int postrecnt   = [[dataSource model] postrecnt:i];
            int prerecnt    = [[dataSource model] prerecnt:i];
                        
            flatTopBugX = b.origin.x + (2048. - ftCnt)* b.size.width/2048.;
            postReBugX  = flatTopBugX -  postrecnt* b.size.width/2048.;
            preReBugX = postReBugX -  prerecnt* b.size.width/2048.;
            break;
        }
    }
}

- (void) loadLocalFields
{
    int i;
    for(i=0;i<kNumGretina4MChannels;i++){
        if([[dataSource model]easySelected:i]){
            [preReField setIntValue:[[dataSource model] prerecnt:i]];
            [postReField setIntValue:[[dataSource model] postrecnt:i]];
            [flatTopField setIntValue:[[dataSource model] ftCnt:i]];
            baseline = [[dataSource model] baseLineLength:i];
            break;
        }
    }
}

- (void) applyConstrainsts
{
    float minX = b.origin.x;
    float maxX = b.size.width + kBugPad/2.;
    
    if(movingFlatTop){
        if(flatTopBugX < minX)      flatTopBugX = minX;
        else if(flatTopBugX > maxX) flatTopBugX = maxX;

        if(flatTopBugX < postReBugX+1)      flatTopBugX = postReBugX+1;
    }
    else if(movingPostRisingEdge){
        if(postReBugX < minX)      postReBugX = minX;
        else if(postReBugX > maxX) postReBugX = maxX;

        if(postReBugX < preReBugX+1)postReBugX = preReBugX+1;
        else if(postReBugX > flatTopBugX-1)postReBugX = flatTopBugX-1;
    }
    else if(movingPreRisingEdge){
        if(preReBugX < minX)      preReBugX = minX;
        else if(preReBugX > maxX) preReBugX = maxX;

        if(preReBugX > postReBugX-1)preReBugX = postReBugX-1;
    }
}

- (void) setValues:(BOOL)finalValues
{
    int i;
    for(i=0;i<kNumGretina4MChannels;i++){
        if([[dataSource model]easySelected:i]){
            [self setValues:i final:finalValues];
        }
    }
}

- (void) setValues:(short)channel final:(BOOL)finalValues
{
	if(!finalValues)[[[NSApp delegate] undoManager] disableUndoRegistration];
    
    int ftCnt = 2048 - (flatTopBugX-b.origin.x)*2048/b.size.width;
    [[dataSource model] setFtCnt:channel withValue:ftCnt];
    
    int postCnt = ((flatTopBugX - postReBugX)-b.origin.x)*2048/b.size.width;
    [[dataSource model] setPostrecnt:channel withValue:postCnt];
 
    int preCnt = ((postReBugX - preReBugX)-b.origin.x)*2048/b.size.width;
    [[dataSource model] setPrerecnt:channel withValue:preCnt];

    
	if(!finalValues)[[[NSApp delegate] undoManager] enableUndoRegistration];
}

#pragma mark ¥¥¥Archival
- (void) mouseDown:(NSEvent*)event
{
	[[self undoManager] disableUndoRegistration];
    NSPoint localPoint = [self convertPoint:[event locationInWindow] fromView:nil];

	movingPreRisingEdge		= NO;
	movingPostRisingEdge	= NO;
	movingFlatTop           = NO;

    
    NSRect r1 = NSMakeRect(preReBugX-kBugPad/2.,b.size.height,kBugPad,kBugPad);
    NSRect r2 = NSMakeRect(preReBugX-2,0,4,b.size.height);
    if(NSPointInRect(localPoint,r1) || NSPointInRect(localPoint,r2)){
        movingPreRisingEdge = YES;
        [[NSCursor closedHandCursor] set];
        [self setNeedsDisplay:YES];
        return;
    }

    r1 = NSMakeRect(flatTopBugX-kBugPad/2.,b.size.height,kBugPad,kBugPad);
    r2 = NSMakeRect(flatTopBugX-2,0,4,b.size.height);
    if(NSPointInRect(localPoint,r1) || NSPointInRect(localPoint,r2)){
        movingFlatTop = YES;
        [[NSCursor closedHandCursor] set];
        [self setNeedsDisplay:YES];
        return;
    }
    
    r1 = NSMakeRect(postReBugX-kBugPad/2.,b.size.height,kBugPad,kBugPad);
    r2 = NSMakeRect(postReBugX-2,0,4,b.size.height);
    if(NSPointInRect(localPoint,r1) || NSPointInRect(localPoint,r2)){
        movingPostRisingEdge = YES;
        [[NSCursor closedHandCursor] set];
        [self setNeedsDisplay:YES];
        return;
    }
 }

- (void) mouseDragged:(NSEvent*)event
{
	NSPoint localPoint = [self convertPoint:[event locationInWindow] fromView:nil];
	if(movingFlatTop){
        flatTopBugX = localPoint.x;
        [self applyConstrainsts];
        [self setValues:NO];
	}
 	else if(movingPostRisingEdge){
        postReBugX = localPoint.x;
        [self applyConstrainsts];
        [self setValues:NO];
	}
	else if(movingPreRisingEdge){
        preReBugX = localPoint.x;
        [self applyConstrainsts];
        [self setValues:NO];
	}
    [self loadLocalFields];
	[self setNeedsDisplay:YES];
}

- (void) mouseUp:(NSEvent*)event
{
	[[self undoManager] enableUndoRegistration];
	
	NSPoint localPoint = [self convertPoint:[event locationInWindow] fromView:nil];

 	if(movingFlatTop){
        flatTopBugX = localPoint.x;
        [self applyConstrainsts];
        [self setValues:YES];
	}
 	else if(movingPostRisingEdge){
        postReBugX = localPoint.x;
        [self applyConstrainsts];
        [self setValues:YES];
	}
    else if(movingPreRisingEdge){
        preReBugX = localPoint.x;
        [self applyConstrainsts];
        [self setValues:YES];
	}
	[self setNeedsDisplay:YES];
    [self loadLocalFields];
	
	[NSCursor pop];

	movingPreRisingEdge     = NO;
	movingPostRisingEdge    = NO;
	movingFlatTop           = NO;
	[self setNeedsDisplay:YES];
    [[self window] resetCursorRects];
}

- (BOOL)mouseDownCanMoveWindow
{
    return NO;
}

- (void) resetCursorRects
{    
    NSRect r1 = NSMakeRect(flatTopBugX-kBugPad/2.,b.size.height,kBugPad,kBugPad);
    NSRect r2 = NSMakeRect(flatTopBugX-2,0,4,b.size.height);
    [self addCursorRect:r1 cursor:[NSCursor openHandCursor]];
    [self addCursorRect:r2 cursor:[NSCursor openHandCursor]];

    r1 = NSMakeRect(postReBugX-kBugPad/2.,b.size.height,kBugPad,kBugPad);
    r2 = NSMakeRect(postReBugX-2,0,4,b.size.height);
    [self addCursorRect:r1 cursor:[NSCursor openHandCursor]];
    [self addCursorRect:r2 cursor:[NSCursor openHandCursor]];

    r1 = NSMakeRect(preReBugX-kBugPad/2.,b.size.height,kBugPad,kBugPad);
    r2 = NSMakeRect(preReBugX-2,0,4,b.size.height);
    [self addCursorRect:r1 cursor:[NSCursor openHandCursor]];
    [self addCursorRect:r2 cursor:[NSCursor openHandCursor]];
}

- (int)  firstOneSelected
{
    int i;
    for(i=0;i<kNumGretina4MChannels;i++){
        if([[dataSource model]easySelected:i])return i;
    }
    return -1;
}

- (IBAction) tweakFlatTopCounts:(id)sender
{
    int firstOneSelected = [self firstOneSelected];
    if(firstOneSelected >= 0){
        int ftCnt       = [[dataSource model] ftCnt:firstOneSelected] + ([sender tag]?1:-1);
        
        int i;
        for(i=0;i<kNumGretina4MChannels;i++){
            if([[dataSource model]easySelected:i])[[dataSource model] setFtCnt:i withValue:ftCnt];
        }
        movingFlatTop  = YES;
        [self applyConstrainsts];
        [self loadLocalFields];
        [self initBugs];
        movingFlatTop  = NO;
        [self setNeedsDisplay:YES];
    }
}

- (IBAction) tweakPostReCounts:(id)sender
{
    int firstOneSelected = [self firstOneSelected];
    if(firstOneSelected >= 0){
        int postrecnt   = [[dataSource model] postrecnt:firstOneSelected]+([sender tag]?1:-1);
        int i;
        for(i=0;i<kNumGretina4MChannels;i++){
            if([[dataSource model]easySelected:i])[[dataSource model] setPostrecnt:i withValue:postrecnt];
        }
        movingPostRisingEdge  = YES;
        [self applyConstrainsts];
        [self loadLocalFields];
        [self initBugs];
        movingPostRisingEdge  = YES;
        [self setNeedsDisplay:YES];
    }
}

- (IBAction) tweakPreReCounts:(id)sender
{
    int firstOneSelected = [self firstOneSelected];
    if(firstOneSelected >= 0){
        int prerecnt    = [[dataSource model] prerecnt:firstOneSelected] + ([sender tag]?1:-1);
        int i;
        for(i=0;i<kNumGretina4MChannels;i++){
            if([[dataSource model]easySelected:i])[[dataSource model] setPrerecnt:i withValue:prerecnt];
        }
        movingPreRisingEdge  = YES;
        [self applyConstrainsts];
        [self loadLocalFields];
        [self initBugs];
        movingPreRisingEdge  = NO;
        [self setNeedsDisplay:YES];
    }
}

- (IBAction) flatTopCounts:(id)sender
{
    int i;
    for(i=0;i<kNumGretina4MChannels;i++){
        if([[dataSource model]easySelected:i])[[dataSource model] setFtCnt:i withValue:[sender intValue]];
    }
    [self applyConstrainsts];
    [self initBugs];
    [self setNeedsDisplay:YES];
}

- (IBAction) postReCounts:(id)sender
{
    int i;
    for(i=0;i<kNumGretina4MChannels;i++){
        if([[dataSource model]easySelected:i])[[dataSource model] setPostrecnt:i withValue:[sender intValue]];
    }
    [self applyConstrainsts];
    [self initBugs];
    [self setNeedsDisplay:YES];
    
}

- (IBAction) preReCounts:(id)sender
{
    int i;
    for(i=0;i<kNumGretina4MChannels;i++){
        if([[dataSource model]easySelected:i])[[dataSource model] setPrerecnt:i withValue:[sender intValue]];
    }
    [self applyConstrainsts];
    [self initBugs];
    [self setNeedsDisplay:YES];
}


@end
