//
//  ORAdcController.m
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
#import "ORAdcController.h"
#import "ORAdcModel.h"


@implementation ORAdcController

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"Adc"];
    return self;
}

- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [notifyCenter addObserver : self
                     selector : @selector(minChangeChanged:)
                         name : ORAdcModelMinChangeChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(displayFormatChanged:)
                         name : ORAdcModelDisplayFormatChanged
						object: model];

}

- (void) updateWindow
{
	[super updateWindow];
    [self minChangeChanged:nil];
	[self displayFormatChanged:nil];
}

- (void) setButtonStates
{
	[super setButtonStates];
    BOOL locked = [gSecurity isLocked:ORHWAccessLock];
	[displayFormatField setEnabled: !locked ];
}


- (void) displayFormatChanged:(NSNotification*)aNote
{
	[displayFormatField setStringValue: [model displayFormat]];
}

- (void) minChangeChanged:(NSNotification*)aNote
{
	[minChangeField setFloatValue:[model minChange]];
}

- (void) displayFormatAction:(id)sender
{
	[model setDisplayFormat:[sender stringValue]];	
}

- (IBAction) minChangeAction:(id)sender
{
	[model setMinChange:[sender floatValue]];
}


@end
