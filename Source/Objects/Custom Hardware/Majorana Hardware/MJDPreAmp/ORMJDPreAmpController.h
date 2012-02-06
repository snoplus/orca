//
//  MJDPreAmpController.h
//  Orca
//
//  Created by Mark Howe on Wed Jan 18 2012.TimeField
//  Copyright © 2012 University of North Carolina. All rights reserved.
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
#import "OrcaObjectController.h"

@interface ORMJDPreAmpController : OrcaObjectController
{
    @private
		IBOutlet NSButton*		settingsLockButton;
		IBOutlet NSPopUpButton* loopForeverPU;
		IBOutlet NSTextField*	pulseCountField;
		IBOutlet NSPopUpButton* enabled0PU;
		IBOutlet NSPopUpButton* enabled1PU;
		IBOutlet NSPopUpButton* attenuated0PU;
		IBOutlet NSPopUpButton* attenuated1PU;
		IBOutlet NSPopUpButton* finalAttenuated0PU;
		IBOutlet NSPopUpButton* finalAttenuated1PU;
		IBOutlet NSTextField*   pulseHighTimeField;
		IBOutlet NSTextField*   pulseLowTimeField;
		IBOutlet NSMatrix*		dacsMatrix;
		IBOutlet NSMatrix*		amplitudesMatrix;
		IBOutlet NSMatrix*		pulserMaskMatrix;
		IBOutlet NSTextField*   frequencyField;
		IBOutlet NSButton*		startPulserButton;
		IBOutlet NSButton*		stopPulserButton;
}

#pragma mark ¥¥¥Initialization
- (id)		init;
- (void)	dealloc;
- (void)	awakeFromNib;
- (void)	setModel:(id)aModel;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;

#pragma mark ¥¥¥Interface Management
- (void) loopForeverChanged:(NSNotification*)aNote;
- (void) pulseCountChanged:(NSNotification*)aNote;
- (void) amplitudeChanged:(NSNotification*)aNote;
- (void) amplitudeArrayChanged:(NSNotification*)aNote;
- (void) enabledChanged:(NSNotification*)aNote;
- (void) attenuatedChanged:(NSNotification*)aNote;
- (void) finalAttenuatedChanged:(NSNotification*)aNote;
- (void) pulserMaskChanged:(NSNotification*)aNote;
- (void) pulseHighTimeChanged:(NSNotification*)aNote;
- (void) pulseLowTimeChanged:(NSNotification*)aNote;
- (void) dacArrayChanged:(NSNotification*)aNote;
- (void) dacChanged:(NSNotification*)aNote;
- (void) updateWindow;
- (void) checkGlobalSecurity;
- (void) settingsLockChanged:(NSNotification *)notification;
- (void) updateButtons;
- (void) displayFrequency;

#pragma mark ¥¥¥Actions
- (IBAction) amplitudesAction:(id)sender;
- (IBAction) loopForeverAction:(id)sender;
- (IBAction) pulseCountAction:(id)sender;
- (IBAction) enabledAction:(id)sender;
- (IBAction) finalAttenuatedAction:(id)sender;
- (IBAction) attenuatedAction:(id)sender;
- (IBAction) pulserMaskAction:(id)sender;
- (IBAction) pulseHighTimeAction:(id)sender;
- (IBAction) pulseLowTimeAction:(id)sender;
- (IBAction) dacsAction:(id)sender;
- (IBAction) settingsLockAction:(id)sender;
- (IBAction) readAction:(id)sender;
- (IBAction) writeFetVdsAction:(id)sender;
- (IBAction) startPulserAction:(id)sender;
- (IBAction) stopPulserAction:(id)sender;
@end
