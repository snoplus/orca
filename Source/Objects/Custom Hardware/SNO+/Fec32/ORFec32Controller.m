//
//  ORFec32Controller.m
//  Orca
//
//  Created by Mark Howe on Wed Oct 15,2008.
//  Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
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


#pragma mark •••Imported Files
#import "ORFec32Controller.h"
#import "ORFec32Model.h"
#import "ORFecPmtsView.h"
#import "ORPmtImage.h"
#import "ORSwitchImage.h"
#import "ORFecDaughterCardModel.h";
#import "Sno_Monitor_Adcs.h"
#import "OROrderedObjManager.h"
#import "ORSNOConstants.h"
#import "ORSNOCableDB.h"

@implementation ORFec32Controller

#pragma mark •••Initialization
- (id) init
{
    self = [super initWithWindowNibName:@"Fec32"];
    return self;
}

- (void) dealloc
{
	[cmosFormatter release];
	[super dealloc];
}

- (void) awakeFromNib
{
    [groupView setGroup:model];
	cmosFormatter = [[NSNumberFormatter alloc] init];
	int i;
	for(i=0;i<6;i++){
		[[cmosMatrix cellWithTag:i] setFormatter:cmosFormatter];
	}
	//cache these into arrays for easy access later
	onlineSwitches[0] = onlineSwitches0;
	onlineSwitches[1] = onlineSwitches1;
	onlineSwitches[2] = onlineSwitches2;
	onlineSwitches[3] = onlineSwitches3;
	pmtImages[0] = pmtImages0;
	pmtImages[1] = pmtImages1;
	pmtImages[2] = pmtImages2;
	pmtImages[3] = pmtImages3;
	
	//set up the switch images and the pmt images
	for(i=0;i<8;i++){
		[[onlineSwitches0 cellAtRow:0 column:i] setTag:7-i];
		[[onlineSwitches1 cellAtRow:i column:0] setTag:15-i];
		[[onlineSwitches2 cellAtRow:i column:0] setTag:23-i];
		[[onlineSwitches3 cellAtRow:0 column:i] setTag:24+i];
	}
	
	for(i=0;i<kNumFecMonitorAdcs;i++){
		[[adcLabelsMatrix cellAtRow:i column:0] setStringValue:[NSString stringWithCString:fecVoltageAdc[i].label encoding:NSASCIIStringEncoding]];
		[[adcUnitsMatrix cellAtRow:i column:0] setStringValue:[NSString stringWithCString:fecVoltageAdc[i].units encoding:NSASCIIStringEncoding]];
		
	}
	for(i=0;i<16;i++){
		[[thresholds0LabelsMatrix cellAtRow:i column:0] setIntValue:i];
		[[thresholds0LabelsMatrix cellAtRow:i column:0] setTextColor:[NSColor grayColor]];
		[[thresholds1LabelsMatrix cellAtRow:i column:0] setIntValue:i+16];
		[[thresholds1LabelsMatrix cellAtRow:i column:0] setTextColor:[NSColor grayColor]];
		[[thresholds0Matrix cellAtRow:i column:0] setAlignment:NSRightTextAlignment];
		[[thresholds1Matrix cellAtRow:i column:0] setAlignment:NSRightTextAlignment];
		
		
		[[vb0LabelsMatrix cellAtRow:i column:0] setIntValue:i];
		[[vb0LabelsMatrix cellAtRow:i column:0] setTextColor:[NSColor grayColor]];
		[[vb1LabelsMatrix cellAtRow:i column:0] setIntValue:i+16];
		[[vb1LabelsMatrix cellAtRow:i column:0] setTextColor:[NSColor grayColor]];
		[[vb0HMatrix cellAtRow:i column:0] setAlignment:NSRightTextAlignment];
		[[vb0LMatrix cellAtRow:i column:0] setAlignment:NSRightTextAlignment];
		[[vb1HMatrix cellAtRow:i column:0] setAlignment:NSRightTextAlignment];
		[[vb1LMatrix cellAtRow:i column:0] setAlignment:NSRightTextAlignment];
	}
	
	[super awakeFromNib];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupObjectsAdded
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupObjectsRemoved
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupSelectionChanged
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : OROrcaObjectMoved
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(runStatusChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(updateWindow)
                         name : ORSNOCardSlotChanged
                       object : nil];
	
	[notifyCenter addObserver : self
                     selector : @selector(hvRefChanged:)
                         name : ORFecHVRefChanged
                       object : model];
	
	[notifyCenter addObserver : self
                     selector : @selector(cmosChanged:)
                         name : ORFecCmosChanged
                       object : model];
	
	[notifyCenter addObserver : self
                     selector : @selector(vResChanged:)
                         name : ORFecVResChanged
                       object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORFecLock
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(commentsChanged:)
                         name : ORFecCommentsChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(showVoltsChanged:)
                         name : ORFecShowVoltsChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(onlineMaskChanged:)
                         name : ORFecOnlineMaskChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(boardIdChanged:)
                         name : ORSNOCardBoardIDChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(adcStatusChanged:)
                         name : ORFec32ModelAdcVoltageChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(adcStatusChanged:)
                         name : ORFec32ModelAdcVoltageStatusChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(variableDisplayChanged:)
                         name : ORFec32ModelVariableDisplayChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(dcThresholdsChanged:)
                         name : ORDCModelVtChanged
						object: nil];
	
	[notifyCenter addObserver : self
                     selector : @selector(dcVBsChanged:)
                         name : ORDCModelVbChanged
						object: nil];

	[notifyCenter addObserver : self
                     selector : @selector(updatePMTInfo:)
                         name : ORSNOCableDBReadIn
						object: nil];
	

}

