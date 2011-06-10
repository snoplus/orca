/*
 *  ORCV895Model.m
 *  Orca
 *
 *  Created by Mark Howe on Tuesday, June 7, 2011.
 *  Copyright (c) 2011 CENPA, University of North Carolina. All rights reserved.
 *
 */
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sonsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
#import "ORCV895Model.h"

// Address defaults for this unit.
#define k895DefaultBaseAddress 		0xE0000000
#define k895DefaultAddressModifier 	0x39

@implementation ORCV895Model

#pragma mark ***Initialization
- (id) init //designated initializer
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
	
    [self setBaseAddress:k895DefaultBaseAddress];
    [self setAddressModifier:k895DefaultAddressModifier];
	
    [[self undoManager] enableUndoRegistration];
   
    return self;
}

#pragma mark ***Accessors

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"CV895"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORCV895Controller"];
}

- (NSString*) helpURL
{
	return @"VME/V895.html";
}
- (NSString*) identifier
{
    return [NSString stringWithFormat:@"CAEN 895 (Slot %d) ",[self slot]];
}
@end


