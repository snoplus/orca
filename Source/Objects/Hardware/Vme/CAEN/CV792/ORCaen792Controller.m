//--------------------------------------------------------------------------------
// ORCaen792Controller.m
//  Created by Mark Howe on Tues June 1 2010.
//  Copyright © 2010 University of North Carolina. All rights reserved.
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

#import "ORCaen792Controller.h"
#import "ORCaenDataDecoder.h"
#import "ORCaen792Model.h"


@implementation ORCaen792Controller
#pragma mark ***Initialization
- (id) init
{
    self = [ super initWithWindowNibName: @"Caen792" ];
    return self;
}

- (void) awakeFromNib
{
	int i;
	for(i=0;i<16;i++){
		[[onlineMaskMatrixA cellAtRow:i column:0]   setTag:i];
		[[onlineMaskMatrixB cellAtRow:i column:0]   setTag:i+16];
		[[thresholdA cellAtRow:i column:0]          setTag:i];
		[[thresholdB cellAtRow:i column:0]          setTag:i+16];
	}
	[super awakeFromNib];
}


#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    [ super registerNotificationObservers ];
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter addObserver : self
                     selector : @selector(modelTypeChanged:)
                         name : ORCaen792ModelModelTypeChanged
						object: model];

	[notifyCenter addObserver : self
					 selector : @selector(onlineMaskChanged:)
						 name : ORCaen792ModelOnlineMaskChanged
					   object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(iPedChanged:)
                         name : ORCaen792ModelIPedChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(overflowSuppressEnableChanged:)
                         name : ORCaen792ModelOverflowSuppressEnableChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(zeroSuppressEnableChanged:)
                         name : ORCaen792ModelZeroSuppressEnableChanged
						object: model];

/* v5.1 only
 [notifyCenter addObserver : self
                     selector : @selector(zeroSuppressThresResChanged:)
                         name : ORCaen792ModelZeroSuppressThresResChanged
						object: model];
*/
    [notifyCenter addObserver : self
                     selector : @selector(eventCounterIncChanged:)
                         name : ORCaen792ModelEventCounterIncChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(slidingScaleEnableChanged:)
                         name : ORCaen792ModelSlidingScaleEnableChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(slideConstantChanged:)
                         name : ORCaen792ModelSlideConstantChanged
						object: model];

}

#pragma mark ***Interface Management
- (void) updateWindow
{
    [super updateWindow];
	[self modelTypeChanged:nil];
	[self onlineMaskChanged:nil];
	[self iPedChanged:nil];
	[self overflowSuppressEnableChanged:nil];
	[self zeroSuppressEnableChanged:nil];
	//[self zeroSuppressThresResChanged:nil];//v5.1 only
	[self eventCounterIncChanged:nil];
	[self slidingScaleEnableChanged:nil];
	[self slideConstantChanged:nil];
}

- (void) slideConstantChanged:(NSNotification*)aNote
{
	[slideConstantField setIntValue: [model slideConstant]];
}

- (void) slidingScaleEnableChanged:(NSNotification*)aNote
{
	[slidingScaleEnableMatrix selectCellWithTag: [model slidingScaleEnable]];
    [self setUpButtons];
}

- (void) eventCounterIncChanged:(NSNotification*)aNote
{
	[eventCounterIncMatrix selectCellWithTag: [model eventCounterInc]];
}

/* v5.1 only
 - (void) zeroSuppressThresResChanged:(NSNotification*)aNote
{
	[zeroSuppressThresResMatrix selectCellWithTag: [model zeroSuppressThresRes]];
}
*/

- (void) zeroSuppressEnableChanged:(NSNotification*)aNote
{
	[zeroSuppressEnableMatrix selectCellWithTag: [model zeroSuppressEnable]];
}

- (void) overflowSuppressEnableChanged:(NSNotification*)aNote
{
	[overflowSuppressEnableMatrix selectCellWithTag: [model overflowSuppressEnable]];
}

- (void) iPedChanged:(NSNotification*)aNote
{
	[iPedField setIntValue: [model iPed]];
}

#pragma mark ***Interface Management - Module specific
- (NSString*) thresholdLockName {return @"ORCaen792ThresholdLock";}
- (NSString*) basicLockName     {return @"ORCaen792BasicLock";}

- (NSSize) thresholdDialogSize
{
	return NSMakeSize(550,610);
}

