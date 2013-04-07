
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
#import "ORTimeLinePlot.h"
#import "ORCompositePlotView.h"
#import "ORTimeAxis.h"
#import "ORTimeRate.h"

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
		[[adcEnabledMaskMatrix cellAtRow:chan column:0] setTag:chan];
	}
    
    [[plotter0 yAxis] setRngLow:0.0 withHigh:300.];
	[[plotter0 yAxis] setRngLimitsLow:-300.0 withHigh:500 withMinRng:4];
    [[plotter1 yAxis] setRngLow:0.0 withHigh:300.];
	[[plotter1 yAxis] setRngLimitsLow:-300.0 withHigh:500 withMinRng:4];
    [[plotter2 yAxis] setRngLow:0.0 withHigh:300.];
	[[plotter2 yAxis] setRngLimitsLow:-300.0 withHigh:500 withMinRng:4];
    [[plotter3 yAxis] setRngLow:0.0 withHigh:300.];
	[[plotter3 yAxis] setRngLimitsLow:-300.0 withHigh:500 withMinRng:4];
   
    
    [[plotter0 xAxis] setRngLow:0.0 withHigh:10000];
	[[plotter0 xAxis] setRngLimitsLow:0.0 withHigh:200000. withMinRng:200];
    [[plotter1 xAxis] setRngLow:0.0 withHigh:10000];
	[[plotter1 xAxis] setRngLimitsLow:0.0 withHigh:200000. withMinRng:200];
    [[plotter2 xAxis] setRngLow:0.0 withHigh:10000];
	[[plotter2 xAxis] setRngLimitsLow:0.0 withHigh:200000. withMinRng:200];
    [[plotter3 xAxis] setRngLow:0.0 withHigh:10000];
	[[plotter3 xAxis] setRngLimitsLow:0.0 withHigh:200000. withMinRng:200];
	
	NSColor* color[4] = {
		[NSColor redColor],
		[NSColor greenColor],
		[NSColor blueColor],
		[NSColor brownColor],
	};
	int i;
	for(i=0;i<4;i++){
		ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:i andDataSource:self];
		[plotter0 addPlot: aPlot];
		[aPlot setLineColor:color[i]];
		[aPlot setName:[NSString stringWithFormat:@"Adc%d",i]];
		[(ORTimeAxis*)[plotter0 xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
		[aPlot release];
	}
	for(i=0;i<4;i++){
		ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:i+4 andDataSource:self];
		[plotter1 addPlot: aPlot];
		[aPlot setLineColor:color[i]];
		[aPlot setName:[NSString stringWithFormat:@"Adc%d",i+4]];
		[(ORTimeAxis*)[plotter1 xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
		[aPlot release];
	}
	for(i=0;i<4;i++){
		ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:i+8 andDataSource:self];
		[plotter2 addPlot: aPlot];
		[aPlot setLineColor:color[i]];
		[aPlot setName:[NSString stringWithFormat:@"Adc%d",i+8]];
		[(ORTimeAxis*)[plotter2 xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
		[aPlot release];
	}
	for(i=0;i<4;i++){
		ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:i+12 andDataSource:self];
		[plotter3 addPlot: aPlot];
		[aPlot setLineColor:color[i]];
		[aPlot setName:[NSString stringWithFormat:@"Adc%d",i+12]];
		[(ORTimeAxis*)[plotter3 xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
		[aPlot release];
	}
	
	[plotter0 setShowLegend:YES];
	[plotter1 setShowLegend:YES];
	[plotter2 setShowLegend:YES];
	[plotter3 setShowLegend:YES];
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"PreAmp %lu",[model uniqueIdNumber]]];
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
	
    [notifyCenter addObserver : self
                     selector : @selector(shipValuesChanged:)
                         name : ORMJDPreAmpModelShipValuesChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(pollTimeChanged:)
                         name : ORMJDPreAmpModelPollTimeChanged
                       object : model];
	

    [notifyCenter addObserver : self
                     selector : @selector(adcEnabledMaskChanged:)
                         name : ORMJDPreAmpModelAdcEnabledMaskChanged
						object: model];

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
					   object : nil];
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
	[self shipValuesChanged:nil];
	[self pollTimeChanged:nil];
	[self adcEnabledMaskChanged:nil];
	[self updateTimePlot:nil];
}

#pragma mark ⅴ쩒nterface Management
- (void) scaleAction:(NSNotification*)aNotification
{
	if(aNotification == nil || [aNotification object] == [plotter0 xAxis]){
		[model setMiscAttributes:[(ORAxis*)[plotter0 xAxis]attributes] forKey:@"XAttributes0"];
	};
	
	if(aNotification == nil || [aNotification object] == [plotter0 yAxis]){
		[model setMiscAttributes:[(ORAxis*)[plotter0 yAxis]attributes] forKey:@"YAttributes0"];
	};
    
	if(aNotification == nil || [aNotification object] == [plotter1 xAxis]){
		[model setMiscAttributes:[(ORAxis*)[plotter1 xAxis]attributes] forKey:@"XAttributes1"];
	};
	
	if(aNotification == nil || [aNotification object] == [plotter1 yAxis]){
		[model setMiscAttributes:[(ORAxis*)[plotter1 yAxis]attributes] forKey:@"YAttributes1"];
	};
    if(aNotification == nil || [aNotification object] == [plotter2 xAxis]){
		[model setMiscAttributes:[(ORAxis*)[plotter2 xAxis]attributes] forKey:@"XAttributes2"];
	};
	
	if(aNotification == nil || [aNotification object] == [plotter2 yAxis]){
		[model setMiscAttributes:[(ORAxis*)[plotter2 yAxis]attributes] forKey:@"YAttributes2"];
	};
    if(aNotification == nil || [aNotification object] == [plotter3 xAxis]){
		[model setMiscAttributes:[(ORAxis*)[plotter3 xAxis]attributes] forKey:@"XAttributes3"];
	};
	
	if(aNotification == nil || [aNotification object] == [plotter3 yAxis]){
		[model setMiscAttributes:[(ORAxis*)[plotter3 yAxis]attributes] forKey:@"YAttributes3"];
	};
}

