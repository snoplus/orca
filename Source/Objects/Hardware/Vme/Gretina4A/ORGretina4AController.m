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
    settingSize     = NSMakeSize(950,460);
    rateSize		= NSMakeSize(790,340);
    registerTabSize	= NSMakeSize(400,490);
	firmwareTabSize = NSMakeSize(340,187);
    blankView = [[NSView alloc] init];
    
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];
	

	// Setup register popup buttons
	[registerIndexPU removeAllItems];
	[registerIndexPU setAutoenablesItems:NO];
    
	int i;
    for(i=0;i<kNumberOfGretina4ARegisters;i++){
        [[enabledMatrix cellAtRow:i column:0] setTag:i];
    }
	for (i=0;i<kNumberOfGretina4ARegisters;i++) {
        NSString* s = [NSString stringWithFormat:@"(0x%04x) %@",[model registerOffsetAt:i], [model registerNameAt:i]];
        
		[registerIndexPU insertItemWithTitle:s	atIndex:i];
		[[registerIndexPU itemAtIndex:i] setEnabled:![model displayRegisterOnMainPage:i] && ![model displayFPGARegisterOnMainPage:i]];
	}
	// And now the FPGA registers
	for (i=0;i<kNumberOfFPGARegisters;i++) {
        NSString* s = [NSString stringWithFormat:@"(0x%04x) %@",[model fpgaRegisterOffsetAt:i], [model fpgaRegisterNameAt:i]];

		[registerIndexPU insertItemWithTitle:s	atIndex:(i+kNumberOfGretina4ARegisters)];
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
                     selector : @selector(forceFullInitChanged:)
                         name : ORGretina4AForceFullInitChanged
                       object : model];
    [notifyCenter addObserver : self
                     selector : @selector(firmwareVersionChanged:)
                         name : ORGretina4AFirmwareVersionChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(fifoEmptyChanged:)
                         name : ORGretina4AFifoEmpty0Changed
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(fifoEmpty1Changed:)
                         name : ORGretina4AFifoEmpty1Changed
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(fifoAlmostEmptyChanged:)
                         name : ORGretina4AFifoAlmostEmptyChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(fifoHalfFullChanged:)
                         name : ORGretina4AFifoHalfFullChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(fifoAlmostFullChanged:)
                         name : ORGretina4AFifoAlmostFullChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(fifoFullChanged:)
                         name : ORGretina4AFifoFull0Changed
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(fifoFull1Changed:)
                         name : ORGretina4AFifoFull1Changed
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(phSuccessChanged:)
                         name : ORGretina4APhSuccessChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(phFailureChanged:)
                         name : ORGretina4APhFailureChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(phHuntingUpChanged:)
                         name : ORGretina4APhHuntingUpChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(phHuntingDownChanged:)
                         name : ORGretina4APhHuntingDownChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(phCheckingChanged:)
                         name : ORGretina4APhCheckingChanged
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
                     selector : @selector(pileupWaveformOnlyModeChanged:)
                         name : ORGretina4APileupWaveformOnlyMode0Changed
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(ledThresholdChanged:)
                         name : ORGretina4ALedThreshold0Changed
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
                     selector : @selector(d2WindowChanged:)
                         name : ORGretina4AD2WindowChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(baselineStartChanged:)
                         name : ORGretina4ABaselineStartChanged
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
                         name : ORGretina4AOverflowFlagChan0Changed
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(overflowFlagChan1Changed:)
                         name : ORGretina4AOverflowFlagChan1Changed
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(overflowFlagChan2Changed:)
                         name : ORGretina4AOverflowFlagChan2Changed
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(overflowFlagChan3Changed:)
                         name : ORGretina4AOverflowFlagChan3Changed
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(overflowFlagChan4Changed:)
                         name : ORGretina4AOverflowFlagChan4Changed
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(overflowFlagChan5Changed:)
                         name : ORGretina4AOverflowFlagChan5Changed
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(overflowFlagChan6Changed:)
                         name : ORGretina4AOverflowFlagChan6Changed
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(overflowFlagChan7Changed:)
                         name : ORGretina4AOverflowFlagChan7Changed
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(overflowFlagChan8Changed:)
                         name : ORGretina4AOverflowFlagChan8Changed
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(overflowFlagChan9Changed:)
                         name : ORGretina4AOverflowFlagChan9Changed
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
    [self forceFullInitChanged:nil];
    [self firmwareVersionChanged:nil];
    [self fifoEmptyChanged:nil];
    [self fifoEmpty1Changed:nil];
    [self fifoAlmostEmptyChanged:nil];
    [self fifoHalfFullChanged:nil];
    [self fifoAlmostFullChanged:nil];
    [self fifoFullChanged:nil];
    [self fifoFull1Changed:nil];
    [self phSuccessChanged:nil];
    [self phFailureChanged:nil];
    [self phHuntingUpChanged:nil];
    [self phHuntingDownChanged:nil];
    [self phCheckingChanged:nil];
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
    [self pileupWaveformOnlyModeChanged:nil];
    [self ledThresholdChanged:nil];
    [self preampResetDelayChanged:nil];
    [self cFDFractionChanged:nil];
    [self rawDataLengthChanged:nil];
    [self rawDataWindowChanged:nil];
    [self dWindowChanged:nil];
    [self kWindowChanged:nil];
    [self mWindowChanged:nil];
    [self d2WindowChanged:nil];
    [self discWidthChanged:nil];
    [self baselineStartChanged:nil];
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
    [self overflowFlagChan1Changed:nil];
    [self overflowFlagChan2Changed:nil];
    [self overflowFlagChan3Changed:nil];
    [self overflowFlagChan4Changed:nil];
    [self overflowFlagChan5Changed:nil];
    [self overflowFlagChan6Changed:nil];
    [self overflowFlagChan7Changed:nil];
    [self overflowFlagChan8Changed:nil];
    [self overflowFlagChan9Changed:nil];
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
        if (![model displayRegisterOnMainPage:index]) {
            [writeRegisterButton setEnabled:[model canWriteRegister:index]];
            [registerWriteValueField setEnabled:[model canWriteRegister:index]];
            [readRegisterButton setEnabled:[model canReadRegister:index]];
            [registerStatusField setStringValue:@""];
        } else {
            [writeRegisterButton setEnabled:NO];
            [registerWriteValueField setEnabled:NO];
            [readRegisterButton setEnabled:NO];
            [registerStatusField setTextColor:[NSColor redColor]];
            [registerStatusField setStringValue:@"Set value in Basic Ops."];
        }
    }
    else {
        if (![model displayFPGARegisterOnMainPage:index]) {
            index -= kNumberOfGretina4ARegisters;
            [writeRegisterButton setEnabled:[model canWriteFPGARegister:index]];
            [registerWriteValueField setEnabled:[model canWriteFPGARegister:index]];
            [readRegisterButton setEnabled:[model canReadFPGARegister:index]];
            [registerStatusField setStringValue:@""];
        } else {
            [writeRegisterButton setEnabled:NO];
            [registerWriteValueField setEnabled:NO];
            [readRegisterButton setEnabled:NO];
            [registerStatusField setTextColor:[NSColor redColor]];
            [registerStatusField setStringValue:@"Set value in Basic Ops."];
        }
    }
    
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
    [initSerDesStateField setStringValue:[model initSerDesStateName]];
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
- (void) firmwareVersionChanged:(NSNotification*)aNote
{
}
- (void) fifoEmptyChanged:(NSNotification*)aNote
{
}
- (void) fifoEmpty1Changed:(NSNotification*)aNote
{
}
- (void) fifoAlmostEmptyChanged:(NSNotification*)aNote
{
}
- (void) fifoHalfFullChanged:(NSNotification*)aNote
{
}
- (void) fifoAlmostFullChanged:(NSNotification*)aNote
{
}
- (void) fifoFullChanged:(NSNotification*)aNote
{
}
- (void) fifoFull1Changed:(NSNotification*)aNote
{
}
- (void) phSuccessChanged:(NSNotification*)aNote
{
}
- (void) phFailureChanged:(NSNotification*)aNote
{
}
- (void) phHuntingUpChanged:(NSNotification*)aNote
{
}
- (void) phHuntingDownChanged:(NSNotification*)aNote
{
}
- (void) phCheckingChanged:(NSNotification*)aNote
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
}
- (void) pileupWaveformOnlyModeChanged:(NSNotification*)aNote
{
}
- (void) ledThresholdChanged:(NSNotification*)aNote
{
}
- (void) cFDFractionChanged:(NSNotification*)aNote
{
}
- (void) preampResetDelayChanged:(NSNotification*)aNote
{
}
- (void) rawDataLengthChanged:(NSNotification*)aNote
{
}
- (void) rawDataWindowChanged:(NSNotification*)aNote
{
}
- (void) dWindowChanged:(NSNotification*)aNote
{
}
- (void) kWindowChanged:(NSNotification*)aNote
{
}
- (void) mWindowChanged:(NSNotification*)aNote
{
}
- (void) d2WindowChanged:(NSNotification*)aNote
{
}
- (void) discWidthChanged:(NSNotification*)aNote
{
}
- (void) baselineStartChanged:(NSNotification*)aNote
{
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
- (void) peakSensitivityChanged:(NSNotification*)aNote
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
- (void) overflowFlagChan1Changed:(NSNotification*)aNote
{
}
- (void) overflowFlagChan2Changed:(NSNotification*)aNote
{
}
- (void) overflowFlagChan3Changed:(NSNotification*)aNote
{
}
- (void) overflowFlagChan4Changed:(NSNotification*)aNote
{
}
- (void) overflowFlagChan5Changed:(NSNotification*)aNote
{
}
- (void) overflowFlagChan6Changed:(NSNotification*)aNote
{
}
- (void) overflowFlagChan7Changed:(NSNotification*)aNote
{
}
- (void) overflowFlagChan8Changed:(NSNotification*)aNote
{
}
- (void) overflowFlagChan9Changed:(NSNotification*)aNote
{
}
- (void) triggerConfigChanged:(NSNotification*)aNote
{
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

- (IBAction) registerIndexPUAction:(id)sender
{
	unsigned int index = [sender indexOfSelectedItem];
	[model setRegisterIndex:index];
	[self setRegisterDisplay:index];
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
		aValue = [model readRegister:index];
		NSLog(@"Gretina4A(%d,%d) %@: %u (0x%0x)\n",[model crateNumber],[model slot], [model registerNameAt:index],aValue,aValue);
	} 
	else {
		index -= kNumberOfGretina4ARegisters;
		aValue = [model readFPGARegister:index];	
		NSLog(@"Gretina4A(%d,%d) %@: %u (0x%0x)\n",[model crateNumber],[model slot], [model fpgaRegisterNameAt:index],aValue,aValue);
	}
}

- (IBAction) writeRegisterAction:(id)sender
{
	[self endEditing];
	unsigned long aValue = [model registerWriteValue];
	unsigned int index = [model registerIndex];
	if (index < kNumberOfGretina4ARegisters) {
		[model writeRegister:index withValue:aValue];
	} 
	else {
		index -= kNumberOfGretina4ARegisters;
		[model writeFPGARegister:index withValue:aValue];	
	}
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
        NSRunAlertPanel([localException name], @"%@\nFailed Gretina4A Reset", @"OK", nil, nil,
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
        NSRunAlertPanel([localException name], @"%@\nFailed Gretina4A Init", @"OK", nil, nil,
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
        NSRunAlertPanel([localException name], @"%@\nFailed Gretina4A Init", @"OK", nil, nil,
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
        NSRunAlertPanel([localException name], @"%@\nFailed Gretina4A FIFO Clear", @"OK", nil, nil,
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
        NSRunAlertPanel([localException name], @"%@\nFailed Probe", @"OK", nil, nil,
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
        NSRunAlertPanel([localException name], @"%@\nFailed LED Threshold finder", @"OK", nil, nil,
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
        NSRunAlertPanel([localException name], @"%@\nFailed Probe", @"OK", nil, nil,
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
