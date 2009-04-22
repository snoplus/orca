//
//  ORGate1D.h
//  testplot
//
//  Created by Mark Howe on Fri May 14 2004.
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



@class ORPlotter1D;
@class ORCurve1D;
@class ORAnalysisPanel1D;
@class ORGateKey;
@class ORPlotter1D;

enum {
    kInitialDrag,
    kMinDrag,
    kMaxDrag,
    kCenterDrag,
    kNoDrag
};

@interface ORGate1D : NSObject <NSCoding> {
    @private
        ORCurve1D*			mCurve;
		ORPlotter1D*		mPlot;
        NSMutableDictionary*	attributes;
        NSDictionary*			fitLableAttributes;
        ORAnalysisPanel1D*		analysis;
        ORGateKey*      cachedGate;
        int             gate1,gate2;
        BOOL			analyze;
        double			average;
        double			centroid;
        double			sigma;
        double			totalSum;
        float           peaky;
        float           peakx;
        double			startChan;
        BOOL			dragInProgress;
        BOOL			gateValid;
        int				dragType;
        NSString*       displayedGateName;
        BOOL            displayGate;
		NSArray*		fit;
		int				fitMaxChannel;
		int				fitMinChannel;
		NSString*		fitString;
        
}
+ (id) gateForCurve:(ORCurve1D*)aCurve plot:(ORPlotter1D*)aPlot;
- (id) initForCurve:(ORCurve1D*)aCurve plot:(ORPlotter1D*)aPlot;
- (id) init;
- (void)dealloc;
- (void) adjustAnalysisPanels;
- (void) setDefaults;
- (void) setDefaultMin:(double)aMin max:(double)aMax;
- (void) setFit:(NSArray*)anArray;
- (BOOL) fitExists;
- (void) setFitString:(NSString*)aString;
- (BOOL) gateIsActive;
- (ORPlotter1D*) plotter;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;
- (void) gateNameChanged:(NSNotification*)aNote;
- (void) lowValueChanged:(NSNotification*)aNote;
- (void) highValueChanged:(NSNotification*)aNote;

- (NSString *) displayedGateName;
- (void) setDisplayedGateName: (NSString *) aDisplayedGateName;
- (BOOL) displayGate;
- (void) setDisplayGate: (BOOL) flag;
- (ORAnalysisPanel1D *)analysis;
- (void)setAnalysis:(ORAnalysisPanel1D *)anAnalysis;
- (NSMutableDictionary *)attributes;
- (void)setAttributes:(NSMutableDictionary *)anAttributes;
- (BOOL) analyze;
- (void) setAnalyze:(BOOL)newAnalyze;
- (BOOL) gateValid;
- (void) setGateValid:(BOOL)newGateValid;
- (int) gateMinChannel;
- (void) setGateMinChannel:(int)newGateMin;
- (float) gateMaxValue;
- (float) gateMinValue;
- (float) gatePeakValue;
- (float) gateCentroid;
- (float) gateSigma;
- (int) gateMaxChannel;
- (void) setGateMaxChannel:(int)newGateMax;
- (double) average;
- (void) setAverage:(double)newAverage;
- (double) centroid;
- (void) setCentroid:(double)newCentroid;
- (double) sigma;
- (void) setSigma:(double)newSigma;
- (double) totalSum;
- (void) setTotalSum:(double)newTotalSum;
- (int) curveNumber;
- (int) gateNumber;
- (void) clearGate;
- (NSUndoManager *)undoManager;
- (void) setPeakx:(int)aValue;
- (int)  peakx;
- (void) setPeaky:(int)aValue;
- (int)  peaky;
- (void) keyDown:(NSEvent*)theEvent;
- (void) mouseDown:(NSEvent*)theEvent plotter:(ORPlotter1D*)aPlotter;
- (void) doDrag:(NSEvent*)theEvent  plotter:(ORPlotter1D*)aPlotter;
- (void) mouseDragged:(NSEvent*)theEvent plotter:(ORPlotter1D*)aPlotter;
- (void) mouseUp:(NSEvent*)theEvent plotter:(ORPlotter1D*)aPlotter;
- (void) analyzePlot:(ORPlotter1D*)aPlot;
- (void) postNewGateID;
- (void) doFit:(id)userInfo;
- (void) doFFT:(id)userInfo;
- (void) removeFit;
- (void) processResponse:(NSDictionary*)aResponse;
- (int) fitMinChannel;
- (int) fitMaxChannel;
- (int)		numberOfPointsInPlot:(id)aPlotter dataSet:(int)set;
- (float)  	plotter:(id) aPlotter dataSet:(int)set dataValue:(int) x;
@end

extern NSString* ORGate1DValid;
extern NSString* ORGate1DMin;
extern NSString* ORGate1DMax;

extern NSString* ORGateValidChangedNotification;
extern NSString* ORGateMinChangedNotification;
extern NSString* ORGateMaxChangedNotification;
extern NSString* ORGateAverageChangedNotification;
extern NSString* ORGateCentroidChangedNotification;
extern NSString* ORGateSigmaChangedNotification;
extern NSString* ORGateTotalSumChangedNotification;
extern NSString* ORGateCurveNumberChangedNotification;
extern NSString* ORGateNumberChangedNotification;
extern NSString* ORGateDisplayGateChangedNotification;
extern NSString* ORGateDisplayedGateChangedNotification;
extern NSString* ORForcePlotUpdateNotification;
extern NSString* ORGatePeakXChangedNotification;
extern NSString* ORGatePeakYChangedNotification;
extern NSString* ORGateFitChanged;
