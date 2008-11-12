//
//  ORFec32Controller.m
//  Orca
//
//  Created by Mark Howe on Wed Oct 15,2008.
//  Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
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


#pragma mark •••Imported Files
#import "ORFec32Controller.h"
#import "ORFec32Model.h"
#import "ORFec32View.h"
#import "ORFecPmtsView.h"
#import "ORPmtImage.h"
#import "ORSwitchImage.h"
#import "ORFecDaughterCardModel.h";

@implementation ORFec32Controller

#pragma mark •••Initialization
- (id) init
{
    self = [super initWithWindowNibName:@"Fec32"];
    return self;
}

- (void) dealloc
{
	[cmosFormatter release];
	int i;
	int j;
	for(i=0;i<4;i++){
		for(j=0;j<2;j++){
			[onlineStateImage[i][j] release];
		}
	}
	[super dealloc];
}

- (void) awakeFromNib
{
    [groupView setGroup:model];
	cmosFormatter = [[NSNumberFormatter alloc] init];
	int i;
	for(i=0;i<6;i++){
		[[cmosMatrix cellWithTag:i] setFormatter:cmosFormatter];
	}
	//cache these into arrays for easy access later
	onlineSwitches[0] = onlineSwitches0;
	onlineSwitches[1] = onlineSwitches1;
	onlineSwitches[2] = onlineSwitches2;
	onlineSwitches[3] = onlineSwitches3;
	pmtImages[0] = pmtImages0;
	pmtImages[1] = pmtImages1;
	pmtImages[2] = pmtImages2;
	pmtImages[3] = pmtImages3;

	//set up the switch images and the pmt images
	for(i=0;i<8;i++){
		[[pmtImages0 cellAtRow:0 column:i] setImage:[ORPmtImage pmtWithColor:[NSColor redColor] angle:180]];
		[[onlineSwitches0 cellAtRow:0 column:i] setTag:7-i];

		[[pmtImages1 cellAtRow:i column:0] setImage:[ORPmtImage pmtWithColor:[NSColor redColor] angle:90]];
		[[onlineSwitches1 cellAtRow:i column:0] setTag:15-i];

		[[pmtImages2 cellAtRow:i column:0] setImage:[ORPmtImage pmtWithColor:[NSColor redColor] angle:90]];
		[[onlineSwitches2 cellAtRow:i column:0] setTag:23-i];

		[[pmtImages3 cellAtRow:0 column:i] setImage:[ORPmtImage pmtWithColor:[NSColor redColor] angle:0]];
		[[onlineSwitches3 cellAtRow:0 column:i] setTag:24+i];
	}
	
	//cache some switch images
	onlineStateImage[0][1]	= [[ORSwitchImage closedSwitchWithAngle:90] retain];
	onlineStateImage[0][0]	= [[ORSwitchImage openSwitchWithAngle:90] retain];
	onlineStateImage[1][1]	= [[ORSwitchImage closedSwitchWithAngle:0] retain];
	onlineStateImage[1][0]	= [[ORSwitchImage openSwitchWithAngle:0] retain];
	onlineStateImage[2][1]	= [[ORSwitchImage closedSwitchWithAngle:0] retain];
	onlineStateImage[2][0]	= [[ORSwitchImage openSwitchWithAngle:0] retain];
	onlineStateImage[3][1]	= [[ORSwitchImage closedSwitchWithAngle:-90] retain];
	onlineStateImage[3][0]	= [[ORSwitchImage openSwitchWithAngle:-90] retain];
	
	[super awakeFromNib];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupObjectsAdded
                       object : model];
    
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
    
    [notifyCenter addObserver : self
                     selector : @selector(runStatusChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(updateWindow)
                         name : ORSNOCardSlotChanged
                       object : nil];

   [notifyCenter addObserver : self
                     selector : @selector(hvRefChanged:)
                         name : ORFecHVRefChanged
                       object : model];

   [notifyCenter addObserver : self
                     selector : @selector(cmosChanged:)
                         name : ORFecCmosChanged
                       object : model];

   [notifyCenter addObserver : self
                     selector : @selector(vResChanged:)
                         name : ORFecVResChanged
                       object : model];
					   
	[notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORFecLock
						object: nil];
						
    [notifyCenter addObserver : self
                     selector : @selector(commentsChanged:)
                         name : ORFecCommentsChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(showVoltsChanged:)
                         name : ORFecShowVoltsChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(onlineMaskChanged:)
                         name : ORFecOnlineMaskChanged
						object: model];

}

- (void) updateWindow
{
	[super updateWindow];
	[self onlineMaskChanged:nil];
	[self showVoltsChanged:nil];
    [self runStatusChanged:nil];
    [self lockChanged:nil];
    [self slotChanged:nil];
	[self vResChanged:nil];
	[self hvRefChanged:nil];
	[self cmosChanged:nil];
    [groupView setNeedsDisplay:YES];
	[self commentsChanged:nil];
	[pmtView setNeedsDisplay:YES];
}

#pragma mark •••Accessors
- (ORFec32View *)groupView
{
    return [self groupView];
}

