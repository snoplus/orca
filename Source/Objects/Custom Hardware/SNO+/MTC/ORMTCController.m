//
//  ORMTCController.m
//  Orca
//
//Created by Mark Howe on Fri, May 2, 2008
//Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
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

#import "ORMTCController.h"
#import "ORMTCModel.h"
#import "ORRate.h"
#import "ORRateGroup.h"
#import "ORValueBar.h"
#import "ORAxis.h"
#import "ORTimeRate.h"
#import "ORMTC_Constants.h"
#import "ORSelectorSequence.h"
#import "ORPQModel.h"


#define VIEW_RAW_UNITS_TAG 0
#define VIEW_mV_UNITS_TAG 1
#define VIEW_NHIT_UNITS_TAG 2

#define FIRST_NHIT_TAG 1
#define VIEW_N100H_TAG 1
#define VIEW_N100M_TAG 2
#define VIEW_N100L_TAG 3
#define VIEW_N20_TAG 4
#define VIEW_N20LB_TAG 5
#define VIEW_OWLN_TAG 6
#define LAST_NHIT_TAG 6

#define FIRST_ESUM_TAG 7
#define VIEW_ESUMH_TAG 7
#define VIEW_ESUML_TAG 8
#define VIEW_OWLEH_TAG 9
#define VIEW_OWLEL_TAG 10
#define LAST_ESUM_TAG 10


#pragma mark •••PrivateInterface
@interface ORMTCController (private)

- (void) setupNHitFormats;
- (void) setupESumFormats;
- (void) storeUserNHitValue:(float)value index:(int) thresholdIndex;
- (void) calcNHitValueForRow:(int) aRow;
- (void) storeUserESumValue:(float)userValue index:(int) thresholdIndex;
- (void) calcESumValueForRow:(int) aRow;

@end

@implementation ORMTCController

-(id)init
{
    self = [super initWithWindowNibName:@"MTC"];
    return self;
}

- (void) awakeFromNib
{
    standardOpsSizeSmall = NSMakeSize(460,440);
    standardOpsSizeLarge = NSMakeSize(460,760);
    settingsSizeSmall	 = NSMakeSize(600,430);
    settingsSizeLarge	 = NSMakeSize(600,630);
    triggerSize          = NSMakeSize(800,655);
    blankView = [[NSView alloc] init];
    [tabView setFocusRingType:NSFocusRingTypeNone];
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];

	[initProgressField setHidden:YES];
    [settingsAdvancedOptionsBox setHidden:YES];
    [opAdvancedOptionsBox setHidden:YES];

    [super awakeFromNib];
	
    NSString* key = [NSString stringWithFormat: @"orca.ORMTC%d.selectedtab",[model slot]];
    int index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;

    [tabView selectTabViewItemAtIndex: index];
    [self populatePullDown];
    [self updateWindow];
    [self grab_current_thresholds];
    [self trigger_scan_update_nhit];

}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [super registerNotificationObservers];

	//we don't want this notification
	[notifyCenter removeObserver:self name:NSWindowDidResignKeyNotification object:nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(slotChanged:)
						 name : ORVmeCardSlotChangedNotification
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(basicLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(basicLockChanged:)
                         name : ORMTCBasicLock
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(selectedRegisterChanged:)
                         name : ORMTCModelSelectedRegisterChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(memoryOffsetChanged:)
                         name : ORMTCModelMemoryOffsetChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(writeValueChanged:)
                         name : ORMTCModelWriteValueChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(repeatCountChanged:)
                         name : ORMTCModelRepeatCountChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(repeatDelayChanged:)
                         name : ORMTCModelRepeatDelayChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(useMemoryChanged:)
                         name : ORMTCModelUseMemoryChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(autoIncrementChanged:)
                         name : ORMTCModelAutoIncrementChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(basicOpsRunningChanged:)
                         name : ORMTCModelBasicOpsRunningChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(mtcDataBaseChanged:)
                         name : ORMTCModelMtcDataBaseChanged
						object: model];

	[notifyCenter addObserver : self
			 selector : @selector(isPulserFixedRateChanged:)
			     name : ORMTCModelIsPulserFixedRateChanged
			    object: model];

	[notifyCenter addObserver : self
			 selector : @selector(fixedPulserRateCountChanged:)
			     name : ORMTCModelFixedPulserRateCountChanged
			    object: model];

	[notifyCenter addObserver : self
			 selector : @selector(fixedPulserRateDelayChanged:)
			     name : ORMTCModelFixedPulserRateDelayChanged
			    object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(sequenceRunning:)
                         name : ORSequenceRunning
						object: model];
						
    [notifyCenter addObserver : self
                     selector : @selector(sequenceStopped:)
                         name : ORSequenceStopped
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(sequenceProgress:)
                         name : ORSequenceProgress
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(triggerMTCAMaskChanged:)
                         name : ORMTCModelMTCAMaskChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(placeholder:)
                         name : ORMTCAThresholdChanged
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(placeholder:)
                         name : ORMTCABaselineChanged
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(placeholder:)
                         name : ORMTCAConversionChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(triggerMTCAMaskChanged:)
                         name : ORMTCAThresholdChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(isPedestalEnabledInCSRChanged:)
                         name : ORMTCModelIsPedestalEnabledInCSR
                       object : nil];
}

- (void) updateWindow
{
    [super updateWindow];
    [self regBaseAddressChanged:nil];
    [self memBaseAddressChanged:nil];
    [self slotChanged:nil];
    [self basicLockChanged:nil];
	[self selectedRegisterChanged:nil];
	[self memoryOffsetChanged:nil];
	[self writeValueChanged:nil];
	[self repeatCountChanged:nil];
	[self repeatDelayChanged:nil];
	[self useMemoryChanged:nil];
	[self autoIncrementChanged:nil];
	[self basicOpsRunningChanged:nil];
	[self mtcDataBaseChanged:nil];
	[self isPulserFixedRateChanged:nil];
	[self fixedPulserRateCountChanged:nil];
	[self fixedPulserRateDelayChanged:nil];
    [self triggerMTCAMaskChanged:nil];
    [self isPedestalEnabledInCSRChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORMTCBasicLock to:secure];
    [basicOpsLockButton setEnabled:secure];
}

