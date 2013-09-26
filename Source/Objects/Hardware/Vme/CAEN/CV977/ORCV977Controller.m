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
		[[inputSetMatrix cellAtRow:0 column:i] setTag:15-i];
	}
	[super awakeFromNib];
}


#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    [ super registerNotificationObservers ];
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];

	[notifyCenter addObserver : self
					 selector : @selector(inputSetChanged:)
						 name : ORCV977ModelInputSetChanged
					   object : model];
}

#pragma mark ***Interface Management
- (void) updateWindow
{
    [super updateWindow ];
	[self inputSetChanged:nil];
}

#pragma mark ***Interface Management - Module specific
- (NSString*) thresholdLockName  {return @"ORCV977SettingsLock";}
- (NSString*) basicLockName      {return @"ORCV977BasicLock";}

- (NSSize) thresholdDialogSize
{
	return NSMakeSize(610,200);
}

- (void) inputSetChanged:(NSNotification*)aNotification
{
	short i;
	unsigned long theMask = [model inputSet];
	for(i=0;i<16;i++){
		[[inputSetMatrix cellWithTag:i] setIntValue:(theMask&(1<<i))!=0];
	}
    [inputSetField setIntValue:theMask];
}

#pragma mark •••Actions
- (IBAction) inputSetAction:(id)sender
{
	[model setInputSetBit:[[sender selectedCell] tag] withValue:[sender intValue]];
}

@end
