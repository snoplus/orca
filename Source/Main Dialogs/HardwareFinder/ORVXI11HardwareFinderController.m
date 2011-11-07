//
//  ORVXI11HardwareFinderController.m
//  Orca
//
//  Created by Michael Marino on 6 Nov 2011
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


#import "ORVXI11HardwareFinderController.h"
#import "ORVXI11HardwareFinder.h"
#import "SynthesizeSingleton.h"

@implementation ORVXI11HardwareFinderController

SYNTHESIZE_SINGLETON_FOR_ORCLASS(VXI11HardwareFinderController);

-(id)init
{
    self = [super initWithWindowNibName:@"VXI11HardwareFinder"];
    [self setWindowFrameAutosaveName:@"VXI11HardwareFinder"];
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void) awakeFromNib
{
	
    [self registerNotificationObservers];
    [self updateWindow];
}

#pragma mark •••Accessors

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter addObserver:self
					 selector:@selector(hardwareChanged:)
						 name:ORHardwareFinderAvailableHardwareChanged
					   object:[ORVXI11HardwareFinder sharedVXI11HardwareFinder]];     
}

#pragma mark •••Actions

- (void) refreshHardwareAction:(id)sender
{
    [[ORVXI11HardwareFinder sharedVXI11HardwareFinder] refresh];
}

#pragma mark •••Interface Management
- (void) updateWindow
{
}

- (void) hardwareChanged:(NSNotification *)aNote
{
    [availableHardware reloadData];
}

#pragma mark •••Data Source Methods
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
    NSDictionary* aDict = [[ORVXI11HardwareFinder sharedVXI11HardwareFinder] availableHardware];
    ORVXI11IPDevice* dev = [aDict objectForKey:[[aDict allKeys] objectAtIndex:rowIndex]];
    NSString* ident = [aTableColumn identifier];
    if ([ident isEqualToString:@"IP"]) return [dev ipAddress];
    if ([ident isEqualToString:@"Manufacturer"]) return [dev manufacturer];
    if ([ident isEqualToString:@"Model"]) return [dev model];
    if ([ident isEqualToString:@"Serial Number"]) return [dev serialNumber];
    if ([ident isEqualToString:@"Version"]) return [dev version];         
    return @"";
}

// just returns the number of items we have.
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [[[ORVXI11HardwareFinder sharedVXI11HardwareFinder] availableHardware] count];
}
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row
{
    return YES;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
}

@end
