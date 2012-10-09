//-------------------------------------------------------------------------
//  ORGretina4MController.h
//
//  Created by Mark A. Howe on Wednesday 02/07/2007.
//  Copyright (c) 2007 CENPA. University of Washington. All rights reserved.
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

//-------------------------------------------------------------------------

#pragma mark ***Imported Files
#import "OrcaObjectController.h"
#import "ORGretina4MModel.h"

@class ORValueBarGroupView;
@class ORCompositeTimeLineView;

@interface ORGretina4MController : OrcaObjectController 
{
    IBOutlet NSTabView* 	tabView;
    
	IBOutlet   NSTextField* integrateTimeField;
	IBOutlet   NSTextField* collectionTimeField;
	IBOutlet   NSTextField* extTrigLengthField;
	IBOutlet   NSTextField* pileUpWindowField;
	IBOutlet   NSTextField* externalWindowField;

    //basic ops page
	IBOutlet NSMatrix*		enabledMatrix;
	IBOutlet NSMatrix*		cfdEnabledMatrix;
	IBOutlet NSMatrix*		poleZeroEnabledMatrix;
	IBOutlet NSMatrix*		poleZeroTauMatrix;
	IBOutlet NSMatrix*		pzTraceEnabledMatrix;
	IBOutlet NSMatrix*		debugMatrix;
	IBOutlet NSMatrix*		presumEnabledMatrix;
	IBOutlet NSMatrix*		ledThresholdMatrix;
	IBOutlet NSMatrix*		cfdDelayMatrix;
	IBOutlet NSMatrix*		cfdFractionMatrix;
	IBOutlet NSMatrix*		cfdThresholdMatrix;
	IBOutlet NSMatrix*		dataDelayMatrix;
	IBOutlet NSMatrix*		dataLengthMatrix;
	IBOutlet NSMatrix*      tpolMatrix;
	IBOutlet NSMatrix*      triggerModeMatrix;
    IBOutlet NSMatrix*		chpsdvMatrix;
    IBOutlet NSMatrix*		ftCntMatrix;
    IBOutlet NSMatrix*		mrpsrtMatrix;
    IBOutlet NSMatrix*		mrpsdvMatrix;
    IBOutlet NSMatrix*		chpsrtMatrix;
    IBOutlet NSMatrix*		prerecntMatrix;
    IBOutlet NSMatrix*		postrecntMatrix;

    IBOutlet NSPopUpButton* clockMuxPU;

    IBOutlet NSButton*      settingLockButton;
    IBOutlet NSButton*      initButton;
    IBOutlet NSButton*      resetButton;
    IBOutlet NSButton*      clearFIFOButton;
    IBOutlet NSButton*      probeButton;
    IBOutlet NSButton*      statusButton;
    IBOutlet NSButton*      noiseFloorButton;
    IBOutlet NSTextField*   fifoState;

	IBOutlet NSPopUpButton* downSamplePU;
	
	//FPGA download
	IBOutlet NSTextField*			fpgaFilePathField;
	IBOutlet NSButton*				loadMainFPGAButton;
	IBOutlet NSButton*				stopFPGALoadButton;
    IBOutlet NSProgressIndicator*	loadFPGAProgress;
	IBOutlet NSTextField*			mainFPGADownLoadStateField;

    //rate page
    IBOutlet NSMatrix*      rateTextFields;
    IBOutlet NSStepper*     integrationStepper;
    IBOutlet NSTextField*   integrationText;
    IBOutlet NSTextField*   totalRateText;
    IBOutlet NSMatrix*      enabled2Matrix;

    IBOutlet ORValueBarGroupView*    rate0;
    IBOutlet ORValueBarGroupView*    totalRate;
    IBOutlet NSButton*      rateLogCB;
    IBOutlet NSButton*      totalRateLogCB;
    IBOutlet ORCompositeTimeLineView*    timeRatePlot;
    IBOutlet NSButton*      timeRateLogCB;
	
    //register page
	IBOutlet NSPopUpButton*	registerIndexPU;
	IBOutlet NSTextField*	registerWriteValueField;
	IBOutlet NSButton*		writeRegisterButton;
	IBOutlet NSButton*		readRegisterButton;
	IBOutlet NSTextField*	registerStatusField;
	IBOutlet NSTextField*	spiWriteValueField;
	IBOutlet NSButton*		writeSPIButton;
	
    //offset panel
    IBOutlet NSPanel*				noiseFloorPanel;
    IBOutlet NSTextField*			noiseFloorOffsetField;
    IBOutlet NSTextField*			noiseFloorIntegrationField;
    IBOutlet NSButton*				startNoiseFloorButton;
    IBOutlet NSProgressIndicator*	noiseFloorProgress;
	IBOutlet NSButton*				registerLockButton;
	
    NSView *blankView;
    NSSize settingSize;
    NSSize rateSize;
    NSSize registerTabSize;
	NSSize firmwareTabSize;

}

- (id)   init;
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark •••Interface Management
- (void) chpsdvChanged:(NSNotification*)aNote;
- (void) mrpsrtChanged:(NSNotification*)aNote;
- (void) ftCntChanged:(NSNotification*)aNote;
- (void) mrpsdvChanged:(NSNotification*)aNote;
- (void) chsrtChanged:(NSNotification*)aNote;
- (void) prerecntChanged:(NSNotification*)aNote;
- (void) postrecntChanged:(NSNotification*)aNote;

