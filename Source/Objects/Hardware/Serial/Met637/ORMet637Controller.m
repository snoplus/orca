//--------------------------------------------------------
// ORMet637Controller
// Created by Mark  A. Howe on Mon Jan 23, 2012
// Code partially generated by the OrcaCodeWizard. Written by Mark A. Howe.
// Copyright (c) 2012 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Washington reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark ***Imported Files

#import "ORMet637Controller.h"
#import "ORMet637Model.h"
#import "ORSerialPortList.h"
#import "ORSerialPort.h"
#import "ORTimeLinePlot.h"
#import "ORCompositePlotView.h"
#import "ORTimeAxis.h"
#import "ORTimeRate.h"

@interface ORMet637Controller (private)
- (void) populatePortListPopup;
@end

@implementation ORMet637Controller

#pragma mark ***Initialization

- (id) init
{
	self = [super initWithWindowNibName:@"Met637"];
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void) awakeFromNib
{
    [self populatePortListPopup];

    [[plotter0 yAxis] setRngLow:0.0 withHigh:100.];
	[[plotter0 yAxis] setRngLimitsLow:0 withHigh:10000000. withMinRng:5];
	
    [[plotter0 xAxis] setRngLow:0.0 withHigh:10000];
	[[plotter0 xAxis] setRngLimitsLow:0.0 withHigh:200000. withMinRng:200];
	
	ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:0 andDataSource:self];
	[plotter0 addPlot: aPlot];
	[aPlot setLineColor:[NSColor redColor]];
	[aPlot setName:@"0.3 µm"];
	[aPlot release];
	
	aPlot = [[ORTimeLinePlot alloc] initWithTag:1 andDataSource:self];
	[plotter0 addPlot: aPlot];
	[aPlot setLineColor:[NSColor greenColor]];
	[aPlot setName:@"0.5 µm"];
	[aPlot release];
	
	aPlot = [[ORTimeLinePlot alloc] initWithTag:2 andDataSource:self];
	[plotter0 addPlot: aPlot];
	[aPlot setLineColor:[NSColor blueColor]];
	[aPlot setName:@"0.7 µm"];
	[aPlot release];
	
	aPlot = [[ORTimeLinePlot alloc] initWithTag:3 andDataSource:self];
	[plotter0 addPlot: aPlot];
	[aPlot setLineColor:[NSColor blackColor]];
	[aPlot setName:@"1.0 µm"];
	[aPlot release];
	
	aPlot = [[ORTimeLinePlot alloc] initWithTag:4 andDataSource:self];
	[plotter0 addPlot: aPlot];
	[aPlot setLineColor:[NSColor cyanColor]];
	[aPlot setName:@"2.0 µm"];
	[aPlot release];
	
	aPlot = [[ORTimeLinePlot alloc] initWithTag:5 andDataSource:self];
	[plotter0 addPlot: aPlot];
	[aPlot setLineColor:[NSColor orangeColor]];
	[aPlot setName:@"5.0 µm"];
	[aPlot release];
	
	
	[plotter0 setShowLegend:YES];

	[(ORTimeAxis*)[plotter0 xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];

	int i;
	for(i=0;i<6;i++){
		[[countAlarmLimitMatrix cellAtRow:i column:0] setTag:i];
		[[maxCountsMatrix cellAtRow:i column:0] setTag:i];
	}
	
	[super awakeFromNib];
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"Met637 (Unit %d)",[model uniqueIdNumber]]];
}

#pragma mark ***Notifications

