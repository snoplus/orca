//
//  PrespectrometerModel.m
//  Orca
//
//  Created by Mark Howe on Tue Jun 28 2005.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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


#pragma mark ¥¥¥Imported Files
#import "PrespectrometerModel.h"
#import "ORSegmentGroup.h"

@implementation PrespectrometerModel

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"prespectrometer"]];
}

- (void) makeMainController
{
    [self linkToController:@"PrespectrometerController"];
}

#pragma mark ¥¥¥Segment Group Methods
- (void) makeSegmentGroups
{
    ORSegmentGroup* group = [[ORSegmentGroup alloc] initWithName:@"Prespectrometer" numSegments:64];
	[self addGroup:group];
	[group release];
}

- (int)  maxNumSegments
{
	return 64;
}

#pragma mark ¥¥¥Specific Dialog Lock Methods
- (NSString*) experimentMapLock
{
	return @"PrespectrometerMapLock";
}

- (NSString*) experimentDetectorLock
{
	return @"PrespectrometerDetectorLock";
}

- (NSString*) experimentDetailsLock	
{
	return @"PrespectrometerDetailsLock";
}

@end