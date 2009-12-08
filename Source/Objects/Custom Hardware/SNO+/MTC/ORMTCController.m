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
#import "ORPlotter1D.h"
#import "ORTimeRate.h"
#import "ORMTC_Constants.h"
#import "ORSelectorSequence.h"

#pragma mark •••PrivateInterface
@interface ORMTCController (private)
- (void) selectAndLoadDBFile:(NSString*)aStartPath;
- (void) setXilinxFileDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void) setDefaultFileDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void) saveDefaultSetDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void) selectAndLoadDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void) loadDBFileDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void) setMaskTags:(NSMatrix*)aMaskSet;
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
    basicOpsSize    = NSMakeSize(400,350);
	standardOpsSize	= NSMakeSize(390,530);
    settingsSize	= NSMakeSize(790,610);
    triggerSize		= NSMakeSize(790,630);
  
    blankView = [[NSView alloc] init];
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];

	
	[self setMaskTags:globalTriggerMaskMatrix2];
	[self setMaskTags:globalTriggerCrateMaskMatrix2];
	[self setMaskTags:pedCrateMaskMatrix2];
	[initProgressField setHidden:YES];
	
    [super awakeFromNib];
	
    NSString* key = [NSString stringWithFormat: @"orca.ORMTC%d.selectedtab",[model slot]];
    int index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
    [self populatePullDown];

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
					 selector : @selector(settingsLockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(settingsLockChanged:)
						 name : ORMTCLock
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
                     selector : @selector(defaultFileChanged:)
                         name : ORMTCModelDefaultFileChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(mtcDataBaseChanged:)
                         name : ORMTCModelMtcDataBaseChanged
						object: model];
						
    [notifyCenter addObserver : self
                     selector : @selector(lastFileLoadedChanged:)
                         name : ORMTCModelLastFileLoadedChanged
						object: model];
						
   [notifyCenter addObserver : self
                     selector : @selector(nHitViewTypeChanged:)
                         name : ORMTCModelNHitViewTypeChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(eSumViewTypeChanged:)
                         name : ORMTCModelESumViewTypeChanged
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

}

- (void) updateWindow
{
    [super updateWindow];
 	[self nHitViewTypeChanged:nil];
    [self regBaseAddressChanged:nil];
    [self memBaseAddressChanged:nil];
    [self slotChanged:nil];
    [self settingsLockChanged:nil];
	[self selectedRegisterChanged:nil];
	[self memoryOffsetChanged:nil];
	[self writeValueChanged:nil];
	[self repeatCountChanged:nil];
	[self repeatDelayChanged:nil];
	[self useMemoryChanged:nil];
	[self autoIncrementChanged:nil];
	[self basicOpsRunningChanged:nil];
	[self defaultFileChanged:nil];
	[self mtcDataBaseChanged:nil];
	[self lastFileLoadedChanged:nil];
	[self eSumViewTypeChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORMTCLock to:secure];
    [settingsLockButton setEnabled:secure];
    [basicOpsLockButton setEnabled:secure];
    [standardOpsLockButton setEnabled:secure];
	[self updateButtons];
}

#pragma mark •••Interface Management

- (void) updateButtons
{
    //BOOL runInProgress = [gOrcaGlobals runInProgress];
   //BOOL locked	= [gSecurity isLocked:ORMTCLock] ;
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORMTCLock] | sequenceRunning;

	[initMtcButton				setEnabled: !lockedOrRunningMaintenance];
	[initNoXilinxButton			setEnabled: !lockedOrRunningMaintenance];
	[initNo10MHzButton			setEnabled: !lockedOrRunningMaintenance];
	[initNoXilinxNo100MHzButton setEnabled: !lockedOrRunningMaintenance];
	[makeCrateMaskButton		setEnabled: !lockedOrRunningMaintenance];
	[load10MhzCounterButton		setEnabled: !lockedOrRunningMaintenance];
	[loadOnlineMaskButton		setEnabled: !lockedOrRunningMaintenance];
	[loadDacsButton				setEnabled: !lockedOrRunningMaintenance];
	[firePedestalsButton		setEnabled: !lockedOrRunningMaintenance];
	[triggerZeroMatrix			setEnabled: !lockedOrRunningMaintenance];
	[findTriggerZerosButton		setEnabled: !lockedOrRunningMaintenance];
	[continuousButton			setEnabled: !lockedOrRunningMaintenance];
	[stopTriggerZeroButton		setEnabled: !lockedOrRunningMaintenance];
	[stopTriggerZeroButton		setEnabled: !lockedOrRunningMaintenance];
	[passiveOnlyButton			setEnabled: !lockedOrRunningMaintenance];
	[setCoarseDelayButton		setEnabled: !lockedOrRunningMaintenance];
}

