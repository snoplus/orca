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
-(id)init
{
    self = [super initWithWindowNibName:@"Fec32"];
    
    return self;
}

- (void) awakeFromNib
{
    [groupView setGroup:model];
	[testButton setEnabled:YES];
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
}

#pragma mark •••Interface Management

- (void) updateWindow
{
    [self runStatusChanged:nil];
    [self slotChanged:nil];
    [groupView setNeedsDisplay:YES];
}

- (void) slotChanged:(NSNotification*)aNotification
{
	[[self window] setTitle:[NSString stringWithFormat:@"Fec32 (Slot %d)",[model slot]]];
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


#pragma mark •••Actions




@end