- (void) updateWindow
{
	[super updateWindow];
	[self onlineMaskChanged:nil];
	[self showVoltsChanged:nil];
    [self runStatusChanged:nil];
    [self lockChanged:nil];
    [self slotChanged:nil];
	[self vResChanged:nil];
	[self hvRefChanged:nil];
	[self cmosChanged:nil];
	[self boardIdChanged:nil];
    [groupView setNeedsDisplay:YES];
	[self commentsChanged:nil];
	[pmtView setNeedsDisplay:YES];
	[self  adcStatusChanged:nil];
	[self variableDisplayChanged:nil];
	[self dcThresholdsChanged:nil];
	[self dcVBsChanged:nil];
	[self updatePMTInfo:nil];
}

#pragma mark •••Accessors
- (ORGroupView *)groupView
{
    return [self groupView];
}

- (void) setModel:(OrcaObject*)aModel
{
    [super setModel:aModel];
    [groupView setGroup:(ORGroup*)model];
	[fecNumberField setIntValue:[model stationNumber]];
	[crateNumberField setIntValue:[[model guardian] crateNumber]];
	[pmtView setNeedsDisplay:YES];
	[self adcStatusChanged:nil];
	[self dcThresholdsChanged:nil];
	[self dcVBsChanged:nil];
 	[self updateButtons];
}

#pragma mark •••Interface Management
- (void) updatePMTInfo:(NSNotification*)aNote
{
	int crate = [model crateNumber];
	int card  = [model stationNumber];
	int i;
	ORPmtImages* pmtImageCatalog = [ORPmtImages sharedPmtImages];
	for(i=0;i<kNumSNOPmts;i++){
		NSString* label;
		if([model dcPresent:i/8])label = [[ORSNOCableDB sharedSNOCableDB] pmtID:crate card:card channel:i];
		else label = @"---";
		NSColor* tubeColor = [[ORSNOCableDB sharedSNOCableDB] pmtColor:crate card:card channel:i];
		if(i>=0 && i<8)	{
			[[dc0Labels cellAtRow:0 column:7-i] setObjectValue:label];
			[[pmtImages0 cellAtRow:0 column:7-i] setImage:[pmtImageCatalog pmtWithColor:tubeColor angle:180]];
		}
		else if(i>=8 && i<16)	{
			[[dc1Labels cellAtRow:15-i column:0] setObjectValue:label];
			[[pmtImages1 cellAtRow:15-i column:0] setImage:[pmtImageCatalog pmtWithColor:tubeColor angle:90]];
		}
		else if(i>=16 && i<24)	{
			[[dc2Labels cellAtRow:23-i column:0] setObjectValue:label];
			[[pmtImages2 cellAtRow:23-i column:0] setImage:[pmtImageCatalog pmtWithColor:tubeColor angle:90]];
		}
		else if(i>=24 && i<32)	{
			[[dc3Labels cellAtRow:0 column:i-24] setObjectValue:label];
			[[pmtImages3 cellAtRow:0 column:i-24] setImage:[pmtImageCatalog pmtWithColor:tubeColor angle:0]];
		}
	}	
}

- (void) dcThresholdsChanged:(NSNotification*)aNote
{
	int i;
	int displayRow = 0;
	for(i=0;i<kNumSNODaughterCards;i++){
		ORFecDaughterCardModel* dc = [[OROrderedObjManager for:model] objectInSlot:i];
		NSMatrix* matrix = i<2 ? thresholds0Matrix : thresholds1Matrix;
		int chan;
		for(chan=0;chan<8;chan++){
			id displayItem = [matrix cellAtRow:displayRow column:0];
			if(dc)[displayItem setObjectValue:[NSNumber numberWithInt:[dc vt:chan]]];
			else [displayItem setObjectValue:@"---"];
			displayRow++;
			if(displayRow>15)displayRow=0;
		}
	}
}