- (void) registerNotificationObservers
{
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORMet637Lock
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(portNameChanged:)
                         name : ORMet637ModelPortNameChanged
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(portStateChanged:)
                         name : ORSerialPortStateChanged
                       object : nil];
                                              
    [notifyCenter addObserver : self
                     selector : @selector(measurementDateChanged:)
                         name : ORMet637ModelMeasurementDateChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(countChanged:)
                         name : ORMet637ModelCountChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(countingModeChanged:)
                         name : ORMet637ModelCountingModeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(cycleDurationChanged:)
                         name : ORMet637ModelCycleDurationChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(runningChanged:)
                         name : ORMet637ModelRunningChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(cycleStartedChanged:)
                         name : ORMet637ModelCycleStartedChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(cycleWillEndChanged:)
                         name : ORMet637ModelCycleWillEndChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(cycleNumberChanged:)
                         name : ORMet637ModelCycleNumberChanged
						object: model];

    [notifyCenter addObserver : self
					 selector : @selector(scaleAction:)
						 name : ORAxisRangeChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(miscAttributesChanged:)
						 name : ORMiscAttributesChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(updateTimePlot:)
						 name : ORRateAverageChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(maxCountsChanged:)
                         name : ORMet637ModelMaxCountsChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(countAlarmLimitChanged:)
                         name : ORMet637ModelCountAlarmLimitChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(temperatureChanged:)
                         name : ORMet637ModelTemperatureChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(humidityChanged:)
                         name : ORMet637ModelHumidityChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(statusBitsChanged:)
                         name : ORMet637ModelStatusBitsChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(countUnitsChanged:)
                         name : ORMet637ModelCountUnitsChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(tempUnitsChanged:)
                         name : ORMet637ModelTempUnitsChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(holdTimeChanged:)
                         name : ORMet637ModelHoldTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(isLogChanged:)
                         name : ORMet637ModelIsLogChanged
						object: model];
	
	
    [notifyCenter addObserver : self
                     selector : @selector(actualDurationChanged:)
                         name : ORMet637ModelActualDurationChanged
						object: model];	

    [notifyCenter addObserver : self
                     selector : @selector(timedOutChanged:)
                         name : ORMet637ModelTimedOutChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(dumpInProgressChanged:)
                         name : ORMet637ModelDumpInProgressChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(dumpCountChanged:)
                         name : ORMet637ModelDumpCountChanged
						object: model];

}

- (void) updateWindow
{
    [super updateWindow];
    [self lockChanged:nil];
    [self portStateChanged:nil];
    [self portNameChanged:nil];
	[self measurementDateChanged:nil];
	[self countChanged:nil];
	[self countingModeChanged:nil];
	[self cycleDurationChanged:nil];
	[self runningChanged:nil];
	[self cycleStartedChanged:nil];
	[self cycleWillEndChanged:nil];
	[self cycleNumberChanged:nil];
	[self updateTimePlot:nil];
    [self miscAttributesChanged:nil];
	[self maxCountsChanged:nil];
	[self countAlarmLimitChanged:nil];
	[self temperatureChanged:nil];
	[self humidityChanged:nil];
	[self statusBitsChanged:nil];
	[self countUnitsChanged:nil];
	[self tempUnitsChanged:nil];
	[self holdTimeChanged:nil];
	[self isLogChanged:nil];
	[self actualDurationChanged:nil];
	[self timedOutChanged:nil];
	[self dumpInProgressChanged:nil];
	[self dumpCountChanged:nil];
}

- (void) dumpCountChanged:(NSNotification*)aNote
{
	[dumpCountField setIntValue: [model dumpCount]];
}

- (void) dumpInProgressChanged:(NSNotification*)aNote
{
	[dumpInProgressField setStringValue: [model dumpInProgress]?@"Dumping":@"--"];
}

- (void) timedOutChanged:(NSNotification*)aNote
{
	[timedOutField setStringValue: [model timedOut]?@"Last Command Timed Out":@""];
}

- (void) isLogChanged:(NSNotification*)aNote
{
	[isLogCB setIntValue: [model isLog]];
	[[plotter0 yAxis] setLog:[model isLog]];
	[plotter0 setNeedsDisplay:YES];
}

- (void) holdTimeChanged:(NSNotification*)aNote
{
	[holdTimeField setIntValue: [model holdTime]];
}

- (void) actualDurationChanged:(NSNotification*)aNote
{
	[actualDurationField setIntValue: [model actualDuration]];
}

- (void) tempUnitsChanged:(NSNotification*)aNote
{
	[tempUnitsField setStringValue: [model tempUnits]==0?@"C":@"F"];
	[tempUnitsPU selectItemAtIndex: [model tempUnits]];
}

- (void) countUnitsChanged:(NSNotification*)aNote
{
	[countUnitsPU selectItemAtIndex: [model countUnits]]; 
	NSString* s = @"";
	if([model countUnits]==0)		s = @"Counts/Ft^3";
	else if([model countUnits]==1)	s = @"Counts/L^3";
	else if([model countUnits]==2)	s = @"Total Counts";
	[unitsField setStringValue:s];
	[plotter0 setYLabel:s];
}

- (void) statusBitsChanged:(NSNotification*)aNote
{
	int bits = [model statusBits];
	[batteryStatusField setStringValue: (bits & 0x10) ? @"BAD":@"OK"];
	[sensorStatusField  setStringValue:	(bits & 0x20) ? @"BAD":@"OK"];
	[flowStatusField    setStringValue:	(bits & 0x40) ? @"BAD":@"OK"];
}

- (void) humidityChanged:(NSNotification*)aNote
{
	[humidityField setFloatValue: [model humidity]];
}

- (void) temperatureChanged:(NSNotification*)aNote
{
	[temperatureField setFloatValue: [model temperature]];
}

