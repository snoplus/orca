//
//  ORFecPmtsView.h
//  Orca
//
//  Created by Mark Howe on 10/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

@interface ORFecPmtsView : NSView {
	IBOutlet id controller;
	IBOutlet id anchorView; //view to draw pmt lines to/from
	NSBezierPath* topPath[32];
	NSBezierPath* bodyPath[32];	
	NSBezierPath* clickPath[32];

}
- (void) drawPMT:(int)index at:(NSPoint)neckPoint direction:(float)angle ;
- (void) drawPMTSwitch:(int)index at:(NSPoint)switchPoint direction:(float)angle;

@end
