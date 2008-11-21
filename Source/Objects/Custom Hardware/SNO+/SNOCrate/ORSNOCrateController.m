
//
//  ORSNOCrateController.m
//  Orca
//
//  Created by Mark Howe on Tue, Apr 30, 2008.
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
#import "ORSNOCrateController.h"
#import "ORSNOCrateModel.h"
#import "ORSNOCard.h"


@implementation ORSNOCrateController

- (id) init
{
    self = [super initWithWindowNibName:@"SNOCrate"];
    return self;
}

- (void) setCrateTitle
{
	[[self window] setTitle:[NSString stringWithFormat:@"SNO crate %d",[model uniqueIdNumber]]];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
	[super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];   

    [notifyCenter addObserver : self
                     selector : @selector(powerFailed:)
                         name : @"VmePowerFailedNotification"
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(powerRestored:)
                         name : @"VmePowerRestoredNotification"
                       object : nil];

    [notifyCenter addObserver : self
					 selector : @selector(slotChanged:)
						 name : ORSNOCardSlotChanged
					   object : model];
}


- (void) updateWindow
{
    [super updateWindow];
	[self slotChanged:nil];
}

#pragma mark •••Interface Management
- (void) slotChanged:(NSNotification*)aNotification
{
	[[self window] setTitle:[NSString stringWithFormat:@"%@",[model identifier]]];
	[memBaseAddressField setIntValue:[model memoryBaseAddress]];
	[regBaseAddressField setIntValue:[model registerBaseAddress]];
	[crateNumberField setIntValue:[model crateNumber]];
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"%@",[model identifier]]];
	[memBaseAddressField setIntValue:[model memoryBaseAddress]];
	[regBaseAddressField setIntValue:[model registerBaseAddress]];
	[crateNumberField setIntValue:[model crateNumber]];
}

#pragma mark •••Actions
- (IBAction) incCrateAction:(id)sender
{
	[self incModelSortedBy:@selector(crateNumberCompare:)];
}

- (IBAction) decCrateAction:(id)sender
{
	[self decModelSortedBy:@selector(crateNumberCompare:)];
}

- (IBAction) scan:(id)sender
{
	[model scan];
}


@end
