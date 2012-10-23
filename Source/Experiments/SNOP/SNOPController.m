//
//  SNOPController.m
//  Orca
//
//  Created by Mark Howe on Tue Apr 20, 2010.
//  Copyright (c) 2010  University of North Carolina. All rights reserved.
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
#import "SNOPController.h"
#import "SNOPModel.h"
#import "ORColorScale.h"
#import "ORAxis.h"
#import "ORDetectorSegment.h"
#import "ORXL3Model.h"

@implementation SNOPController
#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"SNOP"];
    return self;
}


- (NSString*) defaultPrimaryMapFilePath
{
	return @"~/SNOP";
}


-(void) awakeFromNib
{
	detectorSize		= NSMakeSize(620,595);
	detailsSize		= NSMakeSize(450,589);
	focalPlaneSize		= NSMakeSize(450,589);
	couchDBSize		= NSMakeSize(450,500);
	hvMasterSize		= NSMakeSize(620,595);
	slowControlSize		= NSMakeSize(620,595);
	
	blankView = [[NSView alloc] init];
    [tabView setFocusRingType:NSFocusRingTypeNone];
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
                         name : ORSNOPModelViewTypeChanged
			object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(morcaIsVerboseChanged:)
                         name : ORSNOPModelMorcaIsVerboseChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(morcaIsWithinRunChanged:)
                         name : ORSNOPModelMorcaIsWithinRunChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(morcaUpdateRateChanged:)
                         name : ORSNOPModelMorcaUpdateTimeChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(morcaPortChanged:)
                         name : ORSNOPModelMorcaPortChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(morcaStatusChanged:)
                         name : ORSNOPModelMorcaStatusChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(morcaUserNameChanged:)
                         name : ORSNOPModelMorcaUserNameChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(morcaPasswordChanged:)
                         name : ORSNOPModelMorcaPasswordChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(morcaDBNameChanged:)
                         name : ORSNOPModelMorcaDBNameChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(morcaIPAddressChanged:)
                         name : ORSNOPModelMorcaIPAddressChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(morcaIPAddressChanged:)
                         name : ORSNOPModelMorcaIsUpdatingChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(hvStatusChanged:)
                         name : ORXL3ModelHvStatusChanged
                        object: nil];
}

- (void) updateWindow
{
	[super updateWindow];
	[self viewTypeChanged:nil];
    [self morcaUserNameChanged:nil];
    [self morcaPasswordChanged:nil];
    [self morcaDBNameChanged:nil];
    [self morcaPortChanged:nil];
    [self morcaIPAddressChanged:nil];
    [self morcaIsVerboseChanged:nil];
    [self morcaIsWithinRunChanged:nil];
    [self morcaUpdateRateChanged:nil];
    [self morcaStatusChanged:nil];
    [self hvStatusChanged:nil];
}

- (void) viewTypeChanged:(NSNotification*)aNote
{
	[viewTypePU selectItemAtIndex:[model viewType]];
	[detectorView setViewType:[model viewType]];
	[detectorView makeAllSegments];	
}

- (void) morcaUserNameChanged:(NSNotification*)aNote
{
    [morcaUserNameField setStringValue:[model morcaUserName]];
}

- (void) morcaPasswordChanged:(NSNotification*)aNote
{
    [morcaPasswordField setStringValue:[model morcaPassword]];
}

- (void) morcaDBNameChanged:(NSNotification*)aNote
{
    [morcaDBNameField setStringValue:[model morcaDBName]];
}

- (void) morcaPortChanged:(NSNotification*)aNote
{
    [morcaPortField setStringValue:[NSString stringWithFormat:@"%d",[model morcaPort]]];
}

- (void) morcaIPAddressChanged:(NSNotification*)aNote
{
    [morcaIPAddressPU setStringValue:[model morcaIPAddress]];
}

- (void) morcaIsVerboseChanged:(NSNotification*)aNote
{
    [morcaIsVerboseButton setIntValue:[model morcaIsVerbose]];
}

- (void) morcaIsWithinRunChanged:(NSNotification*)aNote
{
    [morcaIsWithinRunButton setIntValue:[model morcaIsWithinRun]];
}

- (void) morcaUpdateRateChanged:(NSNotification*)aNote
{
    [morcaUpdateRatePU selectItemWithTag:[model morcaUpdateTime]];
}

- (void) morcaStatusChanged:(NSNotification*)aNote
{
    [morcaStatusField setStringValue:[model morcaStatus]];
}

