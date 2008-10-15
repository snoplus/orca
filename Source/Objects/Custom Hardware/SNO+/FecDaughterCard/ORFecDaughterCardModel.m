//
//  ORFecDaughterCardModel.cp
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
#import "ORFecDaughterCardModel.h"

@implementation ORFecDaughterCardModel

#pragma mark •••Initialization
- (id) init //designated initializer
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [[self undoManager] enableUndoRegistration];
    return self;
}

-(void)dealloc
{
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"FecDaughterCard"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORFecDaughterCardController"];
}

- (Class) guardianClass 
{
	return NSClassFromString(@"ORFec32Model");
}


#pragma mark •••Archival
- (id) initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
 }
 @end


