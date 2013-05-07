//
//  ORLakeShore336Heater.h
//  Orca
//
//  Created by Mark Howe on Mon, May 6, 2013.
//  Copyright (c) 2013 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------
@interface ORLakeShore336Heater : NSObject
{
    int     resistance;
    int     maxCurrent;
    int     maxUserCurrent;
    int     currentOrPower;
}

- (NSUndoManager*) undoManager;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@property (assign,nonatomic) int    resistance;
@property (assign,nonatomic) int    maxCurrent;
@property (assign,nonatomic) int    maxUserCurrent;
@property (assign,nonatomic) int    currentOrPower;

@end

extern NSString* ORLakeShore336HeaterResistanceChanged;
extern NSString* ORLakeShore336HeaterMaxCurrentChanged;
extern NSString* ORLakeShore336HeaterMaxUserCurrentChanged;
extern NSString* ORLakeShore336HeaterCompensationChanged;
extern NSString* ORLakeShore336HeaterCurrentOrPowerChanged;