- (void) sequenceRunning:(NSNotification*)aNote
{
	sequenceRunning = YES;
	[initProgressBar startAnimation:self];
	[initProgressBar setDoubleValue:0];
	[initProgressField setHidden:NO];
	[initProgressField setDoubleValue:0];
	[self updateButtons];
}

- (void) sequenceStopped:(NSNotification*)aNote
{
	[initProgressField setHidden:YES];
	[initProgressBar setDoubleValue:0];
	[initProgressBar stopAnimation:self];
	sequenceRunning = NO;
	[self updateButtons];
}

- (void) sequenceProgress:(NSNotification*)aNote
{
	double progress = [[[aNote userInfo] objectForKey:@"progress"] floatValue];
	[initProgressBar setDoubleValue:progress];
	[initProgressField setFloatValue:progress/100.];
}

- (void) eSumViewTypeChanged:(NSNotification*)aNote
{
	[eSumViewTypeMatrix selectCellWithTag: [model eSumViewType]];
	[self setupESumFormats];
	[self mtcDataBaseChanged:nil];
}

- (void) nHitViewTypeChanged:(NSNotification*)aNote
{
	[nHitViewTypeMatrix selectCellWithTag: [model nHitViewType]];
	[self setupNHitFormats];
	[self mtcDataBaseChanged:nil];
}


