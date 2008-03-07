//
//  ORKatrinFLTController.m
//  Orca
//
//  Created by Mark Howe on Wed Aug 24 2005.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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


#pragma mark ¥¥¥Imported Files
#import "ORKatrinFLTController.h"
#import "ORKatrinFLTModel.h"
#import "ORIpeFLTDefs.h"
#import "ORFireWireInterface.h"
#import "ORPlotter1D.h"
#import "ORValueBar.h"
#import "ORAxis.h"
#import "ORTimeRate.h"

@implementation ORKatrinFLTController

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"KatrinFLT"];
    
    return self;
}

#pragma mark ¥¥¥Initialization
- (void) dealloc
{
	[rateFormatter release];
	[blankView release];
    [super dealloc];
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    settingSize     = NSMakeSize(546,680);
    histogramSize   = NSMakeSize(550,680);  // new -tb- 2008-01
    rateSize	    = NSMakeSize(430,615);
    testSize	    = NSMakeSize(400,500);

	rateFormatter = [[NSNumberFormatter alloc] init];
	[rateFormatter setFormat:@"##0.00"];
	[totalHitRateField setFormatter:rateFormatter];

    blankView = [[NSView alloc] init];
    
    NSString* key = [NSString stringWithFormat: @"orca.ORKatrinFLT%d.selectedtab",[model stationNumber]];
    int index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];

	ORValueBar* bar = rate0;
	do {
		[bar setBackgroundColor:[NSColor whiteColor]];
		[bar setBarColor:[NSColor greenColor]];
		bar = [bar chainedView];
	}while(bar!=nil);
	
	[totalRate setBackgroundColor:[NSColor whiteColor]];
	[totalRate setBarColor:[NSColor greenColor]];

    //setup the histogramming stuff
    //NSArray histogramData;    //TODO: store the histogram somewhere -tb-
    //double *histogramData=new double [1024];
    //[eSamplePopUpButton removeAllItems];
    int i;
    #if 0
    [eSamplePopUpButton insertItemWithTitle: @"0 (1)" atIndex: 0];
    [eSamplePopUpButton insertItemWithTitle: @"1 (2)" atIndex: 1];
    [eSamplePopUpButton insertItemWithTitle: @"2 (4)" atIndex: 2];
    [eSamplePopUpButton insertItemWithTitle: @"3 (8)" atIndex: 3];
    [eSamplePopUpButton insertItemWithTitle: @"4 (16)" atIndex: 4];
    [eSamplePopUpButton insertItemWithTitle: @"5 (32)" atIndex: 5];
    [eSamplePopUpButton insertItemWithTitle: @"6 (64)" atIndex: 6];
    [eSamplePopUpButton insertItemWithTitle: @"7 (128)" atIndex: 7];
    [eSamplePopUpButton insertItemWithTitle: @"8 (256)" atIndex: 8];
    [eSamplePopUpButton selectItemAtIndex: 2];//TODO: get it from config file -tb-
NSLog(@"Awaking from NIB ...\n");
    #endif

    [self updateWindow];
}