- (void) modelTypeChanged:(NSNotification*)aNote
{
	[modelTypePU selectItemAtIndex: [model modelType]];
	if([model modelType] == kModel792){
		[thresholdB setEnabled:YES];
		[stepperB setEnabled:YES];
		[onlineMaskMatrixB setEnabled:YES];
	}
	else {
		[thresholdB setEnabled:NO];
		[stepperB setEnabled:NO];
		[onlineMaskMatrixB setEnabled:NO];
	}
	[[self window] setTitle:[NSString stringWithFormat:@"%@",[model identifier]]];
}

- (void) thresholdLockChanged:(NSNotification*)aNotification
{
    [self setUpButtons];
}

- (void) setUpButtons
{
    BOOL runInProgress              = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[self thresholdLockName]];
    BOOL locked                     = [gSecurity isLocked:[self thresholdLockName]];
    
	[modelTypePU setEnabled:!runInProgress];
    [thresholdLockButton setState: locked];
    
	if([model modelType] == kModel792){
		[onlineMaskMatrixB setEnabled:!lockedOrRunningMaintenance];
		[thresholdB setEnabled:!lockedOrRunningMaintenance];
	}
	else {
		[onlineMaskMatrixB setEnabled:NO];
		[thresholdB setEnabled:NO];
	}
	[onlineMaskMatrixA setEnabled:!lockedOrRunningMaintenance];
	[thresholdA setEnabled:!lockedOrRunningMaintenance];
	[stepperA setEnabled:!lockedOrRunningMaintenance];
	
    [thresholdWriteButton setEnabled:!lockedOrRunningMaintenance];
    [thresholdReadButton setEnabled:!lockedOrRunningMaintenance];
	
	[slideConstantField           setEnabled: !lockedOrRunningMaintenance && ![model slidingScaleEnable]];
	[slidingScaleEnableMatrix     setEnabled: !lockedOrRunningMaintenance];
	[eventCounterIncMatrix        setEnabled: !lockedOrRunningMaintenance];
	[zeroSuppressEnableMatrix     setEnabled: !lockedOrRunningMaintenance];
	[overflowSuppressEnableMatrix setEnabled: !lockedOrRunningMaintenance];
	[iPedField                    setEnabled: !lockedOrRunningMaintenance];

    
    
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
		if(runInProgress && ![gSecurity isLocked:[self thresholdLockName]])s = @"Not in Maintenance Run.";
    }
    [thresholdLockDocField setStringValue:s];
}
- (void) onlineMaskChanged:(NSNotification*)aNotification
{
	short i;
	unsigned long theMask = [model onlineMask];
	for(i=0;i<16;i++){
		[[onlineMaskMatrixA cellWithTag:i] setIntValue:(theMask&(1<<i))!=0];
		[[onlineMaskMatrixB cellWithTag:i+16] setIntValue:(theMask&(1<<(i+16)))!=0];
	}
}

#pragma mark ¥¥¥Actions

- (void) slideConstantAction:(id)sender
{
	[model setSlideConstant:[sender intValue]];
}

- (void) slidingScaleEnableAction:(id)sender
{
	[model setSlidingScaleEnable:[[sender selectedCell]tag]];
}

- (void) eventCounterIncAction:(id)sender
{
	[model setEventCounterInc:[[sender selectedCell]tag]];
}

/* v5.1 only
 - (void) zeroSuppressThresResAction:(id)sender
{
	[model setZeroSuppressThresRes:[[sender selectedCell]tag]];
}
*/
- (void) zeroSuppressEnableAction:(id)sender
{
	[model setZeroSuppressEnable:[[sender selectedCell]tag]];
}

- (void) overflowSuppressEnableAction:(id)sender
{
	[model setOverflowSuppressEnable:[[sender selectedCell]tag]];
}

- (IBAction) initBoard:(id) sender
{
    [model initBoard];
}

- (void) iPedAction:(id)sender
{
	[model setIPed:[sender intValue]];	
}

- (void) modelTypePUAction:(id)sender
{
	[model setModelType:[sender indexOfSelectedItem]];
}

- (IBAction) onlineAction:(id)sender
{
	[model setOnlineMaskBit:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) report: (id) pSender
{
    [model readThresholds];
    [model logThresholds];
    NSLog(@"IPed Value: 0x%0x\n",[model readIPed]);
 }

@end
