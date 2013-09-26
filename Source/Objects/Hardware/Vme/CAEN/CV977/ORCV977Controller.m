//--------------------------------------------------------------------------------
//ORCV977Controller.m
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
#import "ORCV977Controller.h"
#import "ORCaenDataDecoder.h"
#import "ORCV977Model.h"


@implementation ORCV977Controller
#pragma mark ***Initialization
- (id) init
{
    self = [ super initWithWindowNibName: @"CV977" ];
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


#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    [ super registerNotificationObservers ];
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];

	[notifyCenter addObserver : self
					 selector : @selector(onlineMaskChanged:)
						 name : ORCV977ModelOnlineMaskChanged
					   object : model];
}

#pragma mark ***Interface Management
- (void) updateWindow
{
   [ super updateWindow ];
	[self onlineMaskChanged:nil];
}

#pragma mark ***Interface Management - Module specific
- (NSString*) thresholdLockName {return @"ORCV977ThresholdLock";}
- (NSString*) basicLockName     {return @"ORCV977BasicLock";}

- (NSSize) thresholdDialogSize
{
	return NSMakeSize(310,640);
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

#pragma mark •••Actions
- (IBAction) onlineAction:(id)sender
{
	[model setOnlineMaskBit:[[sender selectedCell] tag] withValue:[sender intValue]];
}

@end
