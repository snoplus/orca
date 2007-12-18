//
//  ORHistoModel.h
//  Orca
//
//  Created by Mark Howe on Tue Dec 24 2002.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORDataChainObject.h"

#pragma mark ¥¥¥Forward Declarations
@class ORDataPacket;
@class ORDataSet;

@interface ORHistoModel :  ORDataChainObject 
{
    @private
        ORDataSet*   dataSet;
        NSString*    directoryName;
        NSString*    fileName;
        BOOL		 writeFile;
		NSLock*		 mLock;
        BOOL         processedFinalCall;
        NSMutableArray* multiPlots;
}


#pragma mark ¥¥¥Initialization
- (void) makeConnectors;

#pragma mark ¥¥¥Accessors
- (ORDataSet*) 	dataSet;
- (void)        setDataSet:(ORDataSet*)aDataSet;
- (void)        setDirectoryName:(NSString*)aFileName;
- (NSString*)	directoryName;
- (void)        setFileName:(NSString*)aFileName;
- (NSString*)	fileName;
- (BOOL)        writeFile;
- (void)        setWriteFile:(BOOL)newWriteFile;
- (NSMutableArray *)    multiPlots;
- (void) setMultiPlots:(NSMutableArray *) aMultiPlots;
- (void) addMultiPlot:(id)aMultiPlot;
- (void) removeMultiPlot:(id)aMultiPlot;
- (NSArray*) collectObjectsRespondingTo:(SEL)aSelector;

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) processData:(ORDataPacket*)someData userInfo:(NSDictionary*)userInfo;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) closeOutRun:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) runTaskBoundary:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;

- (int)  outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item;
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item;
- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item;
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item;
- (unsigned)  numberOfChildren;
- (id)   childAtIndex:(int)index;
- (id)   name;
- (void) removeDataSet:(ORDataSet*)aSet;
- (BOOL) leafNode;

@end

@interface NSObject (ORHistModel)
- (void) removeFrom:(NSMutableArray*)anArray;
@end

#pragma mark ¥¥¥External String Definitions
extern NSString* ORHistoModelDirChangedNotification;
extern NSString* ORHistoModelFileChangedNotification;
extern NSString* ORHistoModelWriteFileChangedNotification;
extern NSString* ORHistoModelMultiPlotsChangedNotification;

