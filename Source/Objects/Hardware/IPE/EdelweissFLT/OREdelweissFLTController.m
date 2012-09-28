//
//  OREdelweissFLTController.m
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

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Imported Files
#import "OREdelweissFLTController.h"
#import "OREdelweissFLTModel.h"
#import "OREdelweissFLTDefs.h"
#import "SLTv4_HW_Definitions.h"
#import "ORFireWireInterface.h"
#import "ORTimeRate.h"
#import "ORPlotView.h"
#import "ORTimeLinePlot.h"
#import "ORValueBar.h"
#import "ORTimeAxis.h"
#import "ORValueBarGroupView.h"
#import "ORCompositePlotView.h"

@implementation OREdelweissFLTController

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"EdelweissFLT"];
    
    return self;
}

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Initialization
- (void) dealloc
{
	[rateFormatter release];
	[blankView release];
    [super dealloc];
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	
    settingSize			= NSMakeSize(670,790);
    rateSize			= NSMakeSize(490,760);
    testSize			= NSMakeSize(400,420);
    lowlevelSize		= NSMakeSize(400,420);
	
	rateFormatter = [[NSNumberFormatter alloc] init];
	[rateFormatter setFormat:@"##0.00"];
	[totalHitRateField setFormatter:rateFormatter];
	[rateTextFields setFormatter:rateFormatter];
    blankView = [[NSView alloc] init];
    
    NSString* key = [NSString stringWithFormat: @"orca.OREdelweissFLT%d.selectedtab",[model stationNumber]];
    int index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
	

	ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:0 andDataSource:self];
	[timeRatePlot addPlot: aPlot];
	[(ORTimeAxis*)[timeRatePlot xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
	[aPlot release];
	
	[self populatePullDown];
	[self updateWindow];
	
	[rate0 setNumber:24 height:10 spacing:6];

}

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Accessors

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Notifications
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
                         name : OREdelweissFLTSettingsLock
                        object: nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(slotChanged:)
						 name : ORIpeCardSlotChangedNotification
					   object : model];
	
	
    [notifyCenter addObserver : self
                     selector : @selector(modeChanged:)
                         name : OREdelweissFLTModelModeChanged
                       object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(thresholdChanged:)
						 name : OREdelweissFLTModelThresholdChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(gainChanged:)
						 name : OREdelweissFLTModelGainChanged
					   object : model];

	
    [notifyCenter addObserver : self
					 selector : @selector(gainArrayChanged:)
						 name : OREdelweissFLTModelGainsChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(thresholdArrayChanged:)
						 name : OREdelweissFLTModelThresholdsChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(hitRateLengthChanged:)
						 name : OREdelweissFLTModelHitRateLengthChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(hitRateChanged:)
						 name : OREdelweissFLTModelHitRateChanged
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
                     selector : @selector(testEnabledArrayChanged:)
                         name : OREdelweissFLTModelTestEnabledArrayChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(testStatusArrayChanged:)
                         name : OREdelweissFLTModelTestStatusArrayChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(updateWindow)
                         name : OREdelweissFLTModelTestsRunningChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(interruptMaskChanged:)
                         name : OREdelweissFLTModelInterruptMaskChanged
						object: model];
	
    [notifyCenter addObserver : self
					 selector : @selector(selectedRegIndexChanged:)
						 name : OREdelweissFLTSelectedRegIndexChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(writeValueChanged:)
						 name : OREdelweissFLTWriteValueChanged
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(selectedChannelValueChanged:)
						 name : OREdelweissFLTSelectedChannelValueChanged
					   object : model];

    [notifyCenter addObserver : self
                     selector : @selector(fifoBehaviourChanged:)
                         name : OREdelweissFLTModelFifoBehaviourChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(postTriggerTimeChanged:)
                         name : OREdelweissFLTModelPostTriggerTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(gapLengthChanged:)
                         name : OREdelweissFLTModelGapLengthChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(filterLengthChanged:)
                         name : OREdelweissFLTModelFilterLengthChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(storeDataInRamChanged:)
                         name : OREdelweissFLTModelStoreDataInRamChanged
						object: model];


    [notifyCenter addObserver : self
                     selector : @selector(noiseFloorChanged:)
                         name : OREdelweissFLTNoiseFloorChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(noiseFloorOffsetChanged:)
                         name : OREdelweissFLTNoiseFloorOffsetChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(targetRateChanged:)
                         name : OREdelweissFLTModelTargetRateChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(fltModeFlagsChanged:)
                         name : OREdelweissFLTModelFltModeFlagsChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(fiberEnableMaskChanged:)
                         name : OREdelweissFLTModelFiberEnableMaskChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(BBv1MaskChanged:)
                         name : OREdelweissFLTModelBBv1MaskChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(selectFiberTrigChanged:)
                         name : OREdelweissFLTModelSelectFiberTrigChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(streamMaskChanged:)
                         name : OREdelweissFLTModelStreamMaskChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(fiberDelaysChanged:)
                         name : OREdelweissFLTModelFiberDelaysChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(fastWriteChanged:)
                         name : OREdelweissFLTModelFastWriteChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(statusRegisterChanged:)
                         name : OREdelweissFLTModelStatusRegisterChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(totalTriggerNRegisterChanged:)
                         name : OREdelweissFLTModelTotalTriggerNRegisterChanged
						object: model];


    [notifyCenter addObserver : self
                     selector : @selector(controlRegisterChanged:)
                         name : OREdelweissFLTModelControlRegisterChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(repeatSWTriggerModeChanged:)
                         name : OREdelweissFLTModelRepeatSWTriggerModeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(swTriggerIsRepeatingChanged:)
                         name : OREdelweissFLTModelSwTriggerIsRepeatingChanged
						object: model];

}

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Interface Management

