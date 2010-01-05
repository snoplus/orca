/* ORPlotter1D */
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
#import "ORPlotter.h"

@class ORGate1D;

@interface ORPlotter1D : ORPlotter
{
    NSMutableArray*         curves;
	
    int				activeCurveIndex;
    BOOL			shiftKeyIsDown;
	BOOL			commandKeyIsDown;
    BOOL			ignoreDoNotDrawFlag;
	BOOL			setAllLinesBold;
	BOOL			drawSymbols;
}

- (void) dealloc;
- (void) setDefaults;
- (void) drawerDidOpen:(NSNotification*)aNote;

- (void) forcedUpdate:(NSNotification*)aNote;
- (void) windowResizing:(NSNotification*)aNote;
- (BOOL) drawSymbols;
- (void) setDrawSymbols:(BOOL)aFlag;
- (void) drawRect:(NSRect) rect;
- (void) setFrame:(NSRect)aFrame;
- (int)activeCurveIndex;
- (void)setActiveCurveIndex:(int)anactiveCurveIndex;
- (id) activeCurve;
- (id) curve:(int)aCurveIndex gate:(int)aGateIndex;
- (void)setIgnoreDoNotDrawFlag:(BOOL)aFlag;
- (void)setShowActiveGate:(BOOL)flag;
- (void) setAllLinesBold:(BOOL)flag;
- (BOOL) setAllLinesBold;
- (double) plotHeight;
- (double) plotWidth;
- (double) channelWidth;
- (NSArray*) curves;
- (void) setCurves:(NSMutableArray*)anArray;

- (void) tileAnalysisPanels;

- (id)	initWithCoder:(NSCoder *)coder;
- (void) encodeWithCoder:(NSCoder *)coder;
- (void) resetDrawFlag;
- (void) setDifferentiate:(BOOL)state;
- (BOOL) differentiate;
- (void) setAverageWindow:(int)size;
- (int) averageWindow;
- (void) getNonZeroAxisRangeMin:(long*)xMin max:(long*)xMax;
- (void) xAndYAutoScale;
- (void) setXLabel:(NSString*)xLabel yLabel:(NSString*)yLabel;	
- (void) doFFT:(id)userInfo;
- (void) autoScaleXAxis;

//wrappers for KVO bindings
- (void) setDataColor0:(NSColor*)aColor;
- (void) setDataColor1:(NSColor*)aColor; 
- (void) setDataColor2:(NSColor*)aColor; 
- (void) setDataColor3:(NSColor*)aColor; 
- (void) setDataColor4:(NSColor*)aColor; 
- (void) setDataColor5:(NSColor*)aColor; 

- (NSColor*) dataColor0;
- (NSColor*) dataColor1;
- (NSColor*) dataColor2;
- (NSColor*) dataColor3;
- (NSColor*) dataColor4;
- (NSColor*) dataColor5;

- (IBAction) copy:(id)sender;
- (IBAction) clearActiveGate:(id)sender;
- (IBAction) clearActiveCurveGates:(id)sender;
- (IBAction) clearAllGates:(id)sender;
- (IBAction) resetScales:(id)sender;
- (IBAction) centerOnPeak:(id)sender;
- (IBAction) xAndYAutoScale:(id)sender;
- (IBAction) autoScale:(id)sender;
- (IBAction) addGateAction:(id)sender;
- (IBAction) removeGateAction:(id)sender;
- (IBAction) differentiateAction:(id)sender;
- (IBAction) averageWindowAction:(id)sender;
- (IBAction) refresh:(id)sender;

@end

@interface NSObject (OR1DPlotDataSource1)
- (BOOL)   	willSupplyColors;
- (NSColor*) colorForDataSet:(int)set;
- (int) 	numberOfDataSetsInPlot:(id)aPlotter;
- (unsigned long)  	secondsPerUnit:(id) aPlotter;


- (BOOL) useDataObject:(id)aPlotter  dataSet:(int)set;
- (BOOL) useUnsignedValues;
//if useDataObject == YES
- (unsigned long) startingByteOffset:(id)aPlotter  dataSet:(int)set;
- (unsigned short) unitSize:(id)aPlotter  dataSet:(int)set;
- (NSData*) plotter:(id) aPlotter dataSet:(int)set;

//if useDataObject == NO
- (int)		numberOfPointsInPlot:(id)aPlotter dataSet:(int)set;
- (float)  	plotter:(id) aPlotter dataSet:(int)set dataValue:(int) x;

- (BOOL) useXYPlot; //default is no
- (float) plotterMaxX:(id)aPlotter;
- (float) plotterMinX:(id)aPlotter;
- (BOOL)  plotter:(id) aPlotter dataSet:(int)set index:(unsigned long)i x:(float*)x y:(float*)y;
- (BOOL) useXYTimePlot;
- (NSTimeInterval) plotterStartTime:(id)aPlotter;
- (void)  plotter:(id) aPlotter dataSet:(int)set index:(unsigned long)i time:(unsigned long*)x y:(float*)y;
@end

@interface NSObject (ORPlotter1D)
- (void) makeMainController;
@end

extern NSString* ORPlotter1DActiveCurveChanged;
extern NSString* ORPlotter1DDifferentiateChanged;
extern NSString* ORPlotter1DAverageWindowChanged;
extern NSString* ORPlotter1DAverageWindow;



