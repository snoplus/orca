
//
//  ORManualPlotController.m
//  Orca
//
//  Created by Mark Howe on Sat Nov 19 2005.
//  Copyright Â© 2002 CENPA, University of Washington. All rights reserved.
//

#pragma mark ¥¥¥Imported Files
#import "ORManualPlotController.h"
#import "ORManualPlotModel.h"

@implementation ORManualPlotController

#pragma mark ¥¥¥Initialization
- (id) init
{
    self = [super initWithWindowNibName:@"ManualPlot"];
    return self;
}


#pragma mark ¥¥¥Interface Management
- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];   
    
    [notifyCenter addObserver: self
                     selector: @selector(manualPlotLockChanged:)
                         name: ORManualPlotLock
                       object: model];
}

- (void) awakeFromNib
{
	[super awakeFromNib];
}

- (void) updateWindow
{
	[super updateWindow];
    [self manualPlotLockChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORManualPlotLock to:secure];
    [manualPlotLockButton setEnabled:secure];
}

- (void) manualPlotLockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:ORManualPlotLock];
    [manualPlotLockButton setState: locked];
}

#pragma mark ¥¥¥Actions
- (IBAction)manualPlotLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORManualPlotLock to:[sender intValue] forWindow:[self window]];
}

@end
