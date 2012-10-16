//-------------------------------------------------------------------------
//  ORGretina4MController.m
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
#import <Cocoa/Cocoa.h>
#import "ORGretina4MController.h"
#import "ORRateGroup.h"
#import "ORRate.h"
#import "ORValueBar.h"
#import "ORTimeRate.h"
#import "ORTimeLinePlot.h"
#import "ORPlotView.h"
#import "ORTimeAxis.h"
#import "ORCompositePlotView.h"
#import "ORValueBarGroupView.h"

#if !defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6 // 10.6-specific
@interface ORGretina4MController (private)
- (void) openPanelForMainFPGADidEnd:(NSOpenPanel*)sheet
						 returnCode:(int)returnCode
						contextInfo:(void*)contextInfo;
@end
#endif

@implementation ORGretina4MController

-(id)init
{
    self = [super initWithWindowNibName:@"Gretina4M"];
    
    return self;
}

- (void) dealloc
{
	[blankView release];
	[super dealloc];
}

- (void) awakeFromNib
{
    settingSize     = NSMakeSize(1060,460);
    rateSize		= NSMakeSize(790,340);
    registerTabSize	= NSMakeSize(400,287);
	firmwareTabSize = NSMakeSize(340,187);
	definitionsTabSize = NSMakeSize(1200,350);
    blankView = [[NSView alloc] init];
    
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];
	

	// Setup register popup buttons
	[registerIndexPU removeAllItems];
	[registerIndexPU setAutoenablesItems:NO];
	int i;
	for (i=0;i<kNumberOfGretina4MRegisters;i++) {
		[registerIndexPU insertItemWithTitle:[model registerNameAt:i]	atIndex:i];
		[[registerIndexPU itemAtIndex:i] setEnabled:![model displayRegisterOnMainPage:i] && ![model displayFPGARegisterOnMainPage:i]];
	}
	// And now the FPGA registers
	for (i=0;i<kNumberOfFPGARegisters;i++) {
		[registerIndexPU insertItemWithTitle:[model fpgaRegisterNameAt:i]	atIndex:(i+kNumberOfGretina4MRegisters)];
	}

    NSString* key = [NSString stringWithFormat: @"orca.Gretina4M%d.selectedtab",[model slot]];
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
                         name : ORGretina4MSettingsLock
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(registerLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(registerLockChanged:)
                         name : ORGretina4MRegisterLock
                        object: nil];
	   
    [notifyCenter addObserver : self
                     selector : @selector(rateGroupChanged:)
                         name : ORGretina4MRateGroupChangedNotification
                       object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(totalRateChanged:)
						 name : ORRateGroupTotalRateChangedNotification
					   object : nil];
	
    //a fake action for the scale objects
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
                     selector : @selector(noiseFloorChanged:)
                         name : ORGretina4MNoiseFloorChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(noiseFloorOffsetChanged:)
                         name : ORGretina4MModelNoiseFloorOffsetChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(setFifoStateLabel)
                         name : ORGretina4MModelFIFOCheckChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(noiseFloorIntegrationChanged:)
                         name : ORGretina4MModelNoiseFloorIntegrationTimeChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(enabledChanged:)
                         name : ORGretina4MModelEnabledChanged
                       object : model];
		
    [notifyCenter addObserver : self
                     selector : @selector(cfdEnabledChanged:)
                         name : ORGretina4MModelCFDEnabledChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(poleZeroEnabledChanged:)
                         name : ORGretina4MModelPoleZeroEnabledChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(poleZeroTauChanged:)
                         name : ORGretina4MModelPoleZeroMultChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pzTraceEnabledChanged:)
                         name : ORGretina4MModelPZTraceEnabledChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(debugChanged:)
                         name : ORGretina4MModelDebugChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(presumEnabledChanged:)
                         name : ORGretina4MModelPresumEnabledChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(tpolChanged:)
                         name : ORGretina4MModelTpolChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(triggerModeChanged:)
                         name : ORGretina4MModelTriggerModeChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(ledThresholdChanged:)
                         name : ORGretina4MModelLEDThresholdChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(cfdDelayChanged:)
                         name : ORGretina4MModelCFDDelayChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(cfdFractionChanged:)
                         name : ORGretina4MModelCFDFractionChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(cfdThresholdChanged:)
                         name : ORGretina4MModelCFDThresholdChanged
                       object : model];
		
    [notifyCenter addObserver : self
                     selector : @selector(fpgaFilePathChanged:)
                         name : ORGretina4MModelFpgaFilePathChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(mainFPGADownLoadStateChanged:)
                         name : ORGretina4MModelMainFPGADownLoadStateChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(fpgaDownProgressChanged:)
                         name : ORGretina4MModelFpgaDownProgressChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(fpgaDownInProgressChanged:)
                         name : ORGretina4MModelMainFPGADownLoadInProgressChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORGretina4MModelMainFPGADownLoadInProgressChanged
                       object : nil];

	[notifyCenter addObserver : self
                     selector : @selector(registerLockChanged:)
                         name : ORGretina4MModelMainFPGADownLoadInProgressChanged
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(registerWriteValueChanged:)
                         name : ORGretina4MModelRegisterWriteValueChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(registerIndexChanged:)
                         name : ORGretina4MModelRegisterIndexChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(spiWriteValueChanged:)
                         name : ORGretina4MModelSPIWriteValueChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(downSampleChanged:)
                         name : ORGretina4MModelDownSampleChanged
						object: model];

	[self registerRates];
    [notifyCenter addObserver : self
                     selector : @selector(clockMuxChanged:)
                         name : ORGretina4MModelClockMuxChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(externalWindowChanged:)
                         name : ORGretina4MModelExternalWindowChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(pileUpWindowChanged:)
                         name : ORGretina4MModelPileUpWindowChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(extTrigLengthChanged:)
                         name : ORGretina4MModelExtTrigLengthChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(collectionTimeChanged:)
                         name : ORGretina4MModelCollectionTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(integrateTimeChanged:)
                         name : ORGretina4MModelIntegrateTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(chpsdvChanged:)
                         name : ORGretina4MModelChpsdvChanged
						object: model];
 
    [notifyCenter addObserver : self
                     selector : @selector(mrpsrtChanged:)
                         name : ORGretina4MModelMrpsrtChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(ftCntChanged:)
                         name : ORGretina4MModelFtCntChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(mrpsdvChanged:)
                         name : ORGretina4MModelMrpsdvChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(chsrtChanged:)
                         name : ORGretina4MModelChpsrtChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(prerecntChanged:)
                         name : ORGretina4MModelPrerecntChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(postrecntChanged:)
                         name : ORGretina4MModelPostrecntChanged
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
    [self slotChanged:nil];
    [self settingsLockChanged:nil];
	[self enabledChanged:nil];
	[self cfdEnabledChanged:nil];
	[self poleZeroEnabledChanged:nil];
	[self poleZeroTauChanged:nil];
	[self pzTraceEnabledChanged:nil];
	[self debugChanged:nil];
	[self presumEnabledChanged:nil];
	[self tpolChanged:nil];
	[self triggerModeChanged:nil];
	[self ledThresholdChanged:nil];
	[self cfdDelayChanged:nil];
	[self cfdFractionChanged:nil];
	[self cfdThresholdChanged:nil];
	
    [self rateGroupChanged:nil];
    [self integrationChanged:nil];
    [self miscAttributesChanged:nil];
    [self totalRateChanged:nil];
    [self updateTimePlot:nil];
    [self waveFormRateChanged:nil];
	[self noiseFloorChanged:nil];
	[self noiseFloorIntegrationChanged:nil];
	[self noiseFloorOffsetChanged:nil];
		
	[self fpgaFilePathChanged:nil];
	[self mainFPGADownLoadStateChanged:nil];
	[self fpgaDownProgressChanged:nil];
	[self fpgaDownInProgressChanged:nil];

    [self registerLockChanged:nil];

	[self registerIndexChanged:nil];
	[self registerWriteValueChanged:nil];
	[self spiWriteValueChanged:nil];
	[self downSampleChanged:nil];
	[self clockMuxChanged:nil];
	[self externalWindowChanged:nil];
	[self pileUpWindowChanged:nil];
	[self extTrigLengthChanged:nil];
	[self collectionTimeChanged:nil];
	[self integrateTimeChanged:nil];
    
    [self chpsdvChanged:nil];
    [self mrpsrtChanged:nil];
    [self ftCntChanged:nil];
    [self mrpsdvChanged:nil];
    [self chsrtChanged:nil];
    [self prerecntChanged:nil];
    [self postrecntChanged:nil];
}

