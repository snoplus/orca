//
//  BamDetectorController.m
//  Orca
//
//  Created by Mark Howe on Wed Dec 8 2010
//  Copyright (c) 2010 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina  sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------


#pragma mark ¥¥¥Imported Files
#import "BamDetectorController.h"
#import "BamDetectorModel.h"
#import "ORSegmentGroup.h"

@implementation BamDetectorController

#pragma mark ¥¥¥Initialization

-(id)init
{
    self = [super initWithWindowNibName:@"BamDetector"];
    return self;
}


#pragma mark ¥¥¥Subclass responsibility
- (void) loadSegmentGroups
{
	if(!segmentGroups)segmentGroups = [[NSMutableArray array] retain];
	ORSegmentGroup* aGroup = [model segmentGroup:0];
	if(![segmentGroups containsObject:aGroup]){
		[segmentGroups addObject:aGroup];
	}
}

- (NSString*) defaultPrimaryMapFilePath
{
	return @"~/BamDetector";
}

@end