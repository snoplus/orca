/*
 *  ORCMC203ModelController.cpp
 *  Orca
 *
 *  Created by Mark Howe on Sat Nov 16 2002.
 *  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
 *
 */


#pragma mark ¥¥¥Imported Files
#import "ORCMC203Controller.h"
#import "StatusLog.h"
#import "ORDefaults.h"
#import "ORGlobal.h"
#import "ORCamacExceptions.h"
#import "ORCamacExceptions.h"

#pragma mark ¥¥¥Macros


// methods
@implementation ORCMC203Controller

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"CMC203"];

    return self;
}


#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    [notifyCenter addObserver : self
                     selector : @selector(slotChanged:)
                         name : ORCamacCardSlotChangedNotification
                       object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(settingsLockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(settingsLockChanged:)
						 name : ORCMC203SettingsLock
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(controlRegChanged:)
                         name : ORCMC203ModelControlRegChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(reqDelayChanged:)
                         name : ORCMC203ModelReqDelayChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(dacValueChanged:)
                         name : ORCMC203ModelDacValueChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(testGateWidthChanged:)
                         name : ORCMC203ModelTestGateWidthChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(feraClrWidthChanged:)
                         name : ORCMC203ModelFeraClrWidthChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(histogramControlChanged:)
                         name : ORCMC203ModelHistogramControlChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(multiHistogramChanged:)
                         name : ORCMC203ModelMultiHistogramChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(gateTimeOutChanged:)
                         name : ORCMC203ModelGateTimeOutChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(busyEndDelayChanged:)
                         name : ORCMC203ModelBusyEndDelayChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(vsnChanged:)
                         name : ORCMC203ModelVsnChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(ledAssigmentChanged:)
                         name : ORCMC203ModelLedAssigmentChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(outputSelectionChanged:)
                         name : ORCMC203ModelOutputSelectionChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(eventTimeoutChanged:)
                         name : ORCMC203ModelEventTimeoutChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(extRenInputSigSelChanged:)
                         name : ORCMC203ModelExtRenInputSigSelChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(pingPongChanged:)
                         name : ORCMC203ModelPingPongChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(histoBlockSizeChanged:)
                         name : ORCMC203ModelHistoBlockSizeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(histogramMaskChanged:)
                         name : ORCMC203ModelHistogramMaskChanged
						object: model];

}

#pragma mark ¥¥¥Interface Management

- (void) histogramMaskChanged:(NSNotification*)aNote
{
	[histogramMaskTextField setIntValue: [model histogramMask]];
}


- (void) updateWindow
{
    [super updateWindow];
    [self slotChanged:nil];
    [self settingsLockChanged:nil];
	[self controlRegChanged:nil];
	[self reqDelayChanged:nil];
	[self dacValueChanged:nil];
	[self testGateWidthChanged:nil];
	[self feraClrWidthChanged:nil];
	[self histogramControlChanged:nil];
	[self multiHistogramChanged:nil];
	[self gateTimeOutChanged:nil];
	[self busyEndDelayChanged:nil];
	[self vsnChanged:nil];
	[self ledAssigmentChanged:nil];
	[self outputSelectionChanged:nil];
	[self eventTimeoutChanged:nil];
	[self extRenInputSigSelChanged:nil];
	[self pingPongChanged:nil];
	[self histoBlockSizeChanged:nil];
	[self histogramMaskChanged:nil];
}

- (void) controlRegChanged:(NSNotification*)aNote
{
	unsigned short controlReg = [model controlReg];
	[controlRegOpModePopup selectItemAtIndex:controlReg & 0x7];
	int i;
	for(i=0;i<8;i++){
		[[controlRegMatrix cellWithTag:i] setState: controlReg & (0x8L<<i)];
	}
	
}



- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORCMC203SettingsLock to:secure];
    [settingLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{

    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORCMC203SettingsLock];
    BOOL locked = [gSecurity isLocked:ORCMC203SettingsLock];

    [settingLockButton setState: locked];
	[controlRegMatrix setEnabled:!runInProgress && !locked];
	[controlRegOpModePopup setEnabled:!runInProgress && !locked];

	[histoBlockSizeTextField setEnabled:!runInProgress && !locked];
	[multiHistogramTextField setEnabled:!runInProgress && !locked];
	[histogramControlPopup setEnabled:!runInProgress && !locked];
	[controlRegOpModePopup setEnabled:!runInProgress && !locked];
	[controlRegMatrix setEnabled:!runInProgress && !locked];
	
	[pingPongTextField setEnabled:lockedOrRunningMaintenance];
	[extRenInputSigSelPopup setEnabled:lockedOrRunningMaintenance];
	[eventTimeoutTextField setEnabled:lockedOrRunningMaintenance];
	[wsoOutputSelectionPopup setEnabled:lockedOrRunningMaintenance];
	[rqoOutputSelectionPopup setEnabled:lockedOrRunningMaintenance];
	[sOutputSelectionPopup setEnabled:lockedOrRunningMaintenance];
	[qOutputSelectionPopup setEnabled:lockedOrRunningMaintenance];
	[ledAssigmentPopup setEnabled:lockedOrRunningMaintenance];
	[vsnTextField setEnabled:lockedOrRunningMaintenance];
	[busyEndDelayTextField setEnabled:lockedOrRunningMaintenance];
	[gateTimeOutTextField setEnabled:lockedOrRunningMaintenance];
	[feraClrWidthTextField setEnabled:lockedOrRunningMaintenance];
	[testGateWidthTextField setEnabled:lockedOrRunningMaintenance];
	[dacValueTextField setEnabled:lockedOrRunningMaintenance];
	[reqDelayTextField setEnabled:lockedOrRunningMaintenance];

	[readButton setEnabled:lockedOrRunningMaintenance];
	[writeButton setEnabled:lockedOrRunningMaintenance];

}


- (void) slotChanged:(NSNotification*)aNotification
{
	[[self window] setTitle:[NSString stringWithFormat:@"CMC203 (Station %d)",[model stationNumber]]];
}

- (void) histoBlockSizeChanged:(NSNotification*)aNote
{
	[histoBlockSizeTextField setIntValue: [model histoBlockSize]];
}

- (void) pingPongChanged:(NSNotification*)aNote
{
	[pingPongTextField setIntValue: [model pingPong]];
}

- (void) extRenInputSigSelChanged:(NSNotification*)aNote
{
	unsigned short value = [model extRenInputSigSel];
	int i;
	for(i=0;i<7;i++){
		if((value>>i) & 0x1){
			[extRenInputSigSelPopup selectItemAtIndex: i];
			return;
		}
	}
	//if didn't return early above, set to default
	[extRenInputSigSelPopup selectItemAtIndex: 0];

}

- (void) eventTimeoutChanged:(NSNotification*)aNote
{
	[eventTimeoutTextField setIntValue: [model eventTimeout]];
}

- (void) outputSelectionChanged:(NSNotification*)aNote
{
	unsigned short outputSelection = [model outputSelection];
	
	[wsoOutputSelectionPopup selectItemAtIndex: (outputSelection>>0) & 0x7];
	[rqoOutputSelectionPopup selectItemAtIndex: (outputSelection>>3) & 0x7];
	[sOutputSelectionPopup   selectItemAtIndex: (outputSelection>>6) & 0x7];
	[qOutputSelectionPopup   selectItemAtIndex: (outputSelection>>9) & 0x7];
}

- (void) ledAssigmentChanged:(NSNotification*)aNote
{
	[ledAssigmentPopup selectItemAtIndex: [model ledAssigment]];
}

- (void) vsnChanged:(NSNotification*)aNote
{
	[vsnTextField setIntValue: [model vsn]];
}

- (void) busyEndDelayChanged:(NSNotification*)aNote
{
	[busyEndDelayTextField setIntValue: [model busyEndDelay]];
}

- (void) gateTimeOutChanged:(NSNotification*)aNote
{
	[gateTimeOutTextField setIntValue: [model gateTimeOut]];
}

- (void) multiHistogramChanged:(NSNotification*)aNote
{
	[multiHistogramTextField setIntValue: [model multiHistogram]];
}

- (void) histogramControlChanged:(NSNotification*)aNote
{
	[histogramControlPopup selectItemAtIndex: [model histogramControl]];
}

- (void) feraClrWidthChanged:(NSNotification*)aNote
{
	[feraClrWidthTextField setIntValue: [model feraClrWidth]];
}

- (void) testGateWidthChanged:(NSNotification*)aNote
{
	[testGateWidthTextField setIntValue: [model testGateWidth]];
}

- (void) dacValueChanged:(NSNotification*)aNote
{
	float rawValue = [model dacValue];
	float convertedValue = rawValue*10.2375/4095.;
	[dacValueTextField setFloatValue: convertedValue];
}