#pragma mark •••Interface Management
- (void) chpsdvChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [[chpsdvMatrix cellAtRow:i column:0] selectItemAtIndex:[model chpsdv:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[chpsdvMatrix cellAtRow:chan column:0] selectItemAtIndex:[model chpsdv:chan]];
    }
}

- (void) mrpsrtChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [[mrpsrtMatrix cellAtRow:i column:0] selectItemAtIndex:[model mrpsrt:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[mrpsrtMatrix cellAtRow:chan column:0] selectItemAtIndex:[model mrpsrt:chan]];
    }
}

- (void) ftCntChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [[ftCntMatrix cellAtRow:i column:0] setIntValue:[model ftCnt:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[ftCntMatrix cellAtRow:chan column:0] setIntValue:[model ftCnt:chan]];
    }
}

- (void) mrpsdvChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [[mrpsdvMatrix cellAtRow:i column:0] selectItemAtIndex:[model mrpsdv:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[mrpsdvMatrix cellAtRow:chan column:0] selectItemAtIndex:[model mrpsdv:chan]];
    }
}

- (void) chsrtChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [[chpsrtMatrix cellAtRow:i column:0] selectItemAtIndex:[model chpsrt:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[chpsrtMatrix cellAtRow:chan column:0] selectItemAtIndex:[model chpsrt:chan]];
    }
}

