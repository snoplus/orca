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
#import "SynthesizeSingleton.h"
#import "ORMailer.h"

int sortUpFunc(id element1,id element2, void* context){ return [element1 compareStringTo:element2 usingKey:context];}
int sortDnFunc(id element1,id element2, void* context){return [element2 compareStringTo:element1 usingKey:context];}

NSString* ORProcessEmailOptionsChangedNotification = @"ORProcessEmailOptionsChangedNotification";

@implementation ORProcessCenter

#pragma mark ¥¥¥Inialization

SYNTHESIZE_SINGLETON_FOR_ORCLASS(ProcessCenter);

-(id)init
{
    self = [super initWithWindowNibName:@"ProcessCenter"];
    [self setWindowFrameAutosaveName:@"ProcessCenterX"];
    return self;
}

- (void) dealloc
{
	//should never get here since we are a sigleton, but....
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[ascendingSortingImage release];
	[descendingSortingImage release];
    [processorList release];
	[eMailList release];
	[nextHeartbeat release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
	[heartbeatTimeIndexPU selectItemAtIndex:heartbeatTimeIndex];
	[sendAtStartButton setIntValue:sendAtStart];
	[sendAtStopButton setIntValue:sendAtStop];
	[self setHeartbeatImage];
	[self setNextHeartbeatString];
    [[[[NSApp delegate]document] undoManager] enableUndoRegistration];
	
    [self registerNotificationObservers];
    [processView setDoubleAction:@selector(doubleClick:)];
	
	[self updateButtons];
}

- (void) setHeartbeatImage
{
	if([self heartbeatTimeIndex] == 0){
		NSImage* noHeartbeatImage = [NSImage imageNamed:@"noHeartbeat"];
		[heartbeatImage setImage:noHeartbeatImage];
	}
	else [heartbeatImage setImage:nil];
}

- (void) setNextHeartbeatString
{
	if([self heartbeatSeconds]){
		[nextHeartbeat release];
#if defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6 // 10.6-specific
		nextHeartbeat = [[[NSDate date] dateByAddingTimeInterval:[self heartbeatSeconds]] retain];
#else
		nextHeartbeat = [[[NSDate date] addTimeInterval:[self heartbeatSeconds]] retain];
#endif
		[nextHeartbeatField setStringValue:[NSString stringWithFormat:@"Next Heartbeat: %@",[nextHeartbeat description]]];
	}
	else [nextHeartbeatField setStringValue:@""];
	
}

- (void) updateButtons
{
	BOOL anyAddresses = ([eMailList count]>0);
	[heartbeatTimeIndexPU setEnabled:anyAddresses];
	[sendAtStartButton setEnabled:anyAddresses];
	[sendAtStopButton setEnabled:anyAddresses];
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

- (void) awakeAfterDocumentLoaded
{
    [self findObjects];
	//force an update of the processor icons
	[[NSNotificationCenter defaultCenter] postNotificationName:ORProcessEmailOptionsChangedNotification object:self userInfo:nil]; 
}

- (int) numberRunningProcesses
{
	int processCount = 0;
	for(id aProcess in processorList){
		if([aProcess processRunning]) processCount++;
	}
	return processCount;
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

#pragma mark ¥¥¥eMail
- (BOOL) emailEnabled
{
    return emailEnabled;
}

- (void) setEmailEnabled:(BOOL)aEmailEnabled
{
    [[[[NSApp delegate] undoManager] prepareWithInvocationTarget:self] setEmailEnabled:emailEnabled];
    
    emailEnabled = aEmailEnabled;
	
}

- (NSMutableArray*) eMailList
{
    return eMailList;
}

- (void) setEMailList:(NSMutableArray*)aEMailList
{
    [aEMailList retain];
    [eMailList release];
    eMailList = aEMailList;
}

- (void) addAddress:(id)anAddress atIndex:(int)anIndex
{
	if(!eMailList) eMailList= [[NSMutableArray array] retain];
	if([eMailList count] == 0)anIndex = 0;
	anIndex = MIN(anIndex,[eMailList count]);
	
	[[[[NSApp delegate] undoManager] prepareWithInvocationTarget:self] removeAddressAtIndex:anIndex];
	[eMailList insertObject:anAddress atIndex:anIndex];
	
	[addressList reloadData];
}

- (void) removeAddressAtIndex:(int) anIndex
{
	id anAddress = [eMailList objectAtIndex:anIndex];
	[[[[NSApp delegate] undoManager] prepareWithInvocationTarget:self] addAddress:anAddress atIndex:anIndex];
	[eMailList removeObjectAtIndex:anIndex];
	[addressList reloadData];
}

- (int) heartbeatSeconds
{
	switch(heartbeatTimeIndex){
		case 0: return 0;
		case 1: return 30*60;
		case 2: return 60*60;
		case 3: return 2*60*60;
		case 4: return 8*60*60;
		case 5: return 12*60*60;
		case 6: return 24*60*60;
		default: return 0;
	}
	return 0;
}

- (int) heartbeatTimeIndex
{
	return heartbeatTimeIndex;
}

- (void) setHeartbeatTimeIndex:(int)aTime
{
	[[[[[NSApp delegate]document] undoManager] prepareWithInvocationTarget:self] setHeartbeatTimeIndex:heartbeatTimeIndex];
	heartbeatTimeIndex = aTime;
	[heartbeatTimeIndexPU selectItemAtIndex:heartbeatTimeIndex];
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	if([self heartbeatSeconds]){
		[self performSelector:@selector(sendHeartbeat) withObject:nil afterDelay:[self heartbeatSeconds]];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ORProcessEmailOptionsChangedNotification object:self userInfo:nil]; 
	[self setHeartbeatImage];
	[self setNextHeartbeatString];
}

- (BOOL) sendAtStart
{
	return sendAtStart;
}

- (void) setSendAtStart:(BOOL)aState
{
	[[[[[NSApp delegate]document] undoManager] prepareWithInvocationTarget:self] setSendAtStart:sendAtStart];
	sendAtStart = aState;
	[sendAtStartButton setIntValue:sendAtStart];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORProcessEmailOptionsChangedNotification object:self userInfo:nil]; 
}

- (BOOL) sendAtStop
{
	return sendAtStop;
}

- (void) setSendAtStop:(BOOL)aState
{
	[[[[[NSApp delegate]document] undoManager] prepareWithInvocationTarget:self] setSendAtStop:sendAtStop];
	sendAtStop = aState;
	[sendAtStopButton setIntValue:sendAtStop];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORProcessEmailOptionsChangedNotification object:self userInfo:nil]; 
}



- (void) sendHeartbeatShutOffWarning
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	NSString* theContent = @"";
	
	theContent = [theContent stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];						
	theContent = [theContent stringByAppendingFormat:@"The Process Center email heartbeat was shut off manually.\n"];
	theContent = [theContent stringByAppendingFormat:@"If this is unexpected you should contact the operator.\n"];
	theContent = [theContent stringByAppendingString:@"The following people received this message:\n"];
	for(id address in eMailList) theContent = [theContent stringByAppendingFormat:@"%@\n",address];
	theContent = [theContent stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];						
	for(id address in eMailList){
		if(	!address || [address length] == 0 || [address isEqualToString:@"<eMail>"])continue;
		NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:address,@"Address",theContent,@"Message",@"Shutdown",@"Shutdown",nil];
		[NSThread detachNewThreadSelector:@selector(eMailThread:) toTarget:self withObject:userInfo];
	}
}

