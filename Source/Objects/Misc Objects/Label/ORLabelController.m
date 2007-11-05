
//
//  ORLabelController.m
//  Orca
//
//  Created by Mark Howe on Sat Nov 19 2005.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORLabelController.h"
#import "ORLabelModel.h"

@implementation ORLabelController

#pragma mark ¥¥¥Initialization
- (id) init
{
    self = [super initWithWindowNibName:@"Label"];
    return self;
}


#pragma mark ¥¥¥Interface Management
- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];   
    
    [notifyCenter addObserver: self
                     selector: @selector(labelLockChanged:)
                         name: ORLabelLock
                       object: model];

    [notifyCenter addObserver: self
                     selector: @selector(textSizeChanged:)
                         name: ORLabelModelTextSizeChanged
                       object: model];

    [notifyCenter addObserver: self
                     selector: @selector(textDidChange:)
                         name: NSTextDidChangeNotification
                       object: labelField];

}

- (void) awakeFromNib
{
	[super awakeFromNib];
	[labelField setString:[model label]];
}

- (void) updateWindow
{
	[super updateWindow];
    [self textSizeChanged:nil];
    [self labelLockChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORLabelLock to:secure];
    [labelLockButton setEnabled:secure];
}

- (void) labelLockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:ORLabelLock];
    [labelLockButton setState: locked];
    [labelField setEditable: !locked];
    [textSizeField setEnabled: !locked];
}

- (void)textDidChange:(NSNotification *)notification
{
	[model setLabelNoNotify:[labelField string]];
}

- (void) textSizeChanged:(NSNotification*)aNote
{
	[textSizeField setIntValue:[model textSize]];
}


#pragma mark ¥¥¥Actions
- (IBAction) textSizeAction:(id)sender
{
	[model setTextSize:[sender intValue]];
}

- (IBAction)labelLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORLabelLock to:[sender intValue] forWindow:[self window]];
}

@end