#pragma mark •••Interface Management
- (void) sequenceRunning:(NSNotification*)aNote
{
	sequenceRunning = YES;
	[initProgressBar startAnimation:self];
	[initProgressBar setDoubleValue:0];
	[initProgressField setHidden:NO];
	[initProgressField setDoubleValue:0];
    [self basicLockChanged:nil];
    //hack to unlock UI if the sequence couldn't finish and didn't raise an exception (MTCD feature)
    [self performSelector:@selector(sequenceStopped:) withObject:nil afterDelay:5];
}

- (void) sequenceStopped:(NSNotification*)aNote
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
	[initProgressField setHidden:YES];
	[initProgressBar setDoubleValue:0];
	[initProgressBar stopAnimation:self];
	sequenceRunning = NO;
    [self basicLockChanged:nil];
}

- (void) sequenceProgress:(NSNotification*)aNote
{
	double progress = [[[aNote userInfo] objectForKey:@"progress"] floatValue];
	[initProgressBar setDoubleValue:progress];
	[initProgressField setFloatValue:progress/100.];
}

- (void) mtcDataBaseChanged:(NSNotification*)aNote
{
	[lockOutWidthField		setFloatValue:	[model dbFloatByIndex: kLockOutWidth]];
	[pedestalWidthField		setFloatValue:	[model dbFloatByIndex: kPedestalWidth]];
	[nhit100LoPrescaleField setFloatValue:	[model dbFloatByIndex: kNhit100LoPrescale]];
	[pulserPeriodField		setFloatValue:	[model dbFloatByIndex: kPulserPeriod]];
    [extraPulserPeriodField	setFloatValue:	[model dbFloatByIndex: kPulserPeriod]];
    [fineSlopeField			setFloatValue:	[model dbFloatByIndex: kFineSlope]];
	[minDelayOffsetField	setFloatValue:	[model dbFloatByIndex: kMinDelayOffset]];
	[coarseDelayField		setFloatValue:	[model dbFloatByIndex: kCoarseDelay]];
	[fineDelayField			setFloatValue:	[model dbFloatByIndex: kFineDelay]];
	
	[self displayMasks];

	
	NSString* ss = [model dbObjectByIndex: kDBComments];
	if(!ss) ss = @"---";
	[commentsField setStringValue: ss];
}
- (void) placeholder:(NSNotification *)aNote {
    NSLog(@"Placeholder\n");
    int units;
    int view_index = [[nHitViewTypeMatrix selectedCell] tag];
    @try {
        units = [self convert_view_unit_index_to_model_index: view_index];
    } @catch (NSException *exception) {
        NSLogColor([NSColor redColor], @"Improve this error message later. %s\n",[exception reason]);
        return;
    }
    [self changeNhitThresholdsDisplay:units];
}

- (void) displayMasks
{
	int i;
	int maskValue = [model dbIntByIndex: kGtMask];
	for(i=0;i<26;i++){
		[[globalTriggerMaskMatrix cellWithTag:i]  setIntValue: maskValue & (1<<i)];
	}
	maskValue = [model dbIntByIndex: kGtCrateMask];
	for(i=0;i<25;i++){
		[[globalTriggerCrateMaskMatrix cellWithTag:i]  setIntValue: maskValue & (1<<i)];
	}
	maskValue = [model dbIntByIndex: kPEDCrateMask];
	for(i=0;i<25;i++){
		[[pedCrateMaskMatrix cellWithTag:i]  setIntValue: maskValue & (1<<i)];
	}
}

- (void) basicOpsRunningChanged:(NSNotification*)aNote
{
	if([model basicOpsRunning])[basicOpsRunningIndicator startAnimation:model];
	else [basicOpsRunningIndicator stopAnimation:model];
}

- (void) autoIncrementChanged:(NSNotification*)aNote
{
	[autoIncrementCB setIntValue: [model autoIncrement]];
}

- (void) useMemoryChanged:(NSNotification*)aNote
{
	[useMemoryMatrix selectCellWithTag: [model useMemory]];
}

- (void) repeatDelayChanged:(NSNotification*)aNote
{
	[repeatDelayField setIntValue: [model repeatDelay]];
	[repeatDelayStepper setIntValue:   [model repeatDelay]];
}

- (void) repeatCountChanged:(NSNotification*)aNote
{
	[repeatCountField setIntValue:	 [model repeatOpCount]];
	[repeatCountStepper setIntValue: [model repeatOpCount]];
}

- (void) writeValueChanged:(NSNotification*)aNote
{
	[writeValueField setIntValue: [model writeValue]];
}

- (void) memoryOffsetChanged:(NSNotification*)aNote
{
	[memoryOffsetField setIntValue: [model memoryOffset]];
}

- (void) selectedRegisterChanged:(NSNotification*)aNote
{
	[selectedRegisterPU selectItemAtIndex: [model selectedRegister]];
}

- (void) isPulserFixedRateChanged:(NSNotification*)aNote
{
	[[isPulserFixedRateMatrix cellWithTag:1] setIntValue:[model isPulserFixedRate]];
	[[isPulserFixedRateMatrix cellWithTag:0] setIntValue:![model isPulserFixedRate]];
    [self basicLockChanged:nil];
}

- (void) fixedPulserRateCountChanged:(NSNotification*)aNote
{
	[fixedTimePedestalsCountField setIntValue:[model fixedPulserRateCount]];
}

- (void) fixedPulserRateDelayChanged:(NSNotification*)aNote
{
	[fixedTimePedestalsDelayField setFloatValue:[model fixedPulserRateDelay]];
}

