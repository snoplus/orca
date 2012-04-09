
//
//  MJDPreAmpController.m
//  Orca
//
//  Created by Mark Howe on Wed Jan 18 2012.
//  Copyright � 2012 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark ⅴ쩒mported Files
#import "ORMJDPreAmpController.h"
#import "ORMJDPreAmpModel.h"

@implementation ORMJDPreAmpController

- (id) init
{
    self = [super initWithWindowNibName:@"MJDPreAmp"];
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (void) awakeFromNib
{
    [super  awakeFromNib];
	short chan;
	NSNumberFormatter* aFormat = [[[NSNumberFormatter alloc] init] autorelease];
	[aFormat setFormat:@"##0.00"];

	for(chan=0;chan<kMJDPreAmpDacChannels;chan++){
		[[dacsMatrix cellAtRow:chan column:0] setTag:chan];
		[[dacsMatrix cellAtRow:chan column:0] setFormatter:aFormat];
		[[amplitudesMatrix cellAtRow:chan column:0] setTag:chan];
		[[pulserMaskMatrix cellAtRow:chan column:0] setTag:chan];
		[[adcMatrix cellAtRow:chan column:0] setTag:chan];
		[[adcMatrix cellAtRow:chan column:0] setFormatter:aFormat];
	}
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"PreAmp %d",[model uniqueIdNumber]]];
    [self settingsLockChanged:nil];
}

#pragma mark ⅴ쩘otifications
- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
     
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : MJDPreAmpSettingsLock
                        object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(dacArrayChanged:)
                         name : ORMJDPreAmpDacArrayChanged
						object: model];

    [notifyCenter addObserver : self
					 selector : @selector(dacChanged:)
						 name : ORMJDPreAmpDacChanged
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pulseLowTimeChanged:)
                         name : ORMJDPreAmpPulseLowTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(pulseHighTimeChanged:)
                         name : ORMJDPreAmpPulseHighTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(pulserMaskChanged:)
                         name : ORMJDPreAmpPulserMaskChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(attenuatedChanged:)
                         name : ORMJDPreAmpAttenuatedChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(finalAttenuatedChanged:)
                         name : ORMJDPreAmpFinalAttenuatedChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(enabledChanged:)
                         name : ORMJDPreAmpEnabledChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(adcRangeChanged:)
                         name : ORMJDPreAmpAdcRangeChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(amplitudeArrayChanged:)
                         name : ORMJDPreAmpAmplitudeArrayChanged
						object: model];
	
    [notifyCenter addObserver : self
					 selector : @selector(amplitudeChanged:)
						 name : ORMJDPreAmpAmplitudeChanged
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pulseCountChanged:)
                         name : ORMJDPreAmpPulseCountChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(loopForeverChanged:)
                         name : ORMJDPreAmpLoopForeverChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(adcChanged:)
                         name : ORMJDPreAmpAdcChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(adcArrayChanged:)
                         name : ORMJDPreAmpAdcArrayChanged
						object: model];
	
}

- (void) updateWindow
{
    [super updateWindow];
    [self settingsLockChanged:nil];
	[self dacArrayChanged:nil];
	[self dacChanged:nil];
	[self amplitudeArrayChanged:nil];
	[self pulseLowTimeChanged:nil];
	[self pulseHighTimeChanged:nil];
	[self pulserMaskChanged:nil];
	[self attenuatedChanged:nil];
	[self finalAttenuatedChanged:nil];
	[self enabledChanged:nil];
	[self adcRangeChanged:nil];
	[self pulseCountChanged:nil];
	[self loopForeverChanged:nil];
	[self adcArrayChanged:nil];
}

#pragma mark ⅴ쩒nterface Management
- (void) adcRangeChanged:(NSNotification*)aNote
{
	[adcRange0PU selectItemAtIndex: [model adcRange:0]];
	[adcRange1PU selectItemAtIndex: [model adcRange:1]];
}

- (void) adcArrayChanged:(NSNotification*)aNote
{
	short chan;
	for(chan=0;chan<kMJDPreAmpDacChannels;chan++){
		[[adcMatrix cellWithTag:chan] setFloatValue: [model adc:chan]]; 
	}
}

- (void) adcChanged:(NSNotification*)aNote
{
	int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
	[[adcMatrix cellWithTag:chan] setFloatValue: [model adc:chan]];
}

- (void) loopForeverChanged:(NSNotification*)aNote
{
	[loopForeverPU selectItemAtIndex: ![model loopForever]];
	[self updateButtons];
}

- (void) pulseCountChanged:(NSNotification*)aNote
{
	[pulseCountField setIntValue: [model pulseCount]];
}

- (void) enabledChanged:(NSNotification*)aNote
{
	[enabled0PU selectItemAtIndex: [model enabled:0]];
	[enabled1PU selectItemAtIndex: [model enabled:1]];
}

- (void) attenuatedChanged:(NSNotification*)aNote
{
	[attenuated0PU selectItemAtIndex: [model attenuated:0]];
	[attenuated1PU selectItemAtIndex: [model attenuated:1]];
}

- (void) finalAttenuatedChanged:(NSNotification*)aNote
{
	[finalAttenuated0PU selectItemAtIndex: [model finalAttenuated:0]];
	[finalAttenuated1PU selectItemAtIndex: [model finalAttenuated:1]];
}

- (void) pulserMaskChanged:(NSNotification*)aNote
{
	unsigned short aMask = [model pulserMask];
	int i;
	for(i=0;i<16;i++){
		BOOL bitSet = (aMask&(1<<i))>0;
		if(bitSet != [[pulserMaskMatrix cellWithTag:i] intValue]){
			[[pulserMaskMatrix cellWithTag:i] setState:bitSet];
		}
	}
}

