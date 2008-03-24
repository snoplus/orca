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

	ORCalibration* calibration = [[contextInfo objectForKey:@"ObjectToCalibrate"] calibration];
	if(calibration){
		NSArray* calArray = [calibration calibrationArray];
		[[channelForm cellWithTag:0] setObjectValue:[calArray objectAtIndex:0]]; 
		[[channelForm cellWithTag:1] setObjectValue:[calArray objectAtIndex:1]]; 
		[[valueForm cellWithTag:0] setObjectValue:[calArray objectAtIndex:2]]; 
		[[valueForm cellWithTag:1] setObjectValue:[calArray objectAtIndex:3]]; 
		[unitsField setStringValue:[calibration units]];
		[ignoreButton setIntValue:[calibration ignoreCalibration]];
	}
	else {
		[[channelForm cellWithTag:0] setIntValue:0]; 
		[[channelForm cellWithTag:1] setIntValue:1000]; 
		[[valueForm cellWithTag:0] setFloatValue:0]; 
		[[valueForm cellWithTag:1] setFloatValue:1000]; 
		[unitsField setStringValue:@"Kev"];
		[ignoreButton setIntValue:NO];
	}
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
	NSArray* calArray = [NSArray arrayWithObjects:  [[channelForm cellWithTag:0] objectValue],
													[[channelForm cellWithTag:1] objectValue],
													[[valueForm   cellWithTag:0] objectValue],
													[[valueForm   cellWithTag:1] objectValue],nil];
	id cal		= [[ORCalibration alloc] initCalibrationArray:calArray];
	
	[cal setUnits:[unitsField stringValue]];
	[cal setIgnoreCalibration:[ignoreButton intValue]];
	[[contextInfo objectForKey:@"ObjectToCalibrate"] setCalibration:cal];
	[[contextInfo objectForKey:@"ObjectToUpdate"] postUpdate];
	[cal release];
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
	[super dealloc];
}

- (NSArray*)calibrationArray
{
	return calibrationArray;
}

- (void) calibrate
{
	int   c0 = [[calibrationArray objectAtIndex:0] intValue];
	int   c1 = [[calibrationArray objectAtIndex:1] intValue];
	float v0 = [[calibrationArray objectAtIndex:2] floatValue];
	float v1 = [[calibrationArray objectAtIndex:3] floatValue];
	if(c0 != c1){
		slope = (v1-v0)/(float)(c1-c0);
		intercept = (v0*c1 - v1*c0)/(float)(c1-c0);
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
    calibrationArray = [[decoder decodeObjectForKey:	@"calibrationArray"] retain];
	[self setUnits:[decoder decodeObjectForKey:@"units"]];
	[self setIgnoreCalibration:[decoder decodeBoolForKey:@"ignoreCalibration"]];
	[self calibrate];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:calibrationArray	forKey: @"calibrationArray"];
	[encoder encodeObject:units				forKey:@"units"];
	[encoder encodeBool:ignoreCalibration forKey:@"ignoreCalibration"];
}


@end