- (void) mtcDataBaseChanged:(NSNotification*)aNote
{
	[lockOutWidthField		setFloatValue:	[model dbFloatByIndex: kLockOutWidth]];
	[pedestalWidthField		setFloatValue:	[model dbFloatByIndex: kPedestalWidth]];
	[nhit100LoPrescaleField setFloatValue:	[model dbFloatByIndex: kNhit100LoPrescale]];
	[pulserPeriodField		setFloatValue:	[model dbFloatByIndex: kPulserPeriod]];
	[low10MhzClockField		setFloatValue:	[model dbFloatByIndex: kLow10MhzClock]];
	[high10MhzClockField	setFloatValue:	[model dbFloatByIndex: kHigh10MhzClock]];
	[fineSlopeField			setFloatValue:	[model dbFloatByIndex: kFineSlope]];
	[minDelayOffsetField	setFloatValue:	[model dbFloatByIndex: kMinDelayOffset]];
	[coarseDelayField		setFloatValue:	[model dbFloatByIndex: kCoarseDelay]];
	[fineDelayField			setFloatValue:	[model dbFloatByIndex: kFineDelay]];
	
	[self displayMasks];

	//load the nhit values
	int col,row;
	float displayValue=0;
	for(col=0;col<4;col++){
		for(row=0;row<6;row++){
			int index = kNHit100HiThreshold + row + (col * 6);
			if(col == 0){
				int type = [model nHitViewType];
				if(type == kNHitsViewRaw) {
					displayValue = [model dbFloatByIndex: index];
				}	
				else if(type == kNHitsViewmVolts) { 
					float rawValue = [model dbFloatByIndex: index];
					displayValue = [model rawTomVolts:rawValue];
				}
				else if(type == kNHitsViewNHits) {
					int rawValue    = [model dbFloatByIndex: index];
					float mVolts    = [model rawTomVolts:rawValue];
					float dcOffset  = [model dbFloatByIndex:index + kNHitDcOffset_Offset];
					float mVperNHit = [model dbFloatByIndex:index + kmVoltPerNHit_Offset];
					displayValue    = [model mVoltsToNHits:mVolts dcOffset:dcOffset mVperNHit:mVperNHit];			
				}
			}
			else displayValue = [model dbFloatByIndex: index];
			[[nhitMatrix cellAtRow:row column:col] setFloatValue:displayValue];
		}
	}
	
	//now the esum values
	for(col=0;col<4;col++){
		for(row=0;row<4;row++){
			int index = kESumLowThreshold + row + (col * 4);
			if(col == 0){
				int type = [model eSumViewType];
				if(type == kESumViewRaw) {
					displayValue = [model dbFloatByIndex: index];
				}	
				else if(type == kESumViewmVolts) { 
					float rawValue = [model dbFloatByIndex: index];
					displayValue = [model rawTomVolts:rawValue];
				}
				else if(type == kESumVieweSumRel) {					
					float dcOffset = [model dbFloatByIndex:index + kESumDcOffset_Offset];
					displayValue = dcOffset - [model dbFloatByIndex: index];
				}
				else if(type == kESumViewpC) {
					int rawValue   = [model dbFloatByIndex: index];
					float mVolts   = [model rawTomVolts:rawValue];
					float dcOffset = [model dbFloatByIndex:index + kESumDcOffset_Offset];
					float mVperpC  = [model dbFloatByIndex:index + kmVoltPerpC_Offset];
					displayValue   = [model mVoltsTopC:mVolts dcOffset:dcOffset mVperpC:mVperpC];			
				}
			}
			else displayValue = [model dbFloatByIndex: index];
			[[esumMatrix cellAtRow:row column:col] setFloatValue:displayValue];
		}
	}
	
	NSString* ss = [model dbObjectByIndex: kDBComments];
	if(!ss) ss = @"---";
	[commentsField setStringValue: ss];
	
	NSString* xilinxFile = [model dbObjectByIndex: kXilinxFile];
	if(!xilinxFile) xilinxFile = @"---";
	[xilinxFilePathField setStringValue: [xilinxFile stringByAbbreviatingWithTildeInPath]];
}

- (void) displayMasks
{
	int i;
	int maskValue = [model dbIntByIndex: kGtMask];
	for(i=0;i<26;i++){
		[[globalTriggerMaskMatrix cellWithTag:i]  setIntValue: maskValue & (1<<i)];
		[[globalTriggerMaskMatrix2 cellWithTag:i] setIntValue: maskValue & (1<<i)];
	}
	maskValue = [model dbIntByIndex: kGtCrateMask];
	for(i=0;i<22;i++){
		[[globalTriggerCrateMaskMatrix cellWithTag:i]  setIntValue: maskValue & (1<<i)];
		[[globalTriggerCrateMaskMatrix2 cellWithTag:i] setIntValue: maskValue & (1<<i)];
	}
	maskValue = [model dbIntByIndex: kPEDCrateMask];
	for(i=0;i<22;i++){
		[[pedCrateMaskMatrix cellWithTag:i]  setIntValue: maskValue & (1<<i)];
		[[pedCrateMaskMatrix2 cellWithTag:i] setIntValue: maskValue & (1<<i)];
	}
	maskValue = [model dbIntByIndex: kControlMask];
	for(i=0;i<3;i++)[[controlRegMaskMatrix cellWithTag:i] setIntValue: maskValue & (1<<i)];
	
}

- (void) lastFileLoadedChanged:(NSNotification*)aNote
{
	[lastFileLoadedField setStringValue: [[[model lastFileLoaded] stringByAbbreviatingWithTildeInPath] stringByDeletingPathExtension]];
}

