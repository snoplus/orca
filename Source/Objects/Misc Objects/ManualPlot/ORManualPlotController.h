//
//  ORManualPlotController.h
//  Orca
//
//  Created by Mark Howe on Sat Nov 19 2005.
//  Copyright Â© 2002 CENPA, University of Washington. All rights reserved.
//

@interface ORManualPlotController : OrcaObjectController
{
    IBOutlet NSButton*    manualPlotLockButton;
}

#pragma mark ¥¥¥Initialization
- (id) init;

#pragma mark ¥¥¥Interface Management
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) manualPlotLockChanged:(NSNotification *)aNote;
- (void) checkGlobalSecurity;

#pragma mark ¥¥¥Actions
- (IBAction) manualPlotLockAction:(id)sender;

@end
