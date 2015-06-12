//-------------------------------------------------------------------------
//  ORGretina4AController.m
//
//  Created by Mark A. Howe on Wednesday 11/20/14.
//  Copyright (c) 2014 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Washington sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Washington reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

//-------------------------------------------------------------------------

#pragma mark ***Imported Files
#import "ORGretina4AController.h"
#import "ORRateGroup.h"
#import "ORRate.h"
#import "ORValueBar.h"
#import "ORTimeRate.h"
#import "ORTimeLinePlot.h"
#import "ORPlotView.h"
#import "ORTimeAxis.h"
#import "ORCompositePlotView.h"
#import "ORValueBarGroupView.h"

@implementation ORGretina4AController

-(id)init
{
    self = [super initWithWindowNibName:@"Gretina4A"];
    
    return self;
}

- (void) dealloc
{
	[blankView release];
	[super dealloc];
}

- (void) awakeFromNib
{
    settingSize     = NSMakeSize(1000,480);
    rateSize		= NSMakeSize(790,340);
    registerTabSize	= NSMakeSize(400,490);
	firmwareTabSize = NSMakeSize(340,187);
    blankView = [[NSView alloc] init];
    
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];
	

	// Setup register popup buttons
	[registerIndexPU removeAllItems];
	[registerIndexPU setAutoenablesItems:NO];
    int errCount = 0;
	int i;
	for (i=0;i<kNumberOfGretina4ARegisters;i++) {
        NSString* s = [NSString stringWithFormat:@"(0x%04x) %@",[model registerOffsetAt:i], [model registerNameAt:i]];
        if(i!=[model registerEnumAt:i]){
            errCount++;
        }
		[registerIndexPU insertItemWithTitle:s	atIndex:i];
		[[registerIndexPU itemAtIndex:i] setEnabled:YES];
	}
    if(errCount)NSLogColor([NSColor redColor], @"Programming Error... Mismatch in Gretina4A register definitions and eNums\n");
	// And now the FPGA registers
    for (i=0;i<kNumberOfFPGARegisters;i++) {
        NSString* s = [NSString stringWithFormat:@"(0x%04x) %@",[model fpgaRegisterOffsetAt:i], [model fpgaRegisterNameAt:i]];

		[registerIndexPU insertItemWithTitle:s	atIndex:(i+kNumberOfGretina4ARegisters)];
	}

    for (i=0;i<kNumberOfGretina4ARegisters;i++) {
        [[enabledMatrix                 cellAtRow:i column:0] setTag:i];
        [[enabled2Matrix                cellAtRow:i column:0] setTag:i];
        [[ledThresholdMatrix            cellAtRow:i column:0] setTag:i];
        [[cFDFractionMatrix             cellAtRow:i column:0] setTag:i];
        [[pileupModeMatrix              cellAtRow:i column:0] setTag:i];
        [[premapResetDelayEnMatrix      cellAtRow:i column:0] setTag:i];
        [[premapResetDelayMatrix        cellAtRow:i column:0] setTag:i];
        [[triggerPolarityMatrix         cellAtRow:i column:0] setTag:i];
        [[aHitCountModeMatrix           cellAtRow:i column:0] setTag:i];
        [[discCountModeMatrix           cellAtRow:i column:0] setTag:i];
        [[eventExtensionModeMatrix      cellAtRow:i column:0] setTag:i];
        [[pileupExtensionModeMatrix     cellAtRow:i column:0] setTag:i];
        [[counterResetMatrix            cellAtRow:i column:0] setTag:i];
        [[pileupWaveformOnlyModeMatrix  cellAtRow:i column:0] setTag:i];
   }
    
    NSString* key = [NSString stringWithFormat: @"orca.Gretina4A%d.selectedtab",[model slot]];
    int index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
	
	ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:0 andDataSource:self];
	[timeRatePlot addPlot: aPlot];
	[(ORTimeAxis*)[timeRatePlot xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
	[aPlot release];
	
	[rate0 setNumber:10 height:10 spacing:5];
	
	[super awakeFromNib];
	
}

#pragma mark •••Boilerplate
- (void) slotChanged:(NSNotification*)aNotification
{
    [[self window] setTitle:[NSString stringWithFormat:@"Gretina4A Card (Slot %d)",[model slot]]];
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"Gretina4A Card (Slot %d)",[model slot]]];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
	
    [notifyCenter addObserver : self
					 selector : @selector(slotChanged:)
						 name : ORVmeCardSlotChangedNotification
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORGretina4ASettingsLock
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(registerLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(registerLockChanged:)
                         name : ORGretina4ARegisterLock
                        object: nil];
	   
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORGretina4AMainFPGADownLoadInProgressChanged
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(registerLockChanged:)
                         name : ORGretina4AMainFPGADownLoadInProgressChanged
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(rateGroupChanged:)
                         name : ORGretina4ARateGroupChangedNotification
                       object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(totalRateChanged:)
						 name : ORRateGroupTotalRateChangedNotification
					   object : nil];
	
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
                       object : [[model waveFormRateGroup]timeRate]];
    
    [notifyCenter addObserver : self
                     selector : @selector(integrationChanged:)
                         name : ORRateGroupIntegrationChangedNotification
                       object : nil];
		
    [notifyCenter addObserver : self
                     selector : @selector(noiseFloorOffsetChanged:)
                         name : ORGretina4ANoiseFloorOffsetChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(noiseFloorIntegrationChanged:)
                         name : ORGretina4ANoiseFloorIntegrationTimeChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(fpgaFilePathChanged:)
                         name : ORGretina4AFpgaFilePathChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(mainFPGADownLoadStateChanged:)
                         name : ORGretina4AMainFPGADownLoadStateChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(fpgaDownProgressChanged:)
                         name : ORGretina4AFpgaDownProgressChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(fpgaDownInProgressChanged:)
                         name : ORGretina4AMainFPGADownLoadInProgressChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(selectedChannelChanged:)
                         name : ORGretina4ASelectedChannelChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(registerWriteValueChanged:)
                         name : ORGretina4ARegisterWriteValueChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(registerIndexChanged:)
                         name : ORGretina4ARegisterIndexChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(spiWriteValueChanged:)
                         name : ORGretina4ASPIWriteValueChanged
						object: model];
	
   	[self registerRates];
    
    [notifyCenter addObserver : self
                     selector : @selector(enabledChanged:)
                         name : ORGretina4AEnabledChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(forceFullInitChanged:)
                         name : ORGretina4AForceFullInitChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(forceFullCardInitChanged:)
                         name : ORGretina4AForceFullCardInitChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(firmwareVersionChanged:)
                         name : ORGretina4AFirmwareVersionChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(acqDcmCtrlStatusChanged:)
                         name : ORGretina4AAcqDcmCtrlStatusChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(acqDcmLockChanged:)
                         name : ORGretina4AAcqDcmLockChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(acqDcmResetChanged:)
                         name : ORGretina4AAcqDcmResetChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(acqPhShiftOverflowChanged:)
                         name : ORGretina4AAcqPhShiftOverflowChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(acqDcmClockStoppedChanged:)
                         name : ORGretina4AAcqDcmClockStoppedChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(adcDcmCtrlStatusChanged:)
                         name : ORGretina4AAdcDcmCtrlStatusChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(adcDcmLockChanged:)
                         name : ORGretina4AAdcDcmLockChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(adcDcmResetChanged:)
                         name : ORGretina4AAdcDcmResetChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(adcPhShiftOverflowChanged:)
                         name : ORGretina4AAdcPhShiftOverflowChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(adcDcmClockStoppedChanged:)
                         name : ORGretina4AAdcDcmClockStoppedChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(userPackageDataChanged:)
                         name : ORGretina4AUserPackageDataChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(routerVetoEnChanged:)
                         name : ORGretina4ARouterVetoEn0Changed
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(preampResetDelayEnChanged:)
                         name : ORGretina4APreampResetDelayEnChanged
                        object: model];
 
    [notifyCenter addObserver : self
                     selector : @selector(writeFlagChanged:)
                         name : ORGretina4AWriteFlagChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(decimationFactorChanged:)
                         name : ORGretina4ADecimationFactorChanged
                        object: model];
   
    [notifyCenter addObserver : self
                     selector : @selector(pileupModeChanged:)
                         name : ORGretina4APileupMode0Changed
                        object: model];
 
    [notifyCenter addObserver : self
                     selector : @selector(triggerConfigChanged:)
                         name : ORGretina4ATriggerConfigChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(droppedEventCountModeChanged:)
                         name : ORGretina4ADroppedEventCountModeChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(eventCountModeChanged:)
                         name : ORGretina4AEventCountModeChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(triggerPolarityChanged:)
                         name : ORGretina4ATriggerPolarityChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(aHitCountModeChanged:)
                         name :ORGretina4AAHitCountModeChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(discCountModeChanged:)
                         name : ORGretina4ADiscCountModeChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(eventExtensionModeChanged:)
                         name : ORGretina4AEventExtensionModeChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(pileupExtensionModeChanged:)
                         name : ORGretina4APileupExtensionModeChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(counterResetChanged:)
                         name : ORGretina4ACounterResetChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(pileupWaveformOnlyModeChanged:)
                         name : ORGretina4APileupWaveformOnlyModeChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(ledThresholdChanged:)
                         name : ORGretina4ALedThreshold0Changed
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(cfdFractionChanged:)
                         name : ORGretina4ACFDFractionChanged
                        object: model];

    
    [notifyCenter addObserver : self
                     selector : @selector(preampResetDelayChanged:)
                         name : ORGretina4APreampResetDelay0Changed
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(rawDataLengthChanged:)
                         name : ORGretina4ARawDataLengthChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(rawDataWindowChanged:)
                         name : ORGretina4ARawDataWindowChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(dWindowChanged:)
                         name : ORGretina4ADWindowChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(kWindowChanged:)
                         name : ORGretina4AKWindowChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(mWindowChanged:)
                         name : ORGretina4AMWindowChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(d3WindowChanged:)
                         name : ORGretina4AD3WindowChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(discWidthChanged:)
                         name : ORGretina4ADiscWidthChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(windowCompMinChanged:)
                         name : ORGretina4AWindowCompMinChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(windowCompMaxChanged:)
                         name : ORGretina4AWindowCompMaxChanged
                        object: model];
  
    [notifyCenter addObserver : self
                     selector : @selector(baselineStartChanged:)
                         name : ORGretina4ABaselineStartChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(baselineDelayChanged:)
                         name : ORGretina4ABaselineDelayChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(p1WindowChanged:)
                         name : ORGretina4AP1WindowChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(p2WindowChanged:)
                         name : ORGretina4AP2WindowChanged
                        object: model];
  
    [notifyCenter addObserver : self
                     selector : @selector(dacChannelSelectChanged:)
                         name : ORGretina4ADacChannelSelectChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(dacAttenuationChanged:)
                         name : ORGretina4ADacAttenuationChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(phaseHuntChanged:)
                         name : ORGretina4APhaseHuntChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(loadbaselineChanged:)
                         name : ORGretina4ALoadbaselineChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(phaseHuntDebugChanged:)
                         name : ORGretina4APhaseHuntDebugChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(phaseHuntProceedChanged:)
                         name : ORGretina4APhaseHuntProceedChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(phaseDecChanged:)
                         name : ORGretina4APhaseDecChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(phaseIncChanged:)
                         name : ORGretina4APhaseIncChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(serdesPhaseIncChanged:)
                         name : ORGretina4ASerdesPhaseIncChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(serdesPhaseDecChanged:)
                         name : ORGretina4ASerdesPhaseDecChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(peakSensitivityChanged:)
                         name : ORGretina4APeakSensitivityChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(diagInputChanged:)
                         name : ORGretina4ADiagInputChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(rj45SpareIoMuxSelChanged:)
                         name : ORGretina4ARj45SpareIoMuxSelChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(rj45SpareIoDirChanged:)
                         name : ORGretina4ARj45SpareIoDirChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(liveTimestampLsbChanged:)
                         name : ORGretina4ALiveTimestampLsbChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(liveTimestampMsbChanged:)
                         name : ORGretina4ALiveTimestampMsbChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(diagIsyncChanged:)
                         name : ORGretina4ADiagIsyncChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(serdesSmLostLockChanged:)
                         name : ORGretina4ASerdesSmLostLockChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(overflowFlagChanChanged:)
                         name : ORGretina4AOverflowFlagChanChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(phaseStatusChanged:)
                         name : ORGretina4APhaseStatusChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(phaseChanged:)
                         name : ORGretina4APhase0Changed
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(phase1Changed:)
                         name : ORGretina4APhase1Changed
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(phase2Changed:)
                         name : ORGretina4APhase2Changed
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(phase3Changed:)
                         name : ORGretina4APhase3Changed
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(pcbRevisionChanged:)
                         name : ORGretina4APcbRevisionChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(fwTypeChanged:)
                         name : ORGretina4AFwTypeChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(mjrCodeRevisionChanged:)
                         name : ORGretina4AMjrCodeRevisionChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(minCodeRevisionChanged:)
                         name : ORGretina4AMinCodeRevisionChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(codeDateChanged:)
                         name : ORGretina4ACodeDateChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(droppedEventCountChanged:)
                         name : ORGretina4ADroppedEventCountChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(acceptedEventCountChanged:)
                         name : ORGretina4AAcceptedEventCountChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(ahitCountChanged:)
                         name : ORGretina4AAhitCountChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(discCountChanged:)
                         name : ORGretina4ADiscCountChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(auxIoReadChanged:)
                         name : ORGretina4AAuxIoReadChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(auxIoWriteChanged:)
                         name : ORGretina4AAuxIoWriteChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(auxIoConfigChanged:)
                         name : ORGretina4AAuxIoConfigChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(sdPemChanged:)
                         name : ORGretina4ASdPemChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(sdSmLostLockFlagChanged:)
                         name : ORGretina4ASdSmLostLockFlagChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(adcConfigChanged:)
                         name : ORGretina4AAdcConfigChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(configMainFpgaChanged:)
                         name : ORGretina4AConfigMainFpgaChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(powerOkChanged:)
                         name : ORGretina4APowerOkChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(overVoltStatChanged:)
                         name : ORGretina4AOverVoltStatChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(underVoltStatChanged:)
                         name : ORGretina4AUnderVoltStatChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(temp0SensorChanged:)
                         name : ORGretina4ATemp0SensorChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(temp1SensorChanged:)
                         name : ORGretina4ATemp1SensorChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(temp2SensorChanged:)
                         name : ORGretina4ATemp2SensorChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(clkSelectChanged:)
                         name : ORGretina4AClkSelect0Changed
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(clkSelect1Changed:)
                         name : ORGretina4AClkSelect1Changed
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(flashModeChanged:)
                         name : ORGretina4AFlashModeChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(serialNumChanged:)
                         name : ORGretina4ASerialNumChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(boardRevNumChanged:)
                         name : ORGretina4ABoardRevNumChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(vhdlVerNumChanged:)
                         name : ORGretina4AVhdlVerNumChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(fifoAccessChanged:)
                         name : ORGretina4AFifoAccessChanged
                        object: model];

}