- (void) dcVBsChanged:(NSNotification*)aNote
{
	int set;
	for(set=0;set<2;set++){
		int displayRow = 0;
		int i;
		for(i=0;i<kNumSNODaughterCards;i++){
			ORFecDaughterCardModel* dc = [[OROrderedObjManager for:model] objectInSlot:i];
			NSMatrix* matrix;
			if(set == 0) matrix = i<2 ? vb0HMatrix : vb1HMatrix;
			else         matrix = i<2 ? vb0LMatrix : vb1LMatrix;
			int chan;
			for(chan=0;chan<8;chan++){
				id displayItem = [matrix cellAtRow:displayRow column:0];
				if(dc)[displayItem setObjectValue:[NSNumber numberWithInt:[dc vb:chan+(set*8)]]];
				else [displayItem setObjectValue:@"---"];
				displayRow++;
				if(displayRow>15)displayRow=0;
			}
		}
	}
}


- (void) variableDisplayChanged:(NSNotification*)aNote
{
	[variablesSelectionPU selectItemAtIndex: [model variableDisplay]];
	[variablesTabView selectTabViewItemAtIndex:[model variableDisplay]];
	[self updateButtons];
}

- (void) isNowKeyWindow:(NSNotification*)aNotification
{
	[[self window] makeFirstResponder:(NSResponder*)groupView];
}

- (void) enablePmtGroup:(short)enabled groupNumber:(short)group
{
	[onlineSwitches[group] setEnabled:enabled];
 	[self updateButtons];
}

- (void) adcStatusChanged:(NSNotification*)aNote
{
	int i;
	if(!aNote)for(i=0;i<kNumFecMonitorAdcs;i++)[self loadAdcStatus:i];
	else [self loadAdcStatus:[[[aNote userInfo] objectForKey:@"index"] intValue]];
}

- (void) loadAdcStatus:(int)i
{
	id theCell = [adcMatrix cellAtRow:i column:0];
	if([model adcVoltageStatus:i] != kFecMonitorInRange)[theCell setTextColor:[NSColor redColor]];
	else [theCell setTextColor:[NSColor blackColor]];
	NSString* s= @"---";
	if([model adcVoltageStatus:i] == kFecMonitorNeverMeasured)s = @"---";
	else if([model adcVoltageStatus:i] == kFecMonitorReadError)s = @"RdErr";
	else if([model adcVoltageStatus:i] == kFecMonitorReadError)s = @"RgErr";
	else s = [NSString stringWithFormat:@"%5.1f",[model adcVoltage:i]];
	[theCell setObjectValue:s];
	
}

- (void) onlineMaskChanged:(NSNotification*)aNote
{
	ORSwitchImages* switchCatalog = [ORSwitchImages sharedSwitchImages];
	float switchAngles[4] = {90,0,0,-90};
	int i;
	for(i=0;i<32;i++){
		int pmtGroup = i/8;
		int state = [model pmtOnline:i];
		[[onlineSwitches[pmtGroup] cellWithTag:i] setImage:[switchCatalog switchWithState:state angle:switchAngles[pmtGroup]]];
	}
}

- (void) showVoltsChanged:(NSNotification*)aNote
{
	[showVoltsCB setIntValue: [model showVolts]];
	if([model showVolts]) [cmosFormatter setFormat:@"#0.00;0;-#0.00"];
	else [cmosFormatter setFormat:@"#0;0;-#0"];
	[self cmosChanged:aNote];
}

- (void) commentsChanged:(NSNotification*)aNote
{
	[commentsTextField setStringValue: [model comments]];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORFecLock to:secure];
    [lockButton setEnabled:secure];
 	[self updateButtons];
}

- (void) updateButtons
{
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORFecLock];
    BOOL locked = [gSecurity isLocked:ORFecLock];
	[vResField		setEnabled: !lockedOrRunningMaintenance];
	[hvRefField		setEnabled: !lockedOrRunningMaintenance];
	[cmosMatrix		setEnabled: !lockedOrRunningMaintenance];
	[autoInitButton setEnabled: !locked];
	int i;
	for(i=0;i<4;i++){
		[onlineSwitches[i] setEnabled:[model dcPresent:i] && !lockedOrRunningMaintenance];
		[pmtImages[i] setEnabled:[model dcPresent:i]];
	}
	[readVoltagesButton setEnabled:!lockedOrRunningMaintenance && ([model variableDisplay] == 0)];
}

