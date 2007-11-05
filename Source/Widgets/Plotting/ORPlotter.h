/* ORPlotter */

#import <Cocoa/Cocoa.h>
//#import "ORDataSource.h"

@class ORScale;

@interface ORPlotter : NSView 
{
    IBOutlet ORScale*		mXScale;
    IBOutlet ORScale*		mYScale;
    IBOutlet  id 			mDataSource;    
    NSColor*				backgroundColor;
    NSColor*				gridColor;
    NSColor*				dataColor;
    NSColor*				roiColor;
	
    BOOL					roiValid;
    BOOL					dragInProgress;
    double					roi1;
    double					roi2;

    BOOL					analyze;
    double					roiMinChannel;
    double					roiMaxChannel;
    double					average;
    double 					centroid;
    double					sigma;
    double					totalSum;
}

- (id)   initWithFrame:(NSRect)aFrame;
- (void) dealloc;
- (id)	initWithCoder:(NSCoder *)coder;
- (void) encodeWithCoder:(NSCoder *)coder;

- (void) drawRect:(NSRect) rect;
- (void) setFrame:(NSRect)aFrame;
- (BOOL) isOpaque;
- (id)  dataSource;
- (void) setDataSource:(id)d; 

- (void) setBackgroundColor:(NSColor*)c;
- (void) setRoiColor:(NSColor*)c;
- (void) setGridColor:(NSColor*)c;
- (void) setDataColor:(NSColor*)c;
- (NSColor*) backgroundColor;
- (NSColor*) gridColor;
- (NSColor*) dataColor;
- (NSColor*) roiColor;
- (ORScale*) xScale;
- (void) setXScale:(ORScale*)newXScale;
- (ORScale*) yScale;
- (void) setYScale:(ORScale*)newYScale;


- (void) savePDF:(id)sender;
- (void) didEnd:(NSSavePanel *)sheet
	 returnCode:(int)code
	contextInfo:(void *)contextInfo;

- (BOOL) analyze;
- (void) setAnalyze:(BOOL)newAnalyze;
- (BOOL) roiValid;
- (void) setRoiValid:(BOOL)newRoiValid;
- (double) roiMinChannel;
- (void) setRoiMinChannel:(double)newRoiMin;
- (double) roiMaxChannel;
- (void) setRoiMaxChannel:(double)newRoiMax;
- (double) average;
- (void) setAverage:(double)newAverage;
- (double) centroid;
- (void) setCentroid:(double)newCentroid;
- (double) sigma;
- (void) setSigma:(double)newSigma;
- (double) totalSum;
- (void) setTotalSum:(double)newTotalSum;


- (IBAction) clearROI:(id)sender;
- (IBAction) analyze:(id)sender;
- (IBAction) resetScales:(id)sender;
- (IBAction) centerOnPeak:(id)sender;
- (IBAction) autoScale:(id)sender;

@end

@interface NSArray (OR1DPlotDataSource)
- (int)		numberOfPointsInPlot:(id)aPlotter dataSet:(int)set;
- (float)  	plotter:(id) aPlotter dataSet:(int)set dataValue:(int) x;
- (unsigned long)  	secondsPerUnit:(id) aPlotter;
@end


@interface NSObject (OR1DPlotDataSource)
- (BOOL)   	willSupplyColors;
- (NSColor*) colorForDataSet:(int)set;
- (int) 	numberOfDataSetsInPlot:(id)aPlotter;
- (int)		numberOfPointsInPlot:(id)aPlotter dataSet:(int)set;
- (float)  	plotter:(id) aPlotter dataSet:(int)set dataValue:(int) x;
- (unsigned long)  	secondsPerUnit:(id) aPlotter;
@end

extern NSString* ORPlotROIValidChangedNotification;
extern NSString* ORPlotROIMinChangedNotification;
extern NSString* ORPlotROIMaxChangedNotification;
extern NSString* ORPlotAverageChangedNotification;
extern NSString* ORPlotCentroidChangedNotification;
extern NSString* ORPlotSigmaChangedNotification;
extern NSString* ORPlotTotalSumChangedNotification;


