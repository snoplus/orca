//
//  ORCB37Model.m
//  Orca
//
//  Created by Mark Howe on Fri Nov 11,2011.
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Physics and Department sponsored in part by the United States 
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
#import "ORCB37Model.h"

NSString* ORCB37Lock = @"ORCB37Lock";
NSString* ORCB37SlotChangedNotification = @"ORCB37SlotChangedNotification";

@implementation ORCB37Model

- (void) makeMainController
{
    [self linkToController:@"ORCB37Controller"];
}

-(void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"CB37"]];
}

- (NSString*) title 
{
	return [NSString stringWithFormat:@"CB37"];
}
- (NSString*) cardSlotChangedNotification
{
    return ORCB37SlotChangedNotification;
}

- (short) numberSlotsUsed { return 1; }
- (Class) guardianClass	  { return NSClassFromString(@"ORLabJackUE9Model"); }
@end



