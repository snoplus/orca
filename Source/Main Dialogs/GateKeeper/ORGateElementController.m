//
//  ORGateElementController.m
//  Orca
//
//  Created by Mark Howe on 1/25/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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
#import "ORGateElementController.h"
#import "ORGateElement.h"
#import "ORDataTaker.h"
#import "ORGateKeeper.h"

@interface ORGateElementController (private)
- (void) populateDecoderTargetPopup;
- (NSString*) shortName:(NSString*)aName;
@end

@implementation ORGateElementController

#pragma mark •••Initialization
- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void) awakeFromNib
{
    [self populateDecoderTargetPopup];
    [self registerNotificationObservers];
    [self updateWindow];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{

    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORGateKeeperSettingsLock];
    
    [decoderTargetPopup setEnabled:!lockedOrRunningMaintenance && !ignore];
    [crateField setEnabled:!lockedOrRunningMaintenance && !ignore];
    [cardField setEnabled:!lockedOrRunningMaintenance && !ignore];
    [channelField setEnabled:!lockedOrRunningMaintenance && !ignore];

}

#pragma mark •••Accessors
- (BOOL) ignore
{
	return ignore;
}
- (void) setIgnore:(BOOL)aIgnore
{
	ignore = aIgnore;
    [self settingsLockChanged:nil];
}

- (id) model
{
    return model; 
}

- (void) setModel: (id) aModel
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    model = aModel; //don't retain to avoid retain cycle
    
    [self registerNotificationObservers];
    [self updateWindow];
    
}

- (NSMutableArray *) decoderList
{
    return decoderList; 
}

- (void) setDecoderList: (NSMutableArray *) aDecoderList
{
    [aDecoderList retain];
    [decoderList release];
    decoderList = aDecoderList;
}


#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(crateChanged:)
                         name : ORGateCrateChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(cardChanged:)
                         name : ORGateCardChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(channelChanged:)
                         name : ORGateChannelChangedNotification
                       object : model];


    [notifyCenter addObserver : self
                     selector : @selector(decoderTargetChanged:)
                         name : ORGateDecoderTargetChangedNotification
                       object : model];
    
}


#pragma mark ***Interface Management
- (void) updateWindow
{
    [self decoderTargetChanged:nil];
    [self crateChanged:nil];
    [self cardChanged:nil];
    [self channelChanged:nil];
}


- (void) decoderTargetChanged:(NSNotification*)aNote
{
	NSString* aName = [self shortName:[model decoderTarget]];
	if(aName)[decoderTargetPopup selectItemWithTitle:aName];
	else [decoderTargetPopup selectItemAtIndex:[decoderTargetPopup numberOfItems]-1];
}


- (void) crateChanged:(NSNotification*)aNote
{
	[crateField setIntValue:[model crateNumber]];
}

- (void) cardChanged:(NSNotification*)aNote
{
	[cardField setIntValue:[model card]];
}

- (void) channelChanged:(NSNotification*)aNote
{
	[channelField setIntValue:[model channel]];
}

#pragma mark ***Actions
- (IBAction) decoderTargetAction:(id)sender
{
    int index = [decoderTargetPopup indexOfSelectedItem];
    if(index<[decoderList count]){
        [model setDecoderTarget:[decoderList objectAtIndex:index]];
    }
    else  [model setDecoderTarget:nil];

}

- (IBAction) crateAction:(id)sender
{
    [model setCrateNumber:[sender intValue]];
}

- (IBAction) cardAction:(id)sender
{
    [model setCard:[sender intValue]];
}

- (IBAction) channelAction:(id)sender
{
    [model setChannel:[sender intValue]];
}

@end

@implementation ORGateElementController (private)

- (void) populateDecoderTargetPopup
{
    [self setDecoderList:[NSMutableArray array]];
    NSArray* dataTakers = [[[NSApp delegate] document]  collectObjectsConformingTo:@protocol(ORDataTaker)];
    NSEnumerator* e = [dataTakers objectEnumerator];
    OrcaObject* obj;
    while(obj = [e nextObject]){
        if([obj respondsToSelector:@selector(dataRecordDescription)]){
            //loop over the items in the dictionary looking for the decoders
            NSEnumerator* dictenum = [[obj dataRecordDescription] objectEnumerator];
            id anEntry;
            while(anEntry = [dictenum nextObject]){
                id decoderName = [anEntry objectForKey:@"decoder"];
                if(decoderName){
                    if([[anEntry objectForKey:@"canBeGated"] intValue] == 1){
                        [decoderList addObject:decoderName];
                    }
                }
            }
        }
    }
    [decoderTargetPopup removeAllItems];
    int count = [decoderList count];
    int i;
    for(i=0;i<count;i++){
        NSString* shortString = [self shortName:[decoderList objectAtIndex:i]];
        [decoderTargetPopup insertItemWithTitle:shortString atIndex:i];
    }
    [decoderTargetPopup insertItemWithTitle:@"No Decoder Picked" atIndex:count];

}

- (NSString*) shortName:(NSString*)aName
{
    if([aName hasPrefix:@"OR"])aName = [aName substringFromIndex:2];
    return [[aName componentsSeparatedByString:@"DecoderFor"] componentsJoinedByString:@"   "];
}

@end

