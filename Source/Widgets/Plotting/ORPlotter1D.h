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



@class ORAxis;
@class ORGate1D;
@class ZFlowLayout;
@class CTGradient;

@interface ORPlotter1D : NSView <NSCoding>
{
    IBOutlet ZFlowLayout*   analysisView;
    IBOutlet NSDrawer*		analysisDrawer;
    IBOutlet ORAxis*		mXScale;
    IBOutlet ORAxis*		mYScale;
    IBOutlet  id            mDataSource;    

    NSMutableArray*         curves;
    NSMutableDictionary*	attributes;
	
    BOOL			analyze;
    int				activeCurveIndex;
    BOOL			shiftKeyIsDown;
    BOOL			doNotDraw;
    BOOL			ignoreDoNotDrawFlag;
	CTGradient*		gradient;
}

- (void) dealloc;
- (void) setDefaults;
- (void) initCurves;
- (NSMutableDictionary *)attributes;
- (void)setAttributes:(NSMutableDictionary *)anAttributes;
- (BOOL) useGradient;
- (void) setUseGradient:(BOOL)aflag;
- (void) drawerDidOpen:(NSNotification*)aNote;
- (void) forcedUpdate:(NSNotification*)aNote;
- (void) windowResizing:(NSNotification*)aNote;
- (void) setDrawWithGradient:(BOOL)flag;

- (void) drawRect:(NSRect) rect;
- (void) setFrame:(NSRect)aFrame;
- (BOOL) isOpaque;
- (id)  dataSource;
- (void) setDataSource:(id)d; 
- (int)activeCurveIndex;
- (void)setActiveCurveIndex:(int)anactiveCurveIndex;
- (id) activeCurve;

- (void) setBackgroundColor:(NSColor*)c;
- (void) setGridColor:(NSColor*)c;
- (NSColor*) backgroundColor;
- (NSColor*) gridColor;
- (NSColor*)colorForDataSet:(int) aDataSet;
- (void)setDataColor:(NSColor*)aColor dataSet:(int) aDataSet;
- (void)setIgnoreDoNotDrawFlag:(BOOL)aFlag;
- (void)setShowActiveGate:(BOOL)flag;

- (ORAxis*) xScale;
- (void) setXScale:(ORAxis*)newXScale;
- (ORAxis*) yScale;
- (void) setYScale:(ORAxis*)newYScale;
- (double) plotHeight;
- (double) plotWidth;
- (double) channelWidth;
- (NSArray*) curves;
- (void) setCurves:(NSMutableArray*)anArray;

- (void) savePDF:(id)sender;
- (void) didEnd:(NSSavePanel *)sheet
	 returnCode:(int)code
	contextInfo:(void *)contextInfo;

- (IBAction)copy:(id)sender;
- (IBAction) clearActiveGate:(id)sender;
- (IBAction) clearActiveCurveGates:(id)sender;
- (IBAction) clearAllGates:(id)sender;

- (IBAction) analyze:(id)sender;
- (IBAction) resetScales:(id)sender;
- (IBAction) centerOnPeak:(id)sender;
- (IBAction) xAndYAutoScale:(id)sender;
- (IBAction) autoScale:(id)sender;
- (IBAction) addGateAction:(id)sender;
- (IBAction) removeGateAction:(id)sender;
- (IBAction) differentiateAction:(id)sender;
- (IBAction) averageWindowAction:(id)sender;

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
- (void)  plotter:(id) aPlotter dataSet:(int)set index:(int)i x:(float*)x y:(float*)y;
- (BOOL) useXYTimePlot;
- (NSTimeInterval) plotterStartTime:(id)aPlotter;
- (void)  plotter:(id) aPlotter dataSet:(int)set index:(int)i time:(unsigned long*)x y:(float*)y;
@end

@interface NSObject (ORPlotter1D)
- (void) makeMainController;
@end

extern NSString* ORPlotter1DBackgroundColor;
extern NSString* ORPlotter1DGridColor;
extern NSString* ORPlotter1DataColor;
extern NSString* ORPlotter1DActiveCurveChanged;
extern NSString* ORPlotter1DDifferentiateChanged;
extern NSString* ORPlotter1DAverageWindowChanged;
extern NSString* ORPlotter1DAverageWindow;