- (void) integrateTimeChanged:(NSNotification*)aNote;
- (void) collectionTimeChanged:(NSNotification*)aNote;
- (void) extTrigLengthChanged:(NSNotification*)aNote;
- (void) pileUpWindowChanged:(NSNotification*)aNote;
- (void) externalWindowChanged:(NSNotification*)aNote;
- (void) clockMuxChanged:(NSNotification*)aNote;
- (void) downSampleChanged:(NSNotification*)aNote;
- (void) registerIndexChanged:(NSNotification*)aNote;
- (void) fpgaDownInProgressChanged:(NSNotification*)aNote;
- (void) fpgaDownProgressChanged:(NSNotification*)aNote;
- (void) mainFPGADownLoadStateChanged:(NSNotification*)aNote;
- (void) fpgaFilePathChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) registerRates;
- (void) rateGroupChanged:(NSNotification*)aNote;
- (void) waveFormRateChanged:(NSNotification*)aNote;
- (void) noiseFloorChanged:(NSNotification*)aNote;
- (void) totalRateChanged:(NSNotification*)aNote;
- (void) noiseFloorOffsetChanged:(NSNotification*)aNote;
- (void) setFifoStateLabel;
- (void) enabledChanged:(NSNotification*)aNote;
- (void) cfdEnabledChanged:(NSNotification*)aNote;
- (void) poleZeroEnabledChanged:(NSNotification*)aNote;
- (void) poleZeroTauChanged:(NSNotification*)aNote;
- (void) pzTraceEnabledChanged:(NSNotification*)aNote;
- (void) debugChanged:(NSNotification*)aNote;
- (void) presumEnabledChanged:(NSNotification*)aNote;
- (void) tpolChanged:(NSNotification*)aNote;
- (void) triggerModeChanged:(NSNotification*)aNote;
- (void) ledThresholdChanged:(NSNotification*)aNote;
- (void) cfdDelayChanged:(NSNotification*)aNote;
- (void) cfdFractionChanged:(NSNotification*)aNote;
- (void) cfdThresholdChanged:(NSNotification*)aNote;
- (void) dataDelayChanged:(NSNotification*)aNote;
- (void) dataLengthChanged:(NSNotification*)aNote;
- (void) miscAttributesChanged:(NSNotification*)aNote;

- (void) scaleAction:(NSNotification*)aNote;
- (void) integrationChanged:(NSNotification*)aNote;
- (void) updateTimePlot:(NSNotification*)aNote;
- (void) noiseFloorIntegrationChanged:(NSNotification*)aNote;
- (void) registerLockChanged:(NSNotification*)aNote;
- (void) registerWriteValueChanged:(NSNotification*)aNote;
- (void) spiWriteValueChanged:(NSNotification*)aNote;

- (void) setRegisterDisplay:(unsigned int)index;

#pragma mark •••Actions
- (IBAction) integrateTimeFieldAction:(id)sender;
- (IBAction) collectionTimeFieldAction:(id)sender;
- (IBAction) extTrigLengthFieldAction:(id)sender;
- (IBAction) pileUpWindowFieldAction:(id)sender;
- (IBAction) externalWindowFieldAction:(id)sender;
- (IBAction) clockMuxAction:(id)sender;
- (IBAction) downSampleAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) probeBoard:(id)sender;
- (IBAction) readStatus:(id)sender;
- (IBAction) resetBoard:(id)sender;
- (IBAction) initBoardAction:(id)sender;
- (IBAction) clearFIFO:(id)sender;
- (IBAction) integrationAction:(id)sender;
- (IBAction) findNoiseFloors:(id)sender;
- (IBAction) noiseFloorOffsetAction:(id)sender;
- (IBAction) openNoiseFloorPanel:(id)sender;
- (IBAction) closeNoiseFloorPanel:(id)sender;
- (IBAction) noiseFloorIntegrationAction:(id)sender;

- (IBAction) chpsdvAction:(id)sender;
- (IBAction) mrpsrtAction:(id)sender;
- (IBAction) ftCntAction:(id)sender;
- (IBAction) mrpsdvAction:(id)sender;
- (IBAction) chsrtAction:(id)sender;
- (IBAction) prerecntAction:(id)sender;
- (IBAction) postrecntAction:(id)sender;


- (IBAction) enabledAction:(id)sender;
- (IBAction) cfdEnabledAction:(id)sender;
- (IBAction) poleZeroEnabledAction:(id)sender;
- (IBAction) poleZeroTauAction:(id)sender;
- (IBAction) pzTraceEnabledAction:(id)sender;
- (IBAction) debugAction:(id)sender;
- (IBAction) presumEnabledAction:(id)sender;
- (IBAction) tpolAction:(id)sender;
- (IBAction) triggerModeAction:(id)sender;
- (IBAction) ledThresholdAction:(id)sender;
- (IBAction) cfdFractionAction:(id)sender;
- (IBAction) cfdDelayAction:(id)sender;
- (IBAction) cfdThresholdAction:(id)sender;
- (IBAction) dataDelayAction:(id)sender;
- (IBAction) dataLengthAction:(id)sender;
- (IBAction) downloadMainFPGAAction:(id)sender;
- (IBAction) stopLoadingMainFPGAAction:(id)sender;

- (IBAction) registerIndexPUAction:(id)sender;
- (IBAction) readRegisterAction:(id)sender;
- (IBAction) writeRegisterAction:(id)sender;
- (IBAction) registerLockAction:(id) sender;
- (IBAction) registerWriteValueAction:(id)sender;
- (IBAction) spiWriteValueAction:(id)sender;
- (IBAction) writeSPIAction:(id)sender;

#pragma mark •••Data Source
- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;
- (double)  getBarValue:(int)tag;
- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;

@end
