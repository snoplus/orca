
//
//  ORProcessController.m
//  Orca
//
//  Created by Mark Howe on Sat Nov 19 2005.
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
#import "ORProcessController.h"
#import "ORProcessModel.h"
#import "ORProcessOutConnector.h"
#import "ORProcessElementModel.h"

int sortUpFunction(id element1,id element2, void* context){ return [element1 compareStringTo:element2 usingKey:context];}
int sortDnFunction(id element1,id element2, void* context){return [element2 compareStringTo:element1 usingKey:context];}

@implementation ORProcessController

#pragma mark ¥¥¥Initialization
- (id) init
{
    self = [super initWithWindowNibName:@"Process"];
    return self;
}

- (void) dealloc
{
	[ascendingSortingImage release];
	[descendingSortingImage release];
	[super dealloc];
}

-(void) awakeFromNib
{
    [super awakeFromNib];
    
    int index = [[NSUserDefaults standardUserDefaults] integerForKey:[NSString stringWithFormat:@"orca.Process%d.selectedtab",[model uniqueIdNumber]]];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];	
    [tableView setDoubleAction:@selector(doubleClick:)];
    
    ascendingSortingImage = [[NSImage imageNamed:@"NSAscendingSortIndicator"] retain];
    descendingSortingImage = [[NSImage imageNamed:@"NSDescendingSortIndicator"] retain];
	
	[tableView setAutosaveTableColumns:YES];
	[tableView setAutosaveName:@"ORProcessControllerTableView"];    
    
}

#pragma mark ¥¥¥Interface Management

- (void) sampleRateChanged:(NSNotification*)aNote
{
	[sampleRateField setFloatValue: [model sampleRate]];
}

- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];   
    [notifyCenter addObserver : self
                     selector : @selector(elementStateChanged:)
                         name : ORProcessElementStateChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(testModeChanged:)
                         name : ORProcessTestModeChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(processRunningChanged:)
                         name : ORProcessTestModeChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(processRunningChanged:)
                         name : ORProcessRunningChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(commentChanged:)
                         name : ORProcessCommentChangedNotification
                       object : model];
	
	[notifyCenter addObserver : self
                     selector : @selector(shortNameChanged:)
                         name : ORProcessModelShortNameChangedNotification
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(detailsChanged:)
                         name : NSTableViewSelectionDidChangeNotification
                       object : tableView];
    
    [notifyCenter addObserver : self
                     selector : @selector(sampleRateChanged:)
                         name : ORProcessModelSampleRateChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(useAltViewChanged:)
                         name : ORProcessModelUseAltViewChanged
						object: model];	

	[notifyCenter addObserver : self
                     selector : @selector(objectsChanged:)
                         name : ORGroupObjectsAdded
						object: nil];	
}

- (void) updateWindow
{
    [super updateWindow];
    [self testModeChanged:nil];
    [self shortNameChanged:nil];
    [self detailsChanged:nil];
    [self processRunningChanged:nil];
	[self sampleRateChanged:nil];
	[self useAltViewChanged:nil];
}

- (void) useAltViewChanged:(NSNotification*)aNote
{
	[altViewButton setTitle:[model useAltView]?@"Edit Connections":@"Show Displays Only"];
	[groupView setNeedsDisplay:YES];
}

- (void) objectsChanged:(NSNotification*)aNote
{
	//just set the same value to force a reset of the value to all objects
	[model setUseAltView:[model useAltView]];
	//we also have to assign a processID number -- different than the uniqueID number
	[model setProcessIDs];
}

- (void) commentChanged:(NSNotification*)aNote
{
    [tableView reloadData];
}

- (void) processRunningChanged:(NSNotification*)aNote
{
	if([model processRunning]){
		[startButton setTitle:@"Stop"];
		if([model inTestMode])[statusTextField setStringValue:@"Testing This Process"];
		else [statusTextField setStringValue:@"Running This Process"];
	}
	else {
		[startButton setTitle:@"Start"];
		[statusTextField setStringValue:@"Process is Idle"];
	}
}

- (void) testModeChanged:(NSNotification*)aNote
{
	[testModeButton setState:[model inTestMode]];
}


- (void) elementStateChanged:(NSNotification*)aNote
{
    if([[model orcaObjects] containsObject:[aNote object]]){
        //if([[aNote object] canImageChangeWithState]){
		NSRect objRect = [[aNote object] frame];
		//add in all the bounds of the lines
		NSEnumerator* e = [[[aNote object] connectors] objectEnumerator];
		id aConnector;
		while(aConnector = [e nextObject]){
			if([aConnector connector]) objRect = NSUnionRect(objRect,[aConnector lineBounds]);
		}
		[groupView setNeedsDisplayInRect:objRect];
		[tableView reloadData];
		// }
    }
}