#pragma mark ¥¥¥Accessors

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORKatrinFLTSettingsLock
                        object: nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(slotChanged:)
						 name : ORIpeCardSlotChangedNotification
					   object : model];


    [notifyCenter addObserver : self 
                     selector : @selector(fltRunModeChanged:)
                         name : ORKatrinFLTModelFltRunModeChanged
                       object : model];
					   
    [notifyCenter addObserver : self
                     selector : @selector(daqRunModeChanged:)
                         name : ORKatrinFLTModelDaqRunModeChanged
                       object : model];
					   
    [notifyCenter addObserver : self
					 selector : @selector(thresholdChanged:)
						 name : ORKatrinFLTModelThresholdChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(gainChanged:)
						 name : ORKatrinFLTModelGainChanged
					   object : model];

   [notifyCenter addObserver : self
					 selector : @selector(triggerEnabledChanged:)
						 name : ORKatrinFLTModelTriggerEnabledChanged
					   object : model];

   [notifyCenter addObserver : self
					 selector : @selector(hitRateEnabledChanged:)
						 name : ORKatrinFLTModelHitRateEnabledChanged
					   object : model];

   [notifyCenter addObserver : self
					 selector : @selector(triggersEnabledArrayChanged:)
						 name : ORKatrinFLTModelTriggersEnabledChanged
					   object : model];

   [notifyCenter addObserver : self
					 selector : @selector(hitRatesEnabledArrayChanged:)
						 name : ORKatrinFLTModelHitRatesArrayChanged
					   object : model];


    [notifyCenter addObserver : self
					 selector : @selector(gainArrayChanged:)
						 name : ORKatrinFLTModelGainsChanged
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(thresholdArrayChanged:)
						 name : ORKatrinFLTModelThresholdsChanged
					   object : model];
					   
    [notifyCenter addObserver : self
					 selector : @selector(shapingTimesArrayChanged:)
						 name : ORKatrinFLTModelShapingTimesChanged
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(shapingTimeChanged:)
						 name : ORKatrinFLTModelShapingTimeChanged
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(hitRateLengthChanged:)
						 name : ORKatrinFLTModelHitRateLengthChanged
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(hitRateChanged:)
						 name : ORKatrinFLTModelHitRateChanged
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(scaleAction:)
						 name : ORAxisRangeChangedNotification
					   object : nil];

    [notifyCenter addObserver : self
					 selector : @selector(miscAttributesChanged:)
						 name : ORMiscAttributesChanged
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(totalRateChanged:)
						 name : ORRateAverageChangedNotification
					   object : [model totalRate]];

    [notifyCenter addObserver : self
					 selector : @selector(broadcastTimeChanged:)
						 name : ORKatrinFLTModelBroadcastTimeChanged
					   object : model];

    [notifyCenter addObserver : self
                     selector : @selector(testEnabledArrayChanged:)
                         name : ORKatrinFLTModelTestEnabledArrayChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(testStatusArrayChanged:)
                         name : ORKatrinFLTModelTestStatusArrayChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(updateWindow)
                         name : ORKatrinFLTModelTestsRunningChanged
                       object : model];


    [notifyCenter addObserver : self
                     selector : @selector(testParamChanged:)
                         name : ORKatrinFLTModelTestParamChanged
                       object : model];


    [notifyCenter addObserver : self
                     selector : @selector(patternChanged:)
                         name : ORKatrinFLTModelTestPatternsChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(tModeChanged:)
                         name : ORKatrinFLTModelTModeChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(numTestPattersChanged:)
                         name : ORKatrinFLTModelTestPatternCountChanged
                       object : model];
					   
    [notifyCenter addObserver : self
					 selector : @selector(readoutPagesChanged:)
						 name : ORKatrinFLTModelReadoutPagesChanged
					   object : model];


    [notifyCenter addObserver : self
                     selector : @selector(checkWaveFormEnabledChanged:)
                         name : ORKatrinFLTModelCheckWaveFormEnabledChanged
						object: model];

    //hardware histogramming -tb- 2008-02-08
    [notifyCenter addObserver : self
                     selector : @selector(histoBinWidthChanged:)
                         name : ORKatrinFLTModelHistoBinWidthChanged
                       object : model];
					   
    [notifyCenter addObserver : self
                     selector : @selector(histoMinEnergyChanged:)
                         name : ORKatrinFLTModelHistoMinEnergyChanged
                       object : model];
					   
    [notifyCenter addObserver : self
                     selector : @selector(histoMaxEnergyChanged:)
                         name : ORKatrinFLTModelHistoMaxEnergyChanged
                       object : model];
					   
    [notifyCenter addObserver : self
                     selector : @selector(histoFirstBinChanged:)
                         name : ORKatrinFLTModelHistoFirstBinChanged
                       object : model];
					   
    [notifyCenter addObserver : self
                     selector : @selector(histoLastBinChanged:)
                         name : ORKatrinFLTModelHistoLastBinChanged
                       object : model];
					   
    [notifyCenter addObserver : self
                     selector : @selector(histoRunTimeChanged:)
                         name : ORKatrinFLTModelHistoRunTimeChanged
                       object : model];
					   
    [notifyCenter addObserver : self
                     selector : @selector(histoRecordingTimeChanged:)
                         name : ORKatrinFLTModelHistoRecordingTimeChanged
                       object : model];
					   
    [notifyCenter addObserver : self
                     selector : @selector(histoTestValuesChanged:)
                         name : ORKatrinFLTModelHistoTestValuesChanged
                       object : model];
					   
    [notifyCenter addObserver : self
                     selector : @selector(histoTestPlotterWantDisplay:)
                         name : ORKatrinFLTModelHistoTestPlotterWantDisplay
                       object : model];
					   
    [notifyCenter addObserver : self
                     selector : @selector(histoCalibrationChanChanged:)
                         name : ORKatrinFLTModelHistoCalibrationChanChanged
                       object : model];
					   
     
    
    
    
    
  int iiiii;  
#if 0   // TODO: remove it - used for copy and paste -tb-
    istoMinEnergy
    istoMaxEnergy
    istoFirstBin
    istoLastBin
    istoRunTime
    istoRecordingTime


    ORKatrinFLTModelHistoMinEnergyChanged
    ORKatrinFLTModelHistoMaxEnergyChanged
    ORKatrinFLTModelHistoFirstBinChanged
    ORKatrinFLTModelHistoLastBinChanged
    ORKatrinFLTModelHistoRunTimeChanged
    ORKatrinFLTModelHistoRecordingTimeChanged
#endif

}

#pragma mark ¥¥¥Interface Management

- (void) checkWaveFormEnabledChanged:(NSNotification*)aNote
{
	[checkWaveFormEnabledButton setIntValue: [model checkWaveFormEnabled]];
}

