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
		
		calibrationArray = [aCalibration calibrationArray];
		[calibrationTableView reloadData];
		
		[unitsField setStringValue:[aCalibration units]];
		[labelField setStringValue:[aCalibration label]];
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

		[unitsField setStringValue:@"keV"];
		[labelField setStringValue:@"Energy"];
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

	ORCalibration* cal		= [[ORCalibration alloc] initCalibrationArray:calibrationArray];
	[cal setUnits:[unitsField stringValue]];
	[cal setLabel:[labelField stringValue]];
	[cal setCalibrationName:[nameField stringValue]];
	[cal setType:![customButton intValue]];
	[cal setIgnoreCalibration:[ignoreButton intValue]];
	
	if([storeButton intValue]== 1 && [[nameField stringValue] length]){
	
		NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
		NSMutableDictionary* calDic = [NSMutableDictionary dictionaryWithDictionary:[defaults dictionaryForKey:@"ORCACalibrations"]];
		if(!calDic) calDic = [NSMutableDictionary dictionaryWithCapacity:10];
			
		NSMutableData*   calAsData     = [NSMutableData data];
		NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:calAsData];
		[archiver encodeObject:cal forKey:@"aCalibration"];
		[archiver finishEncoding];		
		[archiver release];
		
		[calDic setObject:calAsData forKey:[nameField stringValue]];
		[defaults setObject:calDic forKey:@"ORCACalibrations"];
		
		[defaults synchronize];
		
		[self populateSelectionPU];
		[selectionPU selectItemWithTitle:[nameField stringValue]];
	}
	[[contextInfo objectForKey:@"ObjectToCalibrate"] setCalibration:cal];
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
	[calibrationTableView  setEnabled: [customButton intValue]  == 1];
	[addPtButton	 setEnabled: [customButton intValue]  == 1];
	[removePtButton  setEnabled: [customButton intValue]  == 1];
	[unitsField   setEnabled: [customButton intValue]  == 1];
	[labelField   setEnabled: [customButton intValue]  == 1];
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
	NSMutableDictionary* calDic = [NSMutableDictionary dictionaryWithDictionary:[defaults dictionaryForKey:@"ORCACalibrations"]];
	[calDic removeObjectForKey:[selectionPU titleOfSelectedItem]];
	[defaults setObject:calDic forKey:@"ORCACalibrations"];
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

- (IBAction) addPtAction:(id)sender
{
	if(!calibrationArray)calibrationArray = [[NSMutableArray alloc] init];
	[calibrationArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:0],@"Channel",[NSNumber numberWithFloat:0],@"Energy",nil]];
	[calibrationTableView reloadData];
}

- (IBAction) removePtAction:(id)sender
{
	NSInteger selectedRow = [calibrationTableView selectedRow];
	if(selectedRow == -1){
		[calibrationArray removeLastObject];
		[calibrationTableView reloadData];
	}
	else if(selectedRow<[calibrationArray count]){
		[calibrationArray removeObjectAtIndex:selectedRow];
		[calibrationTableView reloadData];
	}
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

#pragma mark •••Table Data Source
- (int) numberOfRowsInTableView:(NSTableView *)aTableView
{
	if( aTableView == calibrationTableView)return [calibrationArray count];
	else return 0;
}

- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
	if(aTableView == calibrationTableView ){
		return [[calibrationArray objectAtIndex:rowIndex] objectForKey:[aTableColumn identifier]];
	}
	else return nil;
}

- (void) tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if(aTableView == calibrationTableView){
		[[calibrationArray objectAtIndex:rowIndex] setObject: anObject forKey:[aTableColumn identifier]];
	}
}

@end

@implementation ORCalibration
- (id) initCalibrationArray:(NSMutableArray*)calArray
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

- (NSMutableArray*)calibrationArray
{
	return calibrationArray;
}

- (void) calibrate
{
	double SUMx = 0;
	double SUMy = 0;
	double SUMxy= 0;
	double SUMxx= 0;
	calibrationValid = NO;
	int n = [calibrationArray count];
	if(n!=0){
		for(id pt in calibrationArray){
			double x = [[pt objectForKey:@"Channel"] doubleValue];
			double y = [[pt objectForKey:@"Energy"] doubleValue];
			SUMx = SUMx + x;
			SUMy = SUMy + y;
			SUMxy = SUMxy + x*y;
			SUMxx = SUMxx + x*x;
		}
		if((SUMx*SUMx - n*SUMxx) != 0){
			slope = ( SUMx*SUMy - n*SUMxy ) / (SUMx*SUMx - n*SUMxx);
			intercept = ( SUMy - slope*SUMx ) / n;
			calibrationValid = YES;
		}
	}
}


- (double) slope
{
	return slope;
}

- (double) intercept
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


- (NSString*) label
{
	if(!label)return @"Energy";
	else return label;
}

- (void) setLabel:(NSString*)aString
{
	if(!aString) label = @"Energy";
	[label autorelease];
	label = [aString copy];
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

- (double) convertedValueForChannel:(int)aChannel
{
	return (double)aChannel*slope + intercept;
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self		= [super init];
    calibrationArray =			[[decoder decodeObjectForKey:	@"calibrationArray"] retain];
	//check if we need to be backward compatible with the old form which used just an array
	if(![[calibrationArray objectAtIndex:0] isKindOfClass:NSClassFromString(@"NSMutableDictionary")]){
		int i;
		int n = [calibrationArray count];
		NSMutableArray* newArray = [NSMutableArray array];
		if(n%2 == 0){
			for(i=0;i<n;i+=2){
				id chan = [calibrationArray objectAtIndex:i];
				id energy = [calibrationArray objectAtIndex:i+1];
				[newArray addObject:[NSMutableDictionary dictionaryWithObject:chan forKey:@"Channel"]];
				[newArray addObject:[NSMutableDictionary dictionaryWithObject:energy forKey:@"Energy"]];
			}
			[calibrationArray release];
			calibrationArray = [newArray retain];
		}
		else {
			[calibrationArray release];
			calibrationArray = nil;
		}
	}
	
	[self setUnits:				[decoder decodeObjectForKey:@"units"]];
	[self setLabel:				[decoder decodeObjectForKey:@"label"]];
	[self setIgnoreCalibration:	[decoder decodeBoolForKey:@"ignoreCalibration"]];
	[self setCalibrationName:	[decoder decodeObjectForKey:@"calibrationName"]];
	[self setType:				[decoder decodeIntForKey:@"type"]];
	[self calibrate];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:calibrationArray	forKey: @"calibrationArray"];
	[encoder encodeObject:units				forKey:@"units"];
	[encoder encodeObject:label				forKey:@"label"];
	[encoder encodeBool:ignoreCalibration	forKey:@"ignoreCalibration"];
	[encoder encodeObject:calibrationName	forKey:@"calibrationName"];
	[encoder encodeInt:type					forKey:@"type"];
}


@end