- (void) swTriggerIsRepeatingChanged:(NSNotification*)aNote
{
	if([model swTriggerIsRepeating]){
	    [swTriggerProgress  startAnimation:self ];
	}else{
	    [swTriggerProgress  stopAnimation:self ];
	}
}

- (void) repeatSWTriggerModeChanged:(NSNotification*)aNote
{
	[repeatSWTriggerModePU selectItemAtIndex: [model repeatSWTriggerMode]];
	//[repeatSWTriggerModeTextField setIntValue: [model repeatSWTriggerMode]];
}

- (void) controlRegisterChanged:(NSNotification*)aNote
{
	[controlRegisterTextField setIntValue: [model controlRegister]];
    [self fiberEnableMaskChanged:nil];
    [self selectFiberTrigChanged:nil];
    [self BBv1MaskChanged:nil];

	//[selectFiberTrigPU selectItemAtIndex: [model selectFiberTrig]];
	[statusLatencyPU selectItemAtIndex: [model statusLatency]];
	[vetoFlagCB setIntValue: [model vetoFlag]];
}

- (void) totalTriggerNRegisterChanged:(NSNotification*)aNote
{
	[totalTriggerNRegisterTextField setIntValue: [model totalTriggerNRegister]];
}

- (void) statusRegisterChanged:(NSNotification*)aNote
{
	[statusRegisterTextField setIntValue: [model statusRegister]];
}

- (void) fastWriteChanged:(NSNotification*)aNote
{
	[fastWriteCB setIntValue: [model fastWrite]];
}

