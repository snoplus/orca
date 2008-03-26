//  ORCalibrationPane.m
//  Orca
//
//  Created by Mark Howe on 3/21/08.
//  Copyright 2008 CENPA, University of Washington. All rights reserved.
//
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

#import "ORCalibration.h"

@implementation ORCalibrationPane

+ (id) calibrateForWindow:(NSWindow *)aWindow modalDelegate:(id)aDelegate didEndSelector:(SEL)aDidEndSelector contextInfo:(id)aContextInfo
{
    ORCalibrationPane* calibrationPane = [[ORCalibrationPane alloc] initWithContext:aContextInfo];
    [calibrationPane beginSheetFor:aWindow delegate:aDelegate didEndSelector:aDidEndSelector contextInfo:aContextInfo];
    return [calibrationPane autorelease];
}

- (id) initWithContext:(id)aContext 
{
    self = [super initWithWindowNibName:@"Calibration"];
	[self setContext:aContext];
	return self;
}

- (void) dealloc
{
	[contextInfo release];
	[super dealloc];
}

- (void) awakeFromNib
{
	[self populateSelectionPU];
	ORCalibration* calibration = [[contextInfo objectForKey:@"ObjectToCalibrate"] calibration];
	[self loadUI:calibration];
}

- (void) loadUI:(ORCalibration*) aCalibration
{
	if(aCalibration){
		NSArray* calArray = [aCalibration calibrationArray];
		[[channelForm cellWithTag:0] setObjectValue:[calArray objectAtIndex:0]]; 
		[[channelForm cellWithTag:1] setObjectValue:[calArray objectAtIndex:1]]; 
		[[valueForm cellWithTag:0] setObjectValue:[calArray objectAtIndex:2]]; 
		[[valueForm cellWithTag:1] setObjectValue:[calArray objectAtIndex:3]]; 
		[unitsField setStringValue:[aCalibration units]];
		[nameField setStringValue:[aCalibration calibrationName]];
		[ignoreButton setIntValue:[aCalibration ignoreCalibration]];
		[catalogButton setIntValue:[aCalibration type]];
		[customButton setIntValue:![aCalibration type]];
		if([[aCalibration calibrationName] length]){
			if([selectionPU indexOfItemWithTitle:[aCalibration calibrationName]] >=0){
				[selectionPU selectItemWithTitle:[aCalibration calibrationName]];
			}
			else [selectionPU selectItemWithTitle:@"---"];;
		}
		else [selectionPU selectItemWithTitle:@"---"];
	}
	else {
		[[channelForm cellWithTag:0] setFloatValue:0]; 
		[[channelForm cellWithTag:1] setFloatValue:1000]; 
		[[valueForm cellWithTag:0] setFloatValue:0]; 
		[[valueForm cellWithTag:1] setFloatValue:1000]; 
		[unitsField setStringValue:@"keV"];
		[ignoreButton setIntValue:NO];
		[nameField setStringValue:@""];
		[catalogButton setIntValue:0];
		[customButton setIntValue:1];
		[selectionPU selectItemWithTitle:@"---"];
	}
	[self enableControls];

}

- (void) setContext:(NSDictionary*)someContext;
{
	[someContext retain];
	[contextInfo release];
	contextInfo = someContext;
}

- (void) beginSheetFor:(NSWindow *)aWindow delegate:(id)aDelegate didEndSelector:(SEL)aDidEndSelector contextInfo:(id)aContextInfo
{
    [NSApp beginSheet:[self window] modalForWindow:aWindow modalDelegate:aDelegate didEndSelector:aDidEndSelector contextInfo:aContextInfo];
}

- (void) calibrate
{
	if(![[self window] makeFirstResponder:[self window]]){
		[[self window] endEditingFor:nil];		
	}
	NSArray* calArray = [NSArray arrayWithObjects:  [[channelForm cellWithTag:0] objectValue],
													[[channelForm cellWithTag:1] objectValue],
													[[valueForm   cellWithTag:0] objectValue],
													[[valueForm   cellWithTag:1] objectValue],nil];
	id cal		= [[ORCalibration alloc] initCalibrationArray:calArray];
	[cal setUnits:[unitsField stringValue]];
	[cal setCalibrationName:[nameField stringValue]];
	[cal setType:[customButton intValue]];
	[cal setIgnoreCalibration:[ignoreButton intValue]];
	
	if([storeButton intValue]== 1 && [[nameField stringValue] length]){
	
		NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
		NSMutableDictionary* calDic = [NSMutableDictionary dictionaryWithDictionary:[defaults dictionaryForKey:@"ORCACalibrations"]];
		if(!calDic) calDic = [NSMutableDictionary dictionaryWithCapacity:10];
			
		NSMutableData*   calAsData     = [NSMutableData data];
		NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:calAsData];
		[archiver encodeObject:cal forKey:@"aCalibration"];
		[archiver finishEncoding];		
		
		[calDic setObject:calAsData forKey:[nameField stringValue]];
		[defaults setObject:calDic forKey:@"ORCACalibrations"];
		
		[defaults synchronize];
		
		[self populateSelectionPU];
		[selectionPU selectItemWithTitle:[nameField stringValue]];
	}
	[[contextInfo objectForKey:@"ObjectToCalibrate"] setCalibration:cal];
	[[contextInfo objectForKey:@"ObjectToUpdate"] postUpdate];
	[cal release];
}

- (void) populateSelectionPU
{
	[selectionPU removeAllItems];
	[selectionPU addItemWithTitle:@"---"];
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary* calDictionary = [defaults objectForKey:@"ORCACalibrations"];
	NSArray* keys = [calDictionary allKeys];
	if([keys count]){
		NSArray* sortedKeys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
		[selectionPU addItemsWithTitles:sortedKeys];
	}
}

