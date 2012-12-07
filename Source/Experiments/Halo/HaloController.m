//
//  HaloController.m
//  Orca
//
//  Created by Mark Howe on Tue Jun 28 2005.
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
#import "HaloController.h"
#import "HaloModel.h"
#import "ORDetectorSegment.h"
#import "ORSegmentGroup.h"
#import "HaloSentry.h"

@implementation HaloController
#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"Halo"];
    return self;
}

- (NSString*) defaultPrimaryMapFilePath
{
	return @"~/Halo";
}


-(void) awakeFromNib
{
	
	detectorSize		= NSMakeSize(620,595);
	detailsSize			= NSMakeSize(450,589);
	focalPlaneSize		= NSMakeSize(700,589);
	sentrySize          = NSMakeSize(700,589);
	
    blankView = [[NSView alloc] init];
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];

    [super awakeFromNib];
}


#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];

    [notifyCenter addObserver : self
                     selector : @selector(viewTypeChanged:)
                         name : HaloModelViewTypeChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(registerNotificationObservers)
                         name : HaloModelHaloSentryChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(ipNumberChanged:)
                         name : HaloSentryIpNumber1Changed
						object: [model haloSentry]];
    
    [notifyCenter addObserver : self
                     selector : @selector(ipNumberChanged:)
                         name : HaloSentryIpNumber2Changed
						object: [model haloSentry]];
 
    [notifyCenter addObserver : self
                     selector : @selector(sentryTypeChanged:)
                         name : HaloSentryTypeChanged
						object: [model haloSentry]];
    
    [notifyCenter addObserver : self
                     selector : @selector(stateChanged:)
                         name : HaloSentryStateChanged
						object: [model haloSentry]];

    [notifyCenter addObserver : self
                     selector : @selector(remoteStateChanged:)
                         name : HaloSentryRemoteStateChanged
						object: [model haloSentry]];

    [notifyCenter addObserver : self
                     selector : @selector(stealthMode1Changed:)
                         name : HaloSentryStealthMode1Changed
						object: [model haloSentry]];

    [notifyCenter addObserver : self
                     selector : @selector(stealthMode2Changed:)
                         name : HaloSentryStealthMode2Changed
						object: [model haloSentry]];
    
    [notifyCenter addObserver : self
                     selector : @selector(sentryIsRunningChanged:)
                         name : HaloSentryIsRunningChanged
						object: [model haloSentry]];   

    [notifyCenter addObserver : self
                     selector : @selector(sentryLockChanged:)
                         name : HaloModelSentryLock
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(remoteStateChanged:)
                         name : HaloSentryMissedHeartbeat
						object: [model haloSentry]];
   
    [notifyCenter addObserver : self
                     selector : @selector(sbcPasswordChanged:)
                         name : HaloSentrySbcRootPwdChanged
						object: [model haloSentry]];

    [notifyCenter addObserver : self
                     selector : @selector(emailListChanged:)
                         name : HaloModelEmailListChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(heartBeatIndexChanged:)
                         name : HaloModelNextHeartBeatChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(nextHeartBeatChanged:)
                         name : HaloModelNextHeartBeatChanged
						object: model];

    
}

- (void) updateWindow
{
    [super updateWindow];
	[self viewTypeChanged:nil];
	[self stateChanged:nil];
	[self sentryTypeChanged:nil];
	[self ipNumberChanged:nil];
	[self remoteStateChanged:nil];
	[self stealthMode1Changed:nil];
	[self stealthMode2Changed:nil];
	[self sentryIsRunningChanged:nil];
	[self sbcPasswordChanged:nil];
    [self heartBeatIndexChanged:nil];
	[self nextHeartBeatChanged:nil];

    [self sentryLockChanged:nil];
}

#pragma mark ¥¥¥Interface Management

- (void) checkGlobalSecurity
{
    [super checkGlobalSecurity];
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:HaloModelSentryLock to:secure];
    [sentryLockButton setEnabled:secure];
}