- (void) fiberDelaysChanged:(NSNotification*)aNote
{
    uint64_t val=[model fiberDelays];
    //DEBUG OUTPUT: 
 	NSLog(@"%@::%@: UNDER CONSTRUCTION! 0x%016llx \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),[model fiberDelays]);//TODO: DEBUG testing ...-tb-
	//[fiberDelaysTextField setIntValue: [model fiberDelays]];
	[fiberDelaysTextField setStringValue: [NSString stringWithFormat:@"0x%016qx",val]];

	uint64_t fibDelays;
	uint64_t fib;
	int clk12,clk120;

	for(fib=0;fib<6;fib++){
	    //NSLog(@"fib %i:",fib);
			fibDelays = ((val) >> (fib*8)) & 0xffff;
			clk120 = (fibDelays & 0xf0) >> 4;
			clk12  =  fibDelays & 0x0f;
		    [[fiberDelaysMatrix cellAtRow:0 column: fib] selectItemAtIndex: clk12 ];
		    [[fiberDelaysMatrix cellAtRow:1 column: fib] selectItemAtIndex: clk120];
	}

}

- (void) streamMaskChanged:(NSNotification*)aNote
{
	//[streamMaskTextField setIntValue: [model streamMask]];
	[streamMaskTextField setStringValue: [NSString stringWithFormat:@"0x%016qx",[model streamMask]]];
	//[streamMaskTextField setStringValue: [NSString stringWithFormat:@"0x1234000012340000"]];
//DEBUG OUTPUT:
 	NSLog(@"%@::%@: UNDER CONSTRUCTION! 0x%016qx 0x%032qx 0x%016llx \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),[model streamMask],[model streamMask],[model streamMask]);//TODO: DEBUG testing ...-tb-

	//[model setStreamMask:[sender intValue]];	
	uint64_t chan, fib;
    uint64_t val=[model streamMask];
	for(fib=0;fib<6;fib++){
	    //NSLog(@"fib %i:",fib);
		NSString *s = [NSString stringWithFormat:@"fib %llu:",fib];
	    for(chan=0;chan<6;chan++){
		    if([model streamMaskForFiber:fib chan:chan]) [[streamMaskMatrix cellAtRow:fib column: chan] setIntValue: 1];
			else  [[streamMaskMatrix cellAtRow:fib column: chan] setIntValue: 0];
			
			s=[s stringByAppendingString: [NSString stringWithFormat: @"%u",[model streamMaskForFiber:fib chan:chan]]];
			#if 0
		    if([model streamMaskForFiber:fib chan:chan]){ 
			    //val |= ((0x1LL<<chan) << (fib*8));
				s=[s stringByAppendingString: @"1"];
			}else{
				s=[s stringByAppendingString: @"0"];
			}
			#endif
		}
			NSLog(@"%@\n",s);
	}
			NSLog(@"%016qx done.\n",val);
}

- (void) selectFiberTrigChanged:(NSNotification*)aNote
{
    //DEBUG: OUTPUT:  	NSLog(@"%@::%@: UNDER CONSTRUCTION! [model selectFiberTrig] is %i \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),[model selectFiberTrig]);//TODO : DEBUG testing ...-tb-
	//[selectFiberTrigPU setIntValue: [model selectFiberTrig]];
	[selectFiberTrigPU selectItemAtIndex: [model selectFiberTrig]];
}

- (void) BBv1MaskChanged:(NSNotification*)aNote
{
	//[BBv1MaskMatrix setIntValue: [model BBv1Mask]];
	int i;
	for(i=0;i<6;i++){
		[[BBv1MaskMatrix cellWithTag:i] setIntValue:[model BBv1MaskForChan:i]];
        //DEBUG OUTPUT: 	NSLog(@"%@::%@: UNDER CONSTRUCTION! [model BBv1MaskForChan:%i] %i \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),i,[model BBv1MaskForChan:i]);//TODO : DEBUG testing ...-tb-
	}    

}

- (void) fiberEnableMaskChanged:(NSNotification*)aNote
{
	//[fiberEnableMask<custom> setIntValue: [model fiberEnableMask]];
	int i;
	for(i=0;i<6;i++){
		[[fiberEnableMaskMatrix cellAtRow:0 column:i] setIntValue: [model fiberEnableMaskForChan:i] ];
	}    
}

- (void) fltModeFlagsChanged:(NSNotification*)aNote
{
    int index=4;
	switch([model fltModeFlags]){
	    case 0x0: index=0; break;
	    case 0x1: index=1; break;
	    case 0x2: index=2; break;
	    case 0x3: index=3; break;
	    default: index=4; break;
	}
	[fltModeFlagsPU selectItemAtIndex: index];
	//[fltModeFlagsPU setIntValue: [model fltModeFlags]];
}

- (void) targetRateChanged:(NSNotification*)aNote
{
	[targetRateField setIntValue: [model targetRate]];
}


- (void) storeDataInRamChanged:(NSNotification*)aNote
{
	[storeDataInRamCB setIntValue: [model storeDataInRam]];
}

- (void) filterLengthChanged:(NSNotification*)aNote
{
	[filterLengthPU selectItemAtIndex:[model filterLength]-2];
}

- (void) gapLengthChanged:(NSNotification*)aNote
{
	[gapLengthPU selectItemAtIndex: [model gapLength]];
}

- (void) postTriggerTimeChanged:(NSNotification*)aNote
{
	[postTriggerTimeField setIntValue: [model postTriggerTime]];
}

- (void) fifoBehaviourChanged:(NSNotification*)aNote
{
	[fifoBehaviourMatrix selectCellWithTag: [model fifoBehaviour]];
}

- (void) interruptMaskChanged:(NSNotification*)aNote
{
	[interruptMaskField setIntValue: [model interruptMask]];
}

- (void) populatePullDown
{
    short	i;
	
	// Clear all the popup items.
    [registerPopUp removeAllItems];
    
	// Populate the register popup
    for (i = 0; i < [model getNumberRegisters]; i++) {
        [registerPopUp insertItemWithTitle:[model getRegisterName:i] atIndex:i];
    }
    
    
	// Clear all the popup items.
    [channelPopUp removeAllItems];
    
	// Populate the register popup
    for (i = 0; i < 24; i++) {
        [channelPopUp insertItemWithTitle: [NSString stringWithFormat: @"%i",i+1 ] atIndex:i];
        [[channelPopUp itemAtIndex:i] setTag: i];
    }
    [channelPopUp insertItemWithTitle: @"All" atIndex:i];
    [[channelPopUp itemAtIndex:i] setTag: 0x1f];// chan 31 = broadcast to all channels
}

- (void) updateWindow
{
    [super updateWindow];
    [self slotChanged:nil];
	[self modeChanged:nil];
	[self gainArrayChanged:nil];
	[self thresholdArrayChanged:nil];
	[self triggersEnabledArrayChanged:nil];
	[self hitRateLengthChanged:nil];
	[self hitRateChanged:nil];
    [self updateTimePlot:nil];
    [self totalRateChanged:nil];
	[self scaleAction:nil];
    [self testEnabledArrayChanged:nil];
	[self testStatusArrayChanged:nil];
    [self miscAttributesChanged:nil];
	[self interruptMaskChanged:nil];
	[self selectedRegIndexChanged:nil];
	[self writeValueChanged:nil];
	[self selectedChannelValueChanged:nil];
	[self fifoBehaviourChanged:nil];
	[self postTriggerTimeChanged:nil];
    [self settingsLockChanged:nil];
	[self gapLengthChanged:nil];
	[self filterLengthChanged:nil];
	[self storeDataInRamChanged:nil];
	[self noiseFloorChanged:nil];
	[self noiseFloorOffsetChanged:nil];
	[self targetRateChanged:nil];
	[self fltModeFlagsChanged:nil];
	[self fiberEnableMaskChanged:nil];
	[self BBv1MaskChanged:nil];
	[self selectFiberTrigChanged:nil];
	[self streamMaskChanged:nil];
	[self fiberDelaysChanged:nil];
	[self fastWriteChanged:nil];
	[self statusRegisterChanged:nil];
	[self totalTriggerNRegisterChanged:nil];
	[self controlRegisterChanged:nil];
	[self repeatSWTriggerModeChanged:nil];
	[self swTriggerIsRepeatingChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:OREdelweissFLTSettingsLock to:secure];
    [settingLockButton setEnabled:secure];	
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
	[self updateButtons];
}

- (void) updateButtons
{
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:OREdelweissFLTSettingsLock];
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL locked = [gSecurity isLocked:OREdelweissFLTSettingsLock];
	BOOL testsAreRunning = [model testsRunning];
	BOOL testingOrRunning = testsAreRunning | runInProgress;
    
    [testEnabledMatrix setEnabled:!locked && !testingOrRunning];
    [settingLockButton setState: locked];
	[initBoardButton setEnabled:!lockedOrRunningMaintenance];
	[reportButton setEnabled:!lockedOrRunningMaintenance];
	[modeButton setEnabled:!lockedOrRunningMaintenance];
	[resetButton setEnabled:!lockedOrRunningMaintenance];
    [gainTextFields setEnabled:!lockedOrRunningMaintenance];
    [thresholdTextFields setEnabled:!lockedOrRunningMaintenance];
    [triggerEnabledCBs setEnabled:!lockedOrRunningMaintenance];
    [hitRateEnabledCBs setEnabled:!lockedOrRunningMaintenance];
	
	[versionButton setEnabled:!runInProgress];
	[testButton setEnabled:!runInProgress];
	[statusButton setEnabled:!runInProgress];
	
    [hitRateLengthPU setEnabled:!lockedOrRunningMaintenance];
    [hitRateAllButton setEnabled:!lockedOrRunningMaintenance];
    [hitRateNoneButton setEnabled:!lockedOrRunningMaintenance];
		
	if(testsAreRunning){
		[testButton setEnabled: YES];
		[testButton setTitle: @"Stop"];
	}
    else {
		[testButton setEnabled: !runInProgress];	
		[testButton setTitle: @"Test"];
	}
	

	[startNoiseFloorButton setEnabled: runInProgress || [model noiseFloorRunning]];
	
 	[self enableRegControls];
	
	//NSTabViewItem *tvi= [tabView tabViewItemAtIndex:4];
	//[tvi setEnabled:false];
	
}

- (void) enableRegControls
{
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:OREdelweissFLTSettingsLock];
	short index = [model selectedRegIndex];
	BOOL readAllowed = !lockedOrRunningMaintenance && ([model getAccessType:index] & kIpeRegReadable)>0;
	BOOL writeAllowed = !lockedOrRunningMaintenance && ([model getAccessType:index] & kIpeRegWriteable)>0;
	BOOL needsChannel = !lockedOrRunningMaintenance && ([model getAccessType:index] & kIpeRegNeedsChannel)>0;

	
	[regWriteButton setEnabled:writeAllowed];
	[regReadButton setEnabled:readAllowed];
	
	[regWriteValueStepper setEnabled:writeAllowed];
	[regWriteValueTextField setEnabled:writeAllowed];
    
    //TODO: extend the accesstype to "channel" and "block64" -tb-
    [channelPopUp setEnabled: needsChannel];
}

