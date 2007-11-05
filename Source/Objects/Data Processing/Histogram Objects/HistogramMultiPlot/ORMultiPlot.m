//
//  ORMultiPlot.m
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


#import "ORMultiPlot.h"
#import "ORDataSet.h"
#import "ORHistoModel.h"

NSString* ORMultiPlotDataSetItemsChangedNotification = @"ORMultiPlotDataSetItemsChangedNotification";
NSString* ORMultiPlotRemovedNotification             = @"ORMultiPlotRemovedNotification";
NSString* ORMultiPlotReCachedNotification            = @"ORMultiPlotReCachedNotification";
NSString* ORMultiPlotNameChangedNotification         = @"ORMultiPlotNameChangedNotification";

@implementation ORMultiPlot

- (id) init 
{
    self = [super init];
    return self;    
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [dataSetItems release];
    [cachedDataSets release];
    [plotName release];
    
    [super dealloc];
}

-(void)registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver: self
                     selector: @selector(reCache:)
                         name: ORDataSetRemoved
                       object: nil];
    
    [notifyCenter addObserver: self
                     selector: @selector(reCache:)
                         name: ORDataSetAdded
                       object: nil];
    
    [notifyCenter addObserver: self
                     selector: @selector(appQuiting:)
                         name: NSApplicationWillTerminateNotification
                       object: nil];
    
}

- (void) invalidateDataSource
{
    [self setDataSource:nil];
}

- (void) appQuiting:(NSNotification*)aNote
{
    //this is to short circuit the notification process on quits
    //which was causing some strange behavior.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) reCache:(NSNotification*)aNote
{
    
    [cachedDataSets release];
    cachedDataSets = [[NSMutableArray array] retain];
    int n = [dataSetItems count];
    int i;
    for(i=0;i<n;i++){
        id obj = [dataSource dataSetWithName:[[dataSetItems objectAtIndex:i]name]];
        if(obj)[cachedDataSets addObject:obj];
    }
    [[NSNotificationCenter defaultCenter]
				postNotificationName:ORMultiPlotReCachedNotification
                              object: self ];
}

- (BOOL) dataSetInCache:(id)aDataSet
{
    return [cachedDataSets containsObject:aDataSet];
}

#pragma mark ¥¥¥Accessors
- (NSArray *) dataSetItems
{
    return dataSetItems; 
}

- (void) setDataSetItems: (NSMutableArray *) someItems
{
    [someItems retain];
    [dataSetItems release];
    dataSetItems = someItems;
}

- (void) addDataSetName:(NSString*)aName
{
    if(!dataSetItems){
        [self setDataSetItems:[NSMutableArray array]];
    }
    
    id anItem = [ORMultiPlotDataItem dataItem:aName guardian:self];
    
    [[[self undoManager] prepareWithInvocationTarget:self] removeDataSetName:anItem];
    
    [dataSetItems addObject:anItem];
    [self reCache:nil];
    
    [[NSNotificationCenter defaultCenter]
				postNotificationName:ORMultiPlotDataSetItemsChangedNotification
                              object: self ];
}

- (void) removeDataSetName:(id)aDataSetItem
{
    [[[self undoManager] prepareWithInvocationTarget:self] unRemoveDataSetName:aDataSetItem];
    [dataSetItems removeObject:aDataSetItem];
    
    [self reCache:nil];
    
    [[NSNotificationCenter defaultCenter]
				postNotificationName:ORMultiPlotDataSetItemsChangedNotification
                              object: self ];
}

- (void) unRemoveDataSetName:(id)aDataSetItem
{
    [[[self undoManager] prepareWithInvocationTarget:self] removeDataSetName:aDataSetItem];
    [dataSetItems addObject:aDataSetItem];
    
    [self reCache:nil];
    
    [[NSNotificationCenter defaultCenter]
				postNotificationName:ORMultiPlotDataSetItemsChangedNotification
                              object: self ];
}


- (ORMultiPlotDataItem*) dataItemWithName:(NSString*)aName
{
    NSEnumerator* e = [dataSetItems objectEnumerator];
    id anItem;
    while(anItem = [e nextObject]){
        if([aName isEqualToString:[anItem name]])return anItem;
    }
    return nil;
}

- (void) setDataSource:(id)aDataSource
{
    dataSource = aDataSource;
    [self reCache:nil];
}

- (NSString *) plotName
{
    return plotName; 
}

- (void) setPlotName: (NSString *) aPlotName
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPlotName:plotName];
    [plotName autorelease];
    plotName = [aPlotName copy];
    [[NSNotificationCenter defaultCenter]
				postNotificationName:ORMultiPlotNameChangedNotification
                              object: self ];
}

