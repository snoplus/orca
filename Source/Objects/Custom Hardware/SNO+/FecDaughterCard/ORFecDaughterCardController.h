//
//  ORFecDaughterCardController.h
//  Orca
//
//  Created by Mark Howe on Wed Oct 15,2008.
//  Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
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
#import "ORFecDaughterCardModel.h"

@interface ORFecDaughterCardController : OrcaObjectController  {
	@private
		IBOutlet NSMatrix* rp1Matrix;
		IBOutlet NSMatrix* rp2Matrix;
		IBOutlet NSMatrix* vliMatrix;
		IBOutlet NSMatrix* vsiMatrix;
		IBOutlet NSMatrix* vtMatrix;
		IBOutlet NSMatrix* vbMatrix;
		IBOutlet NSMatrix* ns100widthMatrix;			   
		IBOutlet NSMatrix* ns20widthMatrix; 
		IBOutlet NSMatrix* ns20delayMatrix;
		IBOutlet NSMatrix* tac0trimMatrix; 	   
		IBOutlet NSMatrix* tac1trimMatrix;
}

#pragma mark •••Notifications
- (void) registerNotificationObservers;

#pragma mark •••Interface Management
- (void) slotChanged:(NSNotification*)aNote;
- (void) rp1Changed:(NSNotification*)aNote;
- (void) rp2Changed:(NSNotification*)aNote; 
- (void) vliChanged:(NSNotification*)aNote; 
- (void) vsiChanged:(NSNotification*)aNote; 
- (void) vtChanged:(NSNotification*)aNote; 
- (void) vbChanged:(NSNotification*)aNote; 	   
- (void) ns100widthChanged:(NSNotification*)aNote; 			   
- (void) ns20widthChanged:(NSNotification*)aNote; 
- (void) ns20delayChanged:(NSNotification*)aNote; 
- (void) tac0trimChanged:(NSNotification*)aNote; 	   
- (void) tac1trimChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (void) rp1Action:(id)sender;
- (void) rp2Action:(id)sender; 
- (void) vliAction:(id)sender; 
- (void) vsiAction:(id)sender; 
- (void) vtAction:(id)sender; 
- (void) vbAction:(id)sender; 	   
- (void) ns100widthAction:(id)sender; 			   
- (void) ns20widthAction:(id)sender; 
- (void) ns20delayAction:(id)sender; 
- (void) tac0trimAction:(id)sender; 	   
- (void) tac1trimAction:(id)sender;

@end
