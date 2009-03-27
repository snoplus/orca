//
//  ORDataController.h
//  Orca
//
//  Created by Mark Howe on Tue Dec 09 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


@interface ORDataController : OrcaObjectController {
	    
    IBOutlet id             plotter;
    IBOutlet NSDrawer*		analysisDrawer;

    IBOutlet NSTextField*   titleField;
    IBOutlet NSView*		plotterGroupView;
    IBOutlet NSButton*		hideShowButton;
    IBOutlet NSView*        containingView;
    IBOutlet NSTextField*   positionField;
    IBOutlet NSTextField*   pausedField;
    IBOutlet NSTableView*   rawDataTable;
    IBOutlet NSTabView*		rawDataTabView;
    IBOutlet NSPopUpButton*	refreshModePU;
	IBOutlet NSButton*		pauseButton;
}


#pragma mark •••Accessors
- (id) plotter;
- (id) curve:(int)aCurveIndex gate:(int)aGateIndex;

#pragma mark •••Interface Management
- (void) registerNotificationObservers;
- (void) dataSetRemoved:(NSNotification*)aNote;
- (void) updateWindow;

- (void) dataSetChanged:(NSNotification*)aNote;
- (void) drawerDidOpen:(NSNotification*)aNote;
- (void) drawerDidClose:(NSNotification*)aNote;
- (void) scaleAction:(NSNotification*)aNote;
- (void) miscAttributesChanged:(NSNotification*)aNote;
- (void) serviceResponse:(NSNotification*)aNote;
- (void) refreshModeChanged:(NSNotification*)aNote;
- (void) pausedChanged:(NSNotification*)aNote;
- (void) openAnalysisDrawer;
- (void) closeAnalysisDrawer;
- (BOOL) analysisDrawerIsOpen;

- (IBAction) printDocument:(id)sender;

- (IBAction) logLin:(NSToolbarItem*)item;
- (IBAction) toggleRaw:(NSToolbarItem*)item;
- (IBAction) clearROI:(NSToolbarItem*)item;
- (IBAction) clear:(NSToolbarItem*)item;
- (IBAction) doAnalysis:(NSToolbarItem*)item;
- (IBAction) autoScale:(NSToolbarItem*)item;
- (IBAction) hideShowControls:(id)sender;
- (IBAction) refreshModeAction:(id)sender;
- (IBAction) pauseAction:(id)sender;
- (void)_clearSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo;

@end

@interface NSObject (ORDataController_Cat)
- (int)  numberBins;
- (long) value:(unsigned short)aChan;
@end

