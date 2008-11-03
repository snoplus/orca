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
                         name : ORFec32ModelCommentsChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(showVoltsChanged:)
                         name : ORFec32ModelShowVoltsChanged
						object: model];

}

- (void) updateWindow
{
	[super updateWindow];
	[self showVoltsChanged:nil];
    [self runStatusChanged:nil];
    [self lockChanged:nil];
    [self slotChanged:nil];
	[self vResChanged:nil];
	[self hvRefChanged:nil];
	[self cmosChanged:nil];
    [groupView setNeedsDisplay:YES];
	[self commentsChanged:nil];
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
	[cardNumberField setIntValue:[model slot]];
}

#pragma mark •••Interface Management

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
	[[self window] setTitle:[NSString stringWithFormat:@"Fec32 (Slot %d)",[model slot]]];
	[cardNumberField setIntValue:[model slot]];
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

- (IBAction) showVoltsAction:(id)sender
{
	[model setShowVolts:[sender intValue]];	
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