#pragma mark ¥¥¥Data Management
-(void)clear
{
    [cachedDataSets makeObjectsPerformSelector:@selector(clear)];
}

- (void) removeFrom:(NSMutableArray*)anArray
{
    [[NSNotificationCenter defaultCenter]
				postNotificationName:ORMultiPlotRemovedNotification
                              object: self ];
    [anArray removeObject:self];
}

#pragma mark ¥¥¥Data Source Methods

- (int) numberOfDataSetsInPlot:(id)aPlotter
{
    return [dataSetItems count];
}

- (unsigned)  count
{
    return [dataSetItems count];
}

- (unsigned)  cachedCount
{
    return [cachedDataSets count];
}

- (id)   objectAtIndex:(int)index
{
    return [dataSetItems objectAtIndex:index];
}

- (id) cachedObjectAtIndex:(int)index
{
    return [cachedDataSets objectAtIndex:index];
}

- (int)	numberOfPointsInPlot:(id)aPlotter dataSet:(int)set
{ 
    if(!cachedDataSets)[self reCache:nil];
    if(set>=[cachedDataSets count])return 0;
    else return [[cachedDataSets objectAtIndex:set] numberOfPointsInPlot:aPlotter dataSet:set];
}

- (float) plotter:(id) aPlotter dataSet:(int)set dataValue:(int) x 
{
    return [[cachedDataSets objectAtIndex:set] plotter:aPlotter dataSet:set dataValue:x];
}

- (id) description
{
    return [self name];
}

- (id)   name
{
    if(plotName == nil) [self setPlotName:@"MultiPlot"];
    return plotName;
}


#pragma  mark ¥¥¥Actions
- (void) makeMainController
{
    [self linkToController:@"ORMultiPlotController"];
}

#pragma mark ¥¥¥Archival

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    
    [self setDataSetItems:[decoder decodeObjectForKey:@"ORMultiPlotDataSetItems"]];
    [self setPlotName:[decoder decodeObjectForKey:@"ORMultiPlotName"]];
    
    if(plotName == nil) [self setPlotName:@"MultiPlot"];
    
    [[self undoManager] enableUndoRegistration];
    
    [self registerNotificationObservers];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:dataSetItems forKey:@"ORMultiPlotDataSetItems"];
    [encoder encodeObject:plotName forKey:@"ORMultiPlotName"];
}


@end

@implementation ORMultiPlotDataItem
+ (id) dataItem:(NSString*)aName guardian:(id)aGuardian
{
    return [[[ORMultiPlotDataItem alloc] initItem:aName guardian:aGuardian] autorelease];
}

- (id) initItem:(NSString*)aName guardian:(id)aGuardian
{
    self = [super init];
    [self setName:aName];
    [self setGuardian:aGuardian];
    return self;
}

- (void) dealloc
{
    [name release];
    [super dealloc];
}

- (id) guardian
{
    return guardian; 
}

- (void) setGuardian: (id) aGuardian
{
    guardian = aGuardian; //don't retain the guardian
}

- (NSString *) name
{
    return name; 
}

- (void) setName: (NSString *) aName
{
    [name autorelease];
    name = [aName copy];
}

- (void) removeSelf
{
    [guardian removeDataSetName:self];
}

- (NSString*) description
{
    return name;
}

- (void) doDoubleClick:(id)sender
{
    [guardian doDoubleClick:sender];
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    
    [self setName:  [decoder decodeObjectForKey:@"ORMultiPlotDataItemName"]];
    [self setGuardian:[decoder decodeObjectForKey:@"ORMultiPlotDataItemParent"]];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:name  forKey:@"ORMultiPlotDataItemName"];
    [encoder encodeObject:guardian forKey:@"ORMultiPlotDataItemParent"];
}

@end