- (void) registerRates
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter removeObserver:self name:ORRateChangedNotification object:nil];
    
    NSEnumerator* e = [[[model waveFormRateGroup] rates] objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
		
        [notifyCenter removeObserver:self name:ORRateChangedNotification object:obj];
		
        [notifyCenter addObserver : self
                         selector : @selector(waveFormRateChanged:)
                             name : ORRateChangedNotification
                           object : obj];
    }
}

- (void) updateWindow
{
    [super updateWindow];
    
    //Card Movement
    [self slotChanged:nil];
    
    //Security
    [self settingsLockChanged:nil];
    [self registerLockChanged:nil];
    [self lockChanged:nil];

    //Low-level registers and diagnostics
    [self selectedChannelChanged:nil];
    [self registerIndexChanged:nil];
    [self registerWriteValueChanged:nil];
    [self spiWriteValueChanged:nil];
    [self diagnosticsEnabledChanged:nil];

    //firmware loading
    [self fpgaFilePathChanged:nil];
    [self mainFPGADownLoadStateChanged:nil];
    [self fpgaDownProgressChanged:nil];
    [self fpgaDownInProgressChanged:nil];

    //rates
    [self rateGroupChanged:nil];
    [self integrationChanged:nil];
    [self miscAttributesChanged:nil];
    [self totalRateChanged:nil];
    [self updateTimePlot:nil];

    //noise floor
    [self waveFormRateChanged:nil];
	[self noiseFloorChanged:nil];
	[self noiseFloorIntegrationChanged:nil];
	[self noiseFloorOffsetChanged:nil];
		
    //SerDes and Clock Distribution
    [self initSerDesStateChanged:nil];
    
    //Card Params
    [self enabledChanged:nil];
    [self forceFullInitChanged:nil];
    [self forceFullCardInitChanged:nil];
    [self firmwareVersionChanged:nil];
    [self acqDcmCtrlStatusChanged:nil];
    [self acqDcmLockChanged:nil];
    [self acqDcmResetChanged:nil];
    [self acqPhShiftOverflowChanged:nil];
    [self acqDcmClockStoppedChanged:nil];
    [self adcDcmCtrlStatusChanged:nil];
    [self adcDcmLockChanged:nil];
    [self adcDcmResetChanged:nil];
    [self adcPhShiftOverflowChanged:nil];
    [self adcDcmClockStoppedChanged:nil];
    [self userPackageDataChanged:nil];
    [self routerVetoEnChanged:nil];
    [self preampResetDelayEnChanged:nil];
    [self decimationFactorChanged:nil];
    [self writeFlagChanged:nil];
    [self pileupModeChanged:nil];
    [self droppedEventCountModeChanged:nil];
    [self eventCountModeChanged:nil];
    [self aHitCountModeChanged:nil];
    [self discCountModeChanged:nil];
    [self eventExtensionModeChanged:nil];
    [self pileupExtensionModeChanged:nil];
    [self counterResetChanged:nil];
    [self pileupWaveformOnlyModeChanged:nil];

    
    [self ledThresholdChanged:nil];
    [self cfdFractionChanged:nil];
    [self triggerPolarityChanged:nil];
    [self preampResetDelayChanged:nil];
    [self rawDataLengthChanged:nil];
    [self rawDataWindowChanged:nil];
    [self dWindowChanged:nil];
    [self kWindowChanged:nil];
    [self mWindowChanged:nil];
    [self d3WindowChanged:nil];
    [self windowCompMinChanged:nil];
    [self windowCompMaxChanged:nil];
    [self discWidthChanged:nil];
    [self baselineStartChanged:nil];
    [self baselineDelayChanged:nil];
    [self p1WindowChanged:nil];
    [self p2WindowChanged:nil];
    [self dacChannelSelectChanged:nil];
    [self dacAttenuationChanged:nil];
    [self ilaConfigChanged:nil];
    [self phaseHuntChanged:nil];
    [self loadbaselineChanged:nil];
    [self phaseHuntDebugChanged:nil];
    [self phaseHuntProceedChanged:nil];
    [self phaseDecChanged:nil];
    [self phaseIncChanged:nil];
    [self serdesPhaseIncChanged:nil];
    [self serdesPhaseDecChanged:nil];
    [self diagMuxControlChanged:nil];
    [self peakSensitivityChanged:nil];
    [self diagInputChanged:nil];
    [self diagChannelEventSelChanged:nil];
    [self rj45SpareIoMuxSelChanged:nil];
    [self rj45SpareIoDirChanged:nil];
    [self ledStatusChanged:nil];
    [self liveTimestampLsbChanged:nil];
    [self liveTimestampMsbChanged:nil];
    [self diagIsyncChanged:nil];
    [self serdesSmLostLockChanged:nil];
    [self overflowFlagChanChanged:nil];
    [self triggerConfigChanged:nil];
    [self phaseErrorCountChanged:nil];
    [self phaseStatusChanged:nil];
    [self phaseChanged:nil];
    [self phase1Changed:nil];
    [self phase2Changed:nil];
    [self phase3Changed:nil];
    [self serdesPhaseValueChanged:nil];
    [self pcbRevisionChanged:nil];
    [self fwTypeChanged:nil];
    [self mjrCodeRevisionChanged:nil];
    [self minCodeRevisionChanged:nil];
    [self codeDateChanged:nil];
    [self tSErrCntCtrlChanged:nil];
    [self tSErrorCountChanged:nil];
    [self droppedEventCountChanged:nil];
    [self acceptedEventCountChanged:nil];
    [self ahitCountChanged:nil];
    [self discCountChanged:nil];
    [self auxIoReadChanged:nil];
    [self auxIoWriteChanged:nil];
    [self auxIoConfigChanged:nil];
    [self sdPemChanged:nil];
    [self sdSmLostLockFlagChanged:nil];
    [self adcConfigChanged:nil];
    [self configMainFpgaChanged:nil];
    [self powerOkChanged:nil];
    [self overVoltStatChanged:nil];
    [self underVoltStatChanged:nil];
    [self temp0SensorChanged:nil];
    [self temp1SensorChanged:nil];
    [self temp2SensorChanged:nil];
    [self clkSelectChanged:nil];
    [self clkSelect1Changed:nil];
    [self flashModeChanged:nil];
    [self serialNumChanged:nil];
    [self boardRevNumChanged:nil];
    [self vhdlVerNumChanged:nil];
    [self fifoAccessChanged:nil];
}

