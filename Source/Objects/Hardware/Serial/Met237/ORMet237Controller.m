//--------------------------------------------------------
// ORMet237Controller
// Created by Mark  A. Howe on Fri Jul 22 2005
// Code partially generated by the OrcaCodeWizard. Written by Mark A. Howe.
// Copyright (c) 2005 CENPA, University of Washington. All rights reserved.
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

#import "ORMet237Controller.h"
#import "ORMet237Model.h"
#import "ORSerialPortList.h"
#import "ORSerialPort.h"
#import "ORTimeLinePlot.h"
#import "ORCompositePlotView.h"
#import "ORTimeAxis.h"
#import "ORTimeRate.h"

@interface ORMet237Controller (private)
- (void) populatePortListPopup;
@end

@implementation ORMet237Controller

#pragma mark ***Initialization

- (id) init
{
	self = [super initWithWindowNibName:@"Met237"];
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
	[[plotter0 yAxis] setRngLimitsLow:0 withHigh:1000. withMinRng:5];
	
    [[plotter0 xAxis] setRngLow:0.0 withHigh:10000];
	[[plotter0 xAxis] setRngLimitsLow:0.0 withHigh:200000. withMinRng:200];
	
	ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:0 andDataSource:self];
	[plotter0 addPlot: aPlot];
	[aPlot setLineColor:[NSColor redColor]];
	[aPlot setName:@"0.5 µm"];
	[aPlot release];

	aPlot = [[ORTimeLinePlot alloc] initWithTag:1 andDataSource:self];
	[plotter0 addPlot: aPlot];
	[aPlot setLineColor:[NSColor blueColor]];
	[aPlot setName:@"5 µm"];
	[aPlot release];
	
	[plotter0 setYLabel:@"Counts/Ft^3/Min"];
	[plotter0 setShowLegend:YES];

	[(ORTimeAxis*)[plotter0 xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];

	[super awakeFromNib];
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"Met237 (Unit %d)",[model uniqueIdNumber]]];
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
                         name : ORMet237Lock
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(portNameChanged:)
                         name : ORMet237ModelPortNameChanged
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(portStateChanged:)
                         name : ORSerialPortStateChanged
                       object : nil];
                                              
    [notifyCenter addObserver : self
                     selector : @selector(measurementDateChanged:)
                         name : ORMet237ModelMeasurementDateChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(size1Changed:)
                         name : ORMet237ModelSize1Changed
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(size2Changed:)
                         name : ORMet237ModelSize2Changed
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(count1Changed:)
                         name : ORMet237ModelCount1Changed
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(count2Changed:)
                         name : ORMet237ModelCount2Changed
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(countingModeChanged:)
                         name : ORMet237ModelCountingModeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(cycleDurationChanged:)
                         name : ORMet237ModelCycleDurationChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(runningChanged:)
                         name : ORMet237ModelRunningChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(cycleStartedChanged:)
                         name : ORMet237ModelCycleStartedChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(cycleWillEndChanged:)
                         name : ORMet237ModelCycleWillEndChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(cycleNumberChanged:)
                         name : ORMet237ModelCycleNumberChanged
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
                         name : ORMet237ModelMaxCountsChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(countAlarmLimitChanged:)
                         name : ORMet237ModelCountAlarmLimitChanged
						object: model];

}

- (void) updateWindow
{
    [super updateWindow];
    [self lockChanged:nil];
    [self portStateChanged:nil];
    [self portNameChanged:nil];
	[self measurementDateChanged:nil];
	[self size1Changed:nil];
	[self size2Changed:nil];
	[self count1Changed:nil];
	[self count2Changed:nil];
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
}

- (void) countAlarmLimitChanged:(NSNotification*)aNote
{
	[countAlarmLimitTextField setFloatValue: [model countAlarmLimit]];
}

- (void) maxCountsChanged:(NSNotification*)aNote
{
	[maxCountsTextField setFloatValue: [model maxCounts]];
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
	NSString* dateString = [dateFormatter stringFromDate:[model cycleStarted]];
	
	[dateFormatter release];
	if(dateString) [cycleStartedField setStringValue:dateString];
	else [cycleStartedField setStringValue:@"---"];
	
}