- (void) defaultFileChanged:(NSNotification*)aNote
{
	[defaultFileField setStringValue: [[[model defaultFile] stringByAbbreviatingWithTildeInPath] stringByDeletingPathExtension]];
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

- (void) loadXilinxPathChanged:(NSNotification*)aNote
{
	[xilinxFilePathField setStringValue: [[model xilinxFilePath] stringByAbbreviatingWithTildeInPath]];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
	
   // BOOL runInProgress = [gOrcaGlobals runInProgress];
    //BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORMTCSettingsLock];
    BOOL locked = [gSecurity isLocked:ORMTCLock];
	
    [settingsLockButton setState: locked];
    [basicOpsLockButton setState: locked];
    [standardOpsLockButton setState: locked];
	
}

- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)item
{
    if([tabView indexOfTabViewItem:item] == 0){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:basicOpsSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:item] == 1){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:standardOpsSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:item] == 2){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:settingsSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:item] == 3){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:triggerSize];
		[[self window] setContentView:tabView];
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

//------
- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORMTCLock to:[sender intValue] forWindow:[self window]];
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

- (void) buttonPushed:(id) sender 
{
	NSLog(@"Input received from %@\n", [sender title] );	//This is the only real method.  The other button push methods just call this one.
	NSLogColor([NSColor redColor], @"implementation needed\n");
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

- (IBAction) standardFirePedestals:(id) sender 
{
	[model fireMTCPedestalsFixedRate];
}

- (IBAction) standardFindTriggerZeroes:(id) sender 
{
	[self buttonPushed:sender];
}

- (IBAction) standardStopFindTriggerZeroes:(id) sender 
{
	[self buttonPushed:sender];
}

- (IBAction) standardPeriodicReadout:(id) sender 
{
	[self buttonPushed:sender];
}

//Settings buttons.
- (IBAction) eSumViewTypeAction:(id)sender
{
	[self endEditing];
	[model setESumViewType:[[sender selectedCell] tag]];	
}

- (IBAction) nHitViewTypeAction:(id)sender
{
	[self endEditing];
	[model setNHitViewType:[[sender selectedCell] tag]];
}

- (IBAction) settingsLoadDBFile:(id) sender 
{
	[self selectAndLoadDBFile:[model lastFileLoaded]];
}

- (IBAction) settingsDefaultGetSet:(id) sender 
{
	[self selectAndLoadDBFile:[model lastFile]];
}

- (IBAction) settingsMTCRecordSaveAs:(id) sender 
{
	[self settingsDefaultSaveSet:[model lastFile]];
}

- (IBAction) settingsXilinxFile:(id) sender 
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];
    NSString* startingDir;
	
	NSString* fullPath = [[model xilinxFilePath] stringByExpandingTildeInPath];
    if(fullPath)	startingDir = [[model xilinxFilePath] stringByDeletingLastPathComponent];
    else			startingDir = NSHomeDirectory();
	
    [openPanel beginSheetForDirectory:startingDir
                                 file:nil
                                types:nil
                       modalForWindow:[self window]
                        modalDelegate:self
                       didEndSelector:@selector(setXilinxFileDidEnd:returnCode:contextInfo:)
                          contextInfo:NULL];
}

- (IBAction) settingsLoadDefVals:(id) sender 
{
	[model loadSet:[model defaultFile]];
	NSLog(@"MTC DataBase loaded from: %@\n",[[[model defaultFile] stringByAbbreviatingWithTildeInPath] stringByDeletingPathExtension]);
}

- (IBAction) settingsPrint:(id) sender 
{
	NSLog(@"%@\n",[model mtcDataBase]);
}

- (IBAction) settingsNewComments:(id) sender 
{
	[model setDbObject:[sender stringValue] forIndex:kDBComments];
}

- (IBAction) settingsMTCDAction:(id) sender 
{
	[model setDbObject:[sender stringValue] forIndex:[sender tag]];
}

- (IBAction) settingsNHitAction:(id) sender 
{
	int row = [sender selectedRow];
	int col = [sender selectedColumn];
	int index = kNHit100HiThreshold + row + (col * 6);
	
	//get the value the user entered
	float theValue = [[sender cellAtRow:row column:col] floatValue];
	if((index >= kNHit100HimVperNHit) && (index <= kOWLNdcOffset)) {
		[model setDbFloat:theValue forIndex:index];
		[self calcNHitValueForRow:row];
	}
	else if((index >= kNHit100HiThreshold) && (index <= kOWLNThreshold)){
		[self storeUserNHitValue:theValue index:index];
	}
	else {
		[model setDbFloat:theValue forIndex:index];	
	}	
}


