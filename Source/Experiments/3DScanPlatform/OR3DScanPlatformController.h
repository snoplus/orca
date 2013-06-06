//
//  OR3DScanPlatformController.h
//  Orca
//
//  Created by Mark Howe on Tues Mar 27, 2012.
//  Copyright ¬© 2012 CENPA, University of North Carolina. All rights reserved.
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


#pragma mark •••Forward Declarations
@interface OR3DScanPlatformController : OrcaObjectController
{
	IBOutlet ORGroupView*   subComponentsView;
    IBOutlet NSButton*      lockButton;
}

- (id) init;
- (void) awakeFromNib;

#pragma mark ***Interface Management
- (void) registerNotificationObservers;
- (void) lockChanged:(NSNotification*)aNote;
- (void) groupChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) lockAction:(id) sender;
@end

