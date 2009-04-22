//
//  ORCurve1D.h
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




@class ORGate1D;
@class ORPlotter1D;

@interface ORCurve1D : NSObject <NSCoding> {
    NSMutableDictionary* attributes;
    NSMutableArray*		 gates;
    NSString*			 autoSaveName;
    BOOL                 analyze;
    int                  dataSetID;
    int                  activeGateIndex;
    double               maxValue;
    BOOL                 showActiveGate;
}
+ (id) curve:(int)aDataSetID;
- (id) initWithCurve:(int)aDataSetID;
- (id) init;
- (void)dealloc;
- (void) adjustAnalysisPanels;
- (void) setDefaults;
- (NSMutableDictionary *)attributes;
- (void)setAttributes:(NSMutableDictionary *)anAttributes;
- (NSArray*) gates;
- (void) setGates:(NSMutableArray*)anArray;
- (void) addGate:(ORGate1D*)aGate;
- (void) removeActiveGate;
- (int)dataSetID;
- (void)setDataSetID:(int)aDataSetID;
- (int) gateNumber:(ORGate1D*)aGate;
- (void) keyDown:(NSEvent*)theEvent;
- (void) reportMousePosition:(NSEvent*)theEvent plotter:(ORPlotter1D*)aPlotter;
- (void) mouseDown:(NSEvent*)theEvent plotter:(ORPlotter1D*)aPlotter;
- (void) mouseDragged:(NSEvent*)theEvent plotter:(ORPlotter1D*)aPlotter;
- (void) mouseUp:(NSEvent*)theEvent plotter:(ORPlotter1D*)aPlotter;
- (void) drawDataInPlot:(ORPlotter1D*)aPlot;
- (void) drawSequencialPlot:(ORPlotter1D*)aPlot;
- (void) drawXYPlot:(ORPlotter1D*)aPlot;
- (void) drawFit:(ORPlotter1D*)aPlot;
- (void) drawXYTimePlot:(ORPlotter1D*)aPlot;

- (int)activeGateIndex;
- (void)setActiveGateIndex:(int)anactiveCurveIndex;
- (id) activeGate;
- (BOOL) incGate;
- (BOOL) decGate;
- (void) clearActiveGate;
- (void) clearAllGates;
- (int) gateCount;
- (double) maxValue;
- (BOOL) showActiveGate;
- (void) setShowActiveGate: (BOOL) flag plotter:(ORPlotter1D*)aPlotter;
- (NSArray*) dataPointArray:(ORPlotter1D*)aPlot range:(NSRange)aRange;

@end

extern NSString* ORPlotter1DMousePosition;
extern NSString* ORCurve1DActiveGateChanged;

