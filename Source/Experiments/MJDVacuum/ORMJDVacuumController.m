
//
//  ORMJDVacuumController.m
//  Orca
//
//  Created by Mark Howe on Tues Mar 27, 2012.
//  Copyright © 2012 CENPA, University of North Carolina. All rights reserved.
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
#import "ORMJDVacuumController.h"
#import "ORMJDVacuumModel.h"
#import "ORMJDVacuumView.h"
#import "ORVacuumParts.h"

@implementation ORMJDVacuumController
- (id) init
{
    self = [super initWithWindowNibName:@"MJDVacuum"];
    return self;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
}

#pragma mark •••Accessors


#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];   
	[notifyCenter addObserver : self
                     selector : @selector(showGridChanged:)
                         name : ORMJDVacuumModelShowGridChanged
                       object : nil];
		
    [notifyCenter addObserver : self
                     selector : @selector(stateChanged:)
                         name : ORVacuumPartChanged
						object: model];
	
}
- (void) updateWindow
{
    [super updateWindow];
	[self showGridChanged:nil];
	[self stateChanged:nil];
}

#pragma mark •••Interface Management
- (void) stateChanged:(NSNotification*)aNote
{
	[groupView setNeedsDisplay:YES];
	[adcTableView reloadData];
	[gvTableView reloadData];
}

- (void) showGridChanged:(NSNotification*)aNote
{
	[setShowGridCB setIntValue:[model showGrid]];
	[groupView setNeedsDisplay:YES];
}

- (void) toggleGrid
{
	[model toggleGrid];
}

- (BOOL) showGrid
{
	return [model showGrid];
}

- (int) stateOfRegion:(int)aTag
{
	return [model stateOfRegion:aTag];
}

- (int) stateOfGateValve:(int)aTag
{
	return [model stateOfGateValve:aTag];
}

#pragma mark •••Actions
- (IBAction) showGridAction:(id)sender
{
	[model setShowGrid:[sender intValue]];
}

- (IBAction) openGVControlPanel:(id)sender
{
	[self endEditing];
	[gvControlButton setTag:[sender tag]];
	int gateValveTag = [sender tag];
	int currentValveState = [model stateOfGateValve:gateValveTag];
	ORVacuumGateValve* gv = [model gateValve:gateValveTag];
	if(gv){
		int s1 = [model stateOfRegion:[gv connectingRegion1]];
		int s2 = [model stateOfRegion:[gv connectingRegion2]];
		[gvControlValveState setStringValue:currentValveState==kGVOpen?@"OPEN":(currentValveState==kGVClosed?@"CLOSED":@"CHANGING")];
		[gvControlPressureSide1 setStringValue:s1?@"VACUUM":@"UP TO AIR"];
		[gvControlPressureSide2 setStringValue:s2?@"VACUUM":@"UP TO AIR"];
		NSString* s;
		switch(currentValveState){
			case kGVOpen:
				s = @"The valve is currently shown as open.\n\nAre you sure you want to CLOSE it?";
				[gvControlButton setTitle:@"YES - CLOSE it"];
				[gvControlButton setEnabled:YES];
				break;
			case kGVClosed:
				if(s1 == s2){
					s = @"The valve is currently shown as Closed.\n\nAre you sure you want to OPEN it?";
					[gvControlButton setTitle:@"YES - OPEN it"];
					[gvControlButton setEnabled:YES];
				}
				else {
					s = @"The valve is currently shown as Closed with	DIFFERENT PRESSURES on each side.\nAre you sure you want to OPEN it?";
					[gvControlButton setTitle:@"YES - OPEN it anyway"];
					[gvControlButton setEnabled:YES];
				}
				break;
			case kGVChanging:
				s = @"The valve is currently shown as Changing State.\n\n";
				[gvControlButton setTitle:@"---"];
				[gvControlButton setEnabled:NO];
				break;
		}
		[gvControlField setStringValue:s];
		[NSApp beginSheet:gvControlPanel modalForWindow:[self window]
			modalDelegate:self didEndSelector:NULL contextInfo:nil];
	}
}

- (IBAction) closeGVChangePanel:(id)sender
{
    [gvControlPanel orderOut:nil];
    [NSApp endSheet:gvControlPanel];
	NSLog(@"got cancel\n");
}

- (IBAction) changeGVAction:(id)sender
{
    [gvControlPanel orderOut:nil];
    [NSApp endSheet:gvControlPanel];
	NSLog(@"got changeit for %d\n",[gvControlButton tag]);
}


#pragma mark •••Data Source For Tables
- (int) numberOfRowsInTableView:(NSTableView *)aTableView
{
	if(aTableView == adcTableView){
		return [[model dynamicLabels] count];
	}
	else if(aTableView == gvTableView){
		return [[model gateValves] count];
	}
	else return 0;
}
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
	if(aTableView == adcTableView ){
		NSArray* theLabels = [model dynamicLabels];
		if(rowIndex < [theLabels count]){
			ORVacuumDynamicLabel* theDynamicLabel = [theLabels objectAtIndex:rowIndex];
			if([[aTableColumn identifier] isEqualToString:@"partTag"]){
				return [NSNumber numberWithInt:rowIndex];
			}
			else if([[aTableColumn identifier] isEqualToString:@"label"]){
				return [theDynamicLabel label];
			}
			else  if([[aTableColumn identifier] isEqualToString:@"value"]){
				return [NSString stringWithFormat:@"%.2E",[theDynamicLabel value]];
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
			else  if([[aTableColumn identifier] isEqualToString:@"state"]){
				if([gv controlType] == kManualOnly) return @"Manual Valve";
				else {
					int currentValveState = [gv state];
					if([gv controlType] == kControlOnly){
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