#pragma mark •••Interface Management

#pragma mark •••Security
- (void) lockChanged:(NSNotification*) aNote
{
    [lockStateField setStringValue:[model locked]?@"Yes":@"No"];
    [self updateClockLocked];
}
- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORGretina4ASettingsLock to:secure];
    [gSecurity setLock:ORGretina4ARegisterLock to:secure];
    [settingLockButton setEnabled:secure];
    [registerLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    
    BOOL runInProgress              = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORGretina4ASettingsLock];
    BOOL locked                     = [gSecurity isLocked:ORGretina4ASettingsLock];
    BOOL downloading                = [model downLoadMainFPGAInProgress];
    
    [settingLockButton      setState: locked];
    [initButton             setEnabled:!lockedOrRunningMaintenance && !downloading];
    [fullInitButton         setEnabled:!lockedOrRunningMaintenance && !downloading];
    [initButton1            setEnabled:!lockedOrRunningMaintenance && !downloading];
    [clearFIFOButton        setEnabled:!locked && !runInProgress && !downloading];
    [noiseFloorButton       setEnabled:!locked && !runInProgress && !downloading];
    [statusButton           setEnabled:!lockedOrRunningMaintenance && !downloading];
    [probeButton            setEnabled:!locked && !runInProgress && !downloading];
    [resetButton            setEnabled:!lockedOrRunningMaintenance && !downloading];
    [loadMainFPGAButton     setEnabled:!locked && !downloading];
    [stopFPGALoadButton     setEnabled:!locked && downloading];
    [dumpAllRegistersButton setEnabled:!lockedOrRunningMaintenance && !downloading];
    [snapShotRegistersButton setEnabled:!lockedOrRunningMaintenance && !downloading];
    [compareRegistersButton setEnabled:!lockedOrRunningMaintenance && !downloading];
    
    [diagnosticsReportButton setEnabled:[model diagnosticsEnabled]];
    [diagnosticsClearButton  setEnabled:[model diagnosticsEnabled]];
}