- (NSString*) description 
{
	NSString* theContent = @"";
	for(id aProcess in processorList){
		theContent = [theContent stringByAppendingFormat:@"%@\n",[aProcess description]];
	}
	return theContent;
}

- (void) sendHeartbeat
{
	NSString* theContent = @"";
	
	theContent = [theContent stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];						
	theContent = [theContent stringByAppendingFormat:@"This heartbeat message was generated automatically by the Process Center\n"];
	theContent = [theContent stringByAppendingFormat:@"Unless changed in ORCA, it will be repeated at %@\n",nextHeartbeat];
	theContent = [theContent stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];	
	theContent = [theContent stringByAppendingFormat:@"%@\n",[self description]];
	theContent = [theContent stringByAppendingString:@"\n\n+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];						
	theContent = [theContent stringByAppendingString:@"The following people received this message:\n"];
	for(id address in eMailList) theContent = [theContent stringByAppendingFormat:@"%@\n",address];
	theContent = [theContent stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];						

	for(id address in eMailList){
		if(	!address || [address length] == 0 || [address isEqualToString:@"<eMail>"])continue;
		NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:address,@"Address",theContent,@"Message",nil];
		[NSThread detachNewThreadSelector:@selector(eMailThread:) toTarget:self withObject:userInfo];
	}
	
	if([self heartbeatSeconds]){
		[self performSelector:@selector(sendHeartbeat) withObject:nil afterDelay:[self heartbeatSeconds]];
	}
	
	[self setNextHeartbeatString];
}