- (void) noiseFloorChanged:(NSNotification*)aNote
{
	if([model noiseFloorRunning]){
		[noiseFloorProgress startAnimation:self];
		[startNoiseFloorButton setTitle:@"Stop"];
	}
	else {
		[noiseFloorProgress stopAnimation:self];
		[startNoiseFloorButton setTitle:@"Start"];
	}
	[noiseFloorStateField setStringValue:[model noiseFloorStateString]];
	[noiseFloorStateField2 setStringValue:[model noiseFloorStateString]];
}

- (void) noiseFloorOffsetChanged:(NSNotification*)aNote
{
	[noiseFloorOffsetField setIntValue:[model noiseFloorOffset]];
}


- (void) testEnabledArrayChanged:(NSNotification*)aNotification
{
	int i;
	for(i=0;i<kNumEdelweissFLTTests;i++){
		[[testEnabledMatrix cellWithTag:i] setIntValue:[model testEnabled:i]];
	}    
}

- (void) testStatusArrayChanged:(NSNotification*)aNotification
{
	int i;
	for(i=0;i<kNumEdelweissFLTTests;i++){
		[[testStatusMatrix cellWithTag:i] setStringValue:[model testStatus:i]];
	}
}


- (void) scaleAction:(NSNotification*)aNotification
{
	if(aNotification == nil || [aNotification object] == [rate0 xAxis]){
		[model setMiscAttributes:[[rate0 xAxis]attributes] forKey:@"RateXAttributes"];
	};
	
	if(aNotification == nil || [aNotification object] == [totalRate xAxis]){
		[model setMiscAttributes:[[totalRate xAxis]attributes] forKey:@"TotalRateXAttributes"];
	};
	
	if(aNotification == nil || [aNotification object] == [timeRatePlot xAxis]){
		[model setMiscAttributes:[(ORAxis*)[timeRatePlot xAxis]attributes] forKey:@"TimeRateXAttributes"];
	};
	
	if(aNotification == nil || [aNotification object] == [timeRatePlot yAxis]){
		[model setMiscAttributes:[(ORAxis*)[timeRatePlot yAxis]attributes] forKey:@"TimeRateYAttributes"];
	};
	
}