- (void) registerLockChanged:(NSNotification*)aNotification
{
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORGretina4ARegisterLock];
    BOOL locked = [gSecurity isLocked:ORGretina4ARegisterLock];
    BOOL downloading = [model downLoadMainFPGAInProgress];
    
    [registerLockButton setState: locked];
    [registerWriteValueField setEnabled:!lockedOrRunningMaintenance && !downloading];
    [channelSelectionField setEnabled:!lockedOrRunningMaintenance && !downloading];
    [registerIndexPU setEnabled:!lockedOrRunningMaintenance && !downloading];
    [readRegisterButton setEnabled:!lockedOrRunningMaintenance && !downloading];
    [writeRegisterButton setEnabled:!lockedOrRunningMaintenance && !downloading];
    [spiWriteValueField setEnabled:!lockedOrRunningMaintenance && !downloading];
    [writeSPIButton setEnabled:!lockedOrRunningMaintenance && !downloading];
}

#pragma mark •••Low-level registers and diagnostics
- (void) registerIndexChanged:(NSNotification*)aNote
{
    [registerIndexPU selectItemAtIndex: [model registerIndex]];
    [self setRegisterDisplay:[model registerIndex]];
}

- (void) setRegisterDisplay:(unsigned int)index
{
    if (index < kNumberOfGretina4ARegisters) {
        [writeRegisterButton setEnabled:[model canWriteRegister:index]];
        [registerWriteValueField setEnabled:[model canWriteRegister:index]];
        [readRegisterButton setEnabled:[model canReadRegister:index]];
        [selectedChannelField setEnabled:[model hasChannels:index]];
        
        [registerStatusField setStringValue:@""];
    }
    else {
        index -= kNumberOfGretina4ARegisters;
        [writeRegisterButton setEnabled:[model canWriteFPGARegister:index]];
        [registerWriteValueField setEnabled:[model canWriteFPGARegister:index]];
        [readRegisterButton setEnabled:[model canReadFPGARegister:index]];
        [registerStatusField setStringValue:@""];
     }
}
- (void) selectedChannelChanged:(NSNotification*)aNote
{
    [selectedChannelField setIntValue: [model selectedChannel]];
}

- (void) registerWriteValueChanged:(NSNotification*)aNote
{
    [registerWriteValueField setIntValue: [model registerWriteValue]];
}


- (void) spiWriteValueChanged:(NSNotification*)aNote
{
    [spiWriteValueField setIntValue: [model spiWriteValue]];
}

- (void) diagnosticsEnabledChanged:(NSNotification*)aNote
{
    [diagnosticsEnabledCB setIntValue: [model diagnosticsEnabled]];
}

#pragma mark •••firmware loading
- (void) fpgaDownInProgressChanged:(NSNotification*)aNote
{
    if([model downLoadMainFPGAInProgress])[loadFPGAProgress startAnimation:self];
    else [loadFPGAProgress stopAnimation:self];
}

- (void) fpgaDownProgressChanged:(NSNotification*)aNote
{
    [loadFPGAProgress setDoubleValue:(double)[model fpgaDownProgress]];
}

- (void) mainFPGADownLoadStateChanged:(NSNotification*)aNote
{
    [mainFPGADownLoadStateField setStringValue: [model mainFPGADownLoadState]];
}

- (void) fpgaFilePathChanged:(NSNotification*)aNote
{
    [fpgaFilePathField setStringValue: [[model fpgaFilePath] stringByAbbreviatingWithTildeInPath]];
}