- (void) reqDelayChanged:(NSNotification*)aNote
{
	[reqDelayTextField setIntValue: [model reqDelay]];
}

#pragma mark ¥¥¥Actions

- (void) histogramMaskTextFieldAction:(id)sender
{
	[model setHistogramMask:[sender intValue]];	
}

- (void) histoBlockSizeTextFieldAction:(id)sender
{
	[model setHistoBlockSize:[sender intValue]];	
}
- (IBAction) pingPongTextFieldAction:(id)sender
{
	[model setPingPong:[sender intValue]];	
}

- (IBAction) extRenInputSigSelPopupAction:(id)sender
{
	[model setExtRenInputSigSel:(0x1<<[sender indexOfSelectedItem])];	
}

- (IBAction) eventTimeoutTextFieldAction:(id)sender
{
	[model setEventTimeout:[sender intValue]];	
}

- (IBAction) outputSelectionPopupAction:(id)sender
{
	unsigned short outputSelection = [model outputSelection];
	int theTag = [sender tag];
	int theValue = ([sender indexOfSelectedItem]&0x7);
	outputSelection &= ~(0x7 << (3*theTag));
	outputSelection |= (theValue<<(3*theTag));
	
	[model setOutputSelection:outputSelection];	
}

- (IBAction) ledAssigmentPopupAction:(id)sender
{
	[model setLedAssigment:[sender indexOfSelectedItem]];	
}

- (IBAction) vsnTextFieldAction:(id)sender
{
	[model setVsn:[sender intValue]];	
}

- (IBAction) busyEndDelayTextFieldAction:(id)sender
{
	[model setBusyEndDelay:[sender intValue]];	
}

- (IBAction) gateTimeOutTextFieldAction:(id)sender
{
	[model setGateTimeOut:[sender intValue]];	
}

- (IBAction) multiHistogramTextFieldAction:(id)sender
{
	[model setMultiHistogram:[sender intValue]];	
}

- (IBAction) histogramControlPopupAction:(id)sender
{
	[model setHistogramControl:[sender indexOfSelectedItem]];	
}

- (IBAction) feraClrWidthTextFieldAction:(id)sender
{
	[model setFeraClrWidth:[sender intValue]];	
}

- (IBAction) testGateWidthTextFieldAction:(id)sender
{
	[model setTestGateWidth:[sender intValue]];	
}

- (IBAction) dacValueTextFieldAction:(id)sender
{
	float convertedValue = [sender floatValue];
	unsigned short rawValue = convertedValue * 4095/10.2375;
	[model setDacValue:rawValue];	
}

- (IBAction) reqDelayTextFieldAction:(id)sender
{
	[model setReqDelay:[sender intValue]];	
}

- (IBAction) controlRegOpModePopupAction:(id)sender
{
	unsigned short controlReg = [model controlReg];
	controlReg &= ~0x7; //clr bits 0-2
	controlReg |= [sender indexOfSelectedItem];
	[model setControlReg:controlReg];	
}

- (IBAction) controlRegMatrixAction:(id)sender
{
	unsigned short controlReg = [model controlReg];
	
	if([sender intValue])	controlReg |=  (0x8L << [[sender selectedCell] tag]);
	else					controlReg &= ~(0x8L << [[sender selectedCell] tag]);
		
	[model setControlReg:controlReg];	
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORCMC203SettingsLock to:[sender intValue] forWindow:[self window]];
}


- (IBAction) writeButtonAction:(id)sender
{
    NS_DURING
        [model checkCratePower];
		[model loadHardware];
    NS_HANDLER
        [self showError:localException name:@"Load Hardware" fCode:0];
    NS_ENDHANDLER
}

- (IBAction) readButtonAction:(id)sender
{
    NS_DURING
        [model checkCratePower];
		[model readAndReport];
    NS_HANDLER
        [self showError:localException name:@"Read Hardware" fCode:0];
    NS_ENDHANDLER	
}

- (void) showError:(NSException*)anException name:(NSString*)name fCode:(int)i
{
    NSLog(@"Failed Cmd: %@ (F%d)\n",name,i);
    if([[anException name] isEqualToString: OExceptionNoCamacCratePower]) {
        [[model crate]  doNoPowerAlert:anException action:[NSString stringWithFormat:@"%@ (F%d)",name,i]];
    }
    else {
        NSRunAlertPanel([anException name], @"%@\n%@ (F%d)", @"OK", nil, nil,
                        [anException name],name,i);
    }
}
@end