- (IBAction) settingsESumAction:(id) sender 
{
	int row = [sender selectedRow];
	int col = [sender selectedColumn];
	int index = kESumLowThreshold + row + (col * 4);
	//get the value the user entered
	float theValue = [[sender cellAtRow:row column:col] floatValue];
	if((index >= kESumLowmVperpC) && (index <= kOWLEHidcOffset)) {
		[model setDbFloat:theValue forIndex:index];
		[self calcESumValueForRow:row];
	}
	else if((index >= kESumLowThreshold) && (index <= kOWLEHiThreshold)){
		[self storeUserESumValue:theValue index:index];
	}
	else {
		[model setDbFloat:theValue forIndex:index];	
	}	
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
	for(i=0;i<22;i++){
		if([[sender cellWithTag:i] intValue]){	
			mask |= (1L << i);
		}
	}
	[model setDbLong:mask forIndex:kGtCrateMask];
}

- (IBAction) settingsControlRegMaskAction:(id) sender 
{
	unsigned long mask = 0;
	int i;
	for(i=0;i<3;i++){
		if([[sender cellWithTag:i] intValue]){	
			mask |= (1L << i);
		}
	}
	[model setDbLong:mask forIndex:kControlMask];
}

- (IBAction) settingsPEDCrateMaskAction:(id) sender 
{
	unsigned long mask = 0;
	int i;
	for(i=0;i<22;i++){
		if([[sender cellWithTag:i] intValue]){	
			mask |= (1L << i);
		}
	}
	[model setDbLong:mask forIndex:kPEDCrateMask];
}


- (IBAction) settingsDefValFile:(id) sender 
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];
	[openPanel setRequiredFileType:@"mtcdb"];
    NSString* startingDir;
	
	NSString* fullPath = [[model defaultFile] stringByExpandingTildeInPath];
    if(fullPath)	startingDir = [[model defaultFile] stringByDeletingLastPathComponent];
    else			startingDir = NSHomeDirectory();
	
    [openPanel beginSheetForDirectory:startingDir
                                 file:nil
                                types:[NSArray arrayWithObject:@"mtcdb"]
                       modalForWindow:[self window]
                        modalDelegate:self
                       didEndSelector:@selector(setDefaultFileDidEnd:returnCode:contextInfo:)
                          contextInfo:NULL];
}




- (IBAction) settingsDefaultSaveSet:(id) sender 
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:@"Save As"];
    [savePanel setCanCreateDirectories:YES];
 	[savePanel setRequiredFileType:@"mtcdb"];
   
    NSString* startingDir;
    NSString* defaultFile;
    
	NSString* fullPath = [[model lastFile] stringByExpandingTildeInPath];
    if(fullPath){
        startingDir = [fullPath stringByDeletingLastPathComponent];
        defaultFile = [fullPath lastPathComponent];
    }
    else {
        startingDir = NSHomeDirectory();
        defaultFile = @"MtcDataBase";
    }
    [savePanel beginSheetForDirectory:startingDir
                                 file:[defaultFile stringByExpandingTildeInPath]
                       modalForWindow:[self window]
                        modalDelegate:self
                       didEndSelector:@selector(saveDefaultSetDidEnd:returnCode:contextInfo:)
                          contextInfo:NULL];
	
}

@end

#pragma mark •••PrivateInterface
@implementation ORMTCController (private)
- (void) setXilinxFileDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        [model setXilinxFilePath:[[sheet filenames] objectAtIndex:0]];
		NSLog(@"MTC Xilinx default file set to: %@\n",[[[[sheet filenames] objectAtIndex:0] stringByAbbreviatingWithTildeInPath] stringByDeletingPathExtension]);
    }
}
- (void) setDefaultFileDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        [model setDefaultFile:[[sheet filenames] objectAtIndex:0]];
		NSLog(@"MTC DataBase default file set to: %@\n",[[[[sheet filenames] objectAtIndex:0] stringByAbbreviatingWithTildeInPath] stringByDeletingPathExtension]);
    }
}