#pragma mark •••rates
- (void) integrationChanged:(NSNotification*)aNotification
{
    ORRateGroup* theRateGroup = [aNotification object];
    if(aNotification == nil || [model waveFormRateGroup] == theRateGroup || [aNotification object] == model){
        double dValue = [[model waveFormRateGroup] integrationTime];
        [integrationStepper setDoubleValue:dValue];
        [integrationText setDoubleValue: dValue];
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
    if(!aNote || ([aNote object] == [[model waveFormRateGroup]timeRate])){
        [timeRatePlot setNeedsDisplay:YES];
    }
}
- (void) waveFormRateChanged:(NSNotification*)aNote
{
    ORRate* theRateObj = [aNote object];
    [[rateTextFields cellWithTag:[theRateObj tag]] setFloatValue: [theRateObj rate]];
    [rate0 setNeedsDisplay:YES];
}

- (void) totalRateChanged:(NSNotification*)aNotification
{
    ORRateGroup* theRateObj = [aNotification object];
    if(aNotification == nil || [model waveFormRateGroup] == theRateObj){
        
        [totalRateText setFloatValue: [theRateObj totalRate]];
        [totalRate setNeedsDisplay:YES];
    }
}

- (void) rateGroupChanged:(NSNotification*)aNote
{
    [self registerRates];
}

#pragma mark •••noise floor
- (void) noiseFloorIntegrationChanged:(NSNotification*)aNote
{
    [noiseFloorIntegrationField setFloatValue:[model noiseFloorIntegrationTime]];
}

- (void) noiseFloorChanged:(NSNotification*)aNote
{
    if([model noiseFloorRunning]){
        [noiseFloorProgress startAnimation:self];
    }
    else {
        [noiseFloorProgress stopAnimation:self];
    }
    [startNoiseFloorButton setTitle:[model noiseFloorRunning]?@"Stop":@"Start"];
}

- (void) noiseFloorOffsetChanged:(NSNotification*)aNote
{
    [noiseFloorOffsetField setIntValue:[model noiseFloorOffset]];
}

#pragma mark •••SerDes and Clock Distribution
- (void) updateClockLocked
{
    //if([model clockSource] == 1) [clockLockedField setStringValue:@""];
    //else [clockLockedField setStringValue:[model locked]?@"":@"NOT Locked"];
}

- (void) initSerDesStateChanged:(NSNotification*) aNote
{
    [initSerDesStateField setStringValue:[model serDesStateName]];
}

- (void) forceFullCardInitChanged:(NSNotification*)aNote
{
    [forceFullCardInitCB setIntValue:[model forceFullCardInit]];
}

- (void) forceFullInitChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4AChannels;i++){
            [[forceFullInitMatrix cellWithTag:i] setState:[model forceFullInit:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[forceFullInitMatrix cellWithTag:chan] setState:[model forceFullInit:chan]];
    }
}

#pragma mark •••CardParameters
- (void) enabledChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4AChannels;i++){
            [[enabledMatrix cellWithTag:i] setState:[model enabled:i]];
            [[enabled2Matrix cellWithTag:i] setState:[model enabled:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[enabledMatrix cellWithTag:chan] setState:[model enabled:chan]];
        [[enabled2Matrix cellWithTag:chan] setState:[model enabled:chan]];
    }
}
- (void) firmwareVersionChanged:(NSNotification*)aNote
{
}

- (void) acqDcmCtrlStatusChanged:(NSNotification*)aNote
{
}
- (void) acqDcmLockChanged:(NSNotification*)aNote
{
}
- (void) acqDcmResetChanged:(NSNotification*)aNote
{
}
- (void) acqPhShiftOverflowChanged:(NSNotification*)aNote
{
}
- (void) acqDcmClockStoppedChanged:(NSNotification*)aNote
{
}
- (void) adcDcmCtrlStatusChanged:(NSNotification*)aNote
{
}
- (void) adcDcmLockChanged:(NSNotification*)aNote
{
}
- (void) adcDcmResetChanged:(NSNotification*)aNote
{
}
- (void) adcPhShiftOverflowChanged:(NSNotification*)aNote
{
}
- (void) adcDcmClockStoppedChanged:(NSNotification*)aNote
{
}
- (void) userPackageDataChanged:(NSNotification*)aNote
{
}
- (void) routerVetoEnChanged:(NSNotification*)aNote
{
}
- (void) preampResetDelayEnChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4AChannels;i++){
            [[premapResetDelayEnMatrix cellWithTag:i] setIntValue:[model preampResetDelayEn:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[premapResetDelayEnMatrix cellWithTag:chan] setIntValue:[model preampResetDelayEn:chan]];
    }
}

- (void) decimationFactorChanged:(NSNotification*)aNote
{
    [decimationFactorPU  selectItemAtIndex:[model decimationFactor]];
}

- (void) writeFlagChanged:(NSNotification*)aNote
{
    [writeFlagCB  setIntValue:[model writeFlag]];
}


- (void) pileupModeChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4AChannels;i++){
            [[pileupModeMatrix cellWithTag:i] setIntValue:[model pileupMode:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[pileupModeMatrix cellWithTag:chan] setIntValue:[model pileupMode:chan]];
    }
}

- (void) droppedEventCountModeChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4AChannels;i++){
            [[droppedEventCountModeMatrix cellWithTag:i] setIntValue:[model droppedEventCountMode:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[droppedEventCountModeMatrix cellWithTag:chan] setIntValue:[model droppedEventCountMode:chan]];
    }
}

- (void) eventCountModeChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4AChannels;i++){
            [[eventCountModeMatrix cellWithTag:i] setIntValue:[model eventCountMode:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[eventCountModeMatrix cellWithTag:chan] setIntValue:[model eventCountMode:chan]];
    }
}

- (void) ledThresholdChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4AChannels;i++){
            [[ledThresholdMatrix cellWithTag:i] setIntValue:[model ledThreshold:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[ledThresholdMatrix cellWithTag:chan] setIntValue:[model ledThreshold:chan]];
    }
}

- (void) cfdFractionChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4AChannels;i++){
            [[cFDFractionMatrix cellWithTag:i] setIntValue:[model cFDFraction:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[cFDFractionMatrix cellWithTag:chan] setIntValue:[model cFDFraction:chan]];
    }
}

- (void) triggerPolarityChanged:(NSNotification*)aNote;
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4AChannels;i++){
            [[triggerPolarityMatrix cellAtRow:i column:0] selectItemAtIndex:[model triggerPolarity:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[triggerPolarityMatrix cellAtRow:chan column:0] selectItemAtIndex:[model triggerPolarity:chan]];
    }
   
}
- (void) preampResetDelayChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4AChannels;i++){
            [[premapResetDelayMatrix cellWithTag:i] setIntValue:[model preampResetDelay:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[premapResetDelayMatrix cellWithTag:chan] setIntValue:[model preampResetDelay:chan]];
    }
}

- (void) aHitCountModeChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4AChannels;i++){
            [[aHitCountModeMatrix cellWithTag:i] setIntValue:[model aHitCountMode:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[aHitCountModeMatrix cellWithTag:chan] setIntValue:[model aHitCountMode:chan]];
    }
}
- (void) discCountModeChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4AChannels;i++){
            [[discCountModeMatrix cellWithTag:i] setIntValue:[model discCountMode:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[discCountModeMatrix cellWithTag:chan] setIntValue:[model discCountMode:chan]];
    }
}
- (void) eventExtensionModeChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4AChannels;i++){
            [[eventExtensionModeMatrix cellAtRow:i column:0] selectItemAtIndex:[model eventExtensionMode:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[eventExtensionModeMatrix cellAtRow:chan column:0] selectItemAtIndex:[model eventExtensionMode:chan]];
    }
}