- (void) heartBeatIndexChanged:(NSNotification*)aNote
{
	[heartBeatIndexPU selectItemAtIndex: [model heartBeatIndex]];
}

- (void) nextHeartBeatChanged:(NSNotification*)aNote
{
	if([model heartbeatSeconds]){
		[nextHeartbeatField setStringValue:[NSString stringWithFormat:@"Next Heartbeat: %@",[[model nextHeartbeat]descriptionWithCalendarFormat:nil timeZone:nil locale:nil]]];
	}
	else [nextHeartbeatField setStringValue:@"No Heartbeat Scheduled"];
}

- (void) emailListChanged:(NSNotification*)aNote
{
	[emailListTable reloadData];
}

- (void) sentryIsRunningChanged:(NSNotification*)aNote
{
    [self updateButtons];
}

- (void) remoteStateChanged:(NSNotification*)aNote
{
    if([[model haloSentry]state] != eIdle){
        [remoteMachineRunningField  setStringValue: [[model haloSentry] remoteMachineStatusString]];
        [connectedField             setStringValue: [[model haloSentry] connectionStatusString]];
        [remoteRunInProgressField   setStringValue: [[model haloSentry] remoteORCArunStateString]];
    }
    else {
        [remoteMachineRunningField  setStringValue:@"?"];
        [connectedField             setStringValue:@"?"];
        [remoteRunInProgressField   setStringValue:@"?"];        
    }
    [self updateButtons];
}

- (void) sentryTypeChanged:(NSNotification*)aNote
{
    [sentryTypeField setStringValue:[[model haloSentry] sentryTypeName]];
}

- (void) sbcPasswordChanged:(NSNotification*)aNote
{
    [sbcPasswordField setStringValue:[[model haloSentry] sbcRootPwd]];
}

- (void) stateChanged:(NSNotification*)aNote
{
    [stateField setStringValue:[[model haloSentry] stateName]];
}

- (void) ipNumberChanged:(NSNotification*)aNote
{
    [ip1Field setStringValue:[[model haloSentry] ipNumber1]];
    [ip2Field setStringValue:[[model haloSentry] ipNumber2]];
}

- (void) viewTypeChanged:(NSNotification*)aNote
{
	[viewTypePU selectItemAtIndex:[model viewType]];
	[detectorView setViewType:[model viewType]];
	[detectorView makeAllSegments];	
}

- (void) stealthMode2Changed:(NSNotification*)aNote
{
	[stealthMode2CB setIntValue: [[model haloSentry] stealthMode2]];
}

- (void) stealthMode1Changed:(NSNotification*)aNote
{
	[stealthMode1CB setIntValue: [[model haloSentry] stealthMode1]];
}

- (void) specialUpdate:(NSNotification*)aNote
{
	[super specialUpdate:aNote];
	[detectorView makeAllSegments];
}

- (void) setDetectorTitle
{	
	switch([model displayType]){
		case kDisplayRates:			[detectorTitle setStringValue:@"Detector Rate"];	break;
		case kDisplayThresholds:	[detectorTitle setStringValue:@"Thresholds"];		break;
		case kDisplayGains:			[detectorTitle setStringValue:@"Gains"];			break;
		case kDisplayTotalCounts:	[detectorTitle setStringValue:@"Total Counts"];		break;
		default: break;
	}
}

- (void) sentryLockChanged:(NSNotification*)aNote
{
    BOOL locked = [gSecurity isLocked:HaloModelSentryLock];
	[sentryLockButton setState: locked];
    [self updateButtons];
}

- (void) updateButtons
{
    BOOL locked = [gSecurity isLocked:HaloModelSentryLock];
    BOOL sentryRunning = [[model haloSentry] sentryIsRunning];
    BOOL aRunIsInProgress = [[model haloSentry] runIsInProgress];
   	BOOL anyAddresses = ([[model emailList] count]>0);
    
	[heartBeatIndexPU setEnabled:anyAddresses];
 
    [stealthMode2CB setEnabled:!locked && !sentryRunning];
    [stealthMode1CB setEnabled:!locked && !sentryRunning];
    [ip1Field setEnabled:!locked && !sentryRunning];
    [ip2Field setEnabled:!locked && !sentryRunning];
    [startButton setEnabled:!locked];
    [startButton setTitle:sentryRunning?@"Stop":@"Start"];
    [toggleButton setEnabled:!locked & aRunIsInProgress];
}

- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)tabViewItem
{
    if([tabView indexOfTabViewItem:tabViewItem] == 0){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:detectorSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 1){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:detailsSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 2){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:focalPlaneSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 3){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:sentrySize];
		[[self window] setContentView:tabView];
    }
    
	int index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"orca.HaloController.selectedtab"];
}

#pragma mark ¥¥¥Actions
- (IBAction) addAddress:(id)sender
{
	int index = [[model emailList] count];
	[model addAddress:@"<eMail>" atIndex:index];
	NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:index];
	[emailListTable selectRowIndexes:indexSet byExtendingSelection:NO];
	[self updateButtons];
	[emailListTable reloadData];
}

- (IBAction) removeAddress:(id)sender
{
	//only one can be selected at a time. If that restriction is lifted then the following will have to be changed
	//to something a lot more complicated.
	NSIndexSet* theSet = [emailListTable selectedRowIndexes];
	NSUInteger current_index = [theSet firstIndex];
    if(current_index != NSNotFound){
		[model removeAddressAtIndex:current_index];
	}
	[self updateButtons];
	[emailListTable reloadData];
}

- (IBAction) heartBeatIndexAction:(id)sender
{
	[model setHeartBeatIndex:[sender indexOfSelectedItem]];
}

- (IBAction) sbcPasswordAction:(id)sender
{
	[[model haloSentry] setSbcRootPwd:[sender stringValue]];
}

- (IBAction) stealthMode2Action:(id)sender
{
	[[model haloSentry] setStealthMode2:[sender intValue]];
}

- (IBAction) stealthMode1Action:(id)sender
{
	[[model haloSentry] setStealthMode1:[sender intValue]];	
}

- (IBAction) viewTypeAction:(id)sender
{
	[model setViewType:[sender indexOfSelectedItem]];
}

- (IBAction) ip1Action:(id)sender
{
	[[model haloSentry] setIpNumber1:[sender stringValue]];
}
- (IBAction) ip2Action:(id)sender
{
	[[model haloSentry] setIpNumber2:[sender stringValue]];
}

- (IBAction) toggleSystems:(id)sender
{
    [[model haloSentry] toggleSystems];
}

- (IBAction) sentryLockAction:(id)sender
{
    [gSecurity tryToSetLock:HaloModelSentryLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) startStopSentry:(id)sender
{
    if(![[model haloSentry] sentryIsRunning]){
        [[model haloSentry] start];
    }
    else {
        [[model haloSentry] stop];
    }
}

#pragma mark ¥¥¥Data Source
- (void) tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if([aNotification object] == emailListTable || aNotification == nil){
		int selectedIndex = [emailListTable selectedRow];
		[removeAddressButton setEnabled:selectedIndex>=0];
	}
}

- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
	if(aTableView == emailListTable){
		if(rowIndex < [[model emailList] count]){
			id addressObj = [[model emailList] objectAtIndex:rowIndex];
			return addressObj;
		}
		else return @"";
	}
    else return [super tableView:aTableView objectValueForTableColumn:aTableColumn row:rowIndex];
}
- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if(aTableView == emailListTable){
		if(rowIndex < [[model emailList] count]){
			[[model emailList] replaceObjectAtIndex:rowIndex withObject:anObject];
		}
	}
    else [super tableView:aTableView setObjectValue:anObject forTableColumn:aTableColumn row:rowIndex];
}

// just returns the number of items we have.
- (int) numberOfRowsInTableView:(NSTableView *)aTableView
{
 	if(aTableView == emailListTable){
		return [[model emailList] count];
    }
    else return [super numberOfRowsInTableView:aTableView];
}

@end