- (void) basicLockChanged:(NSNotification*)aNotification
{

    BOOL locked						= [gSecurity isLocked:ORMTCBasicLock];
    BOOL lockedOrNotRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORMTCBasicLock];

    //Basic ops
    [basicOpsLockButton setState: locked];
    [autoIncrementCB setEnabled: !lockedOrNotRunningMaintenance];
    [useMemoryMatrix setEnabled: !lockedOrNotRunningMaintenance];
    [repeatDelayField setEnabled: !lockedOrNotRunningMaintenance];
    [repeatDelayStepper setEnabled: !lockedOrNotRunningMaintenance];
    [repeatCountField setEnabled: !lockedOrNotRunningMaintenance];
    [repeatCountStepper setEnabled: !lockedOrNotRunningMaintenance];
    [writeValueField setEnabled: !lockedOrNotRunningMaintenance];
    [writeValueStepper setEnabled: !lockedOrNotRunningMaintenance];
    [memoryOffsetField setEnabled: !lockedOrNotRunningMaintenance];
    [memoryOffsetStepper setEnabled: !lockedOrNotRunningMaintenance];
    [selectedRegisterPU setEnabled: !lockedOrNotRunningMaintenance];
    [memBaseAddressStepper setEnabled: !lockedOrNotRunningMaintenance];
    [readButton setEnabled: !lockedOrNotRunningMaintenance];
    [writteButton setEnabled: !lockedOrNotRunningMaintenance];
    [stopButton setEnabled: !lockedOrNotRunningMaintenance];
    [statusButton setEnabled: !lockedOrNotRunningMaintenance];
    
    //Standards ops
    lockedOrNotRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORMTCBasicLock] | sequenceRunning;
    
    [initMtcButton				setEnabled: !lockedOrNotRunningMaintenance];
    [initNoXilinxButton			setEnabled: !lockedOrNotRunningMaintenance];
    [initNo10MHzButton			setEnabled: !lockedOrNotRunningMaintenance];
    [initNoXilinxNo100MHzButton setEnabled: !lockedOrNotRunningMaintenance];
    [pulserFeedsMatrix          setEnabled: !lockedOrNotRunningMaintenance];
    
    [firePedestalsButton		setEnabled: !lockedOrNotRunningMaintenance && [model isPulserFixedRate]];
    [stopPedestalsButton		setEnabled: !lockedOrNotRunningMaintenance && [model isPulserFixedRate]];
    [continuePedestalsButton	setEnabled: !lockedOrNotRunningMaintenance && [model isPulserFixedRate]];
    [fireFixedTimePedestalsButton	setEnabled: !lockedOrNotRunningMaintenance  && ![model isPulserFixedRate]];
    [stopFixedTimePedestalsButton	setEnabled: !lockedOrNotRunningMaintenance && ![model isPulserFixedRate]];
    [fixedTimePedestalsCountField	setEnabled: !lockedOrNotRunningMaintenance && ![model isPulserFixedRate]];
    [fixedTimePedestalsDelayField	setEnabled: !lockedOrNotRunningMaintenance && ![model isPulserFixedRate]];
    
    //Settings
    [load10MhzCounterButton		    setEnabled: !lockedOrNotRunningMaintenance];
    [setCoarseDelayButton           setEnabled: !lockedOrNotRunningMaintenance];
    [setFineDelayButton				setEnabled: !lockedOrNotRunningMaintenance];
    [loadMTCADacsButton				setEnabled: !lockedOrNotRunningMaintenance];
    [nhitMatrix                     setEnabled: !lockedOrNotRunningMaintenance];
    [esumMatrix                     setEnabled: !lockedOrNotRunningMaintenance];
    [lockOutWidthField              setEnabled: !lockedOrNotRunningMaintenance];
    [pedestalWidthField             setEnabled: !lockedOrNotRunningMaintenance];
    [low10MhzClockField             setEnabled: !lockedOrNotRunningMaintenance];
    [high10MhzClockField            setEnabled: !lockedOrNotRunningMaintenance];
    [nhit100LoPrescaleField         setEnabled: !lockedOrNotRunningMaintenance];
    [pulserPeriodField              setEnabled: !lockedOrNotRunningMaintenance];
    [extraPulserPeriodField         setEnabled: !lockedOrNotRunningMaintenance];
    [fineSlopeField                 setEnabled: !lockedOrNotRunningMaintenance];
    [minDelayOffsetField            setEnabled: !lockedOrNotRunningMaintenance];
    [fineDelayField                 setEnabled: !lockedOrNotRunningMaintenance];
    [coarseDelayField               setEnabled: !lockedOrNotRunningMaintenance];

    //Triggers
    [globalTriggerCrateMaskMatrix setEnabled: !lockedOrNotRunningMaintenance];
    [globalTriggerMaskMatrix setEnabled: !lockedOrNotRunningMaintenance];
    [pedCrateMaskMatrix setEnabled: !lockedOrNotRunningMaintenance];
    [mtcaEHIMatrix setEnabled: !lockedOrNotRunningMaintenance];
    [mtcaELOMatrix setEnabled: !lockedOrNotRunningMaintenance];
    [mtcaN100Matrix setEnabled: !lockedOrNotRunningMaintenance];
    [mtcaN20Matrix setEnabled: !lockedOrNotRunningMaintenance];
    [mtcaOEHIMatrix setEnabled: !lockedOrNotRunningMaintenance];
    [mtcaOELOMatrix setEnabled: !lockedOrNotRunningMaintenance];
    [mtcaOWLNMatrix setEnabled: !lockedOrNotRunningMaintenance];
    
    [loadGTCrateMaskButton setEnabled: !lockedOrNotRunningMaintenance];
    [loadMTCACrateMaskButton setEnabled: !lockedOrNotRunningMaintenance];
    [loadPEDCrateMaskButton setEnabled: !lockedOrNotRunningMaintenance];
    [loadTriggerMaskButton setEnabled: !lockedOrNotRunningMaintenance];
}

- (void) isPedestalEnabledInCSRChanged:(NSNotification*)aNotification
{
    if ([model isPedestalEnabledInCSR]) {
        [[pulserFeedsMatrix cellWithTag:0] setIntegerValue:0];
        [[pulserFeedsMatrix cellWithTag:1] setIntegerValue:1];
    }
    else {
        [[pulserFeedsMatrix cellWithTag:0] setIntegerValue:1];
        [[pulserFeedsMatrix cellWithTag:1] setIntegerValue:0];
    }
}

- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)item
{

    if ([tabView indexOfTabViewItem:item] == 0){
        NSSize* newSize =nil;
        if([opAdvancedOptionsBox isHidden]) {
            newSize = &standardOpsSizeSmall;
        }
        else {
            newSize = &standardOpsSizeLarge;
        }
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:*newSize];
		[[self window] setContentView:mtcView];
    }
    else if([tabView indexOfTabViewItem:item] == 1){
        NSSize* newSize = nil;
        if([settingsAdvancedOptionsBox isHidden]) {
            newSize = &settingsSizeSmall;
        }
        else {
            newSize = &settingsSizeLarge;
        }
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:*newSize];
		[[self window] setContentView:mtcView];
    }
    else if([tabView indexOfTabViewItem:item] == 2){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:triggerSize];
		[[self window] setContentView:mtcView];
    }


    NSString* key = [NSString stringWithFormat: @"orca.ORMTC%d.selectedtab",[model slot]];
    int index = [tabView indexOfTabViewItem:item];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
	
}

- (void) slotChanged:(NSNotification*)aNotification
{
	[slotField setIntValue: [model slot]];
	[[self window] setTitle:[NSString stringWithFormat:@"MTC Card (Slot %d)",[model slot]]];
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"MTC Card (Slot %d)",[model slot]]];
}

- (void) regBaseAddressChanged:(NSNotification*)aNotification
{
	[regBaseAddressText setIntValue: [model baseAddress]];
}

- (void) memBaseAddressChanged:(NSNotification*)aNotification
{
	[memBaseAddressText setIntValue: [model memBaseAddress]];
}

- (void) triggerMTCAMaskChanged:(NSNotification*)aNotification
{
    unsigned long maskValue = [model mtcaN100Mask];
    unsigned short i;
	for(i=0;i<20;i++) [[mtcaN100Matrix cellWithTag:i] setIntValue: maskValue & (1<<i)];

    maskValue = [model mtcaN20Mask];
	for(i=0;i<20;i++) [[mtcaN20Matrix cellWithTag:i] setIntValue: maskValue & (1<<i)];

    maskValue = [model mtcaEHIMask];
	for(i=0;i<20;i++) [[mtcaEHIMatrix cellWithTag:i] setIntValue: maskValue & (1<<i)];

    maskValue = [model mtcaELOMask];
	for(i=0;i<20;i++) [[mtcaELOMatrix cellWithTag:i] setIntValue: maskValue & (1<<i)];
    
    maskValue = [model mtcaOELOMask];
	for(i=0;i<20;i++) {
        if ([mtcaOELOMatrix cellWithTag:i]) {
            [[mtcaOELOMatrix cellWithTag:i]  setIntValue: maskValue & (1<<i)];
        }
    }

    maskValue = [model mtcaOEHIMask];
	for(i=0;i<20;i++) {
        if ([mtcaOEHIMatrix cellWithTag:i]) {
            [[mtcaOEHIMatrix cellWithTag:i]  setIntValue: maskValue & (1<<i)];
        }
    }

    maskValue = [model mtcaOWLNMask];
	for(i=0;i<20;i++) {
        if ([mtcaOWLNMatrix cellWithTag:i]) {
            [[mtcaOWLNMatrix cellWithTag:i]  setIntValue: maskValue & (1<<i)];
        }
    }
}

#pragma mark •••Actions

- (IBAction) basicAutoIncrementAction:(id)sender
{
	[model setAutoIncrement:[sender intValue]];	
}

//basic ops
- (IBAction) basicUseMemoryAction:(id)sender
{
	[model setUseMemory:[[sender selectedCell] tag]];	
}

- (IBAction) basicRepeatDelayAction:(id)sender
{
	[model setRepeatDelay:[sender intValue]];	
}

- (IBAction) basicRepeatCountAction:(id)sender
{
	[model setRepeatOpCount:[sender intValue]];	
}

- (IBAction) basicWriteValueAction:(id)sender
{
	[model setWriteValue:[sender intValue]];	
}

- (IBAction) basicMemoryOffsetAction:(id)sender
{
	[model setMemoryOffset:[sender intValue]];	
}

- (void) basicSelectedRegisterAction:(id)sender
{
	[model setSelectedRegister:[sender indexOfSelectedItem]];	
}

- (IBAction) basicLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORMTCBasicLock to:[sender intValue] forWindow:[self window]];
}

- (void) populatePullDown
{
    short	i;
        
    [selectedRegisterPU removeAllItems];
    
    for (i = 0; i < [model getNumberRegisters]; i++) {
        [selectedRegisterPU insertItemWithTitle:[model getRegisterName:i] atIndex:i];
    }
     
    [self selectedRegisterChanged:nil];

}

//basic ops Actions
- (IBAction) basicReadAction:(id) sender
{
	[model readBasicOps];
}

- (IBAction) basicWriteAction:(id) sender
{
	[model writeBasicOps];
}

- (IBAction) basicStatusAction:(id) sender
{
	[model reportStatus];
}

- (IBAction) basicStopAction:(id) sender
{
	[model stopBasicOps];
}

//MTC Init Ops buttons.
- (IBAction) standardInitMTC:(id) sender 
{
	[model initializeMtc:YES load10MHzClock:YES]; 
}

- (IBAction) standardInitMTCnoXilinx:(id) sender 
{
	[model initializeMtc:NO load10MHzClock:YES]; 
}

- (IBAction) standardInitMTCno10MHz:(id) sender 
{
	[model initializeMtc:YES load10MHzClock:NO]; 
}

- (IBAction) standardInitMTCnoXilinxno10MHz:(id) sender 
{
	[model initializeMtc:NO load10MHzClock:NO]; 
}

- (IBAction) standardLoad10MHzCounter:(id) sender 
{
	[model load10MHzClock];
}

- (IBAction) standardLoadOnlineGTMasks:(id) sender 
{
	[model setGlobalTriggerWordMask];
}
	