- (void) pileupExtensionModeChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4AChannels;i++){
            [[pileupExtensionModeMatrix cellWithTag:i] setIntValue:[model pileupExtensionMode:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[pileupExtensionModeMatrix cellWithTag:chan] setIntValue:[model pileupExtensionMode:chan]];
    }
}

- (void) counterResetChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4AChannels;i++){
            [[counterResetMatrix cellWithTag:i] setIntValue:[model counterReset:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[counterResetMatrix cellWithTag:chan] setIntValue:[model counterReset:chan]];
    }
}

- (void) pileupWaveformOnlyModeChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4AChannels;i++){
            [[pileupWaveformOnlyModeMatrix cellWithTag:i] setIntValue:[model pileupWaveformOnlyMode:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[pileupWaveformOnlyModeMatrix cellWithTag:chan] setIntValue:[model pileupWaveformOnlyMode:chan]];
    }
}

- (void) rawDataLengthChanged:(NSNotification*)aNote
{
    //waveform length
    [rawDataLengthField setIntValue:[model rawDataLength:0]];
}

- (void) rawDataWindowChanged:(NSNotification*)aNote
{
    [rawDataWindowField setIntValue:[model rawDataWindow:0]];
}

- (void) dWindowChanged:(NSNotification*)aNote
{
    [dWindowField setIntValue:[model dWindow:0]];
}

- (void) kWindowChanged:(NSNotification*)aNote
{
    [kWindowField setIntValue:[model kWindow:0]];
}

- (void) mWindowChanged:(NSNotification*)aNote
{
    [mWindowField setIntValue:[model mWindow:0]];
}

- (void) d3WindowChanged:(NSNotification*)aNote
{
    [d3WindowField setIntValue:[model d3Window:0]];
}

- (void) discWidthChanged:(NSNotification*)aNote
{
    [discWidthField setIntValue:[model discWidth:0]];
}

- (void) windowCompMinChanged:(NSNotification*)aNote
{
    [windowCompMinField setIntValue:[model windowCompMin]];
}

- (void) windowCompMaxChanged:(NSNotification*)aNote
{
    [windowCompMaxField setIntValue:[model windowCompMax]];
}

- (void) baselineStartChanged:(NSNotification*)aNote
{
    [baselineStartField setIntValue:[model baselineStart:0]];
}
- (void) baselineDelayChanged:(NSNotification*)aNote
{
    [baselineDelayField setIntValue:[model baselineDelay]];
}

- (void) p1WindowChanged:(NSNotification*)aNote
{
    [p1WindowField setIntValue:[model p1Window:0]];
}
- (void) p2WindowChanged:(NSNotification*)aNote
{
    [p2WindowField setIntValue:[model p2Window]];
}

- (void) peakSensitivityChanged:(NSNotification*)aNote
{
    [peakSensitivityField setIntValue:[model peakSensitivity]];
}

- (void) dacChannelSelectChanged:(NSNotification*)aNote
{
}
- (void) dacAttenuationChanged:(NSNotification*)aNote
{
}
- (void) ilaConfigChanged:(NSNotification*)aNote
{
}
- (void) phaseHuntChanged:(NSNotification*)aNote
{
}
- (void) loadbaselineChanged:(NSNotification*)aNote
{
}
- (void) phaseHuntDebugChanged:(NSNotification*)aNote
{
}
- (void) phaseHuntProceedChanged:(NSNotification*)aNote
{
}
- (void) phaseDecChanged:(NSNotification*)aNote
{
}
- (void) phaseIncChanged:(NSNotification*)aNote
{
}
- (void) serdesPhaseIncChanged:(NSNotification*)aNote
{
}
- (void) serdesPhaseDecChanged:(NSNotification*)aNote
{
}
- (void) diagMuxControlChanged:(NSNotification*)aNote
{
}
- (void) diagInputChanged:(NSNotification*)aNote
{
}
- (void) diagChannelEventSelChanged:(NSNotification*)aNote
{
}
- (void) rj45SpareIoMuxSelChanged:(NSNotification*)aNote
{
}
- (void) rj45SpareIoDirChanged:(NSNotification*)aNote
{
}
- (void) ledStatusChanged:(NSNotification*)aNote
{
}
- (void) liveTimestampLsbChanged:(NSNotification*)aNote
{
}
- (void) liveTimestampMsbChanged:(NSNotification*)aNote
{
}
- (void) diagIsyncChanged:(NSNotification*)aNote
{
}
- (void) serdesSmLostLockChanged:(NSNotification*)aNote
{
}
- (void) overflowFlagChanChanged:(NSNotification*)aNote
{
}
- (void) triggerConfigChanged:(NSNotification*)aNote
{
    [triggerConfigPU selectItemAtIndex:[model triggerConfig]];
}

- (void) phaseErrorCountChanged:(NSNotification*)aNote
{
}
- (void) phaseStatusChanged:(NSNotification*)aNote
{
}
- (void) phaseChanged:(NSNotification*)aNote
{
}
- (void) phase1Changed:(NSNotification*)aNote
{
}
- (void) phase2Changed:(NSNotification*)aNote
{
}
- (void) phase3Changed:(NSNotification*)aNote
{
}
- (void) serdesPhaseValueChanged:(NSNotification*)aNote
{
}
- (void) pcbRevisionChanged:(NSNotification*)aNote
{
}
- (void) fwTypeChanged:(NSNotification*)aNote
{
}
- (void) mjrCodeRevisionChanged:(NSNotification*)aNote
{
}
- (void) minCodeRevisionChanged:(NSNotification*)aNote
{
}
- (void) codeDateChanged:(NSNotification*)aNote
{
}
- (void) tSErrCntCtrlChanged:(NSNotification*)aNote
{
}
- (void) tSErrorCountChanged:(NSNotification*)aNote
{
}
- (void) droppedEventCountChanged:(NSNotification*)aNote
{
}
- (void) acceptedEventCountChanged:(NSNotification*)aNote
{
}
- (void) ahitCountChanged:(NSNotification*)aNote
{
}
- (void) discCountChanged:(NSNotification*)aNote
{
}
- (void) auxIoReadChanged:(NSNotification*)aNote
{
}
- (void) auxIoWriteChanged:(NSNotification*)aNote
{
}
- (void) auxIoConfigChanged:(NSNotification*)aNote
{
}
- (void) sdPemChanged:(NSNotification*)aNote
{
}
- (void) sdSmLostLockFlagChanged:(NSNotification*)aNote
{
}
- (void) adcConfigChanged:(NSNotification*)aNote
{
}
- (void) configMainFpgaChanged:(NSNotification*)aNote
{
}
- (void) powerOkChanged:(NSNotification*)aNote
{
}
- (void) overVoltStatChanged:(NSNotification*)aNote
{
}
- (void) underVoltStatChanged:(NSNotification*)aNote
{
}
- (void) temp0SensorChanged:(NSNotification*)aNote
{
}
- (void) temp1SensorChanged:(NSNotification*)aNote
{
}
- (void) temp2SensorChanged:(NSNotification*)aNote
{
}
- (void) clkSelectChanged:(NSNotification*)aNote
{
}
- (void) clkSelect1Changed:(NSNotification*)aNote
{
}
- (void) flashModeChanged:(NSNotification*)aNote
{
}
- (void) serialNumChanged:(NSNotification*)aNote
{
}
- (void) boardRevNumChanged:(NSNotification*)aNote
{
}
- (void) vhdlVerNumChanged:(NSNotification*)aNote
{
}
- (void) fifoAccessChanged:(NSNotification*)aNote
{
}