- (void) pulseHighTimeChanged:(NSNotification*)aNote
{
	[pulseHighTimeField setFloatValue: [model pulseHighTime]*2]; //convert to 탎econds
	[self displayFrequency];
}

- (void) pulseLowTimeChanged:(NSNotification*)aNote
{
	[pulseLowTimeField setFloatValue: [model pulseLowTime]*2]; //convert to 탎econds
	[self displayFrequency];
}

- (void) displayFrequency
{
	[frequencyField setFloatValue: 1/ (([model pulseLowTime] + [model pulseHighTime]) * 2.0E-6)];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:MJDPreAmpSettingsLock to:secure];
    [settingsLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification *)notification
{    
    BOOL locked = [gSecurity isLocked:MJDPreAmpSettingsLock];
    [settingsLockButton setState:locked];
	[self updateButtons];
}

- (void) updateButtons
{
    //BOOL locked = [gSecurity isLocked:MJDPreAmpSettingsLock];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:MJDPreAmpSettingsLock];
	[loopForeverPU		setEnabled:!lockedOrRunningMaintenance];
	[pulseCountField	setEnabled:!lockedOrRunningMaintenance && ![model loopForever]];
	[enabled0PU			setEnabled:!lockedOrRunningMaintenance];
	[enabled1PU			setEnabled:!lockedOrRunningMaintenance];
	[finalAttenuated0PU setEnabled:!lockedOrRunningMaintenance];
	[finalAttenuated1PU setEnabled:!lockedOrRunningMaintenance];
	[pulseHighTimeField setEnabled:!lockedOrRunningMaintenance];
	[pulseLowTimeField	setEnabled:!lockedOrRunningMaintenance];
	[dacsMatrix			setEnabled:!lockedOrRunningMaintenance];
	[amplitudesMatrix	setEnabled:!lockedOrRunningMaintenance];
	[pulserMaskMatrix	setEnabled:!lockedOrRunningMaintenance];	
	[startPulserButton	setEnabled:!lockedOrRunningMaintenance];	
	[stopPulserButton	setEnabled:!lockedOrRunningMaintenance];	
}


- (void) dacChanged:(NSNotification*)aNotification
{
	int chan = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
	[[dacsMatrix cellWithTag:chan] setFloatValue: [model dac:chan]*4.1/65535.];		//convert to volts
}

- (void) amplitudeChanged:(NSNotification*)aNotification
{
	int chan = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
	[[amplitudesMatrix cellWithTag:chan] setIntValue: [model amplitude:chan]];		//convert to volts
}

- (void) dacArrayChanged:(NSNotification*)aNotification
{
	short chan;
	for(chan=0;chan<kMJDPreAmpDacChannels;chan++){
		[[dacsMatrix cellWithTag:chan] setFloatValue: [model dac:chan]*4.1/65535.]; //convert to volts
	}
}
- (void) amplitudeArrayChanged:(NSNotification*)aNotification
{
	short chan;
	for(chan=0;chan<kMJDPreAmpDacChannels;chan++){
		[[amplitudesMatrix cellWithTag:chan] setIntValue: [model amplitude:chan]]; //convert to volts
	}
}


#pragma mark ⅴ쩇ctions
- (void) loopForeverAction:(id)sender
{
	[model setLoopForever:![sender indexOfSelectedItem]];	
}

- (void) pulseCountAction:(id)sender
{
	[model setPulseCount:[sender intValue]];	
}

- (IBAction) enabledAction:(id)sender
{
	int index = [sender tag];
	[model setEnabled:index value:[sender indexOfSelectedItem]];	
}

- (IBAction) attenuatedAction:(id)sender
{
	int index = [sender tag];
	[model setAttenuated:index value:[sender indexOfSelectedItem]];	
}

- (IBAction) finalAttenuatedAction:(id)sender
{
	int index = [sender tag];
	[model setFinalAttenuated:index value:[sender indexOfSelectedItem]];	
}

- (IBAction) pulserMaskAction:(id)sender
{
	unsigned short mask = 0;
	int i;
	for(i=0;i<16;i++){
		int theValue = [[pulserMaskMatrix cellWithTag:i] intValue];
		if(theValue) mask |= (0x1<<i);
	}
	[model setPulserMask:mask];	
}

- (IBAction) pulseHighTimeAction:(id)sender
{
	[model setPulseHighTime:[sender intValue]/2]; //convert from 탎econds to hw value
}

- (IBAction) pulseLowTimeAction:(id)sender
{
	[model setPulseLowTime:[sender intValue]/2];	 //convert from 탎econds to hw value
}

- (IBAction) dacsAction:(id)sender
{
	[model setDac:[[sender selectedCell] tag] withValue:[sender floatValue]*65535./4.1]; //convert from volts to hw value
}

- (IBAction) amplitudesAction:(id)sender
{
	[model setAmplitude:[[sender selectedCell] tag] withValue:[sender intValue]]; 
}

- (IBAction) settingsLockAction:(id)sender
{
    [gSecurity tryToSetLock:MJDPreAmpSettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) writeFetVdsAction:(id)sender
{
	[model writeFetVdsToHW];
}

- (IBAction) startPulserAction:(id)sender
{
	[model startPulser];
}

- (IBAction) stopPulserAction:(id)sender
{
	[model stopPulser];
}

- (IBAction) adcRangeAction:(id)sender
{
	[model setAdcRange:[sender tag] value:[sender indexOfSelectedItem]]; 
}

- (IBAction) readAdcs:(id)sender
{
	[model readAdcs]; 
}


@end
