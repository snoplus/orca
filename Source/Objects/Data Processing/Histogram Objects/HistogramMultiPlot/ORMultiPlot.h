//
//  ORMultiPlot.h
//  Orca
//
//  Created by Mark Howe on Sun Nov 17 2002.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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


#pragma mark ¥¥¥Imported Files

#import "ORDataSetModel.h"

#pragma mark ¥¥¥Forward Declarations
@class ORMultiPlotController;
@class ORMultiPlotDataItem;

@interface ORMultiPlot : ORDataSetModel  {
    NSMutableArray* dataSetItems;
    id dataSource;
    NSString* plotName;
    
    NSMutableArray* cachedDataSets;

}

#pragma mark ¥¥¥Accessors
- (NSArray *) dataSetItems;
- (void) setDataSetItems: (NSMutableArray *) someItems;
- (void) setDataSource:(id)aDataSource;
- (BOOL) dataSetInCache:(id)dataSet;
- (id)   cachedObjectAtIndex:(int)index;
- (NSString *) plotName;
- (void) setPlotName: (NSString *) aPlotName;

#pragma mark ¥¥¥Data Management
- (void) invalidateDataSource;
- (void) clear;
- (void) removeDataSetName:(id)aDataSetItem;
- (void) unRemoveDataSetName:(id)aDataSetItem;
- (void) addDataSetName:(NSString*)aName;
- (void) reCache:(NSNotification*)aNote;
- (ORMultiPlotDataItem*) dataItemWithName:(NSString*)aName;
- (void) appQuiting:(NSNotification*)aNote;

#pragma mark ¥¥¥Writing Data

#pragma mark ¥¥¥Data Source Methods
- (unsigned)  count;
- (unsigned)  cachedCount;
- (id)   name;
- (int)	numberOfPointsInPlot:(id)aPlotter dataSet:(int)set;
- (float) plotter:(id) aPlotter dataSet:(int)set dataValue:(int) x;
@end

extern NSString* ORMultiPlotDataSetItemsChangedNotification;
extern NSString* ORMultiPlotRemovedNotification;
extern NSString* ORMultiPlotReCachedNotification;
extern NSString* ORMultiPlotNameChangedNotification;


@interface ORMultiPlotDataItem : NSObject
{
    id guardian;
    NSString*    name;
}
+ (id) dataItem:(NSString*)aName guardian:(id)aGuardian;
- (id) initItem:(NSString*)aName guardian:(id)aGuardian;

- (id) guardian;
- (void) setGuardian: (id) aGuardian;
- (NSString *) name;
- (void) setName: (NSString *) aName;
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
- (NSString*) description;
- (void) removeSelf;
- (void) doDoubleClick:(id)sender;

@end

