//-------------------------------------------------------------------------
//  OREHS8260pController.h
//
//  Created by Mark Howe on Tues Feb 1,2011
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
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

#pragma mark ***Imported Files
#import "OREHS8260pController.h"
#import "OREHS8260pModel.h"

@implementation OREHS8260pController

-(id)init
{
    self = [super initWithWindowNibName:@"EHS8260p"];
    return self;
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
	
    [notifyCenter addObserver : self
                     selector : @selector(tripTimeChanged:)
                         name : OREHS8260pModelTripTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(supervisorMaskChanged:)
                         name : OREHS8260pModelSupervisorMaskChanged
						object: model];

}

- (void) updateWindow
{
    [super updateWindow];
 	[self tripTimeChanged:nil];
	[self supervisorMaskChanged:nil];
}

#pragma mark •••Interface Management
- (void) supervisorMaskChanged:(NSNotification*)aNote
{
//	[supervisorMask<custom> setIntValue: [model supervisorMask]];
}

- (void) tripTimeChanged:(NSNotification*)aNote
{
	int chan = [model selectedChannel];
	[tripTimeTextField setIntValue: [model tripTime:chan]];
    [self channelReadParamsChanged:nil]; //force reload of table
}

#pragma mark •••Actions

- (IBAction) tripTimeAction:(id)sender
{
	int chan = [model selectedChannel];

	[model setTripTime:chan withValue:[sender intValue]];
}


#pragma mark •••Data Source Methods
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
	if(aTableView == hvTableView){
		NSParameterAssert(rowIndex >= 0 && rowIndex < 8);
		if([[aTableColumn identifier] isEqualToString:@"channel"])return [NSNumber numberWithInt:rowIndex];
		else {
			if([[aTableColumn identifier] isEqualToString:@"outputSwitch"]){
				return [model channelState:rowIndex];
			}
			else if([[aTableColumn identifier] isEqualToString:@"target"]){
				return [NSNumber numberWithInt:[model target:rowIndex]];
			}
			else if([[aTableColumn identifier] isEqualToString:@"tripTime"]){
				return [NSNumber numberWithInt:[model tripTime:rowIndex]];
			}
			else if([[aTableColumn identifier] isEqualToString:@"maxCurrent"]){
				return [NSNumber numberWithFloat:[model maxCurrent:rowIndex]];
			}
			else if([[aTableColumn identifier] isEqualToString:@"outputMeasurementCurrent"]){
				float theCurrent = [model channel:rowIndex readParamAsFloat:[aTableColumn identifier]] *1000000.;
				return [NSNumber numberWithFloat:theCurrent];
			}
			else {
					//for now return value as object
				NSDictionary* theEntry = [model channel:rowIndex readParamAsObject:[aTableColumn identifier]];
				NSString* theValue = [theEntry objectForKey:@"Value"];
				if(theValue)return theValue;
				else return @"0";
			}
		}
		return @"--";
	}
	else return @"";
}

@end
