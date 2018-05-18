//
//  ORHPTDS2024Controller.m
//  Orca
//  Created by Mark Howe on Mon, May 9, 2018.
//  Copyright (c) 2018 University of North Carolina. All rights reserved.
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


#import "ORTDS2024Controller.h"
#import "ORTDS2024Model.h"
#import "ORUSB.h"
#import "ORUSBInterface.h"
#import "ORAxis.h"
#import "ORPlotView.h"
#import "ORCompositePlotView.h"
#import "ORXYPlot.h"

@implementation ORTDS2024Controller
- (id) init
{
    self = [ super initWithWindowNibName: @"TDS2024" ];
    return self;
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    [ super registerNotificationObservers ];
    
			
    [notifyCenter addObserver : self
                     selector : @selector(interfacesChanged:)
                         name : ORUSBInterfaceAdded
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(interfacesChanged:)
                         name : ORUSBInterfaceRemoved
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(serialNumberChanged:)
                         name : ORTDS2024SerialNumberChanged
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(serialNumberChanged:)
                         name : ORTDS2024USBInterfaceChanged
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(pollTimeChanged:)
                         name : ORTDS2024PollTimeChanged
						object: model];
 
    [notifyCenter addObserver : self
                     selector : @selector(selectedChannelChanged:)
                         name : ORTDS2024SelectedChannelChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(waveFormDataChanged:)
                         name : ORWaveFormDataChanged
                        object: model];
    
}

- (void) awakeFromNib
{
	[self populateInterfacePopup];
	[super awakeFromNib];
    [[plotter yAxis] setRngLimitsLow:0 withHigh:5E9 withMinRng:25];
    int i;
    for(i=0;i<4;i++){
        ORXYPlot* aPlot= [[ORXYPlot alloc] initWithTag:i andDataSource:self];
        [plotter addPlot: aPlot];
        [aPlot setLineColor:[self colorForDataSet:i]];
        [aPlot setName:[NSString stringWithFormat:@"Ch %d",i]];
        [aPlot release];
    }
    [plotter setShowLegend:YES];

    [[plotter xAxis] setRngLimitsLow:0 withHigh:2500 withMinRng:25];
    [[plotter xAxis] setRngDefaultsLow:0 withHigh:2500];
    [[plotter xAxis] setAllowNegativeValues:NO];
    
    [[plotter yAxis] setRngLimitsLow:-65535/2 withHigh:65535/2 withMinRng:25];
    [[plotter yAxis] setRngDefaultsLow:-65535/2 withHigh:65535/2];
    [[plotter yAxis] setAllowNegativeValues:YES];
}

- (NSColor*) colorForDataSet:(int)set
{
    if(set==0)return [NSColor redColor];
    else if(set==1)return [NSColor darkGrayColor];
    else if(set==2)return [NSColor blueColor];
    else return [NSColor blackColor];
}
- (void) updateWindow
{
    [ super updateWindow ];
    
    [self selectedChannelChanged:nil];
    [self serialNumberChanged:nil];
	[self pollTimeChanged:nil];
    [self waveFormDataChanged:nil];
}

#pragma mark •••Notifications
- (void) waveFormDataChanged:(NSNotification*)aNote
{
    [plotter setNeedsDisplay:YES];
}
- (void) selectedChannelChanged:(NSNotification*)aNote
{
    [selectedChannelPopup selectItemAtIndex:[model selectedChannel]];
}

- (void) serialNumberChanged:(NSNotification*)aNote
{
	if(![model serialNumber] || ![[model serialNumber] length] || ![model usbInterface])[serialNumberPopup selectItemAtIndex:0];
	else [serialNumberPopup selectItemWithTitle:[model serialNumber]];
    [[self window] setTitle:[model title]];
}

- (void) pollTimeChanged:(NSNotification*)aNote
{
	[pollTimePopup selectItemWithTag: [model pollTime]];
}