- (void) prerecntChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [[prerecntMatrix cellAtRow:i column:0] setIntValue:[model prerecnt:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[prerecntMatrix cellAtRow:chan column:0] setIntValue:[model prerecnt:chan]];
    }
}

- (void) postrecntChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [[postrecntMatrix cellAtRow:i column:0] setIntValue:[model postrecnt:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[postrecntMatrix cellAtRow:chan column:0] setIntValue:[model postrecnt:chan]];
    }
}


- (void) integrateTimeChanged:(NSNotification*)aNote
{
	[integrateTimeField setFloatValue: [model integrateTimeConverted]];
}

- (void) collectionTimeChanged:(NSNotification*)aNote
{
	[collectionTimeField setFloatValue: [model collectionTimeConverted]];
}

- (void) extTrigLengthChanged:(NSNotification*)aNote
{
	[extTrigLengthField setFloatValue: [model extTrigLengthConverted]];
}

- (void) pileUpWindowChanged:(NSNotification*)aNote
{
	[pileUpWindowField setFloatValue: [model pileUpWindowConverted]];
}

- (void) externalWindowChanged:(NSNotification*)aNote
{
	[externalWindowField setFloatValue: [model externalWindowConverted]];
}

- (void) clockMuxChanged:(NSNotification*)aNote
{
	[clockMuxPU selectItemAtIndex: [model clockMux]];
}

- (void) downSampleChanged:(NSNotification*)aNote
{
	[downSamplePU selectItemAtIndex:[model downSample]];
}

- (void) registerWriteValueChanged:(NSNotification*)aNote
{
	[registerWriteValueField setIntValue: [model registerWriteValue]];
}

- (void) registerIndexChanged:(NSNotification*)aNote
{
	[registerIndexPU selectItemAtIndex: [model registerIndex]];
	[self setRegisterDisplay:[model registerIndex]];
}

- (void) spiWriteValueChanged:(NSNotification*)aNote
{
	[spiWriteValueField setIntValue: [model spiWriteValue]];
}

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

