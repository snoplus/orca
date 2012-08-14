
//
//  ORMJDPumpCartController.m
//  Orca
//
//  Created by Mark Howe on Mon Aug 13, 2012.
//  Copyright ¬© 2012 CENPA, University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------


#pragma mark •••Imported Files
#import "ORMJDPumpCartController.h"
#import "ORMJDPumpCartModel.h"
#import "ORMJDPumpCartView.h"
#import "ORVacuumParts.h"

@implementation ORMJDPumpCartController
- (id) init
{
    self = [super initWithWindowNibName:@"MJDPumpCart"];
    return self;
}

- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[super dealloc];
}

- (void) awakeFromNib
{
	[subComponentsView setGroup:model];
	[testStand0 setDelegate:[model testCryoStat:0]];
	[testStand1 setDelegate:[model testCryoStat:1]];
	[testStand2 setDelegate:[model testCryoStat:2]];
	[testStand3 setDelegate:[model testCryoStat:3]];
	[testStand4 setDelegate:[model testCryoStat:4]];
	[testStand5 setDelegate:[model testCryoStat:5]];
	[testStand6 setDelegate:[model testCryoStat:6]];
	[super awakeFromNib];
}

#pragma mark •••Accessors
- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"MJD Vacuum (Cryostat %lu)",[model uniqueIdNumber]]];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];   
	[notifyCenter addObserver : self
                     selector : @selector(showGridChanged:)
                         name : ORMJDPumpCartModelShowGridChanged
                       object : nil];
		
    [notifyCenter addObserver : self
                     selector : @selector(stateChanged:)
                         name : ORVacuumPartChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORMJCTestCryoVacLock
                        object: nil];
	
	[notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupObjectsAdded
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupObjectsRemoved
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupSelectionChanged
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : OROrcaObjectMoved
                       object : nil];

}

- (void) updateWindow
{
    [super updateWindow];
	[self showGridChanged:nil];
	[self stateChanged:nil];
	[self lockChanged:nil];
}

#pragma mark •••Interface Management

-(void) groupChanged:(NSNotification*)note
{
	if(note == nil || [note object] == model || [[note object] guardian] == model){
		[subComponentsView setNeedsDisplay:YES];
	}
}

- (void) lockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:ORMJCTestCryoVacLock];
    [lockButton setState: locked];
}

- (void) stateChanged:(NSNotification*)aNote
{
	if(!updateScheduled){
		updateScheduled = YES;
		[self performSelector:@selector(delayedRefresh) withObject:nil afterDelay:.5];
	}
}
- (void) delayedRefresh
{
	updateScheduled = NO;
	[vacuumView setNeedsDisplay:YES];
	[valueTableView reloadData];
	[statusTableView reloadData];
	[gvTableView reloadData];
}

- (void) showGridChanged:(NSNotification*)aNote
{
	[setShowGridCB setIntValue:[model showGrid]];
	[vacuumView setNeedsDisplay:YES];
}

- (void) toggleGrid
{
	[model toggleGrid];
}

- (BOOL) showGrid
{
	return [model showGrid];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORMJCTestCryoVacLock to:secure];
    [lockButton setEnabled:secure];
}

#pragma mark •••Actions
- (IBAction) showGridAction:(id)sender
{
	[model setShowGrid:[sender intValue]];
}

- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORMJCTestCryoVacLock to:[sender intValue] forWindow:[self window]];
}


#pragma mark •••Data Source For Tables
- (int) numberOfRowsInTableView:(NSTableView *)aTableView
{
	if(aTableView == valueTableView){
		return [[model valueLabels] count];
	}
	else if(aTableView == statusTableView){
		return [[model valueLabels] count];
	}
	else if(aTableView == gvTableView){
		return [[model gateValves] count];
	}
	else return 0;
}

- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
	if((aTableView == valueTableView) || (aTableView == statusTableView)){
		NSArray* theLabels;
		if(aTableView == valueTableView) theLabels = [model valueLabels];
		else							 theLabels = [model statusLabels];
		if(rowIndex < [theLabels count]){
			ORVacuumDynamicLabel* theLabel = [theLabels objectAtIndex:rowIndex];
			if([[aTableColumn identifier] isEqualToString:@"partTag"]){
				return [NSNumber numberWithInt:rowIndex];
			}
			else if([[aTableColumn identifier] isEqualToString:@"label"]){
				return [theLabel label];
			}

			else  if([[aTableColumn identifier] isEqualToString:@"value"]){
				return [theLabel displayString];
			}
			else return @"--";
		}
		else return @"";
	}
	else if(aTableView == gvTableView ){
		NSArray* theGateValves = [model gateValves];
		if(rowIndex < [theGateValves count]){
			ORVacuumGateValve* gv = [theGateValves objectAtIndex:rowIndex];
			if([[aTableColumn identifier] isEqualToString:@"partTag"]){
				return [NSNumber numberWithInt:rowIndex];
			}
			else if([[aTableColumn identifier] isEqualToString:@"label"]){
				return [gv label];
			}
			else if([[aTableColumn identifier] isEqualToString:@"constraints"]){
				return [NSNumber numberWithInt:[gv constraintCount]];
			}
			else if([[aTableColumn identifier] isEqualToString:@"controlChannel"]){
				if([gv controlObj])return [NSNumber numberWithInt:[gv controlChannel]];
				else return @" ";
			}
			else  if([[aTableColumn identifier] isEqualToString:@"state"]){
				if([gv controlType]      == kManualOnlyShowClosed) return @"Manual-Closed??";
				else if([gv controlType] == kManualOnlyShowChanging) return @"Manual-Open??";
				else {
					int currentValveState = [gv state];
					if([gv controlType] == k1BitReadBack){
						return currentValveState==kGVOpen?@"OPEN":@"CLOSED";
					}
					else {
						return currentValveState==kGVOpen?@"OPEN":(currentValveState==kGVClosed?@"CLOSED":@"CHANGING");
					}
				}
			}
			else return @"--";
		}
		else return @"";
	}
	return @"";
}



@end