- (void) countAlarmLimitChanged:(NSNotification*)aNote
{
	if(!aNote){
		int i;
		for(i=0;i<6;i++){
			[[countAlarmLimitMatrix cellWithTag:i] setIntValue:[model countAlarmLimit:i]];
		}
	}
	else {
		int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
		if(chan<6){
			[[countAlarmLimitMatrix cellWithTag:chan] setIntValue:[model countAlarmLimit:chan]];
		}
	}
}

- (void) maxCountsChanged:(NSNotification*)aNote
{
	if(!aNote){
		int i;
		for(i=0;i<6;i++){
			[[maxCountsMatrix cellWithTag:i] setFloatValue:[model maxCounts:i]];
		}
	}
	else {
		int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
		if(chan<6){
			[[maxCountsMatrix cellWithTag:chan] setFloatValue:[model maxCounts:chan]];
		}
	}
}

- (void) scaleAction:(NSNotification*)aNotification
{
	if(aNotification == nil || [aNotification object] == [plotter0 xAxis]){
		[model setMiscAttributes:[(ORAxis*)[plotter0 xAxis]attributes] forKey:@"XAttributes0"];
	};
	
	if(aNotification == nil || [aNotification object] == [plotter0 yAxis]){
		[model setMiscAttributes:[(ORAxis*)[plotter0 yAxis]attributes] forKey:@"YAttributes0"];
	};
}

- (void) miscAttributesChanged:(NSNotification*)aNote
{
	
	NSString*				key = [[aNote userInfo] objectForKey:ORMiscAttributeKey];
	NSMutableDictionary* attrib = [model miscAttributesForKey:key];
	
	if(aNote == nil || [key isEqualToString:@"XAttributes0"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"XAttributes0"];
		if(attrib){
			[(ORAxis*)[plotter0 xAxis] setAttributes:attrib];
			[plotter0 setNeedsDisplay:YES];
			[[plotter0 xAxis] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"YAttributes0"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"YAttributes0"];
		if(attrib){
			[(ORAxis*)[plotter0 yAxis] setAttributes:attrib];
			[plotter0 setNeedsDisplay:YES];
			[[plotter0 yAxis] setNeedsDisplay:YES];
		}
	}
}

- (void) updateTimePlot:(NSNotification*)aNote
{
	if(!aNote || ([aNote object] == [model timeRate:1])){
		[plotter0 setNeedsDisplay:YES];
	}
}

- (void) cycleStartedChanged:(NSNotification*)aNote
{	
	NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"%H:%M:%S" allowNaturalLanguage:NO];
	NSString* startDateString = [dateFormatter stringFromDate:[model cycleStarted]];
	
	[dateFormatter release];
	if(startDateString && [model running]) [cycleStartedField setStringValue:startDateString];
	else [cycleStartedField setStringValue:@"---"];
}

- (void) cycleWillEndChanged:(NSNotification*)aNote
{
	NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"%H:%M:%S" allowNaturalLanguage:NO];
	NSString* endDateString   = [dateFormatter stringFromDate:[model cycleWillEnd]];
	[dateFormatter release];
	if(endDateString && [model running]) {
		if([model countingMode] == kMet637Manual)[cycleWillEndField setStringValue:@"--"];
		else [cycleWillEndField setStringValue:endDateString];
	}
	else [cycleWillEndField setStringValue:@"---"];
}

- (void) cycleNumberChanged:(NSNotification*)aNote
{
	[cycleNumberField setIntValue: [model cycleNumber]];
}

- (void) runningChanged:(NSNotification*)aNote
{
	[self updateButtons];
	[runningField setStringValue:[model running]?@"Counting":@"Idle"];
	[self cycleStartedChanged:nil];
	[self cycleWillEndChanged:nil];
}

- (void) cycleDurationChanged:(NSNotification*)aNote
{
	[cycleDurationField setIntValue: [model cycleDuration]];
}

- (void) countingModeChanged:(NSNotification*)aNote
{
	[countingModePU selectItemAtIndex: [model countingMode]];
	[self updateButtons];
}

- (void) countChanged:(NSNotification*)aNote
{
	int i;
	for(i=0;i<6;i++){
		[[countMatrix cellAtRow:i column:0] setIntValue:[model count:i]];
	}
}

- (void) measurementDateChanged:(NSNotification*)aNote
{
	[measurementDateField setStringValue: [model measurementDate]];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORMet637Lock to:secure];
    [lockButton setEnabled:secure];
}

- (void) lockChanged:(NSNotification*)aNotification
{
	[self updateButtons];
}