- (IBAction) standardLoadMTCADacs:(id) sender 
{
	[model loadTheMTCADacs];
}

- (IBAction) standardSetCoarseDelay:(id) sender 
{
	[model setupGTCorseDelay];
}

- (IBAction) standardSetFineDelay:(id) sender
{
    [model setupGTFineDelay];
}

- (IBAction) standardIsPulserFixedRate:(id) sender
{
	[self endEditing];
	[model setIsPulserFixedRate:[[sender selectedCell] tag]];
}

- (IBAction) standardFirePedestals:(id) sender 
{
	[model fireMTCPedestalsFixedRate];
}

- (IBAction) standardStopPedestals:(id) sender 
{
	[model stopMTCPedestalsFixedRate];
}

- (IBAction) standardContinuePedestals:(id) sender 
{
	[model continueMTCPedestalsFixedRate];
}

- (IBAction) standardFirePedestalsFixedTime:(id) sender
{
	[model fireMTCPedestalsFixedTime];
}

- (IBAction) standardStopPedestalsFixedTime:(id) sender
{
	[model stopMTCPedestalsFixedTime];
}

- (IBAction) standardSetPedestalsCount:(id) sender
{
	unsigned long aValue = [sender intValue];
	if (aValue < 1) aValue = 1;
	if (aValue > 10000) aValue = 10000;
	[model setFixedPulserRateCount:aValue];
}

- (IBAction) standardSetPedestalsDelay:(id) sender
{
	float aValue = [sender floatValue];
	if (aValue < 0.1) aValue = 0.1;
	if (aValue > 2000000) aValue = 2000000;
	[model setFixedPulserRateDelay:aValue];
}


- (IBAction) standardPulserFeeds:(id)sender
{
    [model setIsPedestalEnabledInCSR:[[sender selectedCell] tag]];
    [self endEditing];
}

//Settings buttons.
- (IBAction) eSumViewTypeAction:(id)sender
{
    int unit_index;
    int view_index = [[sender selectedCell] tag];
    @try {
        unit_index = [self convert_view_unit_index_to_model_index:view_index];
    } @catch (NSException *exception) {
        NSLogColor([NSColor redColor], @"Could not change views. Reason:%s\n",[exception reason]);
        return;
    }
    [self changeESUMThresholdDisplay:unit_index];
}

- (IBAction) nHitViewTypeAction:(id)sender
{
    int unit_index;
    int view_index = [[sender selectedCell] tag];
    @try {
        unit_index = [self convert_view_unit_index_to_model_index:view_index];
    } @catch (NSException *exception) {
        NSLogColor([NSColor redColor], @"Could not change views. Reason:%s\n",[exception reason]);
        return;
    }
    [self changeNhitThresholdsDisplay: [self convert_view_unit_index_to_model_index:unit_index]];

}
- (IBAction)opsAdvancedOptionsTriangeChanged:(id)sender {
    [self showHideOptions:sender Box:opAdvancedOptionsBox resizeSmall:standardOpsSizeSmall resizeLarge:standardOpsSizeLarge];
}
- (IBAction)settingsAdvancedOptionsTriangeChanged:(id)sender {
    [self showHideOptions:sender Box:settingsAdvancedOptionsBox resizeSmall:settingsSizeSmall resizeLarge:settingsSizeLarge];
}
- (void) showHideOptions:(id) sender Box:(id)box resizeSmall:(NSSize) smallSize resizeLarge:(NSSize) largeSize {
    if([sender state] == NSOffState) {
        [box setHidden:YES];
        [self resizeWindowToSize:smallSize];
    }
    else {
        [box setHidden:NO];
        // Don't resize if the window is already large enough
        if(self.window.frame.size.height <  largeSize.height || self.window.frame.size.width < largeSize.width)
        {
            [self resizeWindowToSize:largeSize];
        }
    }
}
- (void) changeNhitThresholdsDisplay: (int) type
{
    int threshold_index;
    for(int i=FIRST_NHIT_TAG;i<=LAST_NHIT_TAG;i++)
    {
        @try {
            threshold_index = [self convert_view_thresold_index_to_model_index:i];
        } @catch (NSException *exception) {
            NSLogColor([NSColor redColor], @"Failed to interpret a tag, Reason: %s\n. Someone must have changed the MTC view or something. Aborting after %i changes",[exception reason],i-FIRST_NHIT_TAG);
            return;
        }
        float value = [model getThresholdOfType: threshold_index inUnits:type];
        [[nhitMatrix cellWithTag:i] setFloatValue: value];
    }
}
- (void) changeESUMThresholdDisplay: (int) type
{
    int threshold_index;
    for(int i=FIRST_ESUM_TAG;i<=LAST_ESUM_TAG;i++)
    {
        @try {
            threshold_index = [self convert_view_thresold_index_to_model_index:i];
        } @catch (NSException *exception) {
            NSLogColor([NSColor redColor], @"Failed to interpret a tag, Reason: %s\n. Someone must have changed the MTC view or something. Aborting after %i changes",[exception reason],i-FIRST_ESUM_TAG);
            return;
        }
        float value = [model getThresholdOfType: threshold_index inUnits:type];
        [[esumMatrix cellWithTag:i] setFloatValue: value];
    }
}
- (int) convert_view_thresold_index_to_model_index: (int) view_index {
    switch (view_index) {
        case VIEW_N100H_TAG:
            return MTC_N100_HI_THRESHOLD_INDEX;
            break;
        case VIEW_N100M_TAG:
            return MTC_N100_MED_THRESHOLD_INDEX;
            break;
        case VIEW_N100L_TAG:
            return MTC_N100_LO_THRESHOLD_INDEX;
            break;
        case VIEW_N20_TAG:
            return MTC_N20_THRESHOLD_INDEX;
            break;
        case VIEW_N20LB_TAG:
            return MTC_N20LB_THRESHOLD_INDEX;
            break;
        case VIEW_ESUMH_TAG:
            return MTC_ESUMH_THRESHOLD_INDEX;
            break;
        case VIEW_ESUML_TAG:
            return MTC_ESUML_THRESHOLD_INDEX;
            break;
        case VIEW_OWLEH_TAG:
            return MTC_OWLEHI_THRESHOLD_INDEX;
            break;
        case VIEW_OWLEL_TAG:
            return MTC_OWLELO_THRESHOLD_INDEX;
            break;
        case VIEW_OWLN_TAG:
            return MTC_OWLN_THRESHOLD_INDEX;
            break;
        default:
            [NSException raise:@"MTCController" format:@"Cannot convert threshold index %i to model index",view_index];
            break;
    }
    return -1; // Will never reach here
}
- (int) convert_model_threshold_index_to_view_index: (int) model_index{
    switch (model_index) {
        case MTC_N100_HI_THRESHOLD_INDEX:
            return VIEW_N100H_TAG;
            break;
        case MTC_N100_MED_THRESHOLD_INDEX:
            return VIEW_N100M_TAG;
            break;
        case MTC_N100_LO_THRESHOLD_INDEX:
            return VIEW_N100L_TAG;
            break;
        case MTC_N20_THRESHOLD_INDEX:
            return VIEW_N20_TAG;
            break;
        case MTC_N20LB_THRESHOLD_INDEX:
            return VIEW_N20LB_TAG;
            break;
        case MTC_ESUMH_THRESHOLD_INDEX:
            return VIEW_ESUMH_TAG;
            break;
        case MTC_ESUML_THRESHOLD_INDEX:
            return VIEW_ESUML_TAG;
            break;
        case MTC_OWLEHI_THRESHOLD_INDEX:
            return VIEW_OWLEH_TAG;
            break;
        case MTC_OWLELO_THRESHOLD_INDEX:
            return VIEW_OWLEL_TAG;
            break;
        case MTC_OWLN_THRESHOLD_INDEX:
            return VIEW_OWLN_TAG;
            break;
        default:
            [NSException raise:@"MTCController" format:@"Cannot convert threshold  index %i to view index",model_index];
        break;
    }
    return -1;
}
- (int) convert_view_unit_index_to_model_index: (int) view_index {
    switch (view_index) {
        case VIEW_RAW_UNITS_TAG:
            return MTC_RAW_UNITS;
            break;
        case VIEW_mV_UNITS_TAG:
            return MTC_mV_UNITS;
            break;
        case VIEW_NHIT_UNITS_TAG:
            return MTC_NHIT_UNITS;
            break;
        default:
            [NSException raise:@"MTCController" format:@"Cannot convert units index %i to model index",view_index];
            break;
    }
    return -1;
}
- (int) convert_model_unit_index_to_view_index: (int) model_index {
    switch (model_index) {
        case MTC_RAW_UNITS:
            return VIEW_RAW_UNITS_TAG;
            break;
        case MTC_mV_UNITS:
            return VIEW_NHIT_UNITS_TAG;
            break;
        case MTC_NHIT_UNITS:
            return VIEW_NHIT_UNITS_TAG;
            break;
        default:
            [NSException raise:@"MTCController" format:@"Cannot convert units index %i to view index",model_index];
            break;
    }
    return -1;
}
- (IBAction) settingsMTCDAction:(id) sender
{
	[model setDbObject:[sender stringValue] forIndex:[sender tag]];
}

