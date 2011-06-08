/*
 *  ORCV812Controller.m
 *  Orca
 *
 *  Created by Mark Howe on Tuesday, June 7, 2011.
 *  Copyright (c) 2011 CENPA, University of North Carolina. All rights reserved.
 *
 */
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sonsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
#import "ORCV812Controller.h"
#import "ORCV812Model.h"

@implementation ORCV812Controller

#pragma mark ***Initialization
- (id) init
{
    self = [ super initWithWindowNibName: @"CV812" ];
    return self;
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    [ super registerNotificationObservers ];
	
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [notifyCenter addObserver : self
                     selector : @selector(testPulseChanged:)
                         name : ORCV812ModelTestPulseChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(patternInhibitChanged:)
                         name : ORCV812ModelPatternInhibitChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(majorityThresholdChanged:)
                         name : ORCV812ModelMajorityThresholdChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(deadTime0_7Changed:)
                         name : ORCV812ModelDeadTime0_7Changed
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(deadTime8_15Changed:)
                         name : ORCV812ModelDeadTime8_15Changed
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(outputWidth0_7Changed:)
                         name : ORCV812ModelOutputWidth0_7Changed
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(outputWidth8_15Changed:)
                         name : ORCV812ModelOutputWidth8_15Changed
						object: model];
	
}

#pragma mark ***Interface Management
- (void) updateWindow
{
	[super updateWindow];
	[self testPulseChanged:nil];
	[self patternInhibitChanged:nil];
	[self majorityThresholdChanged:nil];
	[self deadTime0_7Changed:nil];
	[self deadTime8_15Changed:nil];
	[self outputWidth0_7Changed:nil];
	[self outputWidth8_15Changed:nil];
}

- (void) selectedRegIndexChanged:(NSNotification*) aNotification
{
	[super selectedRegIndexChanged:aNotification];
	//  Set value of popup
	short index = [model selectedRegIndex];

	if(index>=kOutputWidt0_7){
		[channelPopUp setEnabled:NO];
	}
}

- (void) thresholdLockChanged:(NSNotification*)aNotification
{
	[super thresholdLockChanged:aNotification];
	
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[self basicLockName]];
	
    [testPulseField setEnabled:!lockedOrRunningMaintenance]; 
    [patternInhibitField setEnabled:!lockedOrRunningMaintenance]; 
    [majorityThresholdField setEnabled:!lockedOrRunningMaintenance]; 
    [deadTime0_7Field setEnabled:!lockedOrRunningMaintenance]; 
    [deadTime8_15Field setEnabled:!lockedOrRunningMaintenance]; 
    [outputWidth0_7Field setEnabled:!lockedOrRunningMaintenance]; 
    [outputWidth8_15Field setEnabled:!lockedOrRunningMaintenance]; 
}	

- (void) testPulseChanged:(NSNotification*)aNote
{
	[testPulseField setIntValue:[model testPulse]];	
}

- (void) patternInhibitChanged:(NSNotification*)aNote
{
	[patternInhibitField setIntValue:[model patternInhibit]];		
}

- (void) majorityThresholdChanged:(NSNotification*)aNote
{
	[majorityThresholdField setIntValue:[model majorityThreshold]];		

}

- (void) deadTime0_7Changed:(NSNotification*)aNote
{
	[deadTime0_7Field setIntValue:[model deadTime0_7]];			
}

- (void) deadTime8_15Changed:(NSNotification*)aNote
{
	[deadTime8_15Field setIntValue:[model deadTime8_15]];			
}

- (void) outputWidth0_7Changed:(NSNotification*)aNote
{
	[outputWidth0_7Field setIntValue:[model outputWidth0_7]];			
}

- (void) outputWidth8_15Changed:(NSNotification*)aNote
{
	[outputWidth8_15Field setIntValue:[model outputWidth8_15]];			
}

#pragma mark ***Interface Management - Module specific
- (NSString*) thresholdLockName {return @"ORCV812ThresholdLock";}
- (NSString*) basicLockName     {return @"ORCV812BasicLock";}

#pragma mark •••Actions
- (IBAction) testPulseAction:(id)sender
{
	[model setTestPulse:[sender intValue]];
}

- (IBAction) patternInhibitAction:(id)sender
{
	[model setPatternInhibit:[sender intValue]];
}

- (IBAction) majorityThresholdAction:(id)sender
{
	[model setMajorityThreshold:[sender intValue]];
}

- (IBAction) deadTime0_7Action:(id)sender
{
	[model setDeadTime0_7:[sender intValue]];
}

- (IBAction) deadTime8_15Action:(id)sender
{
	[model setDeadTime8_15:[sender intValue]];
}

- (IBAction) outputWidth0_7Action:(id)sender
{
	[model setOutputWidth0_7:[sender intValue]];
}

- (IBAction) outputWidth8_15Action:(id)sender
{
	[model setOutputWidth8_15:[sender intValue]];
}

@end