- (void) saveDefaultSetDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        [model saveSet:[[sheet filenames] objectAtIndex:0]];
		NSLog(@"MTC DataBase saved into: %@\n",[[[[sheet filenames] objectAtIndex:0] stringByAbbreviatingWithTildeInPath] stringByDeletingPathExtension]);
    }
}

- (void) selectAndLoadDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        [model loadSet:[[sheet filenames] objectAtIndex:0]];
		NSLog(@"MTC DataBase loaded from: %@\n",[[[[sheet filenames] objectAtIndex:0] stringByAbbreviatingWithTildeInPath] stringByDeletingPathExtension]);
    }
}


- (void) loadDBFileDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        [model loadSet:[[sheet filenames] objectAtIndex:0]];
		NSLog(@"MTC DataBase loaded from: %@\n",[[[[sheet filenames] objectAtIndex:0] stringByAbbreviatingWithTildeInPath] stringByDeletingPathExtension]);
    }
}

- (void) setMaskTags:(NSMatrix*)aMaskSet
{
	//note... works only for the vertical mask matrices
	int n = [aMaskSet numberOfRows];
	int i;
	for(i=0;i<n;i++)[[aMaskSet cellAtRow:i column:0] setTag:i];
}

- (void) selectAndLoadDBFile:(NSString*)aStartPath
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];
 	[openPanel setRequiredFileType:@"mtcdb"];
	NSString* startingDir;
	
	NSString* fullPath = [aStartPath stringByExpandingTildeInPath];
    if(fullPath)	startingDir = [fullPath stringByDeletingLastPathComponent];
    else			startingDir = NSHomeDirectory();
    [openPanel beginSheetForDirectory:startingDir
                                 file:nil
                                types:[NSArray arrayWithObject:@"mtcdb"]
                       modalForWindow:[self window]
                        modalDelegate:self
                       didEndSelector:@selector(selectAndLoadDidEnd:returnCode:contextInfo:)
                          contextInfo:NULL];
}

- (void) setupNHitFormats
{
	NSNumberFormatter *thresholdFormatter = [[[NSNumberFormatter alloc] init] autorelease];;
	
	if([model nHitViewType] == kNHitsViewRaw) [thresholdFormatter setFormat:@"##0"];
	else [thresholdFormatter setFormat:@"##0.0"];
	
	NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
	[numberFormatter setFormat:@"##0.0;0;-##0.0"];
	
	int row,col;
	for(col=0;col<4;col++){
		for(row=0;row<6;row++){
			NSCell* theCell = [nhitMatrix cellAtRow:row column:col];
			if(col==0)	[theCell setFormatter:thresholdFormatter];
			else		[theCell setFormatter:numberFormatter];
		}
	}
	[nhitMatrix setNeedsDisplay:YES];
}

- (void) setupESumFormats
{
	NSNumberFormatter *thresholdFormatter = [[[NSNumberFormatter alloc] init] autorelease];;
	
	if([model eSumViewType] == kESumViewRaw) [thresholdFormatter setFormat:@"##0"];
	else [thresholdFormatter setFormat:@"##0.0"];
	
	NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
	[numberFormatter setFormat:@"##0.0;0;-##0.0"];
	
	int row,col;
	for(col=0;col<4;col++){
		for(row=0;row<4;row++){
			NSCell* theCell = [esumMatrix cellAtRow:row column:col];
			if(col==0)	[theCell setFormatter:thresholdFormatter];
			else		[theCell setFormatter:numberFormatter];
		}
	}
	[esumMatrix setNeedsDisplay:YES];
}