- (void) updateWindow
{
    [super updateWindow];
    [self slotChanged:nil];
    [self settingsLockChanged:nil];
	[self fltRunModeChanged:nil];
	[self daqRunModeChanged:nil];
	[self gainArrayChanged:nil];
	[self thresholdArrayChanged:nil];
	[self triggersEnabledArrayChanged:nil];
	[self hitRatesEnabledArrayChanged:nil];
	[self shapingTimesArrayChanged:nil];
	[self hitRateLengthChanged:nil];
	[self hitRateChanged:nil];
    [self updateTimePlot:nil];
    [self totalRateChanged:nil];
	[self scaleAction:nil];
	[self broadcastTimeChanged:nil];
    [self testEnabledArrayChanged:nil];
	[self testStatusArrayChanged:nil];
	[self testParamChanged:nil];
    [self patternChanged:nil];
    [self tModeChanged:nil];
	[self numTestPattersChanged:nil];
    [self miscAttributesChanged:nil];
	[self readoutPagesChanged:nil];	
	[self checkWaveFormEnabledChanged:nil];
    //hardware histogramming -tb- 2008-02-08
	[self histoBinWidthChanged:nil];
	[self histoMinEnergyChanged: nil];
	[self histoMaxEnergyChanged: nil];
	[self histoFirstBinChanged: nil];
	[self histoLastBinChanged: nil];
	[self histoRunTimeChanged: nil];
	[self histoRecordingTimeChanged: nil];
	[self histoCalibrationChanChanged: nil];

}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];


    [gSecurity setLock:ORKatrinFLTSettingsLock to:secure];
    [settingLockButton setEnabled:secure];
	
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORKatrinFLTSettingsLock];
	BOOL isRunning = [gOrcaGlobals runInProgress];
    BOOL locked = [gSecurity isLocked:ORKatrinFLTSettingsLock];
	BOOL testsAreRunning = [model testsRunning];
	BOOL testingOrRunning = testsAreRunning | runInProgress;
    
    [testEnabledMatrix setEnabled:!locked && !testingOrRunning];
    [settingLockButton setState: locked];
	[readFltModeButton setEnabled:!lockedOrRunningMaintenance];
	[writeFltModeButton setEnabled:!lockedOrRunningMaintenance];
	[daqRunModeButton setEnabled:!lockedOrRunningMaintenance];
	[resetButton setEnabled:!lockedOrRunningMaintenance];
	[triggerButton setEnabled:isRunning]; // only active in run mode, ak 4.7.07
    [gainTextFields setEnabled:!lockedOrRunningMaintenance];
    [thresholdTextFields setEnabled:!lockedOrRunningMaintenance];
	[readThresholdsGainsButton setEnabled:!lockedOrRunningMaintenance];
    [triggerEnabledCBs setEnabled:!lockedOrRunningMaintenance];
    [hitRateEnabledCBs setEnabled:!lockedOrRunningMaintenance];
    [writeThresholdsGainsButton setEnabled:!lockedOrRunningMaintenance];
    [loadTimeButton setEnabled:!locked];
    [readTimeButton setEnabled:!locked];
    [broadcastTimeCB setEnabled:!lockedOrRunningMaintenance];

	[versionButton setEnabled:!isRunning];
	[testButton setEnabled:!isRunning];
	[statusButton setEnabled:!isRunning];

    [hitRateLengthField setEnabled:!lockedOrRunningMaintenance];
    [hitRateAllButton setEnabled:!lockedOrRunningMaintenance];
    [hitRateNoneButton setEnabled:!lockedOrRunningMaintenance];
	
	[readoutPagesField setEnabled:!lockedOrRunningMaintenance]; // ak, 2.7.07

	[checkWaveFormEnabledButton setEnabled:!lockedOrRunningMaintenance && [model fltRunMode] == kKatrinFlt_Debug_Mode];

	if(testsAreRunning){
		[testButton setEnabled: YES];
		[testButton setTitle: @"Stop"];
	}
    else {
		[testButton setEnabled: !runInProgress];	
		[testButton setTitle: @"Test"];
	}

	[patternTable setEnabled:!locked];
	[numTestPatternsField setEnabled:!locked];
	[numTestPatternsStepper setEnabled:!locked];

	[tModeMatrix setEnabled:!locked];
	[initTPButton setEnabled:!locked];

}

- (void) numTestPattersChanged:(NSNotification*)aNote
{
	[numTestPatternsField setIntValue:[model testPatternCount]];
	[numTestPatternsStepper setIntValue:[model testPatternCount]];
}

- (void) patternChanged:(NSNotification*) aNote
{
	[patternTable reloadData];
}

- (void) tModeChanged:(NSNotification*) aNote
{
	unsigned short pattern = [model tMode];
	int i;
	for(i=0;i<2;i++){
		[[tModeMatrix cellWithTag:i] setState:pattern&(0x1L<<i)];
	}
}

- (void) testParamChanged:(NSNotification*)aNotification
{
	[[testParamsMatrix cellWithTag:0] setIntValue:[model startChan]];
	[[testParamsMatrix cellWithTag:1] setIntValue:[model endChan]];
	[[testParamsMatrix cellWithTag:2] setIntValue:[model page]];	
}


- (void) testEnabledArrayChanged:(NSNotification*)aNotification
{
	int i;
	for(i=0;i<kNumKatrinFLTTests;i++){
		[[testEnabledMatrix cellWithTag:i] setIntValue:[model testEnabled:i]];
	}    
}

- (void) testStatusArrayChanged:(NSNotification*)aNotification
{
	int i;
	for(i=0;i<kNumKatrinFLTTests;i++){
		[[testStatusMatrix cellWithTag:i] setStringValue:[model testStatus:i]];
	}
}


- (void) scaleAction:(NSNotification*)aNotification
{
	if(aNotification == nil || [aNotification object] == [rate0 xScale]){
		[model setMiscAttributes:[[rate0 xScale]attributes] forKey:@"RateXAttributes"];
	};
	
	if(aNotification == nil || [aNotification object] == [totalRate xScale]){
		[model setMiscAttributes:[[totalRate xScale]attributes] forKey:@"TotalRateXAttributes"];
	};
	
	if(aNotification == nil || [aNotification object] == [timeRatePlot xScale]){
		[model setMiscAttributes:[[timeRatePlot xScale]attributes] forKey:@"TimeRateXAttributes"];
	};
	
	if(aNotification == nil || [aNotification object] == [timeRatePlot yScale]){
		[model setMiscAttributes:[[timeRatePlot yScale]attributes] forKey:@"TimeRateYAttributes"];
	};
	
}