- (IBAction) pollNowAction:(id)sender
{
    [model queryAll];
}
- (void) interfacesChanged:(NSNotification*)aNote
{
	[self populateInterfacePopup];
}

- (void) lockChanged: (NSNotification*) aNotification
{	
	[self setButtonStates];
}

- (void) setButtonStates
{	
    BOOL locked			= [gSecurity isLocked:ORTDS2024Lock];
	[serialNumberPopup setEnabled:!locked];
	[pollTimePopup		setEnabled:!locked];
}

#pragma mark •••Plot DataSource

#pragma mark •••Actions
- (IBAction) pollTimeAction:(id)sender
{
	[model setPollTime:[[sender selectedItem] tag]];
}

- (IBAction) sendCommandAction:(id)sender
{
	@try {
		[self endEditing];
		NSString* cmd = [commandField stringValue];
        [model writeToDevice:cmd];
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        ORRunAlertPanel( [ localException name ], 	// Name of panel
						@"%@",	// Reason for error
						@"OK",	// Okay button
						nil,	// alternate button
						nil,	// other button
                        [localException reason ]);
	}
	
}
- (IBAction) lockAction:(id)sender
{
    [gSecurity tryToSetLock:ORTDS2024Lock to:[sender intValue] forWindow:[self window]];
}

- (void) populateInterfacePopup
{
	NSArray* interfaces = [model usbInterfaces];
	[serialNumberPopup removeAllItems];
	[serialNumberPopup addItemWithTitle:@"N/A"];
	for(ORUSBInterface* anInterface in interfaces){
		NSString* serialNumber = [anInterface serialNumber];
		if([serialNumber length]){
			[serialNumberPopup addItemWithTitle:serialNumber];
		}
	}
	[self validateInterfacePopup];
	if([[model serialNumber] length] > 0){
		if([serialNumberPopup indexOfItemWithTitle:[model serialNumber]]>=0){
			[serialNumberPopup selectItemWithTitle:[model serialNumber]];
		}
		else [serialNumberPopup selectItemAtIndex:0];
	}
	else [serialNumberPopup selectItemAtIndex:0];
}

- (void) validateInterfacePopup
{
	NSArray* interfaces = [[model getUSBController] interfacesForVender:[model vendorID] product:[model productID]];
	NSEnumerator* e = [interfaces objectEnumerator];
	ORUSBInterface* anInterface;
	while(anInterface = [e nextObject]){
		NSString* serialNumber = [anInterface serialNumber];
		if([anInterface registeredObject] == nil || [serialNumber isEqualToString:[model serialNumber]]){
			[[serialNumberPopup itemWithTitle:serialNumber] setEnabled:YES];
		}
		else [[serialNumberPopup itemWithTitle:serialNumber] setEnabled:NO];
	}
}

- (IBAction) serialNumberAction:(id)sender
{
	if([serialNumberPopup indexOfSelectedItem] == 0){
		[model setSerialNumber:nil];
	}
	else {
		[model setSerialNumber:[serialNumberPopup titleOfSelectedItem]];
	}
}

- (IBAction) selectChannelAction:(id)sender
{
    [model setSelectedChannel:[selectedChannelPopup indexOfSelectedItem]];
}

- (IBAction) getCurve:(id)sender
{
    [model getCurve];
}

- (IBAction) autoScale:(id)sender
{
    [plotter autoScaleY:nil];
    //[plotter autoScaleX:nil];
}

-(IBAction) readIdAction:(id)sender
{
	@try {
		[model readIDString];
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        ORRunAlertPanel( [ localException name ], 	// Name of panel
						@"%@",	// Reason for error
						@"OK",	// Okay button
						nil,	// alternate button
						nil,	// other button
                        [localException reason ]);
	}
}


- (int) numberPointsInPlot:(id)aPlotter
{
    int set = [aPlotter tag];
    return [model numPoints:set];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
    int set = [aPlotter tag];
    *xValue = i;
    *yValue = [model dataSet:set valueAtChannel:i];
}

@end


