//
//  ResistorDBViewController.h
//  Orca
//
//  Created by Chris Jones on 28/04/2014.
//
//

#import <Cocoa/Cocoa.h>

@interface ResistorDBViewController : OrcaObjectController {
    
    IBOutlet NSButton *queryDBButton;
    IBOutlet NSComboBox *crateSelect;
    IBOutlet NSComboBox *cardSelect;
    IBOutlet NSComboBox *channelSelect;
    IBOutlet NSTextField *currentResistorStatus;
    IBOutlet NSTextField *currentSNOLowOcc;
    IBOutlet NSTextField *currentPMTRemoved;
    IBOutlet NSTextField *currentPMTReinstallled;
    IBOutlet NSTextField *currentPulledCable;
    IBOutlet NSTextField *currentBadCable;
    IBOutlet NSMatrix *updateResistorStatus;
    IBOutlet NSMatrix *updateSnoLowOcc;
    IBOutlet NSMatrix *updatePmtRemoved;
    IBOutlet NSMatrix *updatePmtReinstalled;
    IBOutlet NSMatrix *updatePulledCable;
    IBOutlet NSMatrix *updateBadCable;
    IBOutlet NSComboBox *updateReasonBox;
    IBOutlet NSTextField *updateReasonOther;
    IBOutlet NSTextField *updateInfoForPull;
    IBOutlet NSButton *updateDbButton;
}

-(id)init;
-(void)dealloc;
-(void) updateWindow;
-(void) registerNotificationObservers;

@end
