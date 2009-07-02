//
//  ORPlotter.h
//  Orca
//
//  Created by Mark Howe on 6/25/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
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

#import "ORAxis.h"

@class CTGradient;
@class ORFlippedView;

@interface ORPlotter : NSView <NSCoding> {
	@protected
		IBOutlet ORFlippedView*	analysisView;
		IBOutlet NSDrawer*		analysisDrawer;
		IBOutlet  id            mDataSource; 
		IBOutlet ORAxis*		mXScale;
		IBOutlet ORAxis*		mYScale;
		IBOutlet NSView*		viewForPDF;
	
		BOOL					analyze;
		CTGradient*				gradient;
		NSMutableDictionary*	attributes;
		BOOL					doNotDraw;
}

#pragma mark •••Initialization
-(void) dealloc;

#pragma mark •••Accessors
- (NSMutableDictionary*) attributes;
- (void) setAttributes:(NSMutableDictionary *)anAttributes;
- (ORAxis*) xScale;
- (void) setXScale:(ORAxis*)newXScale;
- (ORAxis*) yScale;
- (void) setYScale:(ORAxis*)newYScale;
- (void) setUseGradient:(BOOL)aFlag;
- (BOOL) useGradient;
- (BOOL) analyze;
- (void) setAnalyze:(BOOL)newAnalyze;
- (void) setBackgroundColor:(NSColor *)aColor;
- (NSColor*) backgroundColor;
- (void) setGridColor:(NSColor *)aColor;
- (NSColor*) gridColor;
- (BOOL) isOpaque;
- (id) dataSource;
-(NSColor*) colorForDataSet:(int) aDataSet;
- (void) setDataColor:(NSColor*)aColor dataSet:(int) aDataSet;
- (int) numberDataSets;

#pragma mark •••Drawing
- (void) drawBackground;
- (NSData*) plotAsPDFData;

#pragma mark •••SubClasses Will Override
- (void) setDataSource:(id)d;
- (void) initCurves;
- (void) doAnalysis;

#pragma mark •••Actions
- (IBAction) analyze:(id)sender;
- (IBAction) publishToPDF:(id)sender;

#pragma mark •••Archival
- (void) encodeWithCoder:(NSCoder *)coder;
- (id) initWithCoder:(NSCoder *)coder;

@end

@interface NSObject (ORPlotDataSource)
- (BOOL) willSupplyColors;
- (int)  numberOfDataSetsInPlot:(id)aPlotter;
@end

extern NSString* ORPlotterBackgroundColor;
extern NSString* ORPlotterGridColor;
extern NSString* ORPlotterDataColor;
