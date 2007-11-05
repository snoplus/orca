//
//  ORProcessCenter.m
//  Orca
//
//  Created by Mark Howe on Sun Dec 11, 2005.
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
#import "ORProcessModel.h"
#import "ORProcessElementModel.h"
#import "ORProcessCenter.h"

int sortUpFunc(id element1,id element2, void* context){ return [element1 compareStringTo:element2 usingKey:context];}
int sortDnFunc(id element1,id element2, void* context){return [element2 compareStringTo:element1 usingKey:context];}

static ORProcessCenter* sharedInstance = nil;

@implementation ORProcessCenter

#pragma mark ¥¥¥Inialization

+ (id) sharedProcessCenter
{
    if(!sharedInstance){
        sharedInstance = [[ORProcessCenter alloc] init];
    }
    return sharedInstance;
}


-(id)init
{
    self = [super initWithWindowNibName:@"ProcessCenter"];
    [self setWindowFrameAutosaveName:@"ProcessCenterX"];
    return self;
}

- (void) dealloc
{
	[ascendingSortingImage release];
	[descendingSortingImage release];
    [processorList release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    sharedInstance = nil;
    [super dealloc];
}

- (void) awakeFromNib
{
    ascendingSortingImage = [[NSImage imageNamed:@"NSAscendingSortIndicator"] retain];
    descendingSortingImage = [[NSImage imageNamed:@"NSDescendingSortIndicator"] retain];
	[processView setAutosaveTableColumns:YES];
	[processView setAutosaveName:@"ORProcessCenterOutlineView"];   
    [[[[NSApp delegate]document] undoManager] disableUndoRegistration];
	[self setProcessMode:0];
    [[[[NSApp delegate]document] undoManager] enableUndoRegistration];
	
    [self registerNotificationObservers];
    [self findObjects];
    [processView setDoubleAction:@selector(doubleClick:)];
}

- (void) findObjects
{
    [processorList release];
    processorList = [[[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORProcessModel")] retain];
    [processView reloadData];
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow*)window
{
    return [[[NSApp delegate]document]  undoManager];
}

- (IBAction) saveDocument:(id)sender
{
    [[[NSApp delegate]document] saveDocument:sender];
}

- (IBAction) saveDocumentAs:(id)sender
{
    [[[NSApp delegate]document] saveDocumentAs:sender];
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter addObserver : self
                     selector : @selector(objectsAdded:)
                         name : ORGroupObjectsAdded
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(objectsRemoved:)
                         name : ORGroupObjectsRemoved
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(doReload:)
                         name : ORProcessModelCommentChangedNotification
                       object : nil];
					   
    [notifyCenter addObserver : self
                     selector : @selector(doReload:)
                         name : ORProcessModelShortNameChangedNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(doReload:)
                         name : ORProcessCommentChangedNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(doReload:)
                         name : ORProcessElementStateChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(doReload:)
                         name : ORProcessTestModeChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(doReload:)
                         name : ORProcessTestModeChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(doReload:)
                         name : ORProcessRunningChangedNotification
                       object : nil];


}

- (void) doReload:(NSNotification*)aNote
{
    [processView reloadData];
}

- (void) objectsAdded:(NSNotification*)aNote
{
    [self findObjects];
}

- (void) objectsRemoved:(NSNotification*)aNote
{
    [self findObjects];
}

#pragma mark ¥¥¥Accessors
- (void) setProcessMode:(int)aMode
{
    [[[[[NSApp delegate]document] undoManager] prepareWithInvocationTarget:self] setProcessMode:processMode];
    
	processMode = aMode;
	
	[modeSelectionButton selectCellWithTag:processMode];
}

- (int) processMode
{
	return processMode;
}


#pragma mark ¥¥¥Actions
- (IBAction) startAll:(id)sender
{
	if(processMode == 0)		[processorList makeObjectsPerformSelector:@selector(putInRunMode)];
	else if(processMode ==1)	[processorList makeObjectsPerformSelector:@selector(putInTestMode)];
    [processorList makeObjectsPerformSelector:@selector(startRun)];
}

- (IBAction) stopAll:(id)sender
{
    [processorList makeObjectsPerformSelector:@selector(stopRun)];
}

- (IBAction) startSelected:(id)sender
{
	NSArray* selectedItems = [processView allSelectedItems];
	NSEnumerator* e = [selectedItems objectEnumerator];
	id obj;
	while(obj = [e nextObject]){
		if([obj respondsToSelector:@selector(startRun)]){
			if(processMode == 0)		[obj putInRunMode];
			else if(processMode ==1)	[obj putInTestMode];
			[obj startRun];
		}
	}	
}

- (IBAction) stopSelected:(id)sender
{
	NSArray* selectedItems = [processView allSelectedItems];
	NSEnumerator* e = [selectedItems objectEnumerator];
	id obj;
	while(obj = [e nextObject]){
		if([obj respondsToSelector:@selector(stopRun)]){
			[obj stopRun];
		}
	}
}

- (IBAction) modeAction:(id)sender
{
	[self setProcessMode:[[sender selectedCell] tag]]; 
}


#pragma mark ¥¥¥Data Source
- (id)   outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
    return item==nil?[processorList objectAtIndex:index]:[[item children] objectAtIndex:index];
}

- (BOOL) outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return [[item children] count];
}

- (int)  outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    return item == nil?[processorList count]:[[item children] count];
}

