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
//--------------------------------------------------------------------------------
// CLASS:		ORCaen792Controller
// Purpose:		Handles the interaction between the user and the VC792 module.
//--------------------------------------------------------------------------------
#import "ORCaen792Controller.h"
#import "ORCaenDataDecoder.h"
#import "ORCaen792Model.h"


@implementation ORCaen792Controller
#pragma mark ***Initialization
//--------------------------------------------------------------------------------
/*!
 * \method	init
 * \brief	Initialize interface with hardware object.
 * \note	
 */
//--------------------------------------------------------------------------------
- (id) init
{
    self = [ super initWithWindowNibName: @"Caen792" ];
    return self;
}

- (void) awakeFromNib
{
	int i;
	for(i=0;i<16;i++){
		[[onlineMaskMatrixA cellAtRow:i column:0] setTag:i];
		[[onlineMaskMatrixB cellAtRow:i column:0] setTag:i+16];
		[[thresholdA cellAtRow:i column:0] setTag:i];
		[[thresholdB cellAtRow:i column:0] setTag:i+16];
	}
	[super awakeFromNib];
}


#pragma mark ¥¥¥Notifications
//--------------------------------------------------------------------------------
/*!\method  registerNotificationObservers
 * \brief	Register notices that we want to receive.
 * \note	
 */
//--------------------------------------------------------------------------------
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

}

#pragma mark ***Interface Management

- (void) iPedChanged:(NSNotification*)aNote
{
	[iPedField setIntValue: [model iPed]];
}

//--------------------------------------------------------------------------------
/*!\method  updateWindow
 * \brief	Sets all GUI values to current model values.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) updateWindow
{
   [ super updateWindow ];
	[self modelTypeChanged:nil];
	[self onlineMaskChanged:nil];
	[self iPedChanged:nil];
}

#pragma mark ***Interface Management - Module specific
- (NSString*) thresholdLockName {return @"ORCaen792ThresholdLock";}
- (NSString*) basicLockName     {return @"ORCaen792BasicLock";}

- (NSSize) thresholdDialogSize
{
	return NSMakeSize(410,640);
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
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[self thresholdLockName]];
    BOOL locked = [gSecurity isLocked:[self thresholdLockName]];
    
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