- (void) miscAttributesChanged:(NSNotification*)aNote
{
	NSString*				key = [[aNote userInfo] objectForKey:ORMiscAttributeKey];
	NSMutableDictionary* attrib = [model miscAttributesForKey:key];
	
	if(aNote == nil || [key isEqualToString:@"RateXAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"RateXAttributes"];
		if(attrib){
			[[rate0 xAxis] setAttributes:attrib];
			[rate0 setNeedsDisplay:YES];
			[[rate0 xAxis] setNeedsDisplay:YES];
			[rateLogCB setState:[[attrib objectForKey:ORAxisUseLog] boolValue]];
		}
	}
	if(aNote == nil || [key isEqualToString:@"TotalRateXAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"TotalRateXAttributes"];
		if(attrib){
			[[totalRate xAxis] setAttributes:attrib];
			[totalRate setNeedsDisplay:YES];
			[[totalRate xAxis] setNeedsDisplay:YES];
			[totalRateLogCB setState:[[attrib objectForKey:ORAxisUseLog] boolValue]];
		}
	}
	if(aNote == nil || [key isEqualToString:@"TimeRateXAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"TimeRateXAttributes"];
		if(attrib){
			[(ORAxis*)[timeRatePlot xAxis] setAttributes:attrib];
			[timeRatePlot setNeedsDisplay:YES];
			[[timeRatePlot xAxis] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"TimeRateYAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"TimeRateYAttributes"];
		if(attrib){
			[(ORAxis*)[timeRatePlot yAxis] setAttributes:attrib];
			[timeRatePlot setNeedsDisplay:YES];
			[[timeRatePlot yAxis] setNeedsDisplay:YES];
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


- (void) gainChanged:(NSNotification*)aNotification
{
	int chan = [[[aNotification userInfo] objectForKey:OREdelweissFLTChan] intValue];
	[[gainTextFields cellWithTag:chan] setIntValue: [model gain:chan]];
}

- (void) triggerEnabledChanged:(NSNotification*)aNotification
{
	int i;
	for(i=0;i<kNumV4FLTChannels;i++){
		[[triggerEnabledCBs cellWithTag:i] setState: [model triggerEnabled:i]];
	}
}

- (void) thresholdChanged:(NSNotification*)aNotification
{
	int chan = [[[aNotification userInfo] objectForKey:OREdelweissFLTChan] intValue];
	[[thresholdTextFields cellWithTag:chan] setIntValue: [(OREdelweissFLTModel*)model threshold:chan]];
}


- (void) slotChanged:(NSNotification*)aNotification
{
    //DEBUG 	NSLog(@"%@::%@ \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
	// Set title of FLT configuration window, ak 15.6.07
	[[self window] setTitle:[NSString stringWithFormat:@"IPE-DAQ-V4 EDELWEISS FLT Card (Slot %d, FLT# %d)",[model slot]+1,[model stationNumber]]];
    [fltSlotNumTextField setStringValue: [NSString stringWithFormat:@"FLT# %d",[model stationNumber]]];
	//[fltSlotNumMatrix setSe];
    //[[fltSlotNumMatrix cellWithTag:[model stationNumber]] setIntValue:1];
	short chan;
	for(chan=0;chan<kNumV4FLTChannels;chan++){
	    if(chan==[model stationNumber]-1)
	        [[fltSlotNumMatrix cellAtRow:0 column:chan] setState:1];
		else
            [[fltSlotNumMatrix cellAtRow:0 column:chan] setState:0];
	}
}

- (void) gainArrayChanged:(NSNotification*)aNotification
{
	short chan;
	for(chan=0;chan<kNumV4FLTChannels;chan++){
		[[gainTextFields cellWithTag:chan] setIntValue: [model gain:chan]];
		
	}	
}

- (void) thresholdArrayChanged:(NSNotification*)aNotification
{
	short chan;
	for(chan=0;chan<kNumV4FLTChannels;chan++){
		[[thresholdTextFields cellWithTag:chan] setIntValue: [(OREdelweissFLTModel*)model threshold:chan]];
	}
}

- (void) triggersEnabledArrayChanged:(NSNotification*)aNotification
{
	short chan;
	for(chan=0;chan<kNumV4FLTChannels;chan++){
		[[triggerEnabledCBs cellWithTag:chan] setIntValue: [model triggerEnabled:chan]];
		
	}
}


- (void) modeChanged:(NSNotification*)aNote
{
	[modeButton selectItemAtIndex:[model runMode]];
	[self updateButtons];
}

- (void) hitRateLengthChanged:(NSNotification*)aNote
{
	[hitRateLengthPU selectItemWithTag:[model hitRateLength]];
}

- (void) hitRateChanged:(NSNotification*)aNote
{
	int chan;
	for(chan=0;chan<kNumV4FLTChannels;chan++){
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

- (void) selectedRegIndexChanged:(NSNotification*) aNote
{
	//	NSLog(@"This is v4FLT selectedRegIndexChanged\n" );
    //[registerPopUp selectItemAtIndex: [model selectedRegIndex]];
	[self updatePopUpButton:registerPopUp	 setting:[model selectedRegIndex]];
	
	[self enableRegControls];
}

- (void) writeValueChanged:(NSNotification*) aNote
{
    [regWriteValueTextField setIntValue: [model writeValue]];
}

- (void) selectedChannelValueChanged:(NSNotification*) aNote
{
    [channelPopUp selectItemWithTag: [model selectedChannelValue]];
	//[self updatePopUpButton:channelPopUp	 setting:[model selectedRegIndex]];
	
	[self enableRegControls];
}

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    [[self window] setContentView:blankView];
    switch([tabView indexOfTabViewItem:tabViewItem]){
        case  0: [self resizeWindowToSize:settingSize];     break;
		case  1: [self resizeWindowToSize:rateSize];	    break;
		case  2: [self resizeWindowToSize:testSize];        break;
		case  3: [self resizeWindowToSize:lowlevelSize];	break;
		default: [self resizeWindowToSize:testSize];	    break;
    }
    [[self window] setContentView:totalView];
	
    NSString* key = [NSString stringWithFormat: @"orca.OREdelweissFLT%d.selectedtab",[model stationNumber]];
    int index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
    
}

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Actions

- (void) repeatSWTriggerModePUAction:(id)sender
{
	[model setRepeatSWTriggerMode:[repeatSWTriggerModePU indexOfSelectedItem]];	
}

- (void) repeatSWTriggerModeTextFieldAction:(id)sender
{
	[model setRepeatSWTriggerMode:[sender intValue]];	
}

- (void) controlRegisterTextFieldAction:(id)sender
{
	[model setControlRegister:[sender intValue]];	
}

- (IBAction) writeControlRegisterButtonAction:(id)sender
{
    //DEBUG
 	NSLog(@"%@::%@ \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
	[model writeControl];	
}

- (IBAction) readControlRegisterButtonAction:(id)sender
{
    //DEBUG
 	NSLog(@"%@::%@ \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
	//[model setStatusLatency:[sender indexOfSelectedItem]];	
	unsigned long controlReg = [model  readControl]; //TODO: use try ... catch ... ? -tb-
	[model  setControlRegister: controlReg];

}


- (IBAction) statusLatencyPUAction:(id)sender
{
    //DEBUG
 	NSLog(@"%@::%@ [sender indexOfSelectedItem] %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),[sender indexOfSelectedItem]);//TODO: DEBUG testing ...-tb-
	[model setStatusLatency:[sender indexOfSelectedItem]];	
}

- (IBAction) vetoFlagCBAction:(id)sender
{
    //DEBUG
 	NSLog(@"%@::%@ \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
	[model setVetoFlag:[sender intValue]];	
}


- (void) totalTriggerNRegisterTextFieldAction:(id)sender
{
	[model setTotalTriggerNRegister:[sender intValue]];	
}

- (void) readStatusButtonAction:(id)sender
{
    //DEBUG
 	NSLog(@"%@::%@ \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
	[model readStatus];	
	[model readTotalTriggerNRegister];	
}

- (void) statusRegisterTextFieldAction:(id)sender
{
	[model setStatusRegister:[sender intValue]];	
}

- (void) fastWriteCBAction:(id)sender
{
	[model setFastWrite:[sender intValue]];	
}

- (void) writeFiberDelaysButtonAction:(id)sender
{
//DEBUG OUTPUT:
 	NSLog(@"%@::%@ \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
	[model writeFiberDelays];	
}

- (void) readFiberDelaysButtonAction:(id)sender
{
//DEBUG OUTPUT:
 	NSLog(@"%@::%@ \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
	[model readFiberDelays];	
}

- (void) fiberDelaysTextFieldAction:(id)sender
{
//DEBUG OUTPUT:
 	NSLog(@"%@::%@: there is something wrong! Please contact a ORCA expert!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
	//[model setFiberDelays:[sender intValue]];	
}

- (IBAction) fiberDelaysMatrixAction:(id)sender
{
//DEBUG OUTPUT:  	NSLog(@"%@::%@: UNDER CONSTRUCTION!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
	//[model setStreamMask:[sender intValue]];	
	uint64_t fib;
    uint64_t val=0;
	int clk12,clk120;
	uint64_t fibDelays;
	for(fib=0;fib<6;fib++){
		//debug NSString *s = [NSString stringWithFormat:@"fib %llu",fib];
		    clk12  = [[fiberDelaysMatrix cellAtRow:0 column: fib] indexOfSelectedItem];
		    clk120 = [[fiberDelaysMatrix cellAtRow:1 column: fib] indexOfSelectedItem];
			//debug s=[s stringByAppendingString: [NSString stringWithFormat:@"clk12 %i:",clk12]];
			//debug s=[s stringByAppendingString: [NSString stringWithFormat:@"clk120 %i:",clk120]];
			fibDelays = ((clk120 & 0xf) << 4)  |   (clk12 & 0xf);
			val |= ((fibDelays) << (fib*8));// see - (int) streamMaskForFiber:(int)aFiber chan:(int)aChan;
			//debug NSLog(@"%@\n",s);
	}
			//debug NSLog(@"%016qx done.\n",val);
	[model setFiberDelays:val];
}

- (IBAction) streamMaskEnableAllAction:(id)sender
{	[model setStreamMask:0x00003f3f3f3f3f3fLL];	 }

- (IBAction) streamMaskEnableNoneAction:(id)sender
{	[model setStreamMask:0x0];	 }


- (void) streamMaskTextFieldAction:(id)sender
{
	//[model setStreamMask:[sender intValue]];	
}

- (void) streamMaskMatrixAction:(id)sender
{
//DEBUG OUTPUT:  	NSLog(@"%@::%@: UNDER CONSTRUCTION!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
	//[model setStreamMask:[sender intValue]];	
	uint64_t chan, fib;
    uint64_t val=0;
	for(fib=0;fib<6;fib++){
		//debug NSString *s = [NSString stringWithFormat:@"fib %lli:",fib];
	    for(chan=0;chan<6;chan++){
		    if([[streamMaskMatrix cellAtRow:fib column: chan] intValue]){ 
			    val |= ((0x1LL<<chan) << (fib*8));// see - (int) streamMaskForFiber:(int)aFiber chan:(int)aChan;
				//debug s=[s stringByAppendingString: @"1"];
			}else{
				//debug s=[s stringByAppendingString: @"0"];
			}
		}
		//debug NSLog(@"%@\n",s);
	}
	//debug NSLog(@"%016qx done.\n",val);
	[model setStreamMask:val];
}


- (IBAction) writeStreamMaskRegisterButtonAction:(id)sender
{	[model writeStreamMask];	}

- (IBAction) readStreamMaskRegisterButtonAction:(id)sender
{	[model readStreamMask];	}



- (void) selectFiberTrigPUAction:(id)sender
{
//DEBUG OUTPUT:
 	NSLog(@"%@::%@: UNDER CONSTRUCTION! %i \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),[sender indexOfSelectedItem]);//TODO: DEBUG testing ...-tb-
	//[model setSelectFiberTrig:[sender intValue]];	
	[model setSelectFiberTrig:[sender indexOfSelectedItem]];	
}

- (void) BBv1MaskMatrixAction:(id)sender
{
	//[model setBBv1Mask:[sender intValue]];	
	int i, val=0;
	for(i=0;i<6;i++){
		if([[sender cellWithTag:i] intValue]) val |= (0x1<<i);
	}
	[model setBBv1Mask:val];
}

- (void) fiberEnableMaskMatrixAction:(id)sender
{
	//[model setFiberEnableMask:[sender intValue]];	
	int i, val=0;
	for(i=0;i<6;i++){
		if([[sender cellWithTag:i] intValue]) val |= (0x1<<i);
	}
	[model setFiberEnableMask:val];
}

- (void) fltModeFlagsPUAction:(id)sender
{
    int flags=4;
	switch([sender indexOfSelectedItem]){
	    case 0: flags=0x0; break;
	    case 1: flags=0x1; break;
	    case 2: flags=0x2; break;
	    case 3: flags=0x4; break;
	    default: flags=0; break;
	}
	//[model setFltModeFlags:[sender intValue]];	
	[model setFltModeFlags: flags];	
}





- (IBAction) writeCommandResyncAction:(id)sender
{
    //DEBUG OUTPUT:
 	NSLog(@"%@::%@ \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
	[model writeCommandResync];	
}

- (IBAction) writeCommandTrigEvCounterResetAction:(id)sender
{
    //DEBUG OUTPUT:
 	NSLog(@"%@::%@ \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
	[model writeCommandTrigEvCounterReset];	
}

- (IBAction) writeSWTriggerAction:(id)sender
{
	[model writeCommandSoftwareTrigger];	
}

- (IBAction) readTriggerDataAction:(id)sender
{
//DEBUG OUTPUT:
 	NSLog(@"%@::%@: UNDER CONSTRUCTION! \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
	[model readTriggerData];	
}


- (void) targetRateAction:(id)sender
{
	[model setTargetRate:[sender intValue]];	
}

- (IBAction) openNoiseFloorPanel:(id)sender
{
	[self endEditing];
    [NSApp beginSheet:noiseFloorPanel modalForWindow:[self window]
		modalDelegate:self didEndSelector:NULL contextInfo:nil];
}

- (IBAction) closeNoiseFloorPanel:(id)sender
{
    [noiseFloorPanel orderOut:nil];
    [NSApp endSheet:noiseFloorPanel];
}

- (IBAction) findNoiseFloors:(id)sender
{
	[noiseFloorPanel endEditingFor:nil];		
    @try {
        NSLog(@"IPE V4 FLT (StationNumber %d) Finding Thresholds \n",[model stationNumber]);
		[model findNoiseFloors];
    }
	@catch(NSException* localException) {
        NSLog(@"Threshold Finder for IPE V4 FLT Board FAILED.\n");
        NSRunAlertPanel([localException name], @"%@\nFailed Threshold finder", @"OK", nil, nil,
                        localException);
    }
}
- (IBAction) noiseFloorOffsetAction:(id)sender
{
    if([sender intValue] != [model noiseFloorOffset]){
        [model setNoiseFloorOffset:[sender intValue]];
    }
}


- (IBAction) storeDataInRamAction:(id)sender
{
	[model setStoreDataInRam:[sender intValue]];	
}

- (IBAction) filterLengthAction:(id)sender
{
	[model setFilterLength:[sender indexOfSelectedItem]+2];	 //tranlate back to range of 2 to 8
}

- (IBAction) gapLengthAction:(id)sender
{
	[model setGapLength:[sender indexOfSelectedItem]];	
}



- (IBAction) postTriggerTimeAction:(id)sender
{
	@try {
		[model setPostTriggerTime:[sender intValue]];	
	}
	@catch(NSException* localException) {
		NSLog(@"Exception reading FLT post trigger time\n");
		NSRunAlertPanel([localException name], @"%@\nSet post trigger time of FLT%d failed", @"OK", nil, nil,
						localException,[model stationNumber]);
	}
}

- (IBAction) fifoBehaviourAction:(id)sender
{
	@try {
		[model setFifoBehaviour:[[sender selectedCell]tag]];	
	}
	@catch(NSException* localException) {
		NSLog(@"Exception setting FLT behavior\n");
		NSRunAlertPanel([localException name], @"%@\nSetting Behaviour of FLT%d failed", @"OK", nil, nil,
						localException,[model stationNumber]);
	}
}

- (IBAction) analogOffsetAction:(id)sender
{
	@try {
		[model setAnalogOffset:[sender intValue]];	
	}
	@catch(NSException* localException) {
		NSLog(@"Exception setting FLT analog offset\n");
		NSRunAlertPanel([localException name], @"%@\nSet analog offset FLT%d failed", @"OK", nil, nil,
						localException,[model stationNumber]);
	}
}

- (IBAction) interruptMaskAction:(id)sender
{
	@try {
		[model setInterruptMask:[sender intValue]];	
	}
	@catch(NSException* localException) {
		NSLog(@"Exception setting FLT interrupt mask\n");
		NSRunAlertPanel([localException name], @"%@\nSet of interrupt mask of FLT%d failed", @"OK", nil, nil,
						localException,[model stationNumber]);
	}
}

- (IBAction) testEnabledAction:(id)sender
{
	NSMutableArray* anArray = [NSMutableArray array];
	int i;
	for(i=0;i<kNumEdelweissFLTTests;i++){
		if([[testEnabledMatrix cellWithTag:i] intValue])[anArray addObject:[NSNumber numberWithBool:YES]];
		else [anArray addObject:[NSNumber numberWithBool:NO]];
	}
	[model setTestEnabledArray:anArray];
}

- (IBAction) setDefaultsAction: (id) sender
{
	@try {
		[model setToDefaults];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception setting FLT default Values\n");
		NSRunAlertPanel([localException name], @"%@\nSet Defaults for FLT%d failed", @"OK", nil, nil,
						localException,[model stationNumber]);
	}
}

- (IBAction) readThresholdsGains:(id)sender
{



//TODO: readThresholdsGains    under construction -tb-
	@try {
		int i;
		NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
		NSLogFont(aFont,   @"FLT (station %d)\n",[model stationNumber]); // ak, 5.10.07
		NSLogFont(aFont,   @"chan | Gain | Threshold\n");
		NSLogFont(aFont,   @"-----------------------\n");
		for(i=0;i<kNumV4FLTChannels;i++){
			//NSLogFont(aFont,@"%4d | %4d | %4d \n",i,[model readGain:i],[model readThreshold:i]);
			//NSLog(@"%d: %d\n",i,[model readGain:i]);
		}
		NSLogFont(aFont,   @"-----------------------\n");
	}
	@catch(NSException* localException) {
		NSLog(@"Exception reading FLT gains and thresholds\n");
        NSRunAlertPanel([localException name], @"%@\nRead of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) writeThresholdsGains:(id)sender
{
	[self endEditing];
	@try {
		[model loadThresholdsAndGains];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception writing FLT gains and thresholds\n");
        NSRunAlertPanel([localException name], @"%@\nWrite of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
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
	if([sender intValue] != [(OREdelweissFLTModel*)model threshold:[[sender selectedCell] tag]]){
		[[self undoManager] setActionName: @"Set Threshold"];
		[model setThreshold:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}


- (IBAction) triggerEnableAction:(id)sender
{
	[[self undoManager] setActionName: @"Set TriggerEnabled"];
	[model setTriggerEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
}


- (IBAction) reportButtonAction:(id)sender
{
	[self endEditing];
	@try {
		[model printVersions];
		[model printStatusReg];
		//[model printPixelRegs];
		[model printValueTable];
		//[model printStatistics];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception reading FLT (%d) status\n",[model stationNumber]);
        NSRunAlertPanel([localException name], @"%@\nRead of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) initBoardButtonAction:(id)sender
{
	[self endEditing];
	@try {
		[model initBoard];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception intitBoard FLT (%d) status\n",[model stationNumber]);
        NSRunAlertPanel([localException name], @"%@\nWrite of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:OREdelweissFLTSettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) modeAction: (id) sender
{
	[model setRunMode:[modeButton indexOfSelectedItem]];
}

- (IBAction) versionAction: (id) sender
{
	@try {
		[model printVersions];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception reading FLT HW Model Version\n");
        NSRunAlertPanel([localException name], @"%@\nRead of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) testAction: (id) sender
{
	NSLog(@"HW tests are currently not available!\n");//TODO: test mode does not exist any more ... -tb- 7/2010
	return;
	@try {
		[model runTests];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception reading FLT HW Model Test\n");
        NSRunAlertPanel([localException name], @"%@\nFLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}


- (IBAction) resetAction: (id) sender
{
	@try {
		[model reset];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception during FLT reset\n");
        NSRunAlertPanel([localException name], @"%@\nFLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) hitRateLengthAction: (id) sender
{
	if([sender indexOfSelectedItem] != [model hitRateLength]){
		[[self undoManager] setActionName: @"Set Hit Rate Length"]; 
		[model setHitRateLength:[[sender selectedItem] tag]];
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

- (IBAction) enableAllTriggersAction: (id) sender
{
	[model enableAllTriggers:YES];
}

- (IBAction) enableNoTriggersAction: (id) sender
{
	[model enableAllTriggers:NO];
}

- (IBAction) statusAction:(id)sender
{
	@try {
		[model printStatusReg];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception during FLT read status\n");
        NSRunAlertPanel([localException name], @"%@\nRead of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) selectRegisterAction:(id) aSender
{
    if ([aSender indexOfSelectedItem] != [model selectedRegIndex]){
	    [[model undoManager] setActionName:@"Select Register"]; // Set undo name
	    [model setSelectedRegIndex:[aSender indexOfSelectedItem]]; // set new value
    }
}

- (IBAction) selectChannelAction:(id) aSender
{
    if ([[aSender selectedItem] tag] != [model selectedChannelValue]){
	    [[model undoManager] setActionName:@"Select Channel Number"]; // Set undo name do it at model side -tb-
	    [model setSelectedChannelValue:[[aSender selectedItem] tag]]; // set new value
    }
}

- (IBAction) writeValueAction:(id) aSender
{
	[self endEditing];
    if ([aSender intValue] != [model writeValue]){
		[[model undoManager] setActionName:@"Set Write Value"]; // Set undo name.
		[model setWriteValue:[aSender intValue]]; // Set new value
    }
}

- (IBAction) readRegAction: (id) sender
{
	int index = [model selectedRegIndex]; 
	@try {
		unsigned long value;
        if(([model getAccessType:index] & kIpeRegNeedsChannel)){
            int chan = [model selectedChannelValue];
		    value = [model readReg:index channel: chan ];
		    NSLog(@"FLTv4 reg: %@ for channel %i has value: 0x%x (%i)\n",[model getRegisterName:index], chan, value, value);
        }
		else {
		    value = [model readReg:index ];
		    NSLog(@"FLTv4 reg: %@ has value: 0x%x (%i)\n",[model getRegisterName:index],value, value);
        }
	}
	@catch(NSException* localException) {
		NSLog(@"Exception reading FLT reg: %@\n",[model getRegisterName:index]);
        NSRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) writeRegAction: (id) sender
{
	[self endEditing];
	int index = [registerPopUp indexOfSelectedItem];
	@try {
		unsigned long val = [model writeValue];
        if(([model getAccessType:index] & kIpeRegNeedsChannel)){
            int chan = [model selectedChannelValue];
     		[model writeReg:index  channel: chan value: val];//TODO: allow hex values, e.g. 0x23 -tb-
    		NSLog(@"wrote 0x%x (%i) to FLTv4 reg: %@ channel %i\n", val, val, [model getRegisterName:index], chan);
        }
		else{
    		[model writeReg:index value: val];//TODO: allow hex values, e.g. 0x23 -tb-
    		NSLog(@"wrote 0x%x (%i) to FLTv4 reg: %@ \n",val,val,[model getRegisterName:index]);
        }
	}
	@catch(NSException* localException) {
		NSLog(@"Exception writing FLTv4 reg: %@\n",[model getRegisterName:index]);
        NSRunAlertPanel([localException name], @"%@\nFLTv4%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) testButtonAction: (id) sender //temp routine to hook up to any on a temp basis
{
//DEBUG OUTPUT:
 	NSLog(@"WARNING: %@::%@: UNDER CONSTRUCTION! \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-

	@try {
		//[model testReadHisto];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception running FLT test code\n");
        NSRunAlertPanel([localException name], @"%@\nFLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Plot DataSource
- (int) numberPointsInPlot:(id)aPlotter
{
	return [[model  totalRate]count];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
	int count = [[model totalRate]count];
	int index = count-i-1;
	*yValue =  [[model totalRate] valueAtIndex:index];
	*xValue =  [[model totalRate] timeSampledAtIndex:index];
}

@end