- (void) sendStopNotice:(ORProcessModel*)aProcess
{
	if(sendAtStop){
		[self sendStartStopNotice:aProcess started:NO];
	}
}

- (void) sendStartNotice:(ORProcessModel*)aProcess
{
	if(sendAtStart){
		[self sendStartStopNotice:aProcess started:YES];
	}
}

- (void) stopAllAndNotify
{
	[self stopAll:nil];
	if(sendAtStop){
		NSString* theContent = @"";
		
		theContent = [theContent stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];						
		theContent = [theContent stringByAppendingString:@"All processes stopped because ORCA was stopped\n"];
		theContent = [theContent stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];	
		theContent = [theContent stringByAppendingString:@"The following people received this message:\n"];
		for(id address in eMailList) theContent = [theContent stringByAppendingFormat:@"%@\n",address];
		theContent = [theContent stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];						
		
		for(id address in eMailList){
			if(	!address || [address length] == 0 || [address isEqualToString:@"<eMail>"])continue;
			NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:address,@"Address",theContent,@"Message",nil];
			[self eMailThread:userInfo];
		}
	}
}

- (void) sendStartStopNotice:(ORProcessModel*)aProcess started:(BOOL)state
{
	NSString* theContent = @"";
	
	theContent = [theContent stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];						
	theContent = [theContent stringByAppendingFormat:@"Process was %@\n",state?@"started":@"stopped"];
	if(state){
		theContent = [theContent stringByAppendingString:@"Some Values may not have had time to be updated\n"];	
	}
	theContent = [theContent stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];	
	
	theContent = [theContent stringByAppendingFormat:@"%@\n",[aProcess description]];
	
	theContent = [theContent stringByAppendingString:@"\n\n+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];						
	theContent = [theContent stringByAppendingString:@"The following people received this message:\n"];
	for(id address in eMailList) theContent = [theContent stringByAppendingFormat:@"%@\n",address];
	theContent = [theContent stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];						
	
	for(id address in eMailList){
		if(	!address || [address length] == 0 || [address isEqualToString:@"<eMail>"])continue;
		NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:address,@"Address",theContent,@"Message",nil];
		[NSThread detachNewThreadSelector:@selector(eMailThread:) toTarget:self withObject:userInfo];
	}
}

#pragma mark ¥¥¥Actions
- (IBAction) heartbeatTimeIndexAction:(id)sender
{
    [self setHeartbeatTimeIndex: [sender indexOfSelectedItem]];
	if([self heartbeatSeconds] == 0){
		[self sendHeartbeatShutOffWarning];
	}
}

- (IBAction) sendAtStartAction:(id)sender
{
    [self setSendAtStart: [sender intValue]];
}

- (IBAction) sendAtStopAction:(id)sender
{
    [self setSendAtStop: [sender intValue]];
}

- (IBAction) doubleClick:(id)sender
{
    [[processView selectedItem] doDoubleClick:sender];
}

- (IBAction) saveDocument:(id)sender
{
    [[[NSApp delegate]document] saveDocument:sender];
}

- (IBAction) saveDocumentAs:(id)sender
{
    [[[NSApp delegate]document] saveDocumentAs:sender];
}