#pragma mark •••Actions
- (IBAction) enabledAction:(id)sender
{
    if([sender intValue] != [model enabled:[[sender selectedCell] tag]]){
        [model setEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
    }
}
- (IBAction) diagnosticsClearAction:(id)sender
{
    [model clearDiagnosticsReport];
    NSLog(@"%@: Cleared Diagnostics Report\n",[model fullID]);
}

- (IBAction) diagnosticsReportAction:(id)sender
{
    [model printDiagnosticsReport];
}

- (IBAction) diagnosticsEnableAction:(id)sender
{
    [model setDiagnosticsEnabled:[sender intValue]];
    [self settingsLockChanged:nil]; //update buttons
}
- (IBAction) peakSensitivityAction:(id)sender;
{
    [model setPeakSensitivity:[sender intValue]];
}

- (IBAction) registerIndexPUAction:(id)sender
{
	unsigned int index = [sender indexOfSelectedItem];
	[model setRegisterIndex:index];
	[self setRegisterDisplay:index];
}

- (IBAction) forceFullCardInitAction:(id)sender;
{
    if([sender intValue] != [model forceFullCardInit]){
        [model setForceFullCardInit:[sender intValue]];
    }
}

- (IBAction) forceFullInitAction:(id)sender;
{
    if([sender intValue] != [model forceFullInit:[[sender selectedCell] tag]]){
        [model setForceFullInit:[[sender selectedCell] tag] withValue:[sender intValue]];
    }
}

-(IBAction) noiseFloorOffsetAction:(id)sender
{
    if([sender intValue] != [model noiseFloorOffset]){
        [model setNoiseFloorOffset:[sender intValue]];
    }
}

- (IBAction) noiseFloorIntegrationAction:(id)sender
{
    if([sender floatValue] != [model noiseFloorIntegrationTime]){
        [model setNoiseFloorIntegrationTime:[sender floatValue]];
    }
}

- (IBAction) readRegisterAction:(id)sender
{
	[self endEditing];
	unsigned long aValue = 0;
	unsigned int index = [model registerIndex];
	if (index < kNumberOfGretina4ARegisters) {
        unsigned long address   = [model registerOffsetAt:index];
        if([model hasChannels:index])address += [model selectedChannel]*0x04;
        aValue = [model readFromAddress:address];

        NSLog(@"Gretina4A(%d,%d) %@: %u (0x%08x)\n",[model crateNumber],[model slot], [model registerNameAt:index],aValue,aValue);
	} 
	else {
		index -= kNumberOfGretina4ARegisters;
		aValue = [model readFPGARegister:index];	
		NSLog(@"Gretina4A(%d,%d) %@: %u (0x%08x)\n",[model crateNumber],[model slot], [model fpgaRegisterNameAt:index],aValue,aValue);
	}
}

- (IBAction) writeRegisterAction:(id)sender
{
	[self endEditing];
	unsigned long aValue    = [model registerWriteValue];
	unsigned int index      = [model registerIndex];
    
	if (index < kNumberOfGretina4ARegisters) {
        unsigned long address   = [model registerOffsetAt:index];
        if([model hasChannels:index])address += [model selectedChannel]*0x04;
        [model writeToAddress:address aValue:aValue];
        NSLog(@"Wrote to Gretina4A(%d,%d) %@: %u (0x%08x)\n",[model crateNumber],[model slot], [model registerNameAt:index],aValue,aValue);
	}
	else {
		index -= kNumberOfGretina4ARegisters;
		[model writeFPGARegister:index withValue:aValue];	
        NSLog(@"Wrote to Gretina4A(%d,%d) %@: %u (0x%08x)\n",[model crateNumber],[model slot], [model fpgaRegisterNameAt:index],aValue,aValue);
	}
}
- (IBAction) selectedChannelAction:(id)sender
{
    [model setSelectedChannel:[sender intValue]];
}

- (IBAction) registerWriteValueAction:(id)sender
{
	[model setRegisterWriteValue:[sender intValue]];
}

- (IBAction) spiWriteValueAction:(id)sender
{
	[model setSPIWriteValue:[sender intValue]];
}

- (IBAction) writeSPIAction:(id)sender
{
	[self endEditing];
	unsigned long aValue = [model spiWriteValue];
	unsigned long readback = [model writeAuxIOSPI:aValue];
	NSLog(@"Gretina4A(%d,%d) writeSPI(%u) readback: (0x%0x)\n",[model crateNumber],[model slot], aValue, readback);
}


- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORGretina4ASettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) registerLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORGretina4ARegisterLock to:[sender intValue] forWindow:[self window]];
}


