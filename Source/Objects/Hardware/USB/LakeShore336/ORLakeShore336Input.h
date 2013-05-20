//
//  ORLakeShore336Input.h
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
typedef enum  {
    kDisabled       = 0,
    kPlatinumRTD    = 2,
    kNTCRTD         = 3,
} ls336SensorTypeEnum;



@interface ORLakeShore336Input : NSObject
{
    int     channel;
    float   temperature;
    ls336SensorTypeEnum sensorType;
    BOOL    autoRange;
    int     range;
    BOOL    compensation;
    int     units;
}

- (NSUndoManager*) undoManager;

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

@property (assign,nonatomic) int                    channel;
@property (assign,nonatomic) float                  temperature;
@property (assign,nonatomic) ls336SensorTypeEnum    sensorType;
@property (assign,nonatomic) BOOL                   autoRange;
@property (assign,nonatomic) int                    range;
@property (assign,nonatomic) BOOL                   compensation;
@property (assign,nonatomic) int                    units;

@end

extern NSString* ORLakeShore336InputTemperatureChanged;
extern NSString* ORLakeShore336InputSensorTypeChanged;
extern NSString* ORLakeShore336InputAutoRangeChanged;
extern NSString* ORLakeShore336InputRangeChanged;
extern NSString* ORLakeShore336InputCompensationChanged;
extern NSString* ORLakeShore336InputUnitsChanged;