- (id)  outlineView:(NSOutlineView *)outlineView  objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    NSString* columnID =  [tableColumn identifier];
    return [item valueForKey:columnID];
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn byItem:(id)item;
{
    [item setValue:anObject forKey:[aTableColumn identifier]];
}

- (IBAction) doubleClick:(id)sender
{
    [[processView selectedItem] doDoubleClick:sender];
}


- (void) outlineView:(NSOutlineView*)tv didClickTableColumn:(NSTableColumn *)tableColumn
{
    NSImage *sortOrderImage = [tv indicatorImageInTableColumn:tableColumn];
    NSString *columnKey = [tableColumn identifier];
    // If the user clicked the column which already has the sort indicator
    // then just flip the sort order.
    
    if (sortOrderImage || columnKey == [self sortColumn]) {
        [self setSortIsDescending:![self sortIsDescending]];
    }
    else {
        [self setSortColumn:columnKey];
    }
    [self updateTableHeaderToMatchCurrentSort];
    // now do it - doc calls us back when done
    [self sort];
    [processView reloadData];
}

- (void) updateTableHeaderToMatchCurrentSort
{
    BOOL isDescending = [self sortIsDescending];
    NSString *key = [self sortColumn];
    NSArray *a = [processView tableColumns];
    NSTableColumn *column = [processView tableColumnWithIdentifier:key];
    unsigned i = [a count];
    
    while (i-- > 0) [processView setIndicatorImage:nil inTableColumn:[a objectAtIndex:i]];
    
    if (key) {
        [processView setIndicatorImage:(isDescending ? ascendingSortingImage:descendingSortingImage) inTableColumn:column];
        
        [processView setHighlightedTableColumn:column];
    }
    else {
        [processView setHighlightedTableColumn:nil];
    }
}

-(void)setSortColumn:(NSString *)identifier {
    if (![identifier isEqualToString:_sortColumn]) {
        [_sortColumn release];
        _sortColumn = [identifier copyWithZone:[self zone]];
    }
}

- (NSString *)sortColumn
{
    return _sortColumn;
}

- (void)setSortIsDescending:(BOOL)whichWay {
    if (whichWay != _sortIsDescending) {
        _sortIsDescending = whichWay;
    }
}

- (BOOL)sortIsDescending
{
    return _sortIsDescending;
}

- (void)sort
{
    if(_sortIsDescending){
		[processorList sortUsingFunction:sortDnFunc context: _sortColumn];
	}
    else {
		[processorList sortUsingFunction:sortUpFunc context: _sortColumn];
	}
	NSEnumerator* mainEnummy = [processorList objectEnumerator];
	ORProcessElementModel* objFromProcessorList;
	while(objFromProcessorList = [mainEnummy nextObject]){
		NSMutableArray* theKids = [objFromProcessorList children];
		if(_sortIsDescending){
			[theKids sortUsingFunction:sortDnFunc context: _sortColumn];
		}
		else {
			[theKids sortUsingFunction:sortUpFunc context: _sortColumn];
		}
	}
}


@end