- (void) enabledChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4MChannels;i++){
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


- (void) cfdEnabledChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [[cfdEnabledMatrix cellWithTag:i] setState:[model cfdEnabled:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[cfdEnabledMatrix cellWithTag:chan] setState:[model cfdEnabled:chan]];
    }
}

- (void) poleZeroEnabledChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [[poleZeroEnabledMatrix cellWithTag:i] setState:[model poleZeroEnabled:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[poleZeroEnabledMatrix cellWithTag:chan] setState:[model poleZeroEnabled:chan]];
    }
}
    

- (void) poleZeroTauChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [[poleZeroTauMatrix cellWithTag:i] setFloatValue:[model poleZeroTauConverted:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[poleZeroTauMatrix cellWithTag:chan] setFloatValue:[model poleZeroTauConverted:chan]];
    }
}

- (void) pzTraceEnabledChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [[pzTraceEnabledMatrix cellWithTag:i] setState:[model pzTraceEnabled:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[pzTraceEnabledMatrix cellWithTag:chan] setState:[model pzTraceEnabled:chan]];
    }
}


- (void) debugChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [[debugMatrix cellWithTag:i] setState:[model debug:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[debugMatrix cellWithTag:chan] setState:[model debug:chan]];
    }
}
- (void) presumEnabledChanged:(NSNotification*)aNote
{
   if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [[presumEnabledMatrix cellWithTag:i] setState:[model presumEnabled:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[presumEnabledMatrix cellWithTag:chan] setState:[model presumEnabled:chan]];
    }
}

- (void) tpolChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [[tpolMatrix  cellWithTag:i] selectItemAtIndex:[model tpol:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[tpolMatrix cellAtRow:chan column:0] selectItemAtIndex:[model tpol:chan]];
    }
}

- (void) triggerModeChanged:(NSNotification*)aNote
{
    
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [[triggerModeMatrix  cellWithTag:i] selectItemAtIndex:[model triggerMode:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[triggerModeMatrix cellAtRow:chan column:0] selectItemAtIndex:[model triggerMode:chan]];
    }
}

- (void) ledThresholdChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [[ledThresholdMatrix cellWithTag:i] setIntValue:[model ledThreshold:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[ledThresholdMatrix cellWithTag:chan] setIntValue:[model ledThreshold:chan]];
    }
}
    
- (void) cfdDelayChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [[cfdDelayMatrix cellWithTag:i] setFloatValue:[model cfdDelayConverted:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[cfdDelayMatrix cellWithTag:chan] setFloatValue:[model cfdDelayConverted:chan]];
    }
}
    
- (void) cfdFractionChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [[cfdFractionMatrix cellWithTag:i] setIntValue:[model cfdFraction:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[cfdFractionMatrix cellWithTag:chan] setIntValue:[model cfdFraction:chan]];
    }
}

