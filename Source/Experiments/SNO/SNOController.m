//
//  SNOController.m
//  Orca
//
//  Created by Mark Howe on Wed Nov 20 2002.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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


#pragma mark •••Imported Files
#import "SNOController.h"
#import "SNOModel.h"
#import "ORColorScale.h"
#import "ORAxis.h"
#import "ORSNOConstants.h"
#import "ORPSUPTubePosition.h"
#import "ORSNOCableDB.h"

@implementation SNOController
#pragma mark •••Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"SNO"];
    return self;
}

- (void) dealloc
{
    
    [super dealloc];
}

-(void) awakeFromNib
{
	[[self window] setAspectRatio:NSMakeSize(5,3)];
	[[self window] setMinSize:NSMakeSize(600,360)];
    [super awakeFromNib];
}

#pragma mark •••Accessors

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    [notifyCenter addObserver : self
                     selector : @selector(colorAttributesChanged:)
                         name : ORSNORateColorBarChangedNotification
                       object : model];
    

    
    //a fake action for the scale objects
    [notifyCenter addObserver : self
                     selector : @selector(scaleAction:)
                         name : ORAxisRangeChangedNotification
                       object : nil];
}

- (void) drawView:(NSView*)aView inRect:(NSRect)aRect
{
	int crate,card,pmt;
	float scaleFactor = (aRect.size.width-20)/kPSUP_width;
	float tubeSize = 4.*aRect.size.width/kPSUP_width;
	ORSNOCableDB* db = [ORSNOCableDB sharedSNOCableDB];
	int i;
	float xoffset = 25;
	float yoffset = 17;
	for(i=0;i<kCMPSUPSTRUT;i++){
		float x1 = (PSUPstrut[i].x1+xoffset) * scaleFactor;
		float y1 = (PSUPstrut[i].y1+yoffset) * scaleFactor;
		float x2 = (PSUPstrut[i].x2+xoffset) * scaleFactor;
		float y2 = (PSUPstrut[i].y2+yoffset) * scaleFactor;
		[NSBezierPath strokeLineFromPoint:NSMakePoint(x1,y1) toPoint:NSMakePoint(x2,y2)];
	}
	
	for(crate=0;crate<kMaxSNOCrates+2;crate++){
		for(card=0;card<kNumSNOCards;card++){
			for(pmt=0;pmt<kNumSNOPmts;pmt++){
				int tubeType = [db tubeTypeCrate:crate card:card channel:pmt];
				if(tubeType >= kTubeTypeNormal && tubeType<=kTubeTypeLowGain){
					int tubeIndex = kChannelsPerCrate * crate + kChannelsPerBoard* card + pmt;
					NSColor* tubeColor = [db pmtColor:crate card:card channel:pmt];
					[tubeColor set];
					float x = psupTubePosition[tubeIndex].x * scaleFactor;
					float y = (psupTubePosition[tubeIndex].y-22) * scaleFactor;
					NSBezierPath* tube = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(x-tubeSize/2.,y-tubeSize/2.,tubeSize,tubeSize)];
					[tube fill];
				}
			}
		}
	}
	
}

#pragma mark •••Actions
//a fake action from the scale object
- (void) scaleAction:(NSNotification*)aNotification
{
    if(aNotification == nil || [aNotification object] == [detectorColorBar colorAxis]){
        [[self undoManager] setActionName: @"Set Color Bar Attributes"];
        [model setColorBarAttributes:[[detectorColorBar colorAxis]attributes]];
    }
}


#pragma mark •••Interface Management
- (void) updateWindow
{
    [super updateWindow];
    [self colorAttributesChanged:nil];
}

- (void) colorAttributesChanged:(NSNotification*)aNote
{        
	[[detectorColorBar colorAxis] setAttributes:[model colorBarAttributes]];
	[detectorColorBar setNeedsDisplay:YES];
	[[detectorColorBar colorAxis]setNeedsDisplay:YES];
	
	BOOL state = [[[model colorBarAttributes] objectForKey:ORAxisUseLog] boolValue];
	[colorBarLogCB setState:state];
}


@end

@implementation ORPSUPView
- (BOOL)isFlipped
{
	return YES;
}
@end

