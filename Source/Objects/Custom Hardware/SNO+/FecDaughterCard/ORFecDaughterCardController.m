//
//  ORFecDaughterCardController.m
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
#import "ORFecDaughterCardController.h"
#import "ORFecDaughterCardModel.h"
#import "ORSNOCard.h"

#pragma mark •••Definitions

@implementation ORFecDaughterCardController

#pragma mark •••Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"FecDaughterCard"];
    
    return self;
}



#pragma mark •••Notifications
-(void)registerNotificationObservers
{
    
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	[super registerNotificationObservers];
    
    [notifyCenter addObserver : self
					 selector : @selector(slotChanged:)
						 name : ORSNOCardSlotChanged
					   object : model];
	
}

#pragma mark •••Interface Management
-(void)updateWindow
{
	[super updateWindow];
    [self slotChanged:nil];
}

- (void) slotChanged:(NSNotification*)aNotification
{
	[[self window] setTitle:[NSString stringWithFormat:@"FecDaughterCard (%@)",[model identifier]]];
}




#pragma mark •••Actions




@end
