/* ORPlotter2D */
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

@class ORCurve2D;
@class ORColorScale;

@interface ORPlotter2D : ORPlotter
{
    IBOutlet ORColorScale*	mColorScale;
    IBOutlet ORAxis*		mZScale;

    id						curve;

    BOOL			cmdKeyIsDown;
    BOOL			ignoreDoNotDrawFlag;
    
    BOOL            vectorMode;
	NSImage*		backgroundImage;
}

- (id)   initWithFrame:(NSRect)aFrame;
- (void) dealloc;
- (void) setDefaults;
- (void)setIgnoreDoNotDrawFlag:(BOOL)aFlag;

- (void) drawRect:(NSRect) rect;
- (void) setFrame:(NSRect)aFrame;
- (void) setBackgroundImage:(NSImage*)anImage;
- (NSColor*)colorForDataSet:(int) aDataSet;
- (void)setDataColor:(NSColor*)aColor dataSet:(int) aDataSet;

- (ORColorScale*) colorScale;
- (void) setColorScale:(ORColorScale*)newColorScale;
- (ORAxis*) zScale;
- (void) setZScale:(ORAxis*)newZScale;
- (double) plotHeight;
- (double) plotWidth;
- (double) channelWidth;
- (ORCurve2D*) curve;
- (void) setCurve:(ORCurve2D*)anArray;

- (IBAction) resetScales:(id)sender;
- (IBAction) autoScale:(id)sender;
- (IBAction) zoomIn:(id)sender;
- (IBAction) zoomOut:(id)sender; 
- (IBAction) copy:(id)sender;
- (IBAction) addGateAction:(id)sender;
- (IBAction) removeGateAction:(id)sender;

- (void) savePDF:(id)sender;
- (void) didEnd:(NSSavePanel *)sheet
	 returnCode:(int)code
	contextInfo:(void *)contextInfo;

- (id)	initWithCoder:(NSCoder *)coder;
- (void) encodeWithCoder:(NSCoder *)coder;
- (void) setVectorMode:(BOOL)state;
- (void) mouseDown:(NSEvent*)theEvent;
- (void) mouseDragged:(NSEvent*)theEvent;
- (void) mouseUp:(NSEvent*)theEvent;
- (void) setShowActiveGate:(BOOL)flag;
- (void)flagsChanged:(NSEvent *)theEvent;

@end

@interface NSObject (OR2DPlotDataSource1)
- (BOOL)   	willSupplyColors;
- (int) 	numberOfDataSetsInPlot:(id)aPlotter;
- (unsigned long*) plotter:(id) aPlotter dataSet:(int)set numberBinsPerSide:(unsigned short*)xValue;
- (void) plotter:(id) aPlotter dataSet:(int)set xMin:(unsigned short*)minX xMax:(unsigned short*)maxX yMin:(unsigned short*)minY yMax:(unsigned short*)maxY;

//for vector drawing
- (unsigned long) plotter:(id)aPlotter numPointsInSet:(int)set;
- (BOOL) plotter:(id)aPlotter dataSet:(int)set index:(unsigned long)index x:(float*)xValue y:(float*)yValue;
- (BOOL) plotter:(id)aPlotter dataSet:(int)set crossHairX:(float*)xValue crossHairY:(float*)yValue;
- (NSColor*) plotter:(id)aPlotter colorForSet:(int)set;
@end

extern NSString* ORPlotter2DataColor;
extern NSString* ORPlotter2DMousePosition;
 