- (void) lockChanged:(NSNotification*)aNotification
{
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL locked = [gSecurity isLocked:ORFecLock];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORFecLock];
    [lockButton setState: locked];	
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
		if(runInProgress && ![gSecurity isLocked:ORFecLock])s = @"Not in Maintenance Run.";
    }
    [lockDocField setStringValue:s];
}

- (void) slotChanged:(NSNotification*)aNotification
{
	[[self window] setTitle:[NSString stringWithFormat:@"Fec32 (%d,%d)",[[model guardian] crateNumber],[model stationNumber]]];
	[fecNumberField setIntValue:[model stationNumber]];
	[crateNumberField setIntValue:[[model guardian] crateNumber]];
	[pmtView setNeedsDisplay:YES];
}

- (void) runStatusChanged:(NSNotification*)aNotification
{
	// int status = [[[aNotification userInfo] objectForKey:ORRunStatusValue] intValue];
}

-(void) groupChanged:(NSNotification*)note
{
	[self updateWindow];
	[pmtView setNeedsDisplay:YES];
}

- (void) vResChanged:(NSNotification*)aNote
{
	[vResField setIntValue:[model vRes]];
}

- (void) hvRefChanged:(NSNotification*)aNote
{
	[hvRefField setIntValue:[model hVRef]];
}

- (void) boardIdChanged:(NSNotification*)aNote
{
	[boardIdField setStringValue:[model boardID]];
}

- (void) cmosChanged:(NSNotification*)aNote
{
	int index;
	for(index=0;index<6;index++){
		if([model showVolts]){
			[[cmosMatrix cellWithTag:index] setFloatValue:[model cmosVoltage:index]];
		}
		else {
			[[cmosMatrix cellWithTag:index] setIntValue:[model cmos:index]];
		}
	}
}

#pragma mark •••Actions

- (IBAction) variableDisplayPUAction:(id)sender
{
	[model setVariableDisplay:[sender indexOfSelectedItem]];
}

- (IBAction) onlineMaskAction:(id)sender
{
	int tag = [[sender selectedCell] tag];
	unsigned long mask = [model onlineMask];
	mask ^= (1L<<tag);
	[model setOnlineMask:mask];
}

- (IBAction) autoInitAction:(id)sender
{
	@try {
		[model autoInit];
	}
	@catch (NSException* localException) {
		NSBeginAlertSheet(@"Fec32 AutoInit Failed",@"OK",nil,nil,[self window],self,nil,nil,nil, @"%@",localException);	
		NSLog(@"AutoInit of Fec32 (%d,%d) failed.\n",[model crateNumber],[model stationNumber]);
	}
}

- (IBAction) readVoltagesAction:(id)sender
{
	switch([model variableDisplay]){
		case 0:
			@try {
				[model readVoltages];
			}
			@catch (NSException* localException) {
				NSBeginAlertSheet(@"Fec32 Voltage Read Failed",@"OK",nil,nil,[self window],self,nil,nil,nil, @"%@",localException);			
				NSLog(@"Read Voltages of Fec32 (%d,%d) failed.\n",[model crateNumber],[model stationNumber]);
			}
		break;
	}
}

- (IBAction) showVoltsAction:(id)sender
{
	[model setShowVolts:[sender intValue]];	
}

- (IBAction) initAction:(id)sender;
{
	@try {
		[model scan:nil];
	}
	@catch(NSException* localException) {
		NSLog(@"Scan of Fec32 FAILED.\n");
		NSBeginAlertSheet(@"Fec32 Scan Failed",@"OK",nil,nil,[self window],self,nil,nil,nil, @"%@",localException);			
	}
}

- (IBAction) probeAction:(id)sender
{
	@try {
		[model readBoardIds];
	}
	@catch(NSException* localException) {
        NSLog(@"Probe of Fec32 FAILED.\n");
		NSBeginAlertSheet(@"Fec32 Probe Failed",@"OK",nil,nil,[self window],self,nil,nil,nil, @"%@",localException);			
	}
}

- (IBAction) commentsTextFieldAction:(id)sender
{
	[model setComments:[sender stringValue]];	
}

- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORFecLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) vResAction:(id)sender
{
	[model setVRes:[sender intValue]];
}

- (IBAction) hvRefAction:(id)sender
{
	[model setHVRef:[sender intValue]];
}

- (IBAction) cmosAction:(id)sender
{
	int i = [[cmosMatrix selectedCell] tag];
	if([model showVolts]){
		[model setCmosVoltage:i withValue:[sender floatValue]];
	}
	else {
		[model setCmos:i withValue:[sender intValue]];
	}
}

- (IBAction) incCardAction:(id)sender
{
	[self incModelSortedBy:@selector(globalCardNumberCompare:)];
}

- (IBAction) decCardAction:(id)sender
{
	[self decModelSortedBy:@selector(globalCardNumberCompare:)];
}


@end
