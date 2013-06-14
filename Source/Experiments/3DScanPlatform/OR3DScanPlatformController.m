
//
//  OR3DScanPlatformController.m
//  Orca
//
//  Created by Mark Howe on Tues Mar 27, 2012.
//  Copyright ¬© 2012 CENPA, University of North Carolina. All rights reserved.
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


#pragma mark •••Imported Files
#import "OR3DScanPlatformController.h"
#import "OR3DScanPlatformModel.h"
#import "OR3DScanPlatformView.h"
#import "ORVXMModel.h"
#import "ORVXMMotor.h"
#include "math.h"

@implementation OR3DScanPlatformController
- (id) init
{
    self = [super initWithWindowNibName:@"3DScanPlatform"];
    
    return self;
}

- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[super dealloc];
}

- (void) awakeFromNib
{
    conversion = 1;
    MOTORNUM = 1;
    currentAngle = motorAngle = fmodf([[self findModelMotor] motorPosition],360);
    rotation = 0;
    
    inc = true;
    dec = false;
    
    [currentAngleText setFloatValue:currentAngle];
	
    [subComponentsView setGroup:model];
	[super awakeFromNib];
}

- (double) getRotation
{
    return rotation;
}

- (double) getTrans
{
    return trans;
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];   

	[notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : OR3DScanPlatformLock
                        object: nil];
	
	[notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupObjectsAdded
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupObjectsRemoved
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupSelectionChanged
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : OROrcaObjectMoved
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(motorTargetChanged:)
                         name : ORVXMMotorTargetChanged
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(motorPositionChanged:)
                         name : ORVXMMotorPositionChanged
                       object : nil];
}

- (void) updateWindow
{
    [super updateWindow];
	[self lockChanged:nil];
}

#pragma mark •••Interface Management

-(void) groupChanged:(NSNotification*)note
{
	if(note == nil || [note object] == model || [[note object] guardian] == model){
		[subComponentsView setNeedsDisplay:YES];
	}
}

- (void) lockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:OR3DScanPlatformLock];
    [lockButton setState: locked];
}

- (void) motorTargetChanged:(NSNotification*)aNotification
{
    if([aNotification object] == [model findMotorModel])
    {
        if([[aNotification userInfo] objectForKey:@"VMXMotor"] == [[model findMotorModel] motor:MOTORNUM])
        {
            int angle = (ceil([[self findModelMotor] targetPosition] / conversion));
            [targetAngleText setIntValue:angle];
        }
    }
}

- (void) motorPositionChanged:(NSNotification*)aNotification
{
    //NSLog(@"motorAngle=%.3f",motorAngle);
    motorAngle = fmodf([[self findModelMotor] motorPosition],360);
    //NSLog(@"motorAngle=%.3f",motorAngle);
    
    if(![[model findMotorModel] isMoving])
    {
        [goButton setEnabled:YES];
        [homePlusButton setEnabled:YES];
        [homeMinusButton setEnabled:YES];
    }
    
    [self performSelector:@selector(updateRotation) withObject:nil afterDelay:.1];

    /*if(currentAngle > targetAngle + .5 || currentAngle < targetAngle - .5)
    {
        rotation = targetAngle;
        currentAngle = targetAngle;
        [currentAngleText setFloatValue:currentAngle];
        [view3D setNeedsDisplay:YES];
    }*/
}

- (void) updateRotation
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    if(currentAngle < motorAngle)
    {
        rotation += .5;
        currentAngle += .5;
    }
    else
    {
        rotation -= .5;
        currentAngle -= .5;
    }
    
    if(inc)
        trans += .01;
    if(dec)
        trans -= .01;
    if(inc && trans>.9)
    {
        inc = false;
        dec = true;
    }
    if(dec && trans<.1)
    {
        inc = true;
        dec = false;
    }
    
    [currentAngleText setFloatValue:currentAngle];
    [view3D setNeedsDisplay:YES];
    
    if(currentAngle > motorAngle + .5 || currentAngle < motorAngle - .5)
        [self performSelector:@selector(updateRotation) withObject:nil afterDelay:.02];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:OR3DScanPlatformLock to:secure];
    [lockButton setEnabled:secure];
}

#pragma mark •••Actions
- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:OR3DScanPlatformLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) angleAction:(id) sender
{
    int steps = floor(conversion * [sender floatValue]);
    [[self findModelMotor] setTargetPosition:steps];
}

- (IBAction) goAction:(id) sender
{
    [[model findMotorModel] move:MOTORNUM dx:[[self findModelMotor] targetPosition]];
    if([[model findMotorModel] isMoving])
    {
        [goButton setEnabled:NO];
        [homePlusButton setEnabled:NO];
        [homeMinusButton setEnabled:NO];
    }
}

- (IBAction) homePlusAction:(id) sender
{
    [[model findMotorModel] goHome:MOTORNUM plusDirection:YES];
    if([[model findMotorModel] isMoving])
    {
        [goButton setEnabled:NO];
        [homePlusButton setEnabled:NO];
        [homeMinusButton setEnabled:NO];
    }
}

- (IBAction) homeMinusAction:(id) sender
{
    [[model findMotorModel] goHome:MOTORNUM plusDirection:NO];
    if([[model findMotorModel] isMoving])
    {
        [goButton setEnabled:NO];
        [homePlusButton setEnabled:NO];
        [homeMinusButton setEnabled:NO];
    }
}

- (ORVXMMotor*) findModelMotor
{
    return [[model findMotorModel] motor:MOTORNUM];
}
@end
