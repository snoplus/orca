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
@class ORAnalysisPanel2D;

@interface ORGate2D : NSObject {
	ORCurve2D*		mCurve;
	NSMutableDictionary*	attributes;
	ORAnalysisPanel2D*		analysis;
	NSMutableArray* points;
	ORPoint*		selectedPoint;	//x in x-axis coords, y in y-axis coords
	BOOL			cmdKeyIsDown;
	BOOL			mouseIsDown;
	BOOL			dragWholePath;
	NSBezierPath*   theGatePath;
	NSPoint			dragStartPoint;
	BOOL			drawControlPoints;
	BOOL			analyze;
	double			totalSum;
	float           peaky;
	float           peakx;
	float			average;

}
- (id) initForCurve:(ORCurve2D*)aCurve;
- (void) setDefaults;
- (void) registerNotificationObservers;

#pragma mark •••Accessors
- (BOOL) gateIsActive;
- (BOOL) gateValid;
- (int) curveNumber;
- (int) gateNumber;
- (void) setGateValid:(BOOL)newGateValid;
- (void) postNewGateID;
- (NSArray*)points;
- (void) setPoints:(NSMutableArray*)somePoints;
- (ORAnalysisPanel2D *)analysis;
- (void)setAnalysis:(ORAnalysisPanel2D *)anAnalysis;
- (NSMutableDictionary *)attributes;
- (void)setAttributes:(NSMutableDictionary *)anAttributes;
- (BOOL) analyze;
- (void) setAnalyze:(BOOL)newAnalyze;
- (BOOL) gateValid;
- (void) setGateValid:(BOOL)newGateValid;
- (double) average;
- (void) setAverage:(double)newAve;
- (double) totalSum;
- (void) setTotalSum:(double)newTotalSum;
- (void) setPeakx:(int)aValue;
- (int)  peakx;
- (void) setPeaky:(int)aValue;;
- (int)  peaky;
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
extern NSString* ORGate2DValidChangedNotification;
extern NSString* ORGate2DAverageChangedNotification;
extern NSString* ORGate2DTotalSumChangedNotification;
extern NSString* ORGate2DNumberChangedNotification;
extern NSString* ORGate2DDisplayGateChangedNotification;
extern NSString* ORGate2DDisplayedGateChangedNotification;
extern NSString* ORGate2DPeakXChangedNotification;
extern NSString* ORGate2DPeakYChangedNotification;

