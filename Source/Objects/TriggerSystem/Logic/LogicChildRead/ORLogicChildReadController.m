//
//  ORLogicChildReadController.m
//  Orca
//
//  Created by Mark Howe on 10/6/10.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Physics and 
//Astrophysics Department sponsored in part by the United States 
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
#import "ORLogicChildReadController.h"
#import "ORLogicChildReadModel.h"


@implementation ORLogicChildReadController

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"LogicChildRead"];
	return self;
}


#pragma mark ¥¥¥Accessors

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];

    [super registerNotificationObservers];
    [notifyCenter addObserver : self
                        selector : @selector(logicChildReadChanged:)
                        name : ORLogicChildReadChanged
                        object : model];
    
}

#pragma mark ¥¥¥Actions
-(IBAction) logicChildReadAction:(id)sender
{
	[model setChildIndex:[sender intValue]];
}

#pragma mark ¥¥¥Interface Management
- (void) updateWindow
{
    [self logicChildReadChanged:nil];
}

- (void) logicChildReadChanged:(NSNotification*)aNotification
{
	[logicChildReadStepper setIntValue: [model childIndex]];
	[logicChildReadTextField setIntValue: [model childIndex]];
	[model setUpImage];
}



@end