- (void) cfdThresholdChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [[cfdThresholdMatrix cellWithTag:i] setFloatValue:[model cfdThresholdConverted:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[cfdThresholdMatrix cellWithTag:chan] setFloatValue:[model cfdThresholdConverted:chan]];

    }
}
    
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

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORGretina4MSettingsLock to:secure];
    [gSecurity setLock:ORGretina4MRegisterLock to:secure];
    [settingLockButton setEnabled:secure];
    [registerLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORGretina4MSettingsLock];
    BOOL locked = [gSecurity isLocked:ORGretina4MSettingsLock];
    BOOL downloading = [model downLoadMainFPGAInProgress];
	
	[self setFifoStateLabel];
	
    [settingLockButton setState: locked];
    [initButton setEnabled:!lockedOrRunningMaintenance && !downloading];
    [clearFIFOButton setEnabled:!locked && !runInProgress && !downloading];
	[noiseFloorButton setEnabled:!locked && !runInProgress && !downloading];
	[statusButton setEnabled:!lockedOrRunningMaintenance && !downloading];
	[probeButton setEnabled:!locked && !runInProgress && !downloading];
	[enabledMatrix setEnabled:!lockedOrRunningMaintenance && !downloading];
	[cfdEnabledMatrix setEnabled:!lockedOrRunningMaintenance && !downloading];
	[poleZeroEnabledMatrix setEnabled:!lockedOrRunningMaintenance && !downloading];
	[poleZeroTauMatrix setEnabled:!lockedOrRunningMaintenance && !downloading];
	[pzTraceEnabledMatrix setEnabled:!lockedOrRunningMaintenance && !downloading];
	[debugMatrix setEnabled:!lockedOrRunningMaintenance && !downloading];
	[presumEnabledMatrix setEnabled:!lockedOrRunningMaintenance && !downloading];
	[ledThresholdMatrix setEnabled:!lockedOrRunningMaintenance && !downloading];
	[cfdDelayMatrix setEnabled:!lockedOrRunningMaintenance && !downloading];
	[cfdFractionMatrix setEnabled:!lockedOrRunningMaintenance && !downloading];
	[cfdThresholdMatrix setEnabled:!lockedOrRunningMaintenance && !downloading];
	[resetButton setEnabled:!lockedOrRunningMaintenance && !downloading];
	[loadMainFPGAButton setEnabled:!locked && !downloading];
	[stopFPGALoadButton setEnabled:!locked && downloading];
	[downSamplePU setEnabled:!lockedOrRunningMaintenance && !downloading];
	
    [tpolMatrix setEnabled:!lockedOrRunningMaintenance && !downloading];
    [triggerModeMatrix setEnabled:!lockedOrRunningMaintenance && !downloading];
}

- (void) registerLockChanged:(NSNotification*)aNotification
{
    
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORGretina4MRegisterLock];
    BOOL locked = [gSecurity isLocked:ORGretina4MRegisterLock];
    BOOL downloading = [model downLoadMainFPGAInProgress];
		
    [registerLockButton setState: locked];
    [registerWriteValueField setEnabled:!lockedOrRunningMaintenance && !downloading];
    [registerIndexPU setEnabled:!lockedOrRunningMaintenance && !downloading];
    [readRegisterButton setEnabled:!lockedOrRunningMaintenance && !downloading];
    [writeRegisterButton setEnabled:!lockedOrRunningMaintenance && !downloading];
    [spiWriteValueField setEnabled:!lockedOrRunningMaintenance && !downloading];
    [writeSPIButton setEnabled:!lockedOrRunningMaintenance && !downloading];
}

- (void) setFifoStateLabel
{
	if(![gOrcaGlobals runInProgress]){
		[fifoState setTextColor:[NSColor blackColor]];
		[fifoState setStringValue:@"--"];
	}
	else {
		int val = [model fifoState];
		if((val & kGretina4MFIFOAllFull)!=0) {
			[fifoState setTextColor:[NSColor redColor]];
			[fifoState setStringValue:@"Full"];
		} else if((val & kGretina4MFIFOAlmostFull)!=0) {
			[fifoState setTextColor:[NSColor redColor]];
			[fifoState setStringValue:@"Almost Full"];
		} else {
			[fifoState setTextColor:[NSColor blackColor]];
            if((val & kGretina4MFIFOEmpty)!=0)               [fifoState setStringValue:@"Empty"];
			else if((val & kGretina4MFIFOAlmostEmpty)!=0)    [fifoState setStringValue:@"Almost Empty"];
            else                                            [fifoState setStringValue:@"Half Full"];
			
		}
	}
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"Gretina4M Card (Slot %d)",[model slot]]];
}

- (void) slotChanged:(NSNotification*)aNotification
{
    [[self window] setTitle:[NSString stringWithFormat:@"Gretina4M Card (Slot %d)",[model slot]]];
}

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

