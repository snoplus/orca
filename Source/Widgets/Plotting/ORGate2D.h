//
//  ORGate2D.h
//  Orca
//
//  Created by Mark Howe on 2/16/08.
//  Copyright 2008 CENPA, University of Washington. All rights reserved.
//
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

@class ORPlotter2D;
@class ORGateKey;

@interface ORGate2D : NSObject {
	BOOL            displayGate;
	ORGateKey*      cachedGate;
	NSString*       displayedGateName;
	int             gate1,gate2;
	NSMutableArray* points;
	BOOL			cmdKeyIsDown;
	
}

#pragma mark •••Accessors
- (NSArray*)points;
- (void) setPoints:(NSMutableArray*)somePoints;

- (void) mouseDown:(NSEvent*)theEvent plotter:(ORPlotter2D*)aPlotter;
- (void) doDrag:(NSEvent*)theEvent  plotter:(ORPlotter2D*)aPlotter;
- (void) mouseDragged:(NSEvent*)theEvent plotter:(ORPlotter2D*)aPlotter;
- (void) mouseUp:(NSEvent*)theEvent plotter:(ORPlotter2D*)aPlotter;
- (void) analyzePlot:(ORPlotter2D*)aPlot;
- (void)flagsChanged:(NSEvent *)theEvent plotter:(ORPlotter2D*)aPlotter;

@end

@interface ORPoint : NSObject {
	NSPoint point;
}
+ (id) point:(NSPoint)aPoint;

- (id) initWithPoint:(NSPoint)aPoint;
- (NSPoint) point;
- (void) setPoint:(NSPoint)aPoint;
- (void) drawPointInPlot:(ORPlotter2D*)aPlotter;

@end

extern NSString* ORPointChanged;