- (void) miscAttributesChanged:(NSNotification*)aNote
{
    
	NSString*				key = [[aNote userInfo] objectForKey:ORMiscAttributeKey];
	NSMutableDictionary* attrib = [model miscAttributesForKey:key];
	
	if(aNote == nil || [key isEqualToString:@"XAttributes0"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"XAttributes0"];
		if(attrib){
			[(ORAxis*)[plotter0 xAxis] setAttributes:attrib];
			[plotter0 setNeedsDisplay:YES];
			[[plotter0 xAxis] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"YAttributes0"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"YAttributes0"];
		if(attrib){
			[(ORAxis*)[plotter0 yAxis] setAttributes:attrib];
			[plotter0 setNeedsDisplay:YES];
			[[plotter0 yAxis] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"XAttributes1"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"XAttributes1"];
		if(attrib){
			[(ORAxis*)[plotter1 xAxis] setAttributes:attrib];
			[plotter1 setNeedsDisplay:YES];
			[[plotter1 xAxis] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"YAttributes1"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"YAttributes1"];
		if(attrib){
			[(ORAxis*)[plotter1 yAxis] setAttributes:attrib];
			[plotter1 setNeedsDisplay:YES];
			[[plotter1 yAxis] setNeedsDisplay:YES];
		}
	}
    if(aNote == nil || [key isEqualToString:@"XAttributes2"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"XAttributes2"];
		if(attrib){
			[(ORAxis*)[plotter2 xAxis] setAttributes:attrib];
			[plotter2 setNeedsDisplay:YES];
			[[plotter2 xAxis] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"YAttributes2"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"YAttributes2"];
		if(attrib){
			[(ORAxis*)[plotter2 yAxis] setAttributes:attrib];
			[plotter2 setNeedsDisplay:YES];
			[[plotter2 yAxis] setNeedsDisplay:YES];
		}
	}
    if(aNote == nil || [key isEqualToString:@"XAttributes3"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"XAttributes3"];
		if(attrib){
			[(ORAxis*)[plotter3 xAxis] setAttributes:attrib];
			[plotter3 setNeedsDisplay:YES];
			[[plotter3 xAxis] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"YAttributes3"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"YAttributes3"];
		if(attrib){
			[(ORAxis*)[plotter3 yAxis] setAttributes:attrib];
			[plotter3 setNeedsDisplay:YES];
			[[plotter3 yAxis] setNeedsDisplay:YES];
		}
	}
}
- (void) updateTimePlot:(NSNotification*)aNote
{
	if(!aNote || ([aNote object] == [model timeRate:0])){
		[plotter0 setNeedsDisplay:YES];
	}
	else if(!aNote || ([aNote object] == [model timeRate:1])){
		[plotter1 setNeedsDisplay:YES];
	}

	else if(!aNote || ([aNote object] == [model timeRate:2])){
		[plotter2 setNeedsDisplay:YES];
	}
    else if(!aNote || ([aNote object] == [model timeRate:3])){
		[plotter3 setNeedsDisplay:YES];
	}
}

- (void) adcEnabledMaskChanged:(NSNotification*)aNote
{

	unsigned short aMask = [model adcEnabledMask];
	int i;
	for(i=0;i<kMJDPreAmpDacChannels;i++){
		BOOL bitSet = (aMask&(1<<i))>0;
		if(bitSet != [[adcEnabledMaskMatrix cellWithTag:i] intValue]){
			[[adcEnabledMaskMatrix cellWithTag:i] setState:bitSet];
		}
	}
}

- (void) pollTimeChanged:(NSNotification*)aNotification
{
	[pollTimePU selectItemWithTag:[model pollTime]];
}

- (void) shipValuesChanged:(NSNotification*)aNote
{
	[shipValuesCB setIntValue: [model shipValues]];
}

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
    BOOL locked = [gSecurity isLocked:MJDPreAmpSettingsLock];
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
	[pollTimePU			setEnabled:!locked];	
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
- (void) adcEnabledMaskAction:(id)sender
{
	unsigned short mask = 0;
	int i;
	for(i=0;i<16;i++){
		int theValue = [[adcEnabledMaskMatrix cellWithTag:i] intValue];
		if(theValue) mask |= (0x1<<i);
	}
	[model setAdcEnabledMask:mask];	
}

- (void) shipValuesAction:(id)sender
{
	[model setShipValues:[sender intValue]];	
}

- (void) pollTimeAction:(id)sender
{
	[model setPollTime:[[sender selectedItem] tag]];
}

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

- (IBAction) pollNowAction:(id)sender
{
	[model pollValues];
}

#pragma mark ⅴ쩊ata Source
- (int) numberPointsInPlot:(id)aPlotter
{
	return [[model timeRate:[aPlotter tag]] count];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
	int set = [aPlotter tag];
	int count = [[model timeRate:set] count];
	int index = count-i-1;
	*xValue = [[model timeRate:set] timeSampledAtIndex:index];
	*yValue = [[model timeRate:set] valueAtIndex:index];
}

@end