- (void) hvStatusChanged:(NSNotification*)aNote
{
    if (!aNote) {//pull from XL3s
        NSArray* xl3s = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")];
        unsigned long xl3Mask = 0x7ffff;
        for (id xl3 in xl3s) {
            xl3Mask ^= 1 << [xl3 crateNumber];
            int mRow;
            int mColumn;
            bool found;
            found = [hvStatusMatrix getRow:&mRow column:&mColumn ofCell:[hvStatusMatrix cellWithTag:[xl3 crateNumber]]];
            if (found) {
                [[hvStatusMatrix cellAtRow:mRow column:1] setStringValue:[xl3 hvASwitch]?@"ON":@"OFF"];
                if ([xl3 hvASwitch]) {
                    [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor redColor]];
                }
                else {
                    [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor blackColor]];
                }
                [[hvStatusMatrix cellAtRow:mRow column:2] setStringValue:
                 [NSString stringWithFormat:@"%d V",(unsigned int)[xl3 hvAVoltageReadValue]]];
                [[hvStatusMatrix cellAtRow:mRow column:3] setStringValue:
                 [NSString stringWithFormat:@"%3.1f mA",[xl3 hvACurrentReadValue]]];
            }
            if ([xl3 crateNumber] == 16) {//16B
                int mRow;
                int mColumn;
                bool found;
                found = [hvStatusMatrix getRow:&mRow column:&mColumn ofCell:[hvStatusMatrix cellWithTag:19]];
                if (found) {
                    [[hvStatusMatrix cellAtRow:mRow column:1] setStringValue:[xl3 hvBSwitch]?@"ON":@"OFF"];
                    if ([xl3 hvBSwitch]) {
                        [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor redColor]];
                    }
                    else {
                        [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor blackColor]];
                    }
                    [[hvStatusMatrix cellAtRow:mRow column:2] setStringValue:
                     [NSString stringWithFormat:@"%d V",(unsigned int)[xl3 hvBVoltageReadValue]]];
                    [[hvStatusMatrix cellAtRow:mRow column:3] setStringValue:
                     [NSString stringWithFormat:@"%3.1f mA",[xl3 hvBCurrentReadValue]]];
                }
            }
        }
        unsigned short crate_num;
        if (xl3Mask & 1 << 16) {//16B needs an extra care
            xl3Mask |= 1 << 19;
        }
        for (crate_num=0; crate_num<20; crate_num++) {
            if (xl3Mask & 1 << crate_num) {
                int mRow;
                int mColumn;
                bool found;
                found = [hvStatusMatrix getRow:&mRow column:&mColumn ofCell:[hvStatusMatrix cellWithTag:crate_num]];
                if (found) {
                    [[hvStatusMatrix cellAtRow:mRow column:1] setStringValue:@"???"];
                    [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor blackColor]];
                    [[hvStatusMatrix cellAtRow:mRow column:2] setStringValue:@"??? V"];
                    [[hvStatusMatrix cellAtRow:mRow column:3] setStringValue:@"??? mA"];
                }
            }
        }
    }
    else { //update from a notification
        int mRow;
        int mColumn;
        bool found;
        found = [hvStatusMatrix getRow:&mRow column:&mColumn ofCell:
                 [hvStatusMatrix cellWithTag:[[aNote object] crateNumber]]];

        if (found) {
            [[hvStatusMatrix cellAtRow:mRow column:1] setStringValue:[[aNote object] hvASwitch]?@"ON":@"OFF"];
            if ([[aNote object] hvASwitch]) {
                [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor redColor]];
            }
            else {
                [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor blackColor]];
            }
            [[hvStatusMatrix cellAtRow:mRow column:2] setStringValue:
             [NSString stringWithFormat:@"%d V",(unsigned int)[[aNote object] hvAVoltageReadValue]]];
            [[hvStatusMatrix cellAtRow:mRow column:3] setStringValue:
             [NSString stringWithFormat:@"%3.1f mA",[[aNote object] hvACurrentReadValue]]];
        }
        if ([[aNote object] crateNumber] == 16) {//16B
            int mRow;
            int mColumn;
            bool found;
            found = [hvStatusMatrix getRow:&mRow column:&mColumn ofCell:[hvStatusMatrix cellWithTag:19]];
            if (found) {
                [[hvStatusMatrix cellAtRow:mRow column:1] setStringValue:[[aNote object] hvBSwitch]?@"ON":@"OFF"];
                if ([[aNote object] hvBSwitch]) {
                    [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor redColor]];
                }
                else {
                    [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor blackColor]];
                }
                [[hvStatusMatrix cellAtRow:mRow column:2] setStringValue:
                 [NSString stringWithFormat:@"%d V",(unsigned int)[[aNote object] hvBVoltageReadValue]]];
                [[hvStatusMatrix cellAtRow:mRow column:3] setStringValue:
                 [NSString stringWithFormat:@"%3.1f mA",[[aNote object] hvBCurrentReadValue]]];
            }
        }
    }
}

