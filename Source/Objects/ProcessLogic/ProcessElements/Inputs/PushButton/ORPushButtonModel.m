//
//  ORPushButtonModel.m
//  Orca
//
//  Created by Mark Howe on Sat Nov 18 2005.
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
#import "ORPushButtonModel.h"
#import "ORProcessModel.h"

@implementation ORPushButtonModel

#pragma mark ¥¥¥Initialization

- (void) setUpImage
{
    if([self state]) [self setImage:[NSImage imageNamed:@"PushButtonOn"]];
    else             [self setImage:[NSImage imageNamed:@"PushButtonOff"]];
    [self addOverLay];
}

- (void) makeMainController
{
    [self linkToController:@"ORPushButtonController"];
}

- (NSString*) elementName
{
	return @"Push Button";
}

- (void) addOverLay
{    
}

- (void) doCmdClick:(id)sender
{
	[self setState:![self state]];
}

//--------------------------------
//runs in the process logic thread
- (int) eval
{
	id obj = [self objectConnectedTo:ORInputElementInConnection];
	if(!alreadyEvaluated){
		int theState = [self state];
		if(!obj)		  [self setEvaluatedState:theState];
		else {
			if(!theState) [self setEvaluatedState: theState];
			else		  [self setEvaluatedState: [obj eval]];
		}
	}
	return evaluatedState;
}
//--------------------------------

@end

