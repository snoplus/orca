//--------------------------------------------------------------------------------
//ORCV977Controller.h
//Mark A. Howe 20013-09-26
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

#import "ORCaenCardController.h"


// Definition of class.
@interface ORCV977Controller : ORCaenCardController {
    IBOutlet NSTextField*	inputSetField;
    IBOutlet NSMatrix*      inputSetMatrix;
}

#pragma mark ***Initialization
- (id)		init;
 	
#pragma mark •••Notifications
- (void) registerNotificationObservers;

#pragma mark ***Interface Management
- (NSSize) thresholdDialogSize;
- (void) updateWindow;
- (void) inputSetChanged:(NSNotification*)aNote;

#pragma mark ***Actions
- (IBAction) inputSetAction:(id)sender;

@end