- (void) setRegisterDisplay:(unsigned int)index
{
	if (index < kNumberOfGretina4MRegisters) {
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
			index -= kNumberOfGretina4MRegisters;
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

#pragma mark •••Actions
- (IBAction) chpsdvAction:(id)sender
{
    [model setChpsdv:[sender selectedRow] withValue:[[sender selectedCell] indexOfSelectedItem]];
}

- (IBAction) mrpsrtAction:(id)sender
{
    [model setMrpsrt:[sender selectedRow] withValue:[[sender selectedCell] indexOfSelectedItem]];
}

- (IBAction) ftCntAction:(id)sender
{
    [model setFtCnt:[sender selectedRow] withValue:[[sender selectedCell] intValue]];
}

- (IBAction) mrpsdvAction:(id)sender
{
    [model setMrpsdv:[sender selectedRow] withValue:[[sender selectedCell] indexOfSelectedItem]];
}

- (IBAction) chsrtAction:(id)sender
{
    [model setChpsrt:[sender selectedRow] withValue:[[sender selectedCell] indexOfSelectedItem]];
}

- (IBAction) prerecntAction:(id)sender
{
    [model setPrerecnt:[sender selectedRow] withValue:[[sender selectedCell] intValue]];
}

- (IBAction) postrecntAction:(id)sender
{
    [model setPostrecnt:[sender selectedRow] withValue:[[sender selectedCell] intValue]];
}

- (IBAction) integrateTimeFieldAction:(id)sender
{
	[model setIntegrateTimeConverted:[sender floatValue]];
}

- (IBAction) collectionTimeFieldAction:(id)sender
{
	[model setCollectionTimeConverted:[sender floatValue]];	
}

- (IBAction) extTrigLengthFieldAction:(id)sender
{
	[model setExtTrigLengthConverted:[sender floatValue]];	
}

- (IBAction) pileUpWindowFieldAction:(id)sender
{
	[model setPileUpWindowConverted:[sender floatValue]];	
}

- (IBAction) externalWindowFieldAction:(id)sender
{
	[model setExternalWindowConverted:[sender floatValue]];
}

- (IBAction) clockMuxAction:(id)sender
{
	[model setClockMux:[sender indexOfSelectedItem]];
}

- (IBAction) downSampleAction:(id)sender
{
	if([sender indexOfSelectedItem] != [model downSample]){
		[model setDownSample:[sender indexOfSelectedItem]];
	}
}

- (IBAction) registerIndexPUAction:(id)sender
{
	unsigned int index = [sender indexOfSelectedItem];
	[model setRegisterIndex:index];
	[self setRegisterDisplay:index];
}

- (IBAction) enabledAction:(id)sender
{
	if([sender intValue] != [model enabled:[[sender selectedCell] tag]]){
		[model setEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}
- (IBAction) cfdEnabledAction:(id)sender
{
	if([sender intValue] != [model cfdEnabled:[[sender selectedCell] tag]]){
		[model setCFDEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}
- (IBAction) poleZeroEnabledAction:(id)sender
{
	if([sender intValue] != [model poleZeroEnabled:[[sender selectedCell] tag]]){
		[model setPoleZeroEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}
- (IBAction) poleZeroTauAction:(id)sender
{
	if([sender intValue] != [model poleZeroTauConverted:[[sender selectedCell] tag]]){
		[model setPoleZeroTauConverted:[[sender selectedCell] tag] withValue:[sender floatValue]];
	}
}
- (IBAction) pzTraceEnabledAction:(id)sender
{
	if([sender intValue] != [model pzTraceEnabled:[[sender selectedCell] tag]]){
		[model setPZTraceEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}
- (IBAction) debugAction:(id)sender
{
	if([sender intValue] != [model debug:[[sender selectedCell] tag]]){
		[model setDebug:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}
- (IBAction) presumEnabledAction:(id)sender
{
	if([sender intValue] != [model presumEnabled:[[sender selectedCell] tag]]){
		[model setPresumEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) tpolAction:(id)sender
{
    [model setTpol:[sender selectedRow] withValue:[[sender selectedCell] indexOfSelectedItem]];
}

- (IBAction) triggerModeAction:(id)sender
{
    [model setTriggerMode:[sender selectedRow] withValue:[[sender selectedCell] indexOfSelectedItem]];
}

- (IBAction) ledThresholdAction:(id)sender
{
	if([sender intValue] != [model ledThreshold:[[sender selectedCell] tag]]){
		[model setLEDThreshold:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) cfdFractionAction:(id)sender
{
	if([sender intValue] != [model cfdFraction:[[sender selectedCell] tag]]){
		[model setCFDFraction:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) cfdDelayAction:(id)sender
{
	if([sender intValue] != [model cfdDelay:[[sender selectedCell] tag]]){
		[model setCFDDelayConverted:[[sender selectedCell] tag] withValue:[sender floatValue]];
	}
}

- (IBAction) cfdThresholdAction:(id)sender
{
	if([sender intValue] != [model cfdThreshold:[[sender selectedCell] tag]]){
		[model setCFDThresholdConverted:[[sender selectedCell] tag] withValue:[sender floatValue]];
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
	if (index < kNumberOfGretina4MRegisters) {
		aValue = [model readRegister:index];
		NSLog(@"Gretina4M(%d,%d) %@: %u (0x%0x)\n",[model crateNumber],[model slot], [model registerNameAt:index],aValue,aValue);
	} 
	else {
		index -= kNumberOfGretina4MRegisters;
		aValue = [model readFPGARegister:index];	
		NSLog(@"Gretina4M(%d,%d) %@: %u (0x%0x)\n",[model crateNumber],[model slot], [model fpgaRegisterNameAt:index],aValue,aValue);
	}
	
}

- (IBAction) writeRegisterAction:(id)sender
{
	[self endEditing];
	unsigned long aValue = [model registerWriteValue];
	unsigned int index = [model registerIndex];
	if (index < kNumberOfGretina4MRegisters) {
		[model writeRegister:index withValue:aValue];
	} 
	else {
		index -= kNumberOfGretina4MRegisters;
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
	NSLog(@"Gretina4M(%d,%d) writeSPI(%u) readback: (0x%0x)\n",[model crateNumber],[model slot], aValue, readback);
}


- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORGretina4MSettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) registerLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORGretina4MRegisterLock to:[sender intValue] forWindow:[self window]];
}


- (IBAction) resetBoard:(id) sender
{
    @try {
        [model resetBoard];
        NSLog(@"Reset Gretina4M Board (Slot %d <%p>)\n",[model slot],[model baseAddress]);
    }
	@catch(NSException* localException) {
        NSLog(@"Reset of Gretina4M Board FAILED.\n");
        NSRunAlertPanel([localException name], @"%@\nFailed Gretina4M Reset", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) initBoardAction:(id)sender
{
    @try {
        [self endEditing];
        [model initBoard:false];		//initialize and load hardware, but don't enable channels
        NSLog(@"Initialized Gretina4M (Slot %d <%p>)\n",[model slot],[model baseAddress]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"Init of Gretina4M FAILED.\n");
        NSRunAlertPanel([localException name], @"%@\nFailed Gretina4M Init", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) clearFIFO:(id)sender
{
    @try {  
        [model clearFIFO];
        NSLog(@"Gretina4M (Slot %d <%p>) FIFO cleared\n",[model slot],[model baseAddress]);
    }
	@catch(NSException* localException) {
        NSLog(@"Clear of Gretina4M FIFO FAILED.\n");
        NSRunAlertPanel([localException name], @"%@\nFailed Gretina4M FIFO Clear", @"OK", nil, nil,
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
        if(theID == ([model baseAddress]>>16))NSLog(@"Gretina BoardID looks correct\n");
        else NSLogColor([NSColor redColor],@"Gretina BoardID 0x%x doesn't match dip settings 0x%x\n", theID, [model baseAddress]>>16);
    }
	@catch(NSException* localException) {
        NSLog(@"Probe Gretina4M Board FAILED.\n");
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
        NSLog(@"LED Threshold Finder for Gretina4M Board FAILED.\n");
        NSRunAlertPanel([localException name], @"%@\nFailed LED Threshold finder", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) readStatus:(id)sender
{    
    [self endEditing];
    @try {
        NSLog(@"Gretina BoardID (slot %d): [0x%x] ID = 0x%x\n",[model slot],[model baseAddress],[model readBoardID]);
        int chan;
        for(chan = 0;chan<kNumGretina4MChannels;chan++){
            unsigned value = [model readControlReg:chan];
            NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"chan: %d Enabled: %@ Debug: %@  PileUp: %@ CFD: %@ Pole-zero: %@ Polarity: 0x%02x TriggerMode: 0x%02x\n",
                      chan, 
                      (value&0x1)?@"[YES]":@"[ NO]",		//enabled
                      ((value>>1)&0x1)?@"[YES]":@"[ NO]",	//debug
                      ((value>>2)&0x1)?@"[YES]":@"[ NO]", //pileup
                      ((value>>12)&0x1)?@"[YES]":@"[ NO]", //CFD
                      ((value>>13)&0x1)?@"[YES]":@"[ NO]", //pole-zero
                      (value>>10)&0x3, (value>>3)&0x3);
        }
        unsigned short fifoStatus = [model readFifoState];
        if(fifoStatus == kFull)			    NSLog(@"FIFO = Full\n");
        else if(fifoStatus == kAlmostFull)	NSLog(@"FIFO = Almost Full\n");
        else if(fifoStatus == kEmpty)		NSLog(@"FIFO = Empty\n");
        else if(fifoStatus == kAlmostEmpty)	NSLog(@"FIFO = Almost Empty\n");
        else if(fifoStatus == kHalfFull)	NSLog(@"FIFO = Half Full\n");
		
		NSLog(@"External Window: %g us\n",  0.01*[model readExternalWindow]);
		NSLog(@"Pileup Window: %g us\n",    0.01*[model readPileUpWindow]);
		NSLog(@"Clock Mux: %@\n",           [model readClockMux]?@"Onboard":@"Front Panel");
		NSLog(@"Ext Trig Length: %g us\n",  0.01*[model readExtTrigLength]);
		NSLog(@"Collection: %g us\n",       0.01*[model readCollectionTime]);
		NSLog(@"Integration Time: %g us\n", 0.01*[model readIntegrateTime]);
		NSLog(@"Down sample: x%d\n", (int) pow(2,[model readDownSample]));
        
    }
	@catch(NSException* localException) {
        NSLog(@"Probe Gretina4M Board FAILED.\n");
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
		[self resizeWindowToSize:rateSize];
		[[self window] setContentView:tabView];
    }     
	else if([tabView indexOfTabViewItem:tabViewItem] == 2){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:registerTabSize];
		[[self window] setContentView:tabView];
    }	
	else if([tabView indexOfTabViewItem:tabViewItem] == 3){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:firmwareTabSize];
		[[self window] setContentView:tabView];
    }  
	else if([tabView indexOfTabViewItem:tabViewItem] == 4){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:definitionsTabSize];
		[[self window] setContentView:tabView];
    }  
	
    NSString* key = [NSString stringWithFormat: @"orca.ORGretina4M%d.selectedtab",[model slot]];
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
#if defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6 // 10.6-specific
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [model setFpgaFilePath:[[openPanel URL]path]];
            [model startDownLoadingMainFPGA];
        }
    }];
#else 	
	[openPanel beginSheetForDirectory:NSHomeDirectory()
								 file:nil
								types:nil //[NSArray arrayWithObjects:@"bin",nil]
					   modalForWindow:[self window]
						modalDelegate:self
					   didEndSelector:@selector(openPanelForMainFPGADidEnd:returnCode:contextInfo:)
						  contextInfo:NULL];
#endif
}

- (IBAction) stopLoadingMainFPGAAction:(id)sender
{
	[model stopDownLoadingMainFPGA];
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

#if !defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6 // 10.6-specific
@implementation ORGretina4MController (private)
- (void) openPanelForMainFPGADidEnd:(NSOpenPanel*)sheet
						 returnCode:(int)returnCode
						contextInfo:(void*)contextInfo
{
    if(returnCode){
		[model setFpgaFilePath:[sheet filename]];
		[model startDownLoadingMainFPGA];
    }
}
@end
#endif