- (void) detailsChanged:(NSNotification*)aNote
{
    if([aNote object] == tableView){
        NSString* theDetails = @"";
        
        NSIndexSet* theSelectedSet =  [tableView selectedRowIndexes];
        if(theSelectedSet){
            int rowIndex = [theSelectedSet firstIndex];
            id item = [[model orcaObjects]objectAtIndex:rowIndex];
            theDetails = [NSString stringWithFormat:@"%@",[item description:@""]];
        }
        [detailsTextView setString:theDetails];
    }
}

- (void) shortNameChanged:(NSNotification*)aNote
{
	[shortNameField setStringValue:[model shortName]];
    [tableView reloadData];
}

#pragma mark ¥¥¥Actions
- (IBAction) useAltViewAction:(id)sender
{
	[model setUseAltView:![model useAltView]];
}

- (void) sampleRateAction:(id)sender
{
	[model setSampleRate:[sender floatValue]];	
}

- (IBAction) startProcess:(id)sender
{
	[[self window] endEditingFor:nil];		
    [model startStopRun];
	[groupView setNeedsDisplayInRect:[groupView bounds]];
}

- (IBAction) testModeAction:(id)sender
{
    [model setInTestMode:[sender intValue]];
}

- (IBAction) shortNameAction:(id)sender
{
	[model setShortName:[sender stringValue]];
}

#pragma mark ¥¥¥Data Source
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
    NSParameterAssert(rowIndex >= 0 && rowIndex < [[model orcaObjects] count]);
    NSString* columnID =  [aTableColumn identifier];
    id item = @"--";
    @try {
        item =  [[[model orcaObjects]objectAtIndex:rowIndex] valueForKey:columnID];
	}
	@catch(NSException* localException) {
	}
	return item;
}
- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    NSParameterAssert(rowIndex >= 0 && rowIndex < [[model orcaObjects] count]);
    id item = [[model orcaObjects]objectAtIndex:rowIndex];
    [item setValue:anObject forKey:[aTableColumn identifier]];
}

// just returns the number of items we have.
- (int) numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [[model orcaObjects] count];
}

- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)item
{
    int index = [tabView indexOfTabViewItem:item];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:[NSString stringWithFormat:@"orca.Process%d.selectedtab",[model uniqueIdNumber]]];
}

- (void) tableView:(NSTableView*)tv didClickTableColumn:(NSTableColumn *)tableColumn
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
    [tableView reloadData];
}

- (void) updateTableHeaderToMatchCurrentSort
{
    BOOL isDescending = [self sortIsDescending];
    NSString *key = [self sortColumn];
    NSArray *a = [tableView tableColumns];
    NSTableColumn *column = [tableView tableColumnWithIdentifier:key];
    unsigned i = [a count];
    
    while (i-- > 0) [tableView setIndicatorImage:nil inTableColumn:[a objectAtIndex:i]];
    
    if (key) {
        [tableView setIndicatorImage:(isDescending ? ascendingSortingImage:descendingSortingImage) inTableColumn:column];
        
        [tableView setHighlightedTableColumn:column];
    }
    else {
        [tableView setHighlightedTableColumn:nil];
    }
}

-(void)setSortColumn:(NSString *)identifier {
    if (![identifier isEqualToString:_sortColumn]) {
        // [[[self undoManager] prepareWithInvocationTarget:self] setSortColumn:_sortColumn];
        [_sortColumn release];
        _sortColumn = [identifier copyWithZone:[self zone]];
        //[[self undoManager] setActionName:@"Column Selection"];
    }
}

- (NSString *)sortColumn
{
    return _sortColumn;
}

- (void)setSortIsDescending:(BOOL)whichWay {
    if (whichWay != _sortIsDescending) {
        //[[[self undoManager] prepareWithInvocationTarget:self] setSortIsDescending:_sortIsDescending];
        _sortIsDescending = whichWay;
        //[[self undoManager] setActionName:@"Sort Direction"];
    }
}

- (BOOL)sortIsDescending
{
    return _sortIsDescending;
}

- (void)sort
{
    if(_sortIsDescending)[[model orcaObjects] sortUsingFunction:sortDnFunction context: _sortColumn];
    else [[model orcaObjects] sortUsingFunction:sortUpFunction context: _sortColumn];
}

- (IBAction) doubleClick:(id)sender
{
    id selectedObj = [[model orcaObjects] objectAtIndex: [tableView selectedRow]];
    [selectedObj doDoubleClick:sender];
}
@end