- (void) enableControls
{
	[channelForm  setEnabled: [customButton intValue]  == 1];
	[valueForm    setEnabled: [customButton intValue]  == 1];
	[unitsField   setEnabled: [customButton intValue]  == 1];
	[nameField    setEnabled: [customButton intValue]  == 1 && [storeButton intValue] == 1];
	[storeButton  setEnabled: [customButton intValue]  == 1];
	
	[selectionPU  setEnabled: [catalogButton intValue] == 1];
	[deleteButton setEnabled: [catalogButton intValue] == 1 &&  [selectionPU indexOfSelectedItem] != 0];
	
	[cancelButton setEnabled:[customButton intValue]  == 1];
	[applyButton setEnabled:[customButton intValue]  == 1];
}

- (IBAction) storeAction:(id)sender
{
	[self enableControls];
}

- (IBAction) typeAction:(id)sender
{
	if(sender == customButton){
		[catalogButton setIntValue:0];
		[customButton setIntValue:1];
	}
	else {
		[catalogButton setIntValue:1];
		[customButton setIntValue:0];
	}
	[self enableControls];
}

- (IBAction) selectionAction:(id)sender
{
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary* calDic = [defaults objectForKey:@"ORCACalibrations"];
	NSData*   calAsData     = [calDic objectForKey:[selectionPU titleOfSelectedItem]];
	if(calAsData){
		NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:calAsData];
		ORCalibration* cal = [unarchiver decodeObjectForKey:@"aCalibration"];
		[cal setType:1];
		[cal setCalibrationName:[selectionPU titleOfSelectedItem]];
		[unarchiver finishDecoding];
		[unarchiver release];
		[self loadUI:cal];
	}
	else [self loadUI:nil];

	[self calibrate];
}

- (IBAction) deleteAction:(id)sender
{	
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary* calDic = [defaults objectForKey:@"ORCACalibrations"];
	[calDic removeObjectForKey:[selectionPU titleOfSelectedItem]];
	[self populateSelectionPU];
	[selectionPU selectItemAtIndex:0];
	[self loadUI:nil];
	if([selectionPU numberOfItems] > 1){
		[catalogButton setIntValue:1]; 
		[customButton setIntValue:0]; 
	}
	else {
		[catalogButton setIntValue:0]; 
		[customButton setIntValue:1]; 
	}
	[self enableControls];
}

- (IBAction) apply:(id)sender
{	
	[self calibrate];
}

- (IBAction) done:(id)sender
{	
	[self calibrate];
	[[self window] orderOut:self];
    [NSApp endSheet:[self window] returnCode:NSOKButton];

}

- (IBAction) cancel:(id)sender
{
    [[self window] orderOut:self];
    [NSApp endSheet:[self window] returnCode:NSCancelButton];
}

@end

@implementation ORCalibration
- (id) initCalibrationArray:(NSArray*)calArray
{
	self = [super init];
	calibrationArray = [calArray retain];
	[self calibrate];	
	return self;
}

- (void)dealloc
{
	[calibrationArray release];
	[calibrationName release];
	[super dealloc];
}

- (NSArray*)calibrationArray
{
	return calibrationArray;
}

- (void) calibrate
{
	float c0 = [[calibrationArray objectAtIndex:0] floatValue];
	float c1 = [[calibrationArray objectAtIndex:1] floatValue];
	float v0 = [[calibrationArray objectAtIndex:2] floatValue];
	float v1 = [[calibrationArray objectAtIndex:3] floatValue];
	if(c0 != c1){
		slope = (v1-v0)/(c1-c0);
		intercept = (v0*c1 - v1*c0)/(c1-c0);
		calibrationValid = YES;
	}
	else {
		calibrationValid = NO;
	}
}


- (float) slope
{
	return slope;
}

- (float) intercept
{
	return intercept;
}

- (BOOL) ignoreCalibration
{
	return ignoreCalibration;
}

- (void) setIgnoreCalibration:(BOOL)aState
{
	ignoreCalibration = aState;
}

- (void) setType:(int)aType
{
	type = aType;
}

- (int) type
{
	return type;
}

- (NSString*) units
{
	if(!units)return @"";
	else return units;
}

- (void) setUnits:(NSString*)unitString
{
	if(!unitString) unitString = @"";
	[units autorelease];
	units = [unitString copy];
}

- (void) setCalibrationName:(NSString*)nameString
{
	if(!nameString) nameString = @"";
	[calibrationName autorelease];
	calibrationName = [nameString copy];
}

- (NSString*) calibrationName
{
	return calibrationName;
}

- (BOOL) useCalibration
{
	return !ignoreCalibration && calibrationValid;
}

- (float) convertedValueForChannel:(float)aChannel
{
	return aChannel*slope + intercept;
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self		= [super init];
    calibrationArray =			[[decoder decodeObjectForKey:	@"calibrationArray"] retain];
	[self setUnits:				[decoder decodeObjectForKey:@"units"]];
	[self setIgnoreCalibration:	[decoder decodeBoolForKey:@"ignoreCalibration"]];
	[self setCalibrationName:	[decoder decodeObjectForKey:@"calibrationName"]];
	[self calibrate];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:calibrationArray	forKey: @"calibrationArray"];
	[encoder encodeObject:units				forKey:@"units"];
	[encoder encodeBool:ignoreCalibration	forKey:@"ignoreCalibration"];
	[encoder encodeObject:calibrationName	forKey:@"calibrationName"];
}


@end
