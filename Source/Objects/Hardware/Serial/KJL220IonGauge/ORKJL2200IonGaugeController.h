//--------------------------------------------------------
// ORKJL2200IonGaugeController
// Created by Mark  A. Howe on Thurs Apr 22 2010
// Copyright (c) 2010 University of North Caroline. All rights reserved.
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
#pragma mark ***Imported Files

@class ORPlotView;
@class BiStateView;

@interface ORKJL2200IonGaugeController : OrcaObjectController
{
	IBOutlet NSPopUpButton*	pressureScalePU;
	IBOutlet NSButton*		onOffButton;
	IBOutlet NSButton*      degasButton;
	IBOutlet NSTextField*   degasOnField;
    IBOutlet NSTextField*   lockDocField;
	IBOutlet NSTextField*	degasTimeField;
	IBOutlet NSTextField*	emissionCurrentField;
	IBOutlet NSTextField*	sensitivityField;
	IBOutlet NSMatrix*		setPointMatrix;
	IBOutlet NSMatrix*		setPointLabelMatrix;
	IBOutlet NSTextField*	pressureField;
	IBOutlet NSTextField*	shippingStateField;
	IBOutlet NSButton*		shipPressureButton;
    IBOutlet NSButton*      lockButton;
    IBOutlet NSTextField*   portStateField;
    IBOutlet NSPopUpButton* portListPopup;
    IBOutlet NSPopUpButton* pollTimePopup;
    IBOutlet NSButton*      openPortButton;
    IBOutlet NSTextField*   timeField;
	IBOutlet ORPlotView*   plotter0;
	
    IBOutlet BiStateView*	setPoint1State;
    IBOutlet BiStateView*	setPoint2State;
    IBOutlet BiStateView*	setPoint3State;
    IBOutlet BiStateView*	setPoint4State;
}

#pragma mark ***Initialization
- (id) init;
- (void) dealloc;
- (void) awakeFromNib;

#pragma mark ***Notifications
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark ***Interface Management
- (void) pressureScaleChanged:(NSNotification*)aNote;
- (void) stateMaskChanged:(NSNotification*)aNote;
- (void) degasTimeChanged:(NSNotification*)aNote;
- (void) emissionCurrentChanged:(NSNotification*)aNote;
- (void) sensitivityChanged:(NSNotification*)aNote;
- (void) setPointChanged:(NSNotification*)aNote;
- (void) pressureChanged:(NSNotification*)aNote;
- (void) updateTimePlot:(NSNotification*)aNotification;
- (void) scaleAction:(NSNotification*)aNotification;
- (void) shipPressureChanged:(NSNotification*)aNotification;
- (void) lockChanged:(NSNotification*)aNotification;
- (void) portNameChanged:(NSNotification*)aNotification;
- (void) portStateChanged:(NSNotification*)aNotification;
- (void) pollTimeChanged:(NSNotification*)aNotification;
- (void) miscAttributesChanged:(NSNotification*)aNotification;
- (void) scaleAction:(NSNotification*)aNotification;

#pragma mark ***Actions
- (IBAction) pressureScaleAction:(id)sender;
- (IBAction) degasTimeAction:(id)sender;
- (IBAction) emissionCurrentAction:(id)sender;
- (IBAction) sensitivityAction:(id)sender;
- (IBAction) shipPressureAction:(id)sender;
- (IBAction) lockAction:(id) sender;
- (IBAction) portListAction:(id) sender;
- (IBAction) openPortAction:(id)sender;
- (IBAction) pollTimeAction:(id)sender;
- (IBAction) readNowAction:(id)sender;
- (IBAction) initBoard:(id)sender;
- (IBAction) toggleIonGauge:(id)sender;
- (IBAction) setPointAction:(id)sender;
- (IBAction) toggleDegass:(id)sender;

@end


