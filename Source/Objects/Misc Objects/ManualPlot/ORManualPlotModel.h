//
//  ORContainerModel.h
//  Orca
//
//  Created by Mark Howe on Sat Nov 19 2005.
//  Copyright ¬© 2002 CENPA, University of Washington. All rights reserved.
//

@interface ORManualPlotModel : OrcaObject  
{
    int				textSize;
    unsigned long 	overFlow;
    unsigned int 	numberBins;
    unsigned long* 	histogram;
	NSLock*			dataSetLock;
    BOOL			scheduledForUpdate;
}

#pragma mark ***Accessors
- (void)setNumberBins:(int)aNumberBins;
- (int) numberBins;
- (void) setValue:(unsigned long)aValue channel:(unsigned short)aChan;
- (unsigned long)value:(unsigned short)aBin;
- (unsigned long) overFlow;
- (void) histogram:(unsigned long)aValue;
- (void) scheduleUpdateOnMainThread;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;


#pragma mark •••Data Source Methods
- (int)		numberOfPointsInPlot:(id)aPlotter dataSet:(int)set;
- (float)	plotter:(id) aPlotter dataSet:(int)set dataValue:(int) x;

@end

extern NSString* ORManualPlotLock;
extern NSString* ORManualPlotDataChanged;