- (void) updateButtons
{
    BOOL locked = [gSecurity isLocked:ORMet637Lock];

    [lockButton setState: locked];

    [portListPopup setEnabled:!locked];
    [openPortButton setEnabled:!locked];
    [openPortButton setEnabled:!locked];
    
	if(!locked){
		[startCycleButton setEnabled:![model running]];
		[stopCycleButton setEnabled:[model running]];
	}
	else {
		[startCycleButton setEnabled:NO];
		[stopCycleButton setEnabled:NO];
	}
	[holdTimeField setEnabled:![model running] && !locked && ([model countingMode]==kMet637Auto)];
	[cycleDurationField setEnabled:![model running] && !locked];
	[countingModePU setEnabled:![model running] && !locked];
	[countUnitsPU setEnabled:![model running] && !locked];
	[tempUnitsPU setEnabled:![model running] && !locked];
}

- (void) portStateChanged:(NSNotification*)aNotification
{
    if(aNotification == nil || [aNotification object] == [model serialPort]){
        if([model serialPort]){
            [openPortButton setEnabled:YES];

            if([[model serialPort] isOpen]){
                [openPortButton setTitle:@"Close"];
                [portStateField setTextColor:[NSColor colorWithCalibratedRed:0.0 green:.8 blue:0.0 alpha:1.0]];
                [portStateField setStringValue:@"Open"];
            }
            else {
                [openPortButton setTitle:@"Open"];
                [portStateField setStringValue:@"Closed"];
                [portStateField setTextColor:[NSColor redColor]];
            }
        }
        else {
            [openPortButton setEnabled:NO];
            [portStateField setTextColor:[NSColor blackColor]];
            [portStateField setStringValue:@"---"];
            [openPortButton setTitle:@"---"];
        }
    }
}

- (void) portNameChanged:(NSNotification*)aNotification
{
    NSString* portName = [model portName];
    
	NSEnumerator *enumerator = [ORSerialPortList portEnumerator];
	ORSerialPort *aPort;

    [portListPopup selectItemAtIndex:0]; //the default
    while (aPort = [enumerator nextObject]) {
        if([portName isEqualToString:[aPort name]]){
            [portListPopup selectItemWithTitle:portName];
            break;
        }
	}  
    [self portStateChanged:nil];
}

#pragma mark ***Actions

- (void) isLogAction:(id)sender
{
	[model setIsLog:[sender intValue]];	
}

- (void) holdTimeAction:(id)sender
{
	[model setHoldTime:[sender intValue]];	
}

- (IBAction) countingModeAction:(id)sender
{
	[model setCountingMode:[sender indexOfSelectedItem]];
}

- (IBAction) tempUnitsAction:(id)sender
{
	[model setTempUnits:[sender indexOfSelectedItem]];	
}

- (IBAction) countAlarmLimitAction:(id)sender
{
	[model setIndex:[[sender selectedCell] tag] countAlarmLimit:[[sender selectedCell] floatValue]];	
}

- (IBAction) maxCountsAction:(id)sender
{
	[model setIndex:[[sender selectedCell] tag] maxCounts:[[sender selectedCell] floatValue]];	
}

- (IBAction) startCycleAction:(id)sender
{
	[self endEditing];
	[model startCycle];	
}

- (IBAction) stopCycleAction:(id)sender
{
	[self endEditing];
	[model stopCycle];	
}

- (IBAction) cycleDurationAction:(id)sender
{
	[model setCycleDuration:[sender intValue]];	
}

- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORMet637Lock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) portListAction:(id) sender
{
    [model setPortName: [portListPopup titleOfSelectedItem]];
}

- (IBAction) openPortAction:(id)sender
{
    [model openPort:![[model serialPort] isOpen]];
}

- (IBAction) countUnitsAction:(id)sender
{
	[model setCountUnits:[sender indexOfSelectedItem]];
}

- (IBAction) dumpAllDataAction:(id)sender
{
	[model sendAllData];
}

- (IBAction) dumpNewDataAction:(id)sender
{
	[model sendNewData];
}

#pragma mark •••Data Source
- (int) numberPointsInPlot:(id)aPlotter
{
	return [[model timeRate:[aPlotter tag]]   count];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
	int set = [aPlotter tag];
	int count = [[model timeRate:set] count];
	int index = count-i-1;
	*yValue = [[model timeRate:set] valueAtIndex:index];
	*xValue = [[model timeRate:set] timeSampledAtIndex:index];
}

@end

@implementation ORMet637Controller (private)

- (void) populatePortListPopup
{
	NSEnumerator *enumerator = [ORSerialPortList portEnumerator];
	ORSerialPort *aPort;
    [portListPopup removeAllItems];
    [portListPopup addItemWithTitle:@"---"];

	while (aPort = [enumerator nextObject]) {
        [portListPopup addItemWithTitle:[aPort name]];
	}    
}

@end