- (IBAction) addAddress:(id)sender
{
	int index = [eMailList count];
	[self addAddress:@"<eMail>" atIndex:index];
	NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:index];
	[addressList selectRowIndexes:indexSet byExtendingSelection:NO];
	[self updateButtons];
}

- (IBAction) removeAddress:(id)sender
{
	//only one can be selected at a time. If that restriction is lifted then the following will have to be changed
	//to something a lot more complicated.
	NSIndexSet* theSet = [addressList selectedRowIndexes];
	NSUInteger current_index = [theSet firstIndex];
    if(current_index != NSNotFound){
		[self removeAddressAtIndex:current_index];
	}
	[self updateButtons];
}

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

#pragma mark ¥¥¥OutlineView Data Source
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

- (void) sort
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

#pragma mark ¥¥¥TableView Data Source Methods
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
	if(rowIndex < [eMailList count]){
		id addressObj = [eMailList objectAtIndex:rowIndex];
		return addressObj; 
	}
	else return @"";
}

- (void) tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if(rowIndex < [eMailList count]){
		[eMailList replaceObjectAtIndex:rowIndex withObject:anObject];
	}
}

- (int) numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [eMailList count];
}

- (void) tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if([aNotification object] == addressList || aNotification == nil){
		int selectedIndex = [addressList selectedRow];
		[removeAddressButton setEnabled:selectedIndex>=0];
	}
}

#pragma mark ¥¥¥Archival
//special -- archived from the main document
- (void) decodeEMailList:(NSCoder*) aDecoder
{
	[self setEMailList:[aDecoder decodeObjectForKey:@"processorEMailList"]];
	[self setHeartbeatTimeIndex:[aDecoder decodeIntForKey:@"heartbeatTimeIndex"]];
	[self setSendAtStart:[aDecoder decodeBoolForKey:@"sendAtStart"]];
	[self setSendAtStop:[aDecoder decodeBoolForKey:@"sendAtStop"]];
}

- (void) encodeEMailList:(NSCoder*) anEncoder
{
    [[[NSApp delegate] undoManager] disableUndoRegistration];
	[anEncoder encodeObject:eMailList forKey:@"processorEMailList"];
	[anEncoder encodeInt:heartbeatTimeIndex forKey:@"heartbeatTimeIndex"];
	[anEncoder encodeBool:sendAtStart forKey:@"sendAtStart"];
	[anEncoder encodeBool:sendAtStop forKey:@"sendAtStop"];
    [[[NSApp delegate] undoManager] enableUndoRegistration];
}

#pragma mark ¥¥¥EMail Thread
- (void) mailSent:(NSString*)address
{
	NSLog(@"Process Center status was sent to:\n%@\n",address);
}

- (void) eMailThread:(id)userInfo
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSString* address =  [userInfo objectForKey:@"Address"];
	NSString* content = [NSString string];
	NSString* hostAddress = @"<Unable to get host address>";
	NSArray* names =  [[NSHost currentHost] addresses];
	for(id aName in names){
		if([aName rangeOfString:@"::"].location == NSNotFound){
			if([aName rangeOfString:@".0.0."].location == NSNotFound){
				hostAddress = aName;
				break;
			}
		}
	}
	content = [content stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];
	content = [content stringByAppendingFormat:@"ORCA Message From Host: %@\n",hostAddress];
	content = [content stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n\n"];
	NSString* theMessage = [userInfo objectForKey:@"Message"];
	if(theMessage){
		content = [content stringByAppendingString:theMessage];
	}
	NSString* shutDownWarning = [userInfo objectForKey:@"Shutdown"];
	if(shutDownWarning){
		//generated from a manual shutdown of the email system. 
		//don't send out any other info.
	}
	@synchronized([NSApp delegate]){
		
		NSAttributedString* theContent = [[NSAttributedString alloc] initWithString:content];
		ORMailer* mailer = [ORMailer mailer];
		[mailer setTo:address];
		[mailer setSubject:@"Orca Message"];
		[mailer setBody:theContent];
		[mailer send:self];
		[theContent autorelease];
	}
	
	[pool release];
	
}

@end

