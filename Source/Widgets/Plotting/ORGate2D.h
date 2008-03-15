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
@class ORPoint;
@class ORCurve2D;

@interface ORGate2D : NSObject {
	ORCurve2D*		mCurve;
	BOOL            displayGate;
	ORGateKey*      cachedGate;
	NSString*       displayedGateName;
	NSMutableArray* points;
	ORPoint*		selectedPoint;	//x in x-axis coords, y in y-axis coords
	BOOL			cmdKeyIsDown;
	BOOL			mouseIsDown;
	BOOL			dragWholePath;
	NSBezierPath*   theGatePath;
	NSPoint			dragStartPoint;
	BOOL			drawControlPoints;

}
- (id) initForCurve:(ORCurve2D*)aCurve;

#pragma mark •••Accessors
- (NSArray*)points;
- (void) setPoints:(NSMutableArray*)somePoints;

- (void) mouseDown:(NSEvent*)theEvent plotter:(ORPlotter2D*)aPlotter;
- (void) mouseDragged:(NSEvent*)theEvent plotter:(ORPlotter2D*)aPlotter;
- (void) mouseUp:(NSEvent*)theEvent plotter:(ORPlotter2D*)aPlotter;
- (void) analyzePlot:(ORPlotter2D*)aPlot;
- (void)flagsChanged:(NSEvent *)theEvent plotter:(ORPlotter2D*)aPlotter;

@end

#define kPointSize 6

@interface ORPoint : NSObject {
	NSPoint xyPosition;
}
+ (id) point:(NSPoint)aPoint;

- (id) initWithPoint:(NSPoint)aPoint;
- (NSPoint) xyPosition;
- (void) setXyPosition:(NSPoint)aPoint;
- (void) drawPointInPlot:(ORPlotter2D*)aPlotter;

@end

extern NSString* ORPointChanged;

