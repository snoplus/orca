
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

- (void) checkGlobalSecurity
{
	[(ORMJDVacuumView*)groupView checkGlobalSecurity];
}

#pragma mark •••Actions
- (IBAction) showGridAction:(id)sender
{
	[model setShowGrid:[sender intValue]];
}

- (IBAction) openGVControlPanel:(id)sender
{
	[self endEditing];
	
	int gateValveTag	  = [sender tag];
	int currentValveState = [model stateOfGateValve:gateValveTag];
	ORVacuumGateValve* gv = [model gateValve:gateValveTag];
	
	if(gv){
		[gvControlValveState setStringValue:currentValveState==kGVOpen?@"OPEN":(currentValveState==kGVClosed?@"CLOSED":@"UnKnown")];
		int region1		= [gv connectingRegion1];
		int region2		= [gv connectingRegion2];
		NSColor* c1		= [model colorOfRegion:region1];
		NSColor* c2		= [model colorOfRegion:region2];
		
		[gvControlPressureSide1 setStringValue:[model dynamicLabel:region1]];
		[gvControlPressureSide2 setStringValue:[model dynamicLabel:region2]];
		
		
		NSString* s = @"";
		
		switch(currentValveState){
			case kGVOpen:
				[gvOpenToText1 setStringValue:[model namesOfRegionsWithColor:c1]];
				[gvOpenToText2 setStringValue:@"Each side appears connected now so closing the valve may isolate some regions."];
				s = @"Are you sure you want to CLOSE it and potentially isolate some regions?";
				[gvControlButton setTitle:@"YES - CLOSE it"];
				[gvControlButton setEnabled:YES];
			break;
				
			case kGVClosed:
				if([c1 isEqual:c2]){
					[gvOpenToText1 setStringValue:[model namesOfRegionsWithColor:c1]];
					[gvOpenToText2 setStringValue:@"Each Side Appears Connected now so opening the valve may be OK."];
					s = @"Are you sure you want to OPEN it?";
				}
				else {
					[gvOpenToText1 setStringValue:[model namesOfRegionsWithColor:c1]];
					[gvOpenToText2 setStringValue:[model namesOfRegionsWithColor:c2]];
					s = @"Are you sure you want to OPEN it and join isolated regions?";
			}
				[gvControlButton setTitle:@"YES - OPEN it"];
				[gvControlButton setEnabled:YES];
			break;
				
			default:
				s = @"The valve is currently shown in an unknown state.";
				[gvOpenToText1 setStringValue:[model namesOfRegionsWithColor:c1]];
				[gvOpenToText2 setStringValue:[model namesOfRegionsWithColor:c2]];
				[gvControlButton setTitle:@"---"];
				[gvControlButton setEnabled:NO];
			break;
		}
		
		[gvControlButton setTag:gateValveTag];
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
				if([gv controlType]      == kManualOnlyShowClosed) return @"Manual-Closed??";
				else if([gv controlType] == kManualOnlyShowChanging) return @"Manual-Open??";
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