- (void) storeUserNHitValue:(float)userValue index:(int) thresholdIndex
{
	//user changed the NHit threshold -- convert from the displayed value to the raw value and store
	float numberToStore=0;
	int viewType = [model nHitViewType];
	if((thresholdIndex >= kNHit100HiThreshold) && (thresholdIndex <= kOWLNThreshold)){
		if(viewType == kNHitsViewRaw) {
			numberToStore = userValue;
		}
		else if(viewType == kNHitsViewmVolts) {
			numberToStore = [model mVoltsToRaw:userValue];
		}
		else if(viewType == kNHitsViewNHits) {
			float dcOffset  = [model dbFloatByIndex:thresholdIndex + kNHitDcOffset_Offset];
			float mVperNHit = [model dbFloatByIndex:thresholdIndex + kmVoltPerNHit_Offset];
			numberToStore = [model NHitsToRaw:userValue dcOffset:dcOffset mVperNHit:mVperNHit];
		}
		[model setDbFloat:numberToStore forIndex:thresholdIndex];	
	}
}

- (void) calcNHitValueForRow:(int) aRow
{
	float numberToStore;
	int index = kNHit100HiThreshold + aRow;
	if((index >= kNHit100HiThreshold) && (index <= kOWLNThreshold)){
		float mVolts    = [model rawTomVolts:[model dbFloatByIndex:index]];
		float dcOffset  = [model dbFloatByIndex:index + kNHitDcOffset_Offset];
		float mVperNHit = [model dbFloatByIndex:index + kmVoltPerNHit_Offset];
		float newNHits  = [model mVoltsToNHits:mVolts dcOffset:dcOffset mVperNHit:mVperNHit];
		float newMilliVolts = [model NHitsTomVolts:newNHits dcOffset:dcOffset mVperNHit:mVperNHit];
		numberToStore = [model mVoltsToRaw:newMilliVolts];
		
		[model setDbFloat:numberToStore forIndex:index];	
	}
}

- (void) storeUserESumValue:(float)userValue index:(int) thresholdIndex
{
	//user changed the ESum threshold -- convert from the displayed value to the raw value and store
	float numberToStore=0;
	int viewType = [model eSumViewType];
	if((thresholdIndex >= kESumLowThreshold) && (thresholdIndex <= kOWLEHiThreshold)){
		if(viewType == kESumViewRaw) {
			numberToStore = userValue;
		}
		else if(viewType == kESumViewmVolts) {
			numberToStore = [model mVoltsToRaw:userValue];
		}
		else if(viewType == kESumVieweSumRel) {
			float dcOffset  = [model dbFloatByIndex:thresholdIndex + kESumDcOffset_Offset];
			numberToStore = [model mVoltsToRaw:dcOffset - userValue];
		}
		else if(viewType == kESumViewpC) {
			float dcOffset  = [model dbFloatByIndex:thresholdIndex + kESumDcOffset_Offset];
			float mVperpC	= [model dbFloatByIndex:thresholdIndex + kmVoltPerpC_Offset];
			numberToStore   = [model pCToRaw:userValue dcOffset:dcOffset mVperpC:mVperpC];
		}
		[model setDbFloat:numberToStore forIndex:thresholdIndex];	
	}
	
}

- (void) calcESumValueForRow:(int) aRow
{
	float numberToStore;
	int index = kESumLowThreshold + aRow;
	if((index >= kESumLowThreshold) && (index <= kOWLEHiThreshold)){
		float mVolts    = [model rawTomVolts:[model dbFloatByIndex:index]];
		float dcOffset  = [model dbFloatByIndex:index + kESumDcOffset_Offset];
		float mVperpC   = [model dbFloatByIndex:index + kmVoltPerpC_Offset];
		
		float newpC		= [model mVoltsTopC:mVolts dcOffset:dcOffset mVperpC:mVperpC];
		float newMilliVolts = [model pCTomVolts:newpC dcOffset:dcOffset mVperpC:mVperpC];
		numberToStore = [model mVoltsToRaw:newMilliVolts];
		
		[model setDbFloat:numberToStore forIndex:index];	
	}
}

@end