#pragma mark ¥¥¥Interface Management
- (IBAction) viewTypeAction:(id)sender
{
	[model setViewType:[sender indexOfSelectedItem]];
}

- (IBAction)morcaUserNameAction:(id)sender {
    [model setMorcaUserName:[sender stringValue]];
}

- (IBAction)morcaPasswordAction:(id)sender {
    [model setMorcaPassword:[sender stringValue]];
}

- (IBAction)morcaDBNameAction:(id)sender {
    [model setMorcaDBName:[sender stringValue]];
}

- (IBAction)morcaPortAction:(id)sender {
    [model setMorcaPort:[sender intValue]];
}

- (IBAction)morcaIPAddressAction:(id)sender {
    [model setMorcaIPAddress:[sender stringValue]];
}

- (IBAction)morcaClearHistoryAction:(id)sender {
    [model clearMorcaConnectionHistory];
}

- (IBAction)morcaFutonAction:(id)sender {    
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%@@%@:%d/_utils/database.html?%@",
        [model morcaUserName], [model morcaPassword], [model morcaIPAddress], [model morcaPort], [model morcaDBName]]]];
}

- (IBAction)morcaTestAction:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%@@%@:%d",
        [model morcaUserName], [model morcaPassword], [model morcaIPAddress], [model morcaPort]]]];
}

- (IBAction)morcaPingAction:(id)sender {
    [model morcaPing];
}

- (IBAction)morcaUpdateNowAction:(id)sender {
    [model morcaUpdateDB];
}

- (IBAction)morcaStartAction:(id)sender {
    [model setMorcaIsUpdating:YES];
    [model morcaCompactDB];
    [model morcaUpdateDB];
}

- (IBAction)morcaStopAction:(id)sender {
    [model setMorcaIsUpdating:NO];
}

- (IBAction)morcaIsVerboseAction:(id)sender {
    [model setMorcaIsVerbose:[sender intValue]];
}

- (IBAction)morcaUpdateRateAction:(id)sender {
    [model setMorcaUpdateTime:[[sender selectedItem] tag]];
}

- (IBAction)morcaUpdateWithinRunAction:(id)sender {
    [model setMorcaIsWithinRun:[sender intValue]];
}

- (IBAction)hvMasterPanicAction:(id)sender
{
    [[[self document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")] makeObjectsPerformSelector:@selector(hvPanicDown)];
/*
    NSArray* xl3s = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")];
    for (id xl3 in xl3s) {
        [model hvPanicDown];
    }
 */
    NSLog(@"Detector wide panic down started\n");
}

- (void) specialUpdate:(NSNotification*)aNote
{
	[super specialUpdate:aNote];
	[detectorView makeAllSegments];
}

- (void) setDetectorTitle
{	
	switch([model displayType]){
		case kDisplayRates:		[detectorTitle setStringValue:@"Detector Rate"];	break;
		case kDisplayThresholds:	[detectorTitle setStringValue:@"Thresholds"];		break;
		case kDisplayTotalCounts:	[detectorTitle setStringValue:@"Total Counts"];		break;
		default: break;
	}
}

#pragma mark ¥¥¥Details Interface Management
- (void) detailsLockChanged:(NSNotification*)aNotification
{
	[super detailsLockChanged:aNotification];
	BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[model experimentDetailsLock]];
	BOOL locked = [gSecurity isLocked:[model experimentDetailsLock]];

	[detailsLockButton setState: locked];
	[initButton setEnabled: !lockedOrRunningMaintenance];
}

#pragma mark ¥¥¥Table Data Source

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
	    [self resizeWindowToSize:couchDBSize];
	    [[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 4){
	    [[self window] setContentView:blankView];
	    [self resizeWindowToSize:hvMasterSize];
	    [[self window] setContentView:tabView];
    }
/*
    else if([tabView indexOfTabViewItem:tabViewItem] == 5){
	    [[self window] setContentView:blankView];
	    [self resizeWindowToSize:slowControlSize];
	    [[self window] setContentView:tabView];
    }
*/	
	int index = [tabView indexOfTabViewItem:tabViewItem];
	[[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"orca.SNOPController.selectedtab"];
}

#pragma mark ¥¥¥ComboBox Data Source
- (NSInteger ) numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
	return  [model morcaConnectionHistoryCount];
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
	return [model morcaConnectionHistoryItem:index];
}


@end