- (void) miscAttributesChanged:(NSNotification*)aNote
{
	NSString*				key = [[aNote userInfo] objectForKey:ORMiscAttributeKey];
	NSMutableDictionary* attrib = [model miscAttributesForKey:key];
	
	if(aNote == nil || [key isEqualToString:@"RateXAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"RateXAttributes"];
		if(attrib){
			[[rate0 xScale] setAttributes:attrib];
			[rate0 setNeedsDisplay:YES];
			[[rate0 xScale] setNeedsDisplay:YES];
			[rateLogCB setState:[[attrib objectForKey:ORAxisUseLog] boolValue]];
		}
	}
	if(aNote == nil || [key isEqualToString:@"TotalRateXAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"TotalRateXAttributes"];
		if(attrib){
			[[totalRate xScale] setAttributes:attrib];
			[totalRate setNeedsDisplay:YES];
			[[totalRate xScale] setNeedsDisplay:YES];
			[totalRateLogCB setState:[[attrib objectForKey:ORAxisUseLog] boolValue]];
		}
	}
	if(aNote == nil || [key isEqualToString:@"TimeRateXAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"TimeRateXAttributes"];
		if(attrib){
			[[timeRatePlot xScale] setAttributes:attrib];
			[timeRatePlot setNeedsDisplay:YES];
			[[timeRatePlot xScale] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"TimeRateYAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"TimeRateYAttributes"];
		if(attrib){
			[[timeRatePlot yScale] setAttributes:attrib];
			[timeRatePlot setNeedsDisplay:YES];
			[[timeRatePlot yScale] setNeedsDisplay:YES];
			[timeRateLogCB setState:[[attrib objectForKey:ORAxisUseLog] boolValue]];
		}
	}
}


- (void) updateTimePlot:(NSNotification*)aNote
{
	//if(!aNote || ([aNote object] == [[model adcRateGroup]timeRate])){
	//	[timeRatePlot setNeedsDisplay:YES];
	//}
}


- (void) shapingTimeChanged:(NSNotification*)aNotification
{
	int group = [[[aNotification userInfo] objectForKey:ORKatrinFLTChan] intValue];
	switch(group){
		case 0: [shapingTimePU0 selectItemAtIndex: [model shapingTime:0]]; break;
		case 1: [shapingTimePU1 selectItemAtIndex: [model shapingTime:1]]; break;
		case 2: [shapingTimePU2 selectItemAtIndex: [model shapingTime:2]]; break;
		case 3: [shapingTimePU3 selectItemAtIndex: [model shapingTime:3]]; break;
		default: break;
	}	
}

- (void) gainChanged:(NSNotification*)aNotification
{
	int chan = [[[aNotification userInfo] objectForKey:ORKatrinFLTChan] intValue];
	[[gainTextFields cellWithTag:chan] setIntValue: [model gain:chan]];
}

- (void) triggerEnabledChanged:(NSNotification*)aNotification
{
	int chan = [[[aNotification userInfo] objectForKey:ORKatrinFLTChan] intValue];
	[[triggerEnabledCBs cellWithTag:chan] setState: [model triggerEnabled:chan]];
}

- (void) hitRateEnabledChanged:(NSNotification*)aNotification
{
	int chan = [[[aNotification userInfo] objectForKey:ORKatrinFLTChan] intValue];
	[[hitRateEnabledCBs cellWithTag:chan] setState: [model hitRateEnabled:chan]];
}

- (void) thresholdChanged:(NSNotification*)aNotification
{
	int chan = [[[aNotification userInfo] objectForKey:ORKatrinFLTChan] intValue];
	[[thresholdTextFields cellWithTag:chan] setIntValue: [model threshold:chan]];
}


- (void) slotChanged:(NSNotification*)aNotification
{
	// Set title of FLT configuration window, ak 15.6.07
	[[self window] setTitle:[NSString stringWithFormat:@"Katrin FLT Card (Slot %d)",[model stationNumber]]];
}

- (void) gainArrayChanged:(NSNotification*)aNotification
{
	short chan;
	for(chan=0;chan<kNumFLTChannels;chan++){
		[[gainTextFields cellWithTag:chan] setIntValue: [model gain:chan]];

	}	
}

- (void) thresholdArrayChanged:(NSNotification*)aNotification
{
	short chan;
	for(chan=0;chan<kNumFLTChannels;chan++){
		[[thresholdTextFields cellWithTag:chan] setIntValue: [model threshold:chan]];
	}
}

- (void) triggersEnabledArrayChanged:(NSNotification*)aNotification
{
	short chan;
	for(chan=0;chan<kNumFLTChannels;chan++){
		[[triggerEnabledCBs cellWithTag:chan] setIntValue: [model triggerEnabled:chan]];

	}
}

- (void) hitRatesEnabledArrayChanged:(NSNotification*)aNotification
{
	short chan;
	for(chan=0;chan<kNumFLTChannels;chan++){
		[[hitRateEnabledCBs cellWithTag:chan] setIntValue: [model hitRateEnabled:chan]];

	}
}


- (void) shapingTimesArrayChanged:(NSNotification*)aNotification
{
	[shapingTimePU0 selectItemAtIndex: [model shapingTime:0]];
	[shapingTimePU1 selectItemAtIndex: [model shapingTime:1]];
	[shapingTimePU2 selectItemAtIndex: [model shapingTime:2]];
	[shapingTimePU3 selectItemAtIndex: [model shapingTime:3]];
}


/** The FLT mode register value.
  */
- (void) fltRunModeChanged:(NSNotification*)aNote
{
NSLog(@"Received notification  -fltModeChanged- ...\n");

	//[modeButton selectItemAtIndex:[model fltRunMode]]; obsolete ! -tb-
	//[modeButton selectItemAtIndex:[model daqRunMode]];//-tb-
    [fltModeField setIntValue:[model fltRunMode]];
	[self settingsLockChanged:nil];	//TODO: still needed? -tb- 2008-02-08
}

/** The DAQ run mode popup value.
  */
- (void) daqRunModeChanged:(NSNotification*)aNote
{
NSLog(@"Received notification  -daqRunModeChanged- ... new is %i\n", [model daqRunMode]);

	//[modeButton selectItemAtIndex:[model fltRunMode]];
    NSLog(@"DAQ run mode is %i\n", [model daqRunMode]);
	[daqRunModeButton selectItemWithTag:[model daqRunMode]];//-tb-
	[self settingsLockChanged:nil];	//TODO: still needed? -tb- 2008-02-08
}

- (void) broadcastTimeChanged:(NSNotification*)aNote
{
	[broadcastTimeCB setState:[model broadcastTime]];
}

- (void) hitRateLengthChanged:(NSNotification*)aNote
{
	[hitRateLengthField setIntValue:[model hitRateLength]];
}

- (void) hitRateChanged:(NSNotification*)aNote
{
	int chan;
	for(chan=0;chan<kNumFLTChannels;chan++){
		id theCell = [rateTextFields cellWithTag:chan];
		if([model hitRateOverFlow:chan]){
			[theCell setFormatter: nil];
			[theCell setTextColor:[NSColor redColor]];
			[theCell setObjectValue: @"OverFlow"];
		}
		else {
			[theCell setFormatter: rateFormatter];
			[theCell setTextColor:[NSColor blackColor]];
			[theCell setFloatValue: [model hitRate:chan]];
		}
	}
	[rate0 setNeedsDisplay:YES];
	[totalHitRateField setFloatValue:[model hitRateTotal]];
	[totalRate setNeedsDisplay:YES];
}

- (void) totalRateChanged:(NSNotification*)aNote
{
	if(aNote==nil || [aNote object] == [model totalRate]){
		[timeRatePlot setNeedsDisplay:YES];
	}
}

- (void) readoutPagesChanged:(NSNotification*)aNote
{
	[readoutPagesField setIntValue:[model readoutPages]];
}

- (void) histoBinWidthChanged:(NSNotification*)aNote
{
    [eSamplePopUpButton selectItemAtIndex:[model histoBinWidth]];
}
- (void) histoMinEnergyChanged:(NSNotification*)aNote
{
    [eMinField setIntValue:[model histoMinEnergy]];
}
- (void) histoMaxEnergyChanged: (NSNotification*)aNote
{
    [eMaxField setIntValue:[model histoMaxEnergy]];
}
- (void) histoFirstBinChanged: (NSNotification*)aNote
{
    [firstBinField setIntValue:[model histoFirstBin]];
}
- (void) histoLastBinChanged: (NSNotification*)aNote
{
    [lastBinField setIntValue:[model histoLastBin]];
}
- (void) histoRunTimeChanged: (NSNotification*)aNote
{
    [tRunField setIntValue:[model histoRunTime]];
}
- (void) histoRecordingTimeChanged: (NSNotification*)aNote
{
    [tRecField setIntValue:[model histoRecordingTime]];
}
- (void) histoTestValuesChanged:(NSNotification*)aNote
{
		//debug -tb- NSLog(@"histoTestValuesChanged called\n");
        // update time, adjust progress circle, ... -tb-
        //set the state of progress indicator
        if([model histoCalibrationIsRunning])
            [histoProgressIndicator startAnimation:nil];
        else
            [histoProgressIndicator stopAnimation:nil];
        // update the timer
        //char s[256];
        //sprintf(s, "%6.2f",[model histoTestElapsedTime]);
        //NSString *str=s;
        //[histoElapsedTimeField setStringValue: str];
        [histoElapsedTimeField setDoubleValue: [model histoTestElapsedTime]];

}

- (void) histoCalibrationChanChanged:(NSNotification*)aNote
{
    NSString *string1 = [NSString stringWithFormat:@"%i",[model histoCalibrationChan]];    
    [histoCalibrationChanNumPopUpButton selectItemWithTitle: string1];
}

- (void) histoTestPlotterWantDisplay:(NSNotification*)aNote
{
    //[histogramPlotterId display];
    [histogramPlotterId setNeedsDisplay:YES]; // -tb- this doesn't do the job - why?
}

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    [[self window] setContentView:blankView];
    switch([tabView indexOfTabViewItem:tabViewItem]){
        case  0: [self resizeWindowToSize:settingSize];     break;
        case  1: [self resizeWindowToSize:histogramSize];   break;
		case  2: [self resizeWindowToSize:rateSize];	    break;
		case  3: [self resizeWindowToSize:testSize];	    break;
		default: [self resizeWindowToSize:testSize];	    break;
    }
    [[self window] setContentView:totalView];
            
    NSString* key = [NSString stringWithFormat: @"orca.ORKatrinFLT%d.selectedtab",[model stationNumber]];
    int index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
    
}

#pragma mark ¥¥¥Actions

- (void) checkWaveFormEnabledAction:(id)sender
{
	[model setCheckWaveFormEnabled:[sender intValue]];	
}

- (IBAction) numTestPatternsAction:(id)sender
{
	[model setTestPatternCount:[sender intValue]];
}

- (IBAction) testEnabledAction:(id)sender
{
	NSMutableArray* anArray = [NSMutableArray array];
	int i;
	for(i=0;i<kNumKatrinFLTTests;i++){
		if([[testEnabledMatrix cellWithTag:i] intValue])[anArray addObject:[NSNumber numberWithBool:YES]];
		else [anArray addObject:[NSNumber numberWithBool:NO]];
	}
	[model setTestEnabledArray:anArray];
}


/** @todo FPGA-Bug
  * In FLT settings click on "read" for thresholds and gains. From time to time (between
  * 4 to 30 times) there are wrong values for the gains: very oftenly the last value is wrong (127
  * or 96 instead of 100), sometimes the second value (instead of 1 it is 0 or 100).
  * (FPGA version is the first "histogramming version".)
  * (This bug report is in ORKatrinFLTController.m  -tb- 2008-02-29 )
  */ //-tb- 2008-02-29
- (IBAction) readThresholdsGains:(id)sender
{
	NS_DURING
		int i;
		NSLog(@"FLT (station %d)\n",[model stationNumber]);
		NSLog(@"chan Threshold Gain\n");
		for(i=0;i<kNumFLTChannels;i++){
			NSLog(@"%d: %d %d \n",i,[model readThreshold:i],[model readGain:i]);
			//NSLog(@"%d: %d\n",i,[model readGain:i]);
		}
	NS_HANDLER
		NSLog(@"Exception reading FLT gains and thresholds\n");
        NSRunAlertPanel([localException name], @"%@\nRead of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) writeThresholdsGains:(id)sender
{
	[self endEditing];
	NS_DURING
		[model loadThresholdsAndGains];
	NS_HANDLER
		NSLog(@"Exception writing FLT gains and thresholds\n");
        NSRunAlertPanel([localException name], @"%@\nWrite of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) gainAction:(id)sender
{
	if([sender intValue] != [model gain:[[sender selectedCell] tag]]){
		[[self undoManager] setActionName: @"Set Gain"];
		[model setGain:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) thresholdAction:(id)sender
{
	if([sender intValue] != [model threshold:[[sender selectedCell] tag]]){
		[[self undoManager] setActionName: @"Set Threshold"];
		[model setThreshold:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}


- (IBAction) triggerEnableAction:(id)sender
{
	[[self undoManager] setActionName: @"Set TriggerEnabled"];
	[model setTriggerEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) hitRateEnableAction:(id)sender
{
	[[self undoManager] setActionName: @"Set HitRate Enabled"];
	[model setHitRateEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
}


- (IBAction) readFltModeButtonAction:(id)sender
{
	[self endEditing];
	NS_DURING
		[model readMode];
	NS_HANDLER
		NSLog(@"Exception reading FLT status\n");
        NSRunAlertPanel([localException name], @"%@\nRead of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) writeFltModeButtonAction:(id)sender
{
	[self endEditing];
	NS_DURING
		[model writeMode:[model fltRunMode]];
	NS_HANDLER
		NSLog(@"Exception writing FLT status\n");
        NSRunAlertPanel([localException name], @"%@\nWrite of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORKatrinFLTSettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) daqRunModeAction: (id) sender
{
	//[model setDaqRunMode:[daqRunModeButton indexOfSelectedItem]];
	[model setDaqRunMode: [[daqRunModeButton selectedItem]tag]  ];
}

- (IBAction) versionAction: (id) sender
{
	NS_DURING
		NSLog(@"FLT %d Revision: %d\n",[model stationNumber],[model readVersion]);
		int fpga;
		for (fpga=0;fpga<4;fpga++) {
			int version = [model readFPGAVersion:fpga];
			NSLog(@"FLT %d peripherial FPGA%d version 0x%02x\n",[model stationNumber], fpga, version);
		}
	NS_HANDLER
		NSLog(@"Exception reading FLT HW Model Version\n");
        NSRunAlertPanel([localException name], @"%@\nRead of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) testAction: (id) sender
{
	NS_DURING
		[model runTests];
	NS_HANDLER
		NSLog(@"Exception reading FLT HW Model Test\n");
        NSRunAlertPanel([localException name], @"%@\nFLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}


- (IBAction) resetAction: (id) sender
{
	NS_DURING
		[model reset];
	NS_HANDLER
		NSLog(@"Exception during FLT reset\n");
        NSRunAlertPanel([localException name], @"%@\nFLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) triggerAction: (id) sender
{
	NS_DURING
		[model trigger];
	NS_HANDLER
		NSLog(@"Exception during FLT trigger\n");
        NSRunAlertPanel([localException name], @"%@\nFLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}


- (IBAction) loadTimeAction: (id) sender
{
	NS_DURING
		[model loadTime];
	NS_HANDLER
		NSLog(@"Exception during FLT load time\n");
        NSRunAlertPanel([localException name], @"%@\nWrite of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
	
}

- (IBAction) readTimeAction: (id) sender
{
	NS_DURING
		unsigned long timeLoaded = [model readTime];
		NSLog(@"FLT %d time:%d = %@\n",[model stationNumber],timeLoaded,[NSDate dateWithTimeIntervalSinceReferenceDate:(NSTimeInterval)timeLoaded]);
	NS_HANDLER
		NSLog(@"Exception during FLT read time\n");
        NSRunAlertPanel([localException name], @"%@\nRead of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) shapingTimeAction: (id) sender
{
	if([sender intValue] != [model gain:[[sender selectedCell] tag]]){
		[[self undoManager] setActionName: @"Set ShapingTime"]; 
		[model setShapingTime:[sender tag] withValue:[sender indexOfSelectedItem]];
	}
}

- (IBAction) hitRateLengthAction: (id) sender
{
	if([sender intValue] != [model hitRateLength]){
		[[self undoManager] setActionName: @"Set Hit Rate Length"]; 
		[model setHitRateLength:[sender intValue]];
	}
}

- (IBAction) hitRateAllAction: (id) sender
{
	[model enableAllHitRates:YES];
}

- (IBAction) hitRateNoneAction: (id) sender
{
	[model enableAllHitRates:NO];
}

- (IBAction) broadcastTimeAction: (id) sender
{
	[model setBroadcastTime:[sender state]];
}

- (IBAction) testParamAction: (id) sender
{
	[self endEditing];
	switch([[sender selectedCell] tag]){
		case 0: 	[model setStartChan:[sender intValue]]; break;
		case 1: 	[model setEndChan:[sender intValue]]; break;
		case 2: 	[model setPage:[sender intValue]]; break;
		default: break;
	}
}

- (IBAction) statusAction:(id)sender
{
	NS_DURING
		[model printStatusReg];
	NS_HANDLER
		NSLog(@"Exception during FLT read status\n");
        NSRunAlertPanel([localException name], @"%@\nRead of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) tModeAction: (id) sender
{
	unsigned long pattern = 0;
	int i;
	for(i=0;i<2;i++){
		BOOL state = [[tModeMatrix cellWithTag:i] state];
		if(state)pattern |= (0x1L<<i);
		else pattern &= ~(0x1L<<i);
	}
	
	[model setTMode:pattern];
}

- (IBAction) initTPAction: (id) sender
{
	NS_DURING
		[model writeTestPatterns];
	NS_HANDLER
		NSLog(@"Exception during FLT init test Pattern\n");
        NSRunAlertPanel([localException name], @"%@\nTest Pattern Init FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}


- (IBAction) readoutPagesAction: (id) sender
{
	if([sender intValue] != [model readoutPages]){
		[[self undoManager] setActionName: @"Set Readout Pages"]; 
		[model setReadoutPages:[sender intValue]];
	}
}


//TODO: from here HWHisto
- (IBAction) helloButtonAction:(id)sender
{
    NSLog(@"This is  helloButtonAction\n");
}

- (IBAction) readEMinButtonAction:(id)sender
{
    
    //TODO: CATCH EXCEPTIONS -tb-
    
    unsigned int EMin = [model readEMin];
    [eMinField setIntValue:EMin ];
    //NSLog(@"This is  readEMinButtonAction\n");
    NSLog(@"EMin is %i\n",EMin);
}

- (IBAction) writeEMinButtonAction:(id)sender
{
    
    //TODO: CATCH EXCEPTIONS -tb-
    
    //NSLog(@"This is  writeEMinButtonAction\n");
    NSLog(@"title is string %@ (int val %i)\n", [eMinField stringValue ],
          [eMinField intValue ]);
    unsigned int EMin = [eMinField intValue ];
    [model writeEMin:EMin];
}

- (IBAction) readEMaxButtonAction:(id)sender
{
    //TODO: this will probably change in the next FPGA version -tb-
    NSLog(@"This is  readEMaxButtonAction\n");
}

- (IBAction) writeEMaxButtonAction:(id)sender
{
    //TODO: this will probably change in the next FPGA version -tb-
    NSLog(@"This is  writeEMaxButtonAction\n");
}

- (IBAction) readTRecButtonAction:(id)sender
{
    
    //TODO: CATCH EXCEPTIONS -tb-
    
    unsigned int tRec = [model readTRec];
    NSLog(@"This is  readTRecButtonAction: tRec = %i\n",tRec);
    [tRecField setIntValue:tRec ];
}

- (IBAction) readTRunAction:(id)sender
{
    NSLog(@"This is   readTRunAction\n");
}

- (IBAction) writeTRunAction:(id)sender
{
    NSLog(@"This is   writeTRunAction\n");
}

- (IBAction) readFirstBinButtonAction:(id)sender
{
    
    //TODO: CATCH EXCEPTIONS -tb-
    unsigned int Pixel = 0; // TODO: for testing: it is not per pixel, but per FPGA
    
    NSLog(@"This is   readFirstBinButtonAction:%i\n", [model readFirstBinOfPixel: Pixel]);
    [firstBinField setIntValue: [model readFirstBinOfPixel: Pixel] ];
}

- (IBAction) readLastBinButtonAction:(id)sender
{
    
    //TODO: CATCH EXCEPTIONS -tb-
    unsigned int Pixel = 0; // TODO: for testing: it is not per pixel, but per FPGA
    
    NSLog(@"This is   readLastBinButtonAction: %i\n",[model readLastBinOfPixel: Pixel]);
    [lastBinField setIntValue: [model readLastBinOfPixel: Pixel] ];
}

- (IBAction) changedBinWidthPopupButtonAction:(id)sender;
{
    //TODO: CATCH EXCEPTIONS -tb-
    //NSLog(@"This is    changedESamplePopupButtonAction: selected %i\n",[sender indexOfSelectedItem]);
    [model setHistoBinWidth:[sender indexOfSelectedItem]];
}
- (IBAction) changedHistoMinEnergyAction:(id)sender
{    [model setHistoMinEnergy:[sender intValue]];  }

- (IBAction) changedHistoMaxEnergyAction:(id)sender // for now: unused -tb- 2008-03-06
{    [model setHistoMaxEnergy:[sender intValue]];  }

- (IBAction) changedHistoFirstBinAction:(id)sender
{    [model setHistoFirstBin:[sender indexOfSelectedItem]];  }

- (IBAction) changedHistoLastBinAction:(id)sender
{    [model setHistoLastBin:[sender indexOfSelectedItem]];  }
- (IBAction) changedHistoRunTimeAction:(id)sender
{    [model setHistoRunTime:[sender intValue]];  }
- (IBAction) changedHistoRecordingTimeAction:(id)sender
{    [model setHistoRecordingTime:[sender indexOfSelectedItem]];  }
    
    
    
    
    
    

- (IBAction) startHistogramButtonAction:(id)sender
{
    
    //TODO: CATCH EXCEPTIONS -tb-
    [self endEditing];
    NSLog(@"This is    startHistogramButtonAction\n");
    [model startHistogramOfPixel:0];  //TODO: testing for pixel 0 -tb-
    [histoProgressIndicator startAnimation:nil];
    //[self readTRecButtonAction:nil];
    //[self readFirstBinButtonAction:nil];
    //[self readLastBinButtonAction:nil];
}

- (IBAction) stopHistogramButtonAction:(id)sender
{
    
    //TODO: CATCH EXCEPTIONS -tb-
    
    //NSLog(@"This is    stopHistogramButtonAction\n");
    [histoProgressIndicator stopAnimation:nil];
    [model stopHistogramOfPixel:0];  //TODO: testing for pixel 0 -tb-
    NSLog(@"Rec time is: %i\n",[model readTRec]);
    //[model setHistoRecordingTime:[model readTRec]];  //TODO: testing for pixel 0 -tb-
    //[self histoRunTimeChanged:nil];
    //[self histoRecordingTimeChanged:nil];
    //[model setHistoFirstBin:[model readFirstBinOfPixel:0]];
    //[model setHistoLastBin:[model readLastBinOfPixel:0]];
    //  [self readTRecButtonAction:nil];
    //  [self readFirstBinButtonAction:nil];
    //  [self readLastBinButtonAction:nil];
    //[histogramPlotterId forcedUpdate:nil];
    //[histogramPlotterId setNeedsDisplay:YES]; //TODO: make notification and let respond it to it -tb-
    //[histogramPlotterId display]; //moved to histoTestPlotterWantDisplay

}

- (IBAction) readHistogramDataButtonAction:(id)sender
{
    
    //TODO: CATCH EXCEPTIONS -tb-
    
    NSLog(@"This is  readHistogramDataButtonAction\n");
    [model readHistogramDataOfPixel:0];  //TODO: testing for pixel 0 -tb-
    //[histogramPlotterId setNeedsDisplay:YES];//TODO: make notification and let respond it to it -tb-


}

- (IBAction) readCurrentStatusButtonAction:(id)sender
{
    
    //TODO: CATCH EXCEPTIONS -tb-
    
    NSLog(@"This is  readCurrentStatusButtonAction\n");
    [model readCurrentStatusOfPixel:0];  //TODO: testing for pixel 0 -tb-
}

- (IBAction) changedHistoCalibrationChanPopupButtonAction:(id)sender
{
    int chan=[[[histoCalibrationChanNumPopUpButton selectedItem] title ] intValue];
    [model setHistoCalibrationChan: chan];
    //TODO: maybe converting title to integer is better? -tb-
}


- (IBAction) vetoTestButtonAction:(id)sender
{
    // button states:  NSOnState, NSOffState  or NSMixedState 
    // ... use outlet vetoEnableButton
    NSLog(@"This is  vetoTestButtonAction, state is %i\n",[sender state]);
    // -tb- [model setVetoEnable: [sender state]];  //TODO: testing for pixel 0 -tb-
}

- (IBAction) readVetoStateButtonAction:(id)sender
{
// -tb- unused
    NSLog(@"Veto state is  %8x\n",[model readVetoState]);
}

- (IBAction) readEnableVetoButtonAction:(id)sender
{
    NSLog(@"Veto state is  %8x\n",[model readVetoState]);
    if([model readVetoState])
        [vetoEnableButton setState: NSOnState];
    else
        [vetoEnableButton setState: NSOffState];
}

- (IBAction) writeEnableVetoButtonAction:(id)sender
{
    NSLog(@"Write Veto state   %8x\n",[vetoEnableButton state]);
    if([vetoEnableButton state]==NSOnState)
      [model setVetoEnable: 1];  //TODO: testing for pixel 0 -tb-
    else
      [model setVetoEnable: 0];  //TODO: testing for pixel 0 -tb-
}

- (IBAction) readVetoDataButtonAction:(id)sender
{
    NSLog(@"This is readVetoDataButtonAction\n");
    NSLog(@"sizeof(unsigned int) is %i\n",sizeof(unsigned int));
    
    //system("say reading veto data");  // -tb- a test ...
    
    [model readVetoDataFrom:0 to:10];
}


#pragma mark ¥¥¥Plot DataSource
- (int)		numberOfPointsInPlot:(id)aPlotter dataSet:(int)set
{
//RatesPlotter1D
	//NSLog(@"    DEBUG: This is  - (int)		numberOfPointsInPlot:(id)aPlotter dataSet:(int)set\n" );
    //if(aPlotter)
	//  NSLog(@"Plottername is %@\n",[aPlotter name] );
    if(histogramPlotterId == aPlotter){
  	    //NSLog(@"    DEBUG:   Testing: YES, it is the histo plotter\n" );
        return 1024;
    }else{
	    //NSLog(@"    DEBUG:   Testing: NO, it is not the histo plotter\n" );
    }

	return [[model  totalRate]count];
}
- (float)  	plotter:(id) aPlotter dataSet:(int)set dataValue:(int) x 
{
	//-tb- NSLog(@"This is  - (float)  	plotter:(id) aPlotter dataSet:(int)set dataValue:(int) x\n" );
    if(histogramPlotterId == aPlotter){
        //if(![model histogramData]) return 200.0 + 100.0 * sin(0.01*x);   // testing: returns a sine wave
        //return 200.0 + 100.0 * sin(0.01*x);   // testing: returns a sine wave
        //if(x<0 || x>1023) return 0.0;
        //return     [model readHistogramDataOfPixel:0 atBin:x];  //TODO: testing for pixel 0 -tb-
        //return     [[[model histogramData] objectAtIndex:x] intValue];  //TODO: testing for pixel 0 -tb-
        unsigned int num = [model getHistogramDataUI: x];
        return (float)num;
    }

	int count = [[model totalRate]count];
	return [[model totalRate] valueAtIndex:count-x-1];
}

- (unsigned long)  	secondsPerUnit:(id) aPlotter
{
	return [[model totalRate] sampleTime];
}

//table 
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
    NSParameterAssert(rowIndex >= 0 && rowIndex < [[model testPatterns] count]);
	if([[aTableColumn identifier] isEqualToString:@"Index"]){
		return [NSNumber numberWithInt:rowIndex];
	}
	else {
		return [[model testPatterns] objectAtIndex:rowIndex];
	}
}

// just returns the number of items we have.
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [[model testPatterns] count];
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if(rowIndex>=0 && rowIndex<24){
		[[model testPatterns] replaceObjectAtIndex:rowIndex withObject:anObject];
	}
}


- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
    if ([menuItem action] == @selector(cut:)) {
        return [patternTable selectedRow] >= 0 ;
    }
    else if ([menuItem action] == @selector(delete:)) {
        return [patternTable selectedRow] >= 0;
    }
    else if ([menuItem action] == @selector(copy:)) {
        return NO; //enable when cut/paste is finished
    }
    else if ([menuItem action] == @selector(paste:)) {
        return NO; //enable when cut/paste is finished
    }
    return YES;
}

@end