- (void) setModel:(OrcaObject*)aModel
{
    [super setModel:aModel];
    [groupView setGroup:(ORGroup*)model];
	[fecNumberField setIntValue:[model stationNumber]];
	[crateNumberField setIntValue:[[model guardian] crateNumber]];
	[pmtView setNeedsDisplay:YES];
 	[self updateButtons];
}

#pragma mark •••Interface Management
- (void) enablePmtGroup:(short)enabled groupNumber:(short)group
{
	[onlineSwitches[group] setEnabled:enabled];
 	[self updateButtons];
}

- (void) onlineMaskChanged:(NSNotification*)aNote
{
	int i;
	for(i=0;i<32;i++){
		int pmtGroup = i/8;
		int state = [model pmtOnline:i];
		[[onlineSwitches[pmtGroup] cellWithTag:i] setImage:onlineStateImage[pmtGroup][state]];
	}
}

- (void) showVoltsChanged:(NSNotification*)aNote
{
	[showVoltsCB setIntValue: [model showVolts]];
	if([model showVolts]) [cmosFormatter setFormat:@"#0.00;0;-#0.00"];
	else [cmosFormatter setFormat:@"#0;0;-#0"];
	[self cmosChanged:aNote];
}

- (void) commentsChanged:(NSNotification*)aNote
{
	[commentsTextField setStringValue: [model comments]];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORFecLock to:secure];
    [lockButton setEnabled:secure];
 	[self updateButtons];
}

- (void) updateButtons
{
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORFecLock];
	[vResField		setEnabled: !lockedOrRunningMaintenance];
	[hvRefField		setEnabled: !lockedOrRunningMaintenance];
	[cmosMatrix		setEnabled: !lockedOrRunningMaintenance];
	int i;
	for(i=0;i<4;i++){
		[onlineSwitches[i] setEnabled:[model dcPresent:i] && !lockedOrRunningMaintenance];
		[pmtImages[i] setEnabled:[model dcPresent:i]];
	}
}

- (void) lockChanged:(NSNotification*)aNotification
{
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL locked = [gSecurity isLocked:ORFecLock];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORFecLock];
    [lockButton setState: locked];	
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
		if(runInProgress && ![gSecurity isLocked:ORFecLock])s = @"Not in Maintenance Run.";
    }
    [lockDocField setStringValue:s];
}

- (void) slotChanged:(NSNotification*)aNotification
{
	[[self window] setTitle:[NSString stringWithFormat:@"Fec32 (%d,%d)",[[model guardian] crateNumber],[model stationNumber]]];
	[fecNumberField setIntValue:[model stationNumber]];
	[crateNumberField setIntValue:[[model guardian] crateNumber]];
	[pmtView setNeedsDisplay:YES];
}

- (void) runStatusChanged:(NSNotification*)aNotification
{
   // int status = [[[aNotification userInfo] objectForKey:ORRunStatusValue] intValue];
}

-(void) groupChanged:(NSNotification*)note
{
	[self updateWindow];
	[pmtView setNeedsDisplay:YES];
}

- (void) vResChanged:(NSNotification*)aNote
{
	[vResField setIntValue:[model vRes]];
}

- (void) hvRefChanged:(NSNotification*)aNote
{
	[hvRefField setIntValue:[model hVRef]];
}

- (void) cmosChanged:(NSNotification*)aNote
{
	int index;
	for(index=0;index<6;index++){
		if([model showVolts]){
			[[cmosMatrix cellWithTag:index] setFloatValue:[model cmosVoltage:index]];
		}
		else {
			[[cmosMatrix cellWithTag:index] setIntValue:[model cmos:index]];
		}
	}
}

#pragma mark •••Actions
- (IBAction) onlineMaskAction:(id)sender
{
	int tag = [[sender selectedCell] tag];
	unsigned long mask = [model onlineMask];
	mask ^= (1L<<tag);
	[model setOnlineMask:mask];
}

- (IBAction) showVoltsAction:(id)sender
{
	[model setShowVolts:[sender intValue]];	
}

- (IBAction) probeAction:(id)sender
{
	NS_DURING
		NSLog(@"%@\n",[model probeFEC32]);
	NS_HANDLER
        NSLog(@"Probe of Fec32 FAILED.\n");
        NSRunAlertPanel([localException name], @"%@\n\nFailed Fec32 Probe.", @"OK", nil, nil,
                        localException);
	
	NS_ENDHANDLER
}

- (IBAction) commentsTextFieldAction:(id)sender
{
	[model setComments:[sender stringValue]];	
}

- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORFecLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) vResAction:(id)sender
{
	[model setVRes:[sender intValue]];
}

- (IBAction) hvRefAction:(id)sender
{
	[model setHVRef:[sender intValue]];
}

- (IBAction) cmosAction:(id)sender
{
	int i = [[cmosMatrix selectedCell] tag];
	if([model showVolts]){
		[model setCmosVoltage:i withValue:[sender floatValue]];
	}
	else {
		[model setCmos:i withValue:[sender intValue]];
	}
}

- (IBAction) incCardAction:(id)sender
{
	[self incModelSortedBy:@selector(globalCardNumberCompare:)];
}

- (IBAction) decCardAction:(id)sender
{
	[self decModelSortedBy:@selector(globalCardNumberCompare:)];
}


@end