- (void) cycleWillEndChanged:(NSNotification*)aNote
{
	NSDate* now = [NSDate date];
	NSDate* timeCycleWillEnd = [model cycleWillEnd];
	NSTimeInterval  timeLeft = [timeCycleWillEnd timeIntervalSinceDate:now];
	[timeLeftInCycleField setIntValue:(int)ceil(timeLeft)];
}

- (void) cycleNumberChanged:(NSNotification*)aNote
{
	[cycleNumberField setIntValue: [model cycleNumber]];
}

- (void) runningChanged:(NSNotification*)aNote
{
	[self updateButtons];
}

- (void) cycleDurationChanged:(NSNotification*)aNote
{
	[cycleDurationPU selectItemWithTag: [model cycleDuration]];
}

- (void) countingModeChanged:(NSNotification*)aNote
{
	[countingModeTextField setStringValue: [model countingModeString]];
}

- (void) count2Changed:(NSNotification*)aNote
{
	[count2TextField setIntValue: [model count2]];
}

- (void) count1Changed:(NSNotification*)aNote
{
	[count1TextField setIntValue: [model count1]];
}

- (void) size2Changed:(NSNotification*)aNote
{
	[size2TextField setFloatValue: [model size2]];
}

- (void) size1Changed:(NSNotification*)aNote
{
	[size1TextField setFloatValue: [model size1]];
}

- (void) measurementDateChanged:(NSNotification*)aNote
{
	[measurementDateTextField setStringValue: [model measurementDate]];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORMet237Lock to:secure];
    [lockButton setEnabled:secure];
}

- (void) lockChanged:(NSNotification*)aNotification
{
	[self updateButtons];
}

- (void) updateButtons
{
    BOOL locked = [gSecurity isLocked:ORMet237Lock];

    [lockButton setState: locked];

    [portListPopup setEnabled:!locked];
    [openPortButton setEnabled:!locked];
    
	if(!locked){
		[startCycleButton setEnabled:![model running]];
		[stopCycleButton setEnabled:[model running]];
	}
	else {
		[startCycleButton setEnabled:NO];
		[stopCycleButton setEnabled:NO];
	}
	[cycleDurationPU setEnabled:![model running] && !locked];

	if([model running]){
		NSDate* now = [NSDate date];
		NSDate* timeCycleWillEnd = [model cycleWillEnd];
		NSTimeInterval  timeLeft = [timeCycleWillEnd timeIntervalSinceDate:now];
		[timeLeftInCycleField setIntValue:(int)ceil(timeLeft)];
		
	}
	else {
		[timeLeftInCycleField setStringValue:@"---"];
		[cycleStartedField setStringValue:@"---"];
	}
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

- (void) countAlarmLimitTextFieldAction:(id)sender
{
	[model setCountAlarmLimit:[sender floatValue]];	
}

- (void) maxCountsTextFieldAction:(id)sender
{
	[model setMaxCounts:[sender floatValue]];	
}
- (IBAction) startCycleAction:(id)sender
{
	[model startCycle];	
}

- (IBAction) stopCycleAction:(id)sender
{
	[model stopCycle];	
}

- (IBAction) cycleDurationAction:(id)sender
{
	[model setCycleDuration:[[sender selectedItem]tag]];	
}

- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORMet237Lock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) portListAction:(id) sender
{
    [model setPortName: [portListPopup titleOfSelectedItem]];
}

- (IBAction) openPortAction:(id)sender
{
    [model openPort:![[model serialPort] isOpen]];
}

- (IBAction) initAction:(id)sender
{
	[model initHardware];
}

- (IBAction) startCountingAction:(id)sender
{
	[model startCountingByComputer];
}

- (IBAction) stopCountingAction:(id)sender
{
	[model stopCounting];
}

- (IBAction) getNumberRecordsAction:(id)sender
{
	[model getNumberRecords];
}

- (IBAction) readRecordAction:(id)sender
{
	[model getRecord];
}

- (IBAction) clearBufferAction:(id)sender
{
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

@implementation ORMet237Controller (private)

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