- (IBAction) settingsNHitAction:(id) sender 
{
    int threshold_index, unit_index;
    @try {
        threshold_index = [self convert_view_thresold_index_to_model_index:[[sender selectedCell] tag]];
        unit_index = [self convert_view_unit_index_to_model_index:[[nHitViewTypeMatrix selectedCell] tag]];
    } @catch (NSException *exception) {
        NSLogColor([NSColor redColor], @"%s\n Aborting\n",[exception reason]);
        return;
    }
    float threshold = [[sender selectedCell] floatValue];
    [model setThresholdOfType:threshold_index fromUnits:unit_index toValue:threshold];
}


- (IBAction) settingsESumAction:(id) sender 
{
    NSLog(@"SettingsESUMAction needs implementation\n");

}
- (IBAction)updateConversionSettingsAction:(id)sender{
    [self trigger_scan_update_nhit];

}
- (IBAction) EditingWindow:(id)sender
{
    NSWindowController *newWindow = [[NSWindowController alloc] init];
    [newWindow showWindow:self];
}
- (void) trigger_scan_update_nhit {
    int threshold_index;
    for(int i = FIRST_NHIT_TAG;i<LAST_NHIT_TAG+1;i++)
    {
        @try {
            threshold_index = [self convert_view_thresold_index_to_model_index:i];
        } @catch (NSException *exception) {
            NSLogColor([NSColor redColor], @"Loaded %i trigge_scans then encountered an error:\n%s\n",i-FIRST_NHIT_TAG,[exception reason]);
            return;
        }
        [self load_settings_from_trigger_scan_for_type:threshold_index];
    }
}


- (IBAction)grab_current_thresholds:(id)sender {
    [self grab_current_thresholds];
}

