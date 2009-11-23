//
//  ORAnalysisPanel1D.h
//  testplot
//
//  Created by Mark Howe on Tue May 18 2004.
//  Copyright (c) 2004 CENPA, University of Washington. All rights reserved.
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


@class ORGate1D;

@interface ORAnalysisPanel1D : NSObject {
    IBOutlet NSTextField*       curveField;
    IBOutlet NSTextField*       gateField;
    IBOutlet NSTextField*       gateMinField;
    IBOutlet NSTextField*       gateMaxField;
    IBOutlet NSTextField*       gateWidthField;
    IBOutlet NSTextField*       gatePeakXField;
    IBOutlet NSTextField*       gatePeakYField;
    IBOutlet NSTextField*       totalSumField;
    IBOutlet NSTextField*       averageField;
    IBOutlet NSTextField*       centroidField;
    IBOutlet NSTextField*       sigmaField;
    IBOutlet NSTextField*       activeField;

    IBOutlet NSButton*      fitButton;
    IBOutlet NSButton*      deleteButton;
    IBOutlet NSPopUpButton* fitTypePopup;
    IBOutlet NSTextField*   serviceStatusField;
    IBOutlet NSTextField*   polyOrderField;
    IBOutlet NSButton*      fftButton;
    IBOutlet NSPopUpButton* fftOptionPopup;
    IBOutlet NSPopUpButton* fftWindowPopup;
	
    IBOutlet NSDrawer*		analysisDrawer;
    IBOutlet NSBox*			analysisView;

    IBOutlet NSPopUpButton* gatePopup;
    IBOutlet NSButton*      displayGateButton;
	IBOutlet NSTextField*   fitFunctionField;
    ORGate1D* gate;
    NSString* fitFunction;
    int fitOrder;
    int fitType;
	BOOL serviceAvailable;
	int fftOption;
	int fftWindow;
}

+ (id) panel;

- (id) init;
- (void) adjustSize;
- (void) setGate:(id)aGate;
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) gateValidChanged:(NSNotification*)aNotification;
- (NSView*) view;
- (int) fitOrder;
- (void) setFitFunction:(NSString*)aFunction;
- (void) setFitOrder:(int)order;
- (int) fitType;
- (void) setFitType:(int)order;
- (int) fftOption;
- (void) setFftOption:(int)option;
- (int) fftWindow;
- (void) setFftWindow:(int)windowType;

- (void) orcaRootServiceConnectionChanged:(NSNotification*)aNote;
- (void) orcaRootServiceFitChanged:(NSNotification*)aNote;
- (void)  activeGateChanged:(NSNotification*)aNote;
- (void) fitFunctionChanged;
- (void) fitOrderChanged;
- (void) fitTypeChanged;
- (void) fftOptionChanged;
- (void) fftWindowChanged;
- (void) displayGateChanged:(NSNotification*)aNotification;
- (void) curveNumberChanged:(NSNotification*)aNotification;
- (void) gateNumberChanged:(NSNotification*)aNotification;
- (void) gateMinChanged:(NSNotification*)aNotification;
- (void) gateMaxChanged:(NSNotification*)aNotification;
- (void) totalSumChanged:(NSNotification*)aNotification;
- (void) averageChanged:(NSNotification*)aNotification;
- (void) centroidChanged:(NSNotification*)aNotification;
- (void) sigmaChanged:(NSNotification*)aNotification;
- (void) peakxChanged:(NSNotification*)aNotification;
- (void) peakyChanged:(NSNotification*)aNotification;

- (IBAction) displayGateAction:(id)sender;
- (IBAction) fitAction:(id)sender;
- (IBAction) deleteFitAction:(id)sender;
- (IBAction) fitTypeAction:(id)sender;
- (IBAction) fitOrderAction:(id)sender;
- (IBAction) fftAction:(id)sender;
- (IBAction) fftOptionAction:(id)sender;
- (IBAction) fftWindowAction:(id)sender;
- (IBAction) fitFunctionAction:(id)sender;

@end


