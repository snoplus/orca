
//
//  ORnEDMCoilController.m
//  Orca
//
//  Created by Michael Marino 15 Mar 2012 
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


#pragma mark •••Imported Files
#import "ORnEDMCoilController.h"
#import "ORnEDMCoilModel.h"


@implementation ORnEDMCoilController

- (id) init
{
    self = [super initWithWindowNibName:@"nEDMCoil"];
    return self;
}
- (void) awakeFromNib
{
	[groupView setGroup:model];
	[super awakeFromNib];
}
#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];   
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
	
	
    [notifyCenter addObserver : self
                     selector : @selector(documentLockChanged:)
                         name : ORDocumentLock
                        object: nil];
	
	[notifyCenter addObserver : self
					 selector : @selector(documentLockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];

	[notifyCenter addObserver : self
					 selector : @selector(runRateChanged:)
						 name : ORnEDMCoilPollingFrequencyChanged
					   object : nil];    
    [notifyCenter addObserver : self
					 selector : @selector(runStatusChanged:)
						 name : ORnEDMCoilPollingActivityChanged
					   object : nil];
    
}

- (void) runRateChanged:(NSNotification *)aNote
{
    [runRateField setFloatValue:[model pollingFrequency]];
}

- (void) runStatusChanged:(NSNotification *)aNote
{
    if ([model isRunning]) [startStopButton setTitle:@"Stop Process"];
    else [startStopButton setTitle:@"Start Process"];
}

- (void) viewChanged:(NSNotification*)aNotification
{
    [model performSelector:@selector(setUpImage) withObject:nil afterDelay:0];
}

- (void) updateWindow
{
    [super updateWindow];
    [self documentLockChanged:nil];
	[self viewChanged:nil];
	[self runRateChanged:nil];    
	[self runStatusChanged:nil];    
    [groupView setNeedsDisplay:YES];
}

- (void) documentLockChanged:(NSNotification*)aNotification
{
    if([gSecurity isLocked:ORDocumentLock]) [lockDocField setStringValue:@"Document is locked."];
    else if([gOrcaGlobals runInProgress])   [lockDocField setStringValue:@"Run In Progress"];
    else				    [lockDocField setStringValue:@""];
}

#pragma mark •••Accessors
- (ORGroupView *)groupView
{
    return [self groupView];
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [groupView setGroup:(ORGroup*)model];
	[[self window] setTitle:[NSString stringWithFormat:@"%@",[model identifier]]];

}

-(void) groupChanged:(NSNotification*)note
{
	if(note == nil || [note object] == model || [[note object] guardian] == model){
		[model setUpImage];
		[self updateWindow];
	}
}

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
	return [groupView validateMenuItem:menuItem];
}

#pragma mark •••Interface Management
- (void) slotChanged:(NSNotification*)aNotification
{
	[[self window] setTitle:[NSString stringWithFormat:@"%@",[model identifier]]];
}

- (void) isNowKeyWindow:(NSNotification*)aNotification
{
	[[self window] makeFirstResponder:(NSResponder*)groupView];
}

- (void) runAction:(id)sender
{
    [model toggleRunState];
}

- (void) runRateAction:(id)sender
{
    [model setPollingFrequency:[sender floatValue]];
}

//---------------------------------------------------------------
//these last actions are here only to work around a strange 
//first responder problem that occurs after cut followed by undo
- (IBAction)delete:(id)sender   { [groupView delete:sender]; }
- (IBAction)cut:(id)sender      { [groupView cut:sender]; }
- (IBAction)paste:(id)sender    { [groupView paste:sender]; }
- (IBAction)selectAll:(id)sender{ [groupView selectAll:sender]; }
//-----------------------------------------------------------------

@end