- (void) waitForTriggerScan: (ORPQResult *) result
{
    int numRows, numCols;
    
    if (!result) {
        //Handle this
        
    }
    
    numRows = [result numOfRows];
    numCols = [result numOfFields];
    if (numRows != 1) {
        //Handle error
    }
    
    if (numCols != 3) {
        // Handle error
    }
    NSDictionary* result_dict = [result fetchRowAsDictionary];
    if(!result_dict)
    {
        //No row exists
        //Handle error
        
    }
    NSLog(@"%@\n",result_dict);
    NSString* name = [result_dict objectForKey:@"name"];
    NSString* baseline = [[result_dict objectForKey:@"baseline"] stringValue];
    
    NSString* dac_per_nhit =[[result_dict objectForKey:@"adc_per_nhit"] stringValue];
    [model setBaselineOfType:[self trigger_scan_name_to_index:name] toValue:[baseline intValue]];
    [model setDAC_per_NHIT_OfType:[self trigger_scan_name_to_index:name] toValue:[dac_per_nhit floatValue]];
    [model setDAC_per_mV_OfType:[self trigger_scan_name_to_index:name] toValue:-4096/10000.0];
    
    
    return;
}
- (int) trigger_scan_name_to_index:(NSString*) name {
    int ret = -1;
    if([name isEqual:@"N100LO"]){ ret = MTC_N100_LO_THRESHOLD_INDEX; }
    else if([name isEqual:@"N100MED"]){ ret = MTC_N100_MED_THRESHOLD_INDEX; }
    else if([name isEqual:@"N100HI"]){ ret = MTC_N100_HI_THRESHOLD_INDEX; }
    else if([name isEqual:@"N20"]){ ret = MTC_N20_THRESHOLD_INDEX; }
    else if([name isEqual:@"N20LB"]){ ret = MTC_N20LB_THRESHOLD_INDEX; }
    else if([name isEqual:@"OWLN"]){ ret = MTC_OWLN_THRESHOLD_INDEX; }
    else {/*raise exception?*/}
    return ret;
}
- (int) index_to_trigger_scan_name:(int) index {
    NSString *ret = @"";
    switch (index) {
        case MTC_N100_HI_THRESHOLD_INDEX:
            ret = @"N100HI";
            break;
        case MTC_N100_MED_THRESHOLD_INDEX:
            ret = @"N100MED";
            break;
        case MTC_N100_LO_THRESHOLD_INDEX:
            ret = @"N100LO";
            break;
        case MTC_N20_THRESHOLD_INDEX:
            ret = @"N20";
            break;
        case MTC_N20LB_THRESHOLD_INDEX:
            ret = @"N20LB";
            break;
        case MTC_OWLN_THRESHOLD_INDEX:
            ret = @"OWLN";
            break;
        default:
            //Raise exception?
            break;
    }
    return ret;
}
- (void) waitForThresholds: (ORPQResult *) result
{
    int numRows, numCols;
    
    if (!result) {
        //Handle this
        
    }
    
    numRows = [result numOfRows];
    numCols = [result numOfFields];
    if (numRows != 1) {
        //Handle error
    }
    
    if (numCols != 1) {
        // Handle error
    }
    NSArray* result_arr = [[result fetchRowAsDictionary] objectForKey:@"mtca_dacs"];
    if(!result_arr)
    {
        //No row exists
        //Handle error
    }

    
    // Note this could be done with a for loop, but I think this is more readable.
    [model setThresholdOfType:MTC_N100_LO_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[result_arr objectAtIndex:SERVER_N100L_INDEX] floatValue]];
    [model setThresholdOfType:MTC_N100_MED_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[result_arr objectAtIndex:SERVER_N100M_INDEX] floatValue]];
    [model setThresholdOfType:MTC_N100_HI_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[result_arr objectAtIndex:SERVER_N100H_INDEX] floatValue]];
    [model setThresholdOfType:MTC_N20_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[result_arr objectAtIndex:SERVER_N20_INDEX] floatValue]];
    [model setThresholdOfType:MTC_N20LB_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[result_arr objectAtIndex:SERVER_N20LB_INDEX] floatValue]];
    [model setThresholdOfType:MTC_ESUML_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[result_arr objectAtIndex:SERVER_ESUML_INDEX] floatValue]];
    [model setThresholdOfType:MTC_ESUMH_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[result_arr objectAtIndex:SERVER_ESUMH_INDEX] floatValue]];
    [model setThresholdOfType:MTC_OWLN_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[result_arr objectAtIndex:SERVER_OWLN_INDEX] floatValue]];
    [model setThresholdOfType:MTC_OWLELO_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[result_arr objectAtIndex:SERVER_OWLEL_INDEX] floatValue]];
    [model setThresholdOfType:MTC_OWLEHI_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[result_arr objectAtIndex:SERVER_OWLEH_INDEX] floatValue]];
    
    NSLog(@"%@\n",result_arr);
}
- (void) load_settings_from_trigger_scan_for_type:(int) type {
    //Note perhaps this should be moved out of the model??
    ORPQModel* pgsql_connec = [ORPQModel getCurrent];
    if(!pgsql_connec)
    {
        NSLog(@"Shitsbad\n");
        return;
        //Raise exception
    }
    NSString* trig_scan_name = [self index_to_trigger_scan_name:type];
    NSString* db_cmd = [NSString stringWithFormat:@"select name,baseline,adc_per_nhit from trigger_scan where name='%@' and timestamp=(SELECT max(timestamp) from trigger_scan where name='%@')",trig_scan_name,trig_scan_name];
    [pgsql_connec dbQuery:db_cmd object:self selector:@selector(waitForTriggerScan:) timeout:2.0];
}

- (void) grab_current_thresholds {
    ORPQModel* pgsql_connec = [ORPQModel getCurrent];
    if(!pgsql_connec)
    {
        NSLog(@"Shitsbad\n");
        return;
        //Raise exception
    }
    NSString* db_cmd = [NSString stringWithFormat:@"select mtca_dacs from mtc where key=0"];
    [pgsql_connec dbQuery:db_cmd object:self selector:@selector(waitForThresholds:) timeout:2.0];
}

- (IBAction) settingsGTMaskAction:(id) sender
{
	unsigned long mask = 0;
	int i;
	for(i=0;i<26;i++){
		if([[sender cellWithTag:i] intValue]){	
			mask |= (1L << i);
		}
	}
	[model setDbLong:mask forIndex:kGtMask];
}

- (IBAction) settingsGTCrateMaskAction:(id) sender 
{
	unsigned long mask = 0;
	int i;
	for(i=0;i<25;i++){
		if([[sender cellWithTag:i] intValue]){	
			mask |= (1L << i);
		}
	}
	[model setDbLong:mask forIndex:kGtCrateMask];
}

- (IBAction) settingsPEDCrateMaskAction:(id) sender 
{
	unsigned long mask = 0;
	int i;
	for(i=0;i<25;i++){
		if([[sender cellWithTag:i] intValue]){	
			mask |= (1L << i);
		}
	}
	[model setDbLong:mask forIndex:kPEDCrateMask];
}


