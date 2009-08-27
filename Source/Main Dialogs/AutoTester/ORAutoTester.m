//
//  ORAutoTester.mh
//  Orca
//
//  Created by Mark Howe on Sat Dec 28 2002.
//  Copyright (c) 2009 University of North Carolina. All rights reserved.
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

#import "ORAutoTester.h"
#import "ORGroup.h"
#import "AutoTesting.h"
#import "SynthesizeSingleton.h"
#import "ORVmeTests.h"

NSString*  AutoTesterLock = @"AutoTesterLock";

@interface ORAutoTester (private)
- (void) runTestThread:(NSArray*)objectsToTest;
@end

@implementation ORAutoTester

SYNTHESIZE_SINGLETON_FOR_ORCLASS(AutoTester);

- (id)init
{
    self = [super initWithWindowNibName:@"AutoTester"];
    return self;
}

- (void) awakeFromNib
{
    [self registerNotificationObservers];
	[totalListView reloadData];
	[runTestsButton setEnabled: NO];
 	[stopTestsButton setEnabled:NO];
	[totalListView setAction:@selector(tableClick:)];
	[self securityStateChanged:nil];
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow*)window
{
    return [[NSApp delegate]  undoManager];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(objectsChanged:)
                         name : ORGroupObjectsAdded
                       object : nil];

	[notifyCenter addObserver : self
                     selector : @selector(objectsChanged:)
                         name : ORGroupObjectsRemoved
                       object : nil];

	[notifyCenter addObserver : self
                     selector : @selector(runStatusChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : AutoTesterLock
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(securityStateChanged:)
                         name : ORGlobalSecurityStateChanged
                        object: nil];
	
	//we don't want this notification
	[notifyCenter removeObserver:self name:NSWindowDidResignKeyNotification object:nil];
}

- (void) runStatusChanged:(NSNotification*)aNote
{
	[runTestsButton setEnabled:![gOrcaGlobals runInProgress]];
}

- (void) objectsChanged:(NSNotification*)aNote
{
	[totalListView reloadData];
}

- (void) securityStateChanged:(NSNotification*)aNote
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:AutoTesterLock to:secure];
    [lockButton setEnabled:secure];
}

- (void) lockChanged:(NSNotification*)aNote
{
    BOOL locked = [gSecurity isLocked:AutoTesterLock];
	[lockButton setState: locked];

	[runTestsButton setEnabled: !locked && [[totalListView allSelectedItems] count]!=0];
	[stopTestsButton setEnabled:!locked && [gOrcaGlobals testInProgress]];
	[totalListView setEnabled: !locked];
}

- (IBAction) runTest:(id)sender
{
	if(!testsRunning){
		[NSThread detachNewThreadSelector:@selector(runTestThread:) toTarget:self withObject:[totalListView allSelectedItems]];
	}
}

- (IBAction) tableClick:(id)sender
{
	if(sender == totalListView){
		[runTestsButton setEnabled:[[totalListView allSelectedItems] count]!=0];
	}
}

- (IBAction) stopTests:(id)sender
{
	stopTesting  = YES;
}

- (IBAction) lockAction:(id)sender
{
    [gSecurity tryToSetLock:AutoTesterLock to:[sender intValue] forWindow:[self window]];
}

#pragma mark •••Delegate Methods
- (BOOL)outlineView:(NSOutlineView *)ov shouldSelectItem:(id)item
{
	if([item conformsToProtocol:@protocol(AutoTesting)])return YES;
	else return NO;		
}

#pragma mark •••Data Source Methods

#define GET_CHILDREN NSArray* children; \
if(!item) children = [[[[[NSApp delegate] document] group] orcaObjects] sortedArrayUsingSelector:@selector(sortCompare:)]; \
else if([item respondsToSelector:@selector(orcaObjects)])children = [[item orcaObjects]sortedArrayUsingSelector:@selector(sortCompare:)]; \
else children = nil;\

- (BOOL) outlineView:(NSOutlineView*)ov isItemExpandable:(id)item 
{
	GET_CHILDREN; //macro: given an item, sets children array and guardian.
	if(!children || ([children count] < 1)) return NO;
	return YES;
}

- (int)  outlineView:(NSOutlineView*)ov numberOfChildrenOfItem:(id)item
{
	GET_CHILDREN; //macro: given an item, sets children array and guardian.
	return [children count];
}

- (id)   outlineView:(NSOutlineView*)ov child:(int)index ofItem:(id)item
{
	GET_CHILDREN; //macro: given an item, sets children array and guardian.
	if(!children || ([children count] <= index)) return nil;
	return [children objectAtIndex:index];
}

- (id)   outlineView:(NSOutlineView*)ov objectValueForTableColumn:(NSTableColumn*)tableColumn byItem:(id)item
{
	if([[tableColumn identifier] isEqualToString:@"isAutoTester"]){
		if([item conformsToProtocol:@protocol(AutoTesting)])return @"YES";
		else return @"NO";
	}
	else return [item valueForKey:[tableColumn identifier]];
}
@end

@implementation ORAutoTester (private)
- (void) runTestThread:(NSArray*)objectsToTest
{
	NSAutoreleasePool* outerPool = [[NSAutoreleasePool alloc] init];
	
	[[objectsToTest retain] autorelease];
	
	stopTesting  = NO;
	[self performSelectorOnMainThread:@selector(testIsRunning) withObject:nil waitUntilDone:YES];
	
	NSEnumerator* objectEnummy = [objectsToTest objectEnumerator];
	id obj;
	while(obj = [objectEnummy nextObject]){
		NSAutoreleasePool* innerPool = [[NSAutoreleasePool alloc] init];
		//loop over all objects
		NSArray* theTests = [obj autoTests];
		NSEnumerator* testEnummy = [theTests objectEnumerator];
		id aTest;
		int failCount=0;
		while(aTest = [testEnummy nextObject]){
			if(stopTesting)break;
			[aTest runTest:obj];
			NSArray* failureLog = [aTest failureLog];
			if(failureLog){
				NSLog(@"%@:  %@ %@\n",[obj fullID], [aTest name],failureLog);
				failCount++;
			}
		}
		if(failCount==0)NSLog(@"%@: PASSED ALL\n",[obj fullID]);

		[innerPool release];
		if(stopTesting) break;
	}
	
	[self performSelectorOnMainThread:@selector(testIsStopped) withObject:nil waitUntilDone:NO];
	[outerPool release];
}

- (void) testIsRunning
{
	[gOrcaGlobals addRunVeto:@"AutoTestinger" comment:@"Can't run while AutoTester running"];
	[gOrcaGlobals setTestInProgress:YES];
	[runTestsButton setEnabled:NO];
	[stopTestsButton setEnabled:YES];
}

- (void) testIsStopped
{
	[runTestsButton setEnabled:[[totalListView allSelectedItems] count]!=0];
	[stopTestsButton setEnabled:NO];
	[gOrcaGlobals removeRunVeto:@"AutoTestinger"];
	[gOrcaGlobals setTestInProgress:NO];
	
}
@end

