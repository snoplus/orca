
/*
 *  ORCMC203ModelController.h
 *  Orca
 *
 *  Created by Mark Howe on Sat Nov 16 2002.
 *  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
 *
 */

#pragma mark ¥¥¥Imported Files
#import <Cocoa/Cocoa.h>
#import "ORCMC203Model.h"
#import "OrcaObjectController.h"

@interface ORCMC203Controller : OrcaObjectController {
	@private
        IBOutlet	NSButton*		settingLockButton;
		IBOutlet    NSTextField*	histogramMaskTextField;
		IBOutlet    NSTextField*	histoBlockSizeTextField;
		IBOutlet	NSTextField*	pingPongTextField;
		IBOutlet	NSPopUpButton*	extRenInputSigSelPopup;
		IBOutlet	NSTextField*	eventTimeoutTextField;
		IBOutlet	NSPopUpButton*	wsoOutputSelectionPopup;
		IBOutlet	NSPopUpButton*	rqoOutputSelectionPopup;
		IBOutlet	NSPopUpButton*	sOutputSelectionPopup;
		IBOutlet	NSPopUpButton*	qOutputSelectionPopup;
		IBOutlet	NSPopUpButton*	ledAssigmentPopup;
		IBOutlet	NSTextField*	vsnTextField;
		IBOutlet	NSTextField*	busyEndDelayTextField;
		IBOutlet	NSTextField*	gateTimeOutTextField;
		IBOutlet	NSTextField*	multiHistogramTextField;
		IBOutlet	NSPopUpButton*	histogramControlPopup;
		IBOutlet	NSTextField*	feraClrWidthTextField;
		IBOutlet	NSTextField*	testGateWidthTextField;
		IBOutlet	NSTextField*	dacValueTextField;
		IBOutlet	NSTextField*	reqDelayTextField;
		IBOutlet	NSPopUpButton*	controlRegOpModePopup;
		IBOutlet	NSMatrix*		controlRegMatrix;
		
		IBOutlet    NSButton* readButton;
		IBOutlet    NSButton* writeButton;
		
};

- (void) registerNotificationObservers;

#pragma mark ¥¥¥Interface Management
- (void) histogramMaskChanged:(NSNotification*)aNote;
- (void) histoBlockSizeChanged:(NSNotification*)aNote;
- (void) pingPongChanged:(NSNotification*)aNote;
- (void) extRenInputSigSelChanged:(NSNotification*)aNote;
- (void) eventTimeoutChanged:(NSNotification*)aNote;
- (void) outputSelectionChanged:(NSNotification*)aNote;
- (void) ledAssigmentChanged:(NSNotification*)aNote;
- (void) vsnChanged:(NSNotification*)aNote;
- (void) busyEndDelayChanged:(NSNotification*)aNote;
- (void) gateTimeOutChanged:(NSNotification*)aNote;
- (void) multiHistogramChanged:(NSNotification*)aNote;
- (void) multiHistogramChanged:(NSNotification*)aNote;
- (void) histogramControlChanged:(NSNotification*)aNote;
- (void) feraClrWidthChanged:(NSNotification*)aNote;
- (void) testGateWidthChanged:(NSNotification*)aNote;
- (void) dacValueChanged:(NSNotification*)aNote;
- (void) reqDelayChanged:(NSNotification*)aNote;
- (void) controlRegChanged:(NSNotification*)aNote;
- (void) settingsLockChanged:(NSNotification*)aNotification;
- (void) slotChanged:(NSNotification*)aNotification;

#pragma mark ¥¥¥Accessors

#pragma mark ¥¥¥Actions
- (IBAction) histogramMaskTextFieldAction:(id)sender;
- (IBAction) readButtonAction:(id)sender;
- (IBAction) writeButtonAction:(id)sender;

- (IBAction) histoBlockSizeTextFieldAction:(id)sender;
- (IBAction) pingPongTextFieldAction:(id)sender;
- (IBAction) extRenInputSigSelPopupAction:(id)sender;
- (IBAction) eventTimeoutTextFieldAction:(id)sender;
- (IBAction) outputSelectionPopupAction:(id)sender;
- (IBAction) ledAssigmentPopupAction:(id)sender;
- (IBAction) vsnTextFieldAction:(id)sender;
- (IBAction) busyEndDelayTextFieldAction:(id)sender;
- (IBAction) gateTimeOutTextFieldAction:(id)sender;
- (IBAction) multiHistogramTextFieldAction:(id)sender;
- (IBAction) histogramControlPopupAction:(id)sender;
- (IBAction) feraClrWidthTextFieldAction:(id)sender;
- (IBAction) testGateWidthTextFieldAction:(id)sender;
- (IBAction) dacValueTextFieldAction:(id)sender;
- (IBAction) reqDelayTextFieldAction:(id)sender;
- (IBAction) controlRegOpModePopupAction:(id)sender;
- (IBAction) controlRegMatrixAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;

 - (void) showError:(NSException*)anException name:(NSString*)name fCode:(int)i;

@end