- (IBAction) triggerMTCAN100:(id) sender
{
    unsigned long mask = 0;
	int i;
	for(i=0;i<20;i++){
		if([[sender cellWithTag:i] intValue]){
			mask |= (1L << i);
		}
	}
    [model setMtcaN100Mask:mask];
}

- (IBAction) triggerMTCAN20:(id) sender
{
    unsigned long mask = 0;
	int i;
	for(i=0;i<20;i++){
		if([[sender cellWithTag:i] intValue]){
			mask |= (1L << i);
		}
	}
    [model setMtcaN20Mask:mask];
}

- (IBAction) triggerMTCAEHI:(id) sender
{
    unsigned long mask = 0;
	int i;
	for(i=0;i<20;i++){
		if([[sender cellWithTag:i] intValue]){
			mask |= (1L << i);
		}
	}
    [model setMtcaEHIMask:mask];
}

- (IBAction) triggerMTCAELO:(id) sender
{
    unsigned long mask = 0;
	int i;
	for(i=0;i<20;i++){
		if([[sender cellWithTag:i] intValue]){
			mask |= (1L << i);
		}
	}
    [model setMtcaELOMask:mask];
}

- (IBAction) triggerMTCAOELO:(id) sender
{
    unsigned long mask = 0;
	int i;
	for(i=0;i<20;i++){
		if([sender cellWithTag:i] && [[sender cellWithTag:i] intValue]){
			mask |= (1L << i);
		}
	}
    [model setMtcaOELOMask:mask];
}

- (IBAction) triggerMTCAOEHI:(id) sender
{
    unsigned long mask = 0;
	int i;
	for(i=0;i<20;i++){
		if([sender cellWithTag:i] && [[sender cellWithTag:i] intValue]){
			mask |= (1L << i);
		}
	}
    [model setMtcaOEHIMask:mask];
}

- (IBAction) triggerMTCAOWLN:(id) sender
{
    unsigned long mask = 0;
	int i;
	for(i=0;i<20;i++){
		if([sender cellWithTag:i] && [[sender cellWithTag:i] intValue]){
			mask |= (1L << i);
		}
	}
    [model setMtcaOWLNMask:mask];
}

- (IBAction) triggersLoadTriggerMask:(id) sender
{
    [model setGlobalTriggerWordMask];
}

- (IBAction) triggersLoadGTCrateMask:(id) sender
{
    [model setGTCrateMask];
}

- (IBAction) triggersLoadPEDCrateMask:(id) sender
{
    [model setPedestalCrateMask];
}

- (IBAction) triggersLoadMTCACrateMask:(id) sender
{
    [model mtcatLoadCrateMasks];
}

- (IBAction)triggerMaskCheckBoxClicked:(id)sender {
    [self CheckBoxMatrixCellClicked:globalTriggerMaskMatrix newState:![[sender selectedCell] nextState]];
}
- (IBAction)gtCratesCheckBoxClicked:(id)sender {
    [self CheckBoxMatrixCellClicked:globalTriggerCrateMaskMatrix newState:![[sender selectedCell] nextState]];
}
- (IBAction)pedCrateCheckBoxClicked:(id)sender {
    [self CheckBoxMatrixCellClicked:pedCrateMaskMatrix newState:![[sender selectedCell] nextState]];
}
- (IBAction)n100RelayCheckBoxClicked:(id)sender {
    [self CheckBoxMatrixCellClicked:mtcaN100Matrix newState:![[sender selectedCell] nextState]];
}
- (IBAction)n20RelayCheckBoxClicked:(id)sender {
    [self CheckBoxMatrixCellClicked:mtcaN20Matrix newState:![[sender selectedCell] nextState]];
}
- (IBAction)esumhRelayCheckBoxClicked:(id)sender {
    [self CheckBoxMatrixCellClicked:mtcaEHIMatrix newState:![[sender selectedCell] nextState]];
}
- (IBAction)esumlRelayCheckBoxClicked:(id)sender {
    [self CheckBoxMatrixCellClicked:mtcaELOMatrix newState:![[sender selectedCell] nextState]];

}
- (IBAction)owlehRelayCheckBoxClicked:(id)sender {
    [self CheckBoxMatrixCellClicked:mtcaOEHIMatrix newState:![[sender selectedCell] nextState]];
}
- (IBAction)owlelRelayCheckBoxClicked:(id)sender {
    [self CheckBoxMatrixCellClicked:mtcaOELOMatrix newState:![[sender selectedCell] nextState]];
}
- (IBAction)owlnRelayCheckBoxClicked:(id)sender {
    [self CheckBoxMatrixCellClicked:mtcaOWLNMatrix newState:![[sender selectedCell] nextState]];
}


- (void)CheckBoxMatrixCellClicked:(NSMatrix*) checkBoxes newState:(int)state {

    BOOL cmdKeyDown = ([[NSApp currentEvent] modifierFlags] & NSCommandKeyMask) != 0;
    if(cmdKeyDown){
        for (int i=0; i<[checkBoxes numberOfRows]; i++)
        {
            [[checkBoxes cellAtRow:i column:0] setState: state];
        }
    }
    return;
}

@end

#pragma mark •••PrivateInterface
@implementation ORMTCController (private)

- (void) setupNHitFormats
{
    NSLog(@"setupNHitFormats -> Needs implemenation\n");
}

- (void) setupESumFormats
{
    NSLog(@"setupESumFormats -> Needs implemenation\n");
}

- (void) storeUserNHitValue:(float)userValue index:(int) thresholdIndex
{
	//user changed the NHit threshold -- convert from the displayed value to the raw value and store
    NSLog(@"storeUserNHitValue -> Needs implemenation\n");

}

- (void) calcNHitValueForRow:(int) aRow
{
    NSLog(@"calcNHitValueForRow -> Needs implemenation\n");

}

- (void) storeUserESumValue:(float)userValue index:(int) thresholdIndex
{
	//user changed the ESum threshold -- convert from the displayed value to the raw value and store
    NSLog(@"storeUserEsumValue -> Needs implemenation\n");
}

- (void) calcESumValueForRow:(int) aRow
{
    NSLog(@"calcESUMValueForRow -> Needs implemenation\n");
}

@end
