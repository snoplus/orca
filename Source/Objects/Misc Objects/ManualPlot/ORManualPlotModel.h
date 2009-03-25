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
	NSLock*			dataSetLock;
	NSMutableArray*	data;
    BOOL			scheduledForUpdate;
}

#pragma mark ***Accessors
- (void) addValue1:(float)v1 value2:(float)v2 value3:(float)v3;
- (id) dataAtIndex:(int)i key:(id)aKey;
- (void) clearData;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

#pragma mark •••Data Source Methods
- (unsigned long) numPoints;
- (BOOL) dataSet:(int)set index:(unsigned long)index x:(float*)xValue y:(float*)yValue;
@end

extern NSString* ORManualPlotLock;
extern NSString* ORManualPlotDataChanged;
