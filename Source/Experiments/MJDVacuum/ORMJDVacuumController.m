
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

- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[super dealloc];
}

- (void) awakeFromNib
{
    [super awakeFromNib];
}

#pragma mark •••Accessors
- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"MJD Vacuum (Cryostat %d)",[model uniqueIdNumber]]];
}

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
	
    [notifyCenter addObserver : self
                     selector : @selector(stateChanged:)
                         name : ORMJDVacuumModelVetoMaskChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(vetoMaskChanged:)
                         name : ORMJDVacuumModelVetoMaskChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORMJCVacuumLock
                        object: nil];
}

- (void) updateWindow
{
    [super updateWindow];
	[self showGridChanged:nil];
	[self stateChanged:nil];
	[self vetoMaskChanged:nil];
	[self lockChanged:nil];
}

#pragma mark •••Interface Management
- (void) vetoMaskChanged:(NSNotification*)aNote
{
}

- (void) lockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:ORMJCVacuumLock];
    [lockButton setState: locked];
	
	[groupView updateButtons];
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
	[groupView setNeedsDisplay:YES];
	[adcTableView reloadData];
	[gvTableView reloadData];
	[miscTableView reloadData];
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
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORMJCVacuumLock to:secure];
    [lockButton setEnabled:secure];
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
	unsigned long changesVetoed = ([model vetoMask] & (0x1>>gateValveTag)) != 0;
	if(gv){
		NSString* statusString = [NSString stringWithFormat:@"%@ is now %@",[gv label],currentValveState==kGVOpen?@"OPEN":(currentValveState==kGVClosed?@"CLOSED":@"UnKnown")];
		[gvControlValveState setStringValue:statusString];
		int region1		= [gv connectingRegion1];
		int region2		= [gv connectingRegion2];
		NSColor* c1		= [model colorOfRegion:region1];
		NSColor* c2		= [model colorOfRegion:region2];
		
		[gvControlPressureSide1 setStringValue:[model dynamicLabel:region1]];
		[gvControlPressureSide2 setStringValue:[model dynamicLabel:region2]];
		NSString* s = @"";
		if([gv controlObj]){
			[gvHwObjectName setStringValue:[NSString stringWithFormat:@"%@,%d",[gv controlObj],[gv controlChannel]]]; 
		
			
			switch(currentValveState){
				case kGVOpen:
					[gvOpenToText1 setStringValue:[model namesOfRegionsWithColor:c1]];
					[gvOpenToText2 setStringValue:@"Valve is open. Closing it may isolate some regions."];
					if(!changesVetoed){
						s = @"Are you sure you want to CLOSE it and potentially isolate some regions?";
						[gvControlButton setTitle:@"YES - CLOSE it"];
						[gvControlButton setEnabled:YES];
					}
					else {
						s = @"Changes to this valve have been vetoed. Probably by the process controller.";
						[gvControlButton setTitle:@"---"];
						[gvControlButton setEnabled:NO];
					}
			
				break;
					
				case kGVClosed:
					if(!changesVetoed){

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
					}
					else {
						s = @"Changes to this valve have been vetoed. Probably by the process controller.";
						[gvControlButton setTitle:@"---"];
						[gvControlButton setEnabled:NO];
					}
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
		}
		else {
			s = @"Not mapped to HW! Valve can NOT be controlled!";
			[gvHwObjectName setStringValue:@"--"];
			[gvControlButton setTitle:@"---"];
			[gvControlButton setEnabled:NO];
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
}

- (IBAction) changeGVAction:(id)sender
{
    [gvControlPanel orderOut:nil];
    [NSApp endSheet:gvControlPanel];
	int gateValveTag = [gvControlButton tag];
	int currentValveState = [model stateOfGateValve:gateValveTag];
	
	if(currentValveState == kGVOpen)       [model closeGateValve:gateValveTag];
	else if(currentValveState == kGVClosed)[model openGateValve:gateValveTag];
	else NSLog(@"GateValve %d in unknown state. Command ignored.\n",gateValveTag);
}


- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORMJCVacuumLock to:[sender intValue] forWindow:[self window]];
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
	else if(aTableView == miscTableView){
		return [[model dynamicLabels] count];
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
			else if([[aTableColumn identifier] isEqualToString:@"dialogIdentifier"]){
				return [theDynamicLabel dialogIdentifier];
			}
			else  if([[aTableColumn identifier] isEqualToString:@"value"]){
				return [NSString stringWithFormat:@"%.2E",[theDynamicLabel value]];
			}
			else return @"--";
		}
		else return @"";
	}
	if(aTableView == miscTableView ){
		NSArray* theLabels = [model staticLabels];
		if(rowIndex < [theLabels count]){
			ORVacuumStaticLabel* theStaticLabel = [theLabels objectAtIndex:rowIndex];
			if([[aTableColumn identifier] isEqualToString:@"partTag"]){
				return [NSNumber numberWithInt:rowIndex];
			}
			else if([[aTableColumn identifier] isEqualToString:@"label"]){
				return [theStaticLabel label];
			}
			else if([[aTableColumn identifier] isEqualToString:@"dialogIdentifier"]){
				return [theStaticLabel dialogIdentifier];
			}
			else  if([[aTableColumn identifier] isEqualToString:@"value"]){
				return [NSString stringWithFormat:@"%.2E",[theStaticLabel value]];
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
			else if([[aTableColumn identifier] isEqualToString:@"vetoed"]){
				if([gv controlType] == k2BitReadBack || [gv controlType] == k1BitReadBack) return [gv vetoed]?@"Vetoed":@" ";
				else return @" ";
			}
			else if([[aTableColumn identifier] isEqualToString:@"controlObj"]){
				if([gv controlObj]) return [gv controlObj];
				else return @" ";
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

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if(aTableView == adcTableView ){
		NSArray* theLabels = [model dynamicLabels];
		if(rowIndex < [theLabels count]){
			ORVacuumDynamicLabel* theDynamicLabel = [theLabels objectAtIndex:rowIndex];
			theDynamicLabel.dialogIdentifier = anObject;
		}
	}
	else if(aTableView == miscTableView ){
		NSArray* theLabels = [model staticLabels];
		if(rowIndex < [theLabels count]){
			ORVacuumStaticLabel* theStaticLabel = [theLabels objectAtIndex:rowIndex];
			theStaticLabel.dialogIdentifier = anObject;
		}
	}
}


@end
