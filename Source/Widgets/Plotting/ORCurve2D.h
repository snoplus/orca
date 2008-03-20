//
//  ORCurve2D.h
//  testplot
//
//  Created by Mark Howe on Mon May 17 2004.
//  Copyright (c) 2004 CENPA, University of Washington. All rights reserved.
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
@class ORGate2D;

@interface ORCurve2D : NSObject <NSCoding> {
    NSMutableDictionary*	attributes;
    NSString*				autoSaveName;
    BOOL					analyze;
    int						dataSetID;
    double					maxValue;
	BOOL					showActiveGate;
	int						activeGateIndex;
	NSMutableArray*			gates;
}
+ (id) curve:(int)aDataSetID;
- (id) initWithCurve:(int)aDataSetID;
- (id) init;
- (void)dealloc;
- (void) setDefaults;
- (NSMutableDictionary *)attributes;
- (void)setAttributes:(NSMutableDictionary *)anAttributes;
- (int)dataSetID;
- (void)setDataSetID:(int)aDataSetID;
- (void) drawDataInPlot:(ORPlotter2D*)aPlot;
- (void) drawVector:(ORPlotter2D*)aPlot;
- (double) maxValue;

- (NSArray*) gates;
- (void) setGates:(NSMutableArray*)anArray;
- (void) addGate:(ORGate2D*)aGate;
- (void) removeActiveGate;
- (int) gateNumber:(ORGate2D*)aGate;
- (int)activeGateIndex;
- (void)setActiveGateIndex:(int)anactiveCurveIndex;
- (id) activeGate;
- (BOOL) incGate;
- (BOOL) decGate;
- (int) gateCount;
- (void) clearActiveGate;
- (void) clearAllGates;
- (BOOL) showActiveGate;
- (void) setShowActiveGate: (BOOL) flag;
- (void) doAnalysis:(ORPlotter2D*)aPlotter;
- (void)flagsChanged:(NSEvent *)theEvent plotter:(ORPlotter2D*)aPlotter;

#pragma mark ¥¥¥Mouse Handling
-(void)	mouseDown:(NSEvent*)theEvent  plotter:(ORPlotter2D*)aPlotter;
-(void)	mouseDragged:(NSEvent*)theEvent  plotter:(ORPlotter2D*)aPlotter;
-(void)	mouseUp:(NSEvent*)theEvent  plotter:(ORPlotter2D*)aPlotter;

@end

extern NSString* ORCurve2DActiveGateChanged;

