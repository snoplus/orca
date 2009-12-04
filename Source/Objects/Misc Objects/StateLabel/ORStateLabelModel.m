//
//  ORStateLabelModel.m
//  Orca
//
//  Created by Mark Howe on Fri Dec 4,2009.
//  Copyright © 2009 University of North Carolina. All rights reserved.
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
#import "ORStateLabelModel.h"
#import "ORCommandCenter.h"

NSString* ORLabelModelBoolTypeChanged = @"ORLabelModelBoolTypeChanged";

@interface ORStateLabelModel (private)
- (NSString*) stringToDisplay;
@end

@implementation ORStateLabelModel

#pragma mark •••initialization
- (id) init
{
    self = [super init];
	[self setLabelType:kDynamicLabel];
    return self;
}

- (void) makeMainController
{
    [self linkToController:@"ORStateLabelController"];
}

#pragma mark ***Accessors
- (int) boolType
{
	return boolType;
}

- (void) setBoolType:(int)aType
{
	[[[self undoManager] prepareWithInvocationTarget:self] setLabelType:labelType];
	boolType = aType;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabelModelBoolTypeChanged object:self];
	[self setUpImage];
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
	[self setBoolType:	[decoder decodeIntForKey: @"boolType"]];
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	[encoder encodeInt:boolType	forKey:@"boolType"];
}

@end

@implementation ORStateLabelModel (private)
- (NSString*) boolString:(BOOL)aValue
{
	switch(boolType){
		case 0: return aValue?@"Open":@"Closed";
		case 1: return aValue?@"Closed":@"Open";
		case 2: return aValue?@"Yes":@"No";
		case 3: return aValue?@"No":@"Yes";
		case 4: return aValue?@"Yes":@"No";
		default:return aValue?@"1":@"0";
	}
}

- (NSString*) stringToDisplay
{
	NSString* s = @"";
	int i;
	int n = [displayValues count];
	NSArray* formats = [displayFormat componentsSeparatedByString:@"\n"];
	NSString* aPrefix;
	for(i=0;i<n;i++){
		id displayValue = [displayValues objectAtIndex:i];
		if(i<[formats count]) aPrefix = [formats objectAtIndex:i];
		else				  aPrefix = @"";
		
		s = [s stringByAppendingFormat:@"%@%@\n",aPrefix,displayValue==nil?@"?":[self boolString:[displayValue boolValue]]];		

	}
	if([s hasSuffix:@"\n"])s = [s substringToIndex:[s length]-1];
	
	return s;
}
@end
