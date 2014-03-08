//
//  ORnEDMCoilController.h
//  Orca
//
//  Created by Michael Marino 15 Mar 2012 
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

#pragma mark •••Imported Files

#import "OrcaObjectController.h"

//modified so this will compile under 10.5 09/06/12 MAH
#if defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
@interface ORnEDMCoilController : OrcaObjectController <NSTableViewDataSource>
#else
@interface ORnEDMCoilController : OrcaObjectController
#endif
{
    IBOutlet NSTabView* 	tabView;
    IBOutlet ORGroupView*   groupView;
    IBOutlet NSTextField*   lockDocField;
    IBOutlet NSButton*      startStopButton;
    IBOutlet NSTextField*   runRateField;   
    IBOutlet NSPopUpButton* listOfAdcs;
    IBOutlet NSProgressIndicator* processIndicate;
    IBOutlet NSTextField*   realProcessFrequencyField;
    
    IBOutlet NSPopUpButton* commandPopUp;
    IBOutlet NSPopUpButton* outputNumberPopUp;    
    IBOutlet NSTextField*   inputValueText;
    IBOutlet NSButton*      debugModeButton;
    
    IBOutlet NSButton*      feedBackMapButton;
    IBOutlet NSButton*      orientationMatrixButton;
    IBOutlet NSButton*      magnetometerMapButton;
    
    IBOutlet NSTextField*   feedBackNotifier;
    IBOutlet NSButton*      deleteADCButton;
    IBOutlet NSButton*      addADCButton;

    IBOutlet NSTableView*   listOfRegisteredADCs;
    IBOutlet NSTableView*   hardwareMap;
    IBOutlet NSTableView*   orientationMatrix;
    IBOutlet NSTableView*   feedbackMatrix;
    IBOutlet NSTableView*   currentValues;
    IBOutlet NSTableView*   fieldValues;
    IBOutlet NSTableView*   targetFieldValues;
    
    IBOutlet NSTextField*   coilText;
    IBOutlet NSTextField*   postToDBText;
    
	IBOutlet NSButton*      refreshIPsButton;
    IBOutlet NSProgressIndicator* refreshIPIndicate;
    
    IBOutlet NSButton*      processVerbose;
    IBOutlet NSButton*      postDataToDBButton;
    
    NSView *blankView;    
    NSSize controlSize;
    NSSize powerSupplySize;
    NSSize adcSize;
    NSString* startingDirectory;
}

- (id) init;
- (void) awakeFromNib;

#pragma mark •••Accessors
- (ORGroupView *)groupView;
- (void) setModel:(id)aModel;

#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark •••Interface Management
- (void) groupChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;
- (BOOL) validateMenuItem:(NSMenuItem*)aMenuItem;
- (void) documentLockChanged:(NSNotification*)aNote;
- (void) runStatusChanged:(NSNotification*)aNote;
- (void) runRateChanged:(NSNotification*)aNote;
- (void) modelADCListChanged:(NSNotification*)aNote;
- (void) channelMapChanged:(NSNotification*)aNote;
- (void) objectsAdded:(NSNotification*)aNote;
- (void) debugRunningChanged:(NSNotification*)aNote;
- (void) refreshIPAddressesDone:(NSNotification*)aNote;
- (void) processVerboseChanged:(NSNotification*)aNote;
- (void) realProcessFrequencyChanged:(NSNotification*)aNote;
- (void) targetFieldChanged:(NSNotification*)aNote;

- (void) populateListADCs;

- (IBAction) runRateAction:(id)sender; 
- (IBAction) runAction:(id)sender; 
- (IBAction) readPrimaryMapFileAction:(id)sender;
- (IBAction) readPrimaryMagnetometerMapFileAction:(id)sender;
- (IBAction) readPrimaryOrientationMatrixFileAction:(id)sender;
- (IBAction) addADCAction:(id)sender;
- (IBAction) sendCommandAction:(id)sender;
- (IBAction) debugCommandAction:(id)sender;
- (IBAction) connectAllAction:(id)sender;
- (IBAction) removeSelectedADCs:(id)sender;
- (IBAction) handleToBeAddedADC:(id)sender;
- (IBAction) refreshIPsAction:(id)sender;
- (IBAction) processVerboseAction:(id)sender;
- (IBAction) refreshCurrentAndFieldValuesAction:(id)sender;
- (IBAction) loadTargetFieldValuesAction:(id)sender;
- (IBAction) saveCurrentFieldAsTargetFieldAction:(id)sender;
- (IBAction) setTargetFieldToZeroAction:(id)sender;

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;

//- (IBAction) delete:(id)sender; 
//- (IBAction) cut:(id)sender; 
//- (IBAction) paste:(id)sender ;
//- (IBAction) selectAll:(id)sender;
//-----------------------------------------------------------------

@end