- (IBAction) resetBoard:(id) sender
{
    @try {
        [model resetBoard];
        NSLog(@"Reset Gretina4A Board (Slot %d <%p>)\n",[model slot],[model baseAddress]);
    }
	@catch(NSException* localException) {
        NSLog(@"Reset of Gretina4A Board FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Gretina4A Reset", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) initBoardAction:(id)sender
{
    @try {
        [self endEditing];
        [model initBoard];		//initialize and load hardware, but don't enable channels
        NSLog(@"Initialized Gretina4A (Slot %d <%p>)\n",[model slot],[model baseAddress]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"Init of Gretina4A FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Gretina4A Init", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) fullInitBoardAction:(id)sender
{
    @try {
        [self endEditing];
        [model clearOldUserValues];
        [model initBoard];		//initialize and load hardware, but don't enable channels
        NSLog(@"Initialized Gretina4A (Slot %d <%p>)\n",[model slot],[model baseAddress]);
        
    }
    @catch(NSException* localException) {
        NSLog(@"Init of Gretina4A FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Gretina4A Init", @"OK", nil, nil,
                        localException);
    }
}


- (IBAction) clearFIFO:(id)sender
{
    @try {  
        [model resetFIFO];
        NSLog(@"Gretina4A (Slot %d <%p>) FIFO reset\n",[model slot],[model baseAddress]);
    }
	@catch(NSException* localException) {
        NSLog(@"Clear of Gretina4A FIFO FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Gretina4A FIFO Clear", @"OK", nil, nil,
                        localException);
    }
}


- (IBAction) integrationAction:(id)sender
{
    [self endEditing];
    if([sender doubleValue] != [[model waveFormRateGroup]integrationTime]){
        [model setRateIntegrationTime:[sender doubleValue]];		
    }
}

-(IBAction)probeBoard:(id)sender
{
    [self endEditing];
    @try {
        unsigned short theID = [model readBoardID];
        NSLog(@"Gretina BoardID (slot %d): 0x%x\n",[model slot],theID);
        if(theID == ([model baseAddress]>>16)){
            NSLog(@"VME slot matches the ORCA configuration\n");
            [model readFPGAVersions];
            [model checkFirmwareVersion:YES];
        }
        else {
            NSLogColor([NSColor redColor],@"Gretina Board 0x%x doesn't match dip settings 0x%x\n", theID, [model baseAddress]>>16);
            NSLogColor([NSColor redColor],@"Apparently it is not in the right slot in the ORCA configuration\n");
        }
    }
	@catch(NSException* localException) {
        NSLog(@"Probe Gretina4A Board FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Probe", @"OK", nil, nil,
                        localException);
    }
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
        NSLog(@"Gretina (slot %d) Finding LED Thresholds \n",[model slot]);
		[model findNoiseFloors];
    }
	@catch(NSException* localException) {
        NSLog(@"LED Threshold Finder for Gretina4A Board FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed LED Threshold finder", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) readStatus:(id)sender
{    
    [self endEditing];
    @try {
        NSLog(@"Gretina BoardID (slot %d): [0x%x] ID = 0x%x\n",[model slot],[model baseAddress],[model readBoardID]);
    }
	@catch(NSException* localException) {
        NSLog(@"Probe Gretina4A Board FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Probe", @"OK", nil, nil,
                        localException);
    }
}


- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    if([tabView indexOfTabViewItem:tabViewItem] == 0){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:settingSize];
		[[self window] setContentView:tabView];
    }
	else if([tabView indexOfTabViewItem:tabViewItem] == 1){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:registerTabSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 2){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:rateSize];
		[[self window] setContentView:tabView];
    }     
	else if([tabView indexOfTabViewItem:tabViewItem] == 3){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:firmwareTabSize];
		[[self window] setContentView:tabView];
    }  
	else if([tabView indexOfTabViewItem:tabViewItem] == 4){
		[[self window] setContentView:blankView];
		[[self window] setContentView:tabView];
    }  
	
    NSString* key = [NSString stringWithFormat: @"orca.ORGretina4A%d.selectedtab",[model slot]];
    int index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
	
}

- (IBAction) downloadMainFPGAAction:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setCanChooseFiles:YES];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setPrompt:@"Select FPGA Binary File"];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [model setFpgaFilePath:[[openPanel URL]path]];
            [model startDownLoadingMainFPGA];
        }
    }];
}

- (IBAction) stopLoadingMainFPGAAction:(id)sender
{
	[model stopDownLoadingMainFPGA];
}
- (IBAction) dumpAllRegisters:(id)sender
{
    [model dumpAllRegisters];
}

- (IBAction) snapShotRegistersAction:(id)sender
{
    [model snapShotRegisters];

}

- (IBAction) compareToSnapShotAction:(id)sender
{
    [model compareToSnapShot];
}

- (IBAction) ledThresholdAction:(id)sender
{
    [model setLedThreshold:[[sender selectedCell] tag] withValue:[sender intValue]];
}
- (IBAction) cdfFractionAction:(id)sender;
{
    if([sender intValue] != [model cFDFraction:[[sender selectedCell] tag]]){
        [model setCFDFraction:[[sender selectedCell] tag] withValue:[sender intValue]];
    }
}

- (IBAction) triggerPolarityAction:(id)sender
{
    [model setTriggerPolarity:[sender selectedRow] withValue:[[sender selectedCell] indexOfSelectedItem]];
}

- (IBAction) aHitCountModeAction:(id)sender
{
    [model setAHitCountMode:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) discCountModeAction:(id)sender
{
    [model setDiscCountMode:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) eventExtensionModeAction:(id)sender
{
    [model setEventExtensionMode:[sender selectedRow] withValue:[[sender selectedCell] indexOfSelectedItem]];
}

- (IBAction) pileupExtensionModeAction:(id)sender
{
    [model setPileupExtensionMode:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) counterResetAction:(id)sender
{
    [model setCounterReset:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) pileupWaveformOnlyModeAction:(id)sender
{
    [model setPileupWaveformOnlyMode:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) decimationFactorAction:(id)sender
{
    [model setDecimationFactor:[sender indexOfSelectedItem]];
}

- (IBAction) writeFlagAction:(id)sender
{
    [model setWriteFlag:[sender intValue]];
}

- (IBAction) pileupModeAction:(id)sender
{
    [model setPileupMode:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) preampResetDelayEnAction:(id)sender
{
    [model setPreampResetDelayEn:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) preampResetDelayAction:(id)sender
{
    [model setPreampResetDelay:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) droppedEventCountModeAction:(id)sender
{
    [model setDroppedEventCountMode:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) eventCountModeAction:(id)sender
{
    [model setEventCountMode:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) rawDataLengthAction:(id)sender
{
    //10 ns/count
    [model setRawDataLength:0 withValue:[sender intValue]];
}

- (IBAction) rawDataWindowAction:(id)sender
{
    [model setRawDataWindow:0 withValue:[sender intValue]];
}
- (IBAction) dWindowAction:(id)sender
{
    [model setDWindow:0 withValue:[sender intValue]];
}

- (IBAction) kWindowAction:(id)sender
{
    [model setKWindow:0 withValue:[sender intValue]];
}

- (IBAction) mWindowAction:(id)sender
{
    [model setMWindow:0 withValue:[sender intValue]];
}

- (IBAction) d3WindowAction:(id)sender
{
    [model setD3Window:0 withValue:[sender intValue]];
}

- (IBAction) discWidthAction:(id)sender
{
    [model setDiscWidth:0 withValue:[sender intValue]];
}

- (IBAction) baselineStartAction:(id)sender
{
    [model setBaselineStart:0 withValue:[sender intValue]];
}

- (IBAction) baselineDelayAction:(id)sender
{
    [model setBaselineDelay:[sender intValue]];
}

- (IBAction) p1WindowAction:(id)sender
{
    [model setP1Window:0 withValue:[sender intValue]];
}

- (IBAction) p2WindowAction:(id)sender
{
    [model setP2Window:[sender intValue]];
}

- (IBAction) triggerConfigAction:(id)sender
{
    [model setTriggerConfig:[sender indexOfSelectedItem]];
}

- (IBAction) windowCompMinAction:(id)sender
{
    [model setWindowCompMin:[sender intValue]];
}

- (IBAction) windowCompMaxAction:(id)sender
{
    [model setWindowCompMax:[sender intValue]];
}

#pragma mark •••Data Source
- (double) getBarValue:(int)tag
{
	return [[[[model waveFormRateGroup]rates] objectAtIndex:tag] rate];
}

- (int) numberPointsInPlot:(id)aPlotter
{
	return [[[model waveFormRateGroup]timeRate]count];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;
{
	int count = [[[model waveFormRateGroup]timeRate] count];
	int index = count-i-1;
	*yValue = [[[model waveFormRateGroup] timeRate] valueAtIndex:index];
	*xValue = [[[model waveFormRateGroup] timeRate] timeSampledAtIndex:index];
}
@end
