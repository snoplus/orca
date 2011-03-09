//
//  ORXLGPSModel.m
//  Orca
//
//  Created by Jarek Kaspar on November 2, 2010.
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
#import "ORXLGPSModel.h"

#pragma mark •••Definitions


@interface ORXLGPSModel (private)
- (void) doBasicOp;
@end

@implementation ORXLGPSModel

#pragma mark •••Initialization

- (id) init
{
	self = [super init];
	return self;
}

- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"XLGPSIcon"]];
}

-(void)dealloc
{
//	[gpsLink release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void) wakeUp 
{
	[super wakeUp];
//	[gpsLink wakeUp];
}

- (void) sleep 
{
	[super sleep];
/*
	if (gpsLink) {
		[gpsLink release];
		xl3Link = nil;
	}
*/
}	

- (void) makeMainController
{
	[self linkToController:@"ORXLGPSController"];
}

#pragma mark •••Accessors
#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];
	[[self undoManager] disableUndoRegistration];
	[[self undoManager] enableUndoRegistration];
	return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
	[super encodeWithCoder:encoder];
}

#pragma mark •••Hardware Access
#pragma mark •••Basic Ops
@end


@implementation ORXLGPSModel (private)
- (void) doBasicOp
{
}

@end

