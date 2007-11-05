//
//  ORAnalysisPanel1D.m
//  
//
//  Created by Mark Howe on Tue May 18 2004.
//  Copyright (c) 2004 CENPA, University of Washington. All rights reserved.
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


#import "ORAnalysisPanel1D.h"
#import "ORGate1D.h"
#import "ORGateGroup.h"
#import "ORGate.h"
#import "ORCARootServiceDefs.h"
#import "ORCurve1D.h"

@interface ORAnalysisPanel1D (private)
- (void) populateSelectGatePopup;
- (void) populateFitServicePopup;
- (void) populateFFTServicePopup;
- (void) populateFFTWindowPopup;
@end

@implementation ORAnalysisPanel1D

+ (id) panel
{
    return [[[ORAnalysisPanel1D alloc] init]autorelease];
}

-(id)	init
{
    if( self = [super init] ){
        [NSBundle loadNibNamed: @"Analysis1D" owner: self];	// We're responsible for releasing the top-level objects in the NIB (our view, right now).
		if(kORCARootFitNames[0] != nil){} //just to get rid of stupid compiler warning
		if(kORCARootFitShortNames[0] != nil){} //just to get rid of stupid compiler warning
		if(kORCARootFFTWindowOptions[0] != nil){} //just to get rid of stupid compiler warning
		if(kORCARootFFTWindowNames[0] != nil){} //just to get rid of stupid compiler warning
    }
    return self;
}


- (void)awakeFromNib
{
    [self updateWindow];
    [self gateValidChanged:nil];
    [view setAutoresizingMask:NSViewNotSizable];
    [self populateSelectGatePopup];
	[self populateFitServicePopup];
	[self populateFFTServicePopup];
	[self populateFFTWindowPopup];
    [self setFitOrder:1];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [view removeFromSuperview];
    [super dealloc];
}


- (NSView*) view
{
    return view;
}

- (void) setGate:(id)aGate
{
    gate = aGate;
    
    [self registerNotificationObservers];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORCARootServiceBroadcastConnection object: self];
    [self updateWindow];
}

- (void) registerNotificationObservers
{
    if(!gate){
        return;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(gateValidChanged:)
                         name : ORGateValidChangedNotification
                       object : gate];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(gateMinChanged:)
                         name : ORGateMinChangedNotification
                       object : gate];
    
    [notifyCenter addObserver : self
                     selector : @selector(gateMaxChanged:)
                         name : ORGateMaxChangedNotification
                       object : gate];
    
    [notifyCenter addObserver : self
                     selector : @selector(averageChanged:)
                         name : ORGateAverageChangedNotification
                       object : gate];
    
    [notifyCenter addObserver : self
                     selector : @selector(centroidChanged:)
                         name : ORGateCentroidChangedNotification
                       object : gate];
    
    [notifyCenter addObserver : self
                     selector : @selector(sigmaChanged:)
                         name : ORGateSigmaChangedNotification
                       object : gate];
    
    [notifyCenter addObserver : self
                     selector : @selector(totalSumChanged:)
                         name : ORGateTotalSumChangedNotification
                       object : gate];
    
    [notifyCenter addObserver : self
                     selector : @selector(curveNumberChanged:)
                         name : ORGateCurveNumberChangedNotification
                       object : gate];
    
    [notifyCenter addObserver : self
                     selector : @selector(gateNumberChanged:)
                         name : ORGateNumberChangedNotification
                       object : gate];
    
    [notifyCenter addObserver : self
                     selector : @selector(displayGateChanged:)
                         name : ORGateDisplayGateChangedNotification
                       object : gate];
    
    [notifyCenter addObserver : self
                     selector : @selector(displayedGateChanged:)
                         name : ORGateDisplayedGateChangedNotification
                       object : gate];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(gateArrayChanged:)
                         name : @"ORGateArrayChangedNotification"
                       object : [[[NSApp delegate] document] gateGroup]];
    

    [notifyCenter addObserver : self
                     selector : @selector(peakxChanged:)
                         name : ORGatePeakXChangedNotification
                       object : gate];

    [notifyCenter addObserver : self
                     selector : @selector(peakyChanged:)
                         name : ORGatePeakYChangedNotification
                       object : gate];

    [notifyCenter addObserver: self
                     selector: @selector(orcaRootServiceConnectionChanged:)
                         name: ORCARootServiceConnectionChanged
                       object: nil];

    [notifyCenter addObserver: self
                     selector: @selector(orcaRootServiceFitChanged:)
                         name: ORGateFitChanged
                       object: gate];
					   
    [notifyCenter addObserver: self
                     selector: @selector(activeGateChanged:)
                         name: ORCurve1DActiveGateChanged
                       object: nil];

}

- (void) updateWindow
{
    [self curveNumberChanged:nil];
    [self gateNumberChanged:nil];
    [self gateMinChanged:nil];
    [self gateMaxChanged:nil];
    [self totalSumChanged:nil];
    [self averageChanged:nil]; 
    [self centroidChanged:nil];
    [self sigmaChanged:nil];
    [self peakxChanged:nil];
    [self peakyChanged:nil];
    [self displayGateChanged:nil];
    [self displayedGateChanged:nil];
    [self fitOrderChanged];
    [self fitTypeChanged];
    [self fftOptionChanged];
    [self fftWindowChanged];
    [self orcaRootServiceConnectionChanged:nil];
	[self orcaRootServiceFitChanged:nil];
	[self activeGateChanged:nil];
}

- (int) fitOrder
{
	return fitOrder;
}

- (void) setFitOrder:(int)order
{
	if(order<1)order = 1;
	else if(order>10)order = 10;
	fitOrder = order;
	[self fitOrderChanged];
}

- (int) fitType
{
	return fitType;
}

- (void) setFitType:(int)type
{
	if(type >= kNumORCARootFitTypes)type = 0;
	fitType = type;
	[self fitTypeChanged];
}

- (int) fftOption
{
	return fftOption;
}

- (void) setFftOption:(int)option
{
	if(option >= kNumORCARootFFTOptions)option = 0;
	fftOption = option;
	[self fftOptionChanged];
	
}

- (int) fftWindow
{
	return fftWindow;
}

- (void) setFftWindow:(int)aWindow
{
	if(aWindow >= kNumORCARootFFTWindows)aWindow = 0;
	fftWindow = aWindow;
	[self fftWindowChanged];
	
}

- (void) fitOrderChanged
{
	[polyOrderField setIntValue:fitOrder];	
}

- (void) fitTypeChanged
{
	[fitTypePopup selectItemAtIndex:fitType];	
	[polyOrderField setEnabled: serviceAvailable && [gate gateIsActive] && fitType == 2];
}

- (void) fftOptionChanged
{
	[fftOptionPopup selectItemAtIndex:fftOption];	
}

- (void) fftWindowChanged
{
	[fftWindowPopup selectItemAtIndex:fftWindow];	
}

- (void)  activeGateChanged:(NSNotification*)aNote
{
	[self orcaRootServiceConnectionChanged:nil];
	[activeField setStringValue:[gate gateIsActive]?@"Active":@""];
}

- (void) orcaRootServiceConnectionChanged:(NSNotification*)aNote
{
	if(aNote){
		serviceAvailable = [[[aNote userInfo] objectForKey:ORCARootServiceConnectedKey] intValue];
	}
	BOOL okToEnable = serviceAvailable && [gate gateIsActive];
	[fitButton setEnabled: okToEnable];
	[deleteButton setEnabled: [gate fitExists] & [gate gateIsActive]];
	[fitTypePopup setEnabled: okToEnable];
	[polyOrderField setEnabled: okToEnable && fitType == 2];
	[fftButton setEnabled: okToEnable];
	[fftWindowPopup setEnabled: okToEnable];
	[fftOptionPopup setEnabled: okToEnable];
	
	if(serviceAvailable) {
		[serviceStatusField setTextColor:[NSColor blackColor]];
		[serviceStatusField setStringValue:@"OrcaRoot fit service running"];
	}
	else {
		[serviceStatusField setTextColor:[NSColor redColor]];
		[serviceStatusField setStringValue:@"OrcaRoot fit server NOT running"];
	}
}

- (void) orcaRootServiceFitChanged:(NSNotification*)aNote
{
	[deleteButton setEnabled: [gate fitExists]];
}


- (void) gateArrayChanged:(NSNotification*)aNotification
{
    if([aNotification object] == [[[NSApp delegate] document] gateGroup]){
        NSDictionary* userInfo = [aNotification userInfo];
        if(userInfo){
            if([[userInfo objectForKey:@"deletedGateName"] isEqualToString:[gatePopup titleOfSelectedItem]]){
                [gate setDisplayGate:NO];
            }
        }
        [self populateSelectGatePopup];
        [gatePopup selectItemWithTitle:[gate displayedGateName]];
    }
}


- (void) curveNumberChanged:(NSNotification*)aNotification
{
    [curveField setIntValue:[gate curveNumber]];
}

- (void) gateNumberChanged:(NSNotification*)aNotification
{
    [gateField setIntValue:[gate gateNumber]];
}

- (void) gateValidChanged:(NSNotification*)aNotification
{
    if(([aNotification object] == gate) || (aNotification == nil)){
        if(![gate gateValid]){
            [gateMinField setStringValue:@"---"];	
            [gateMaxField setStringValue:@"---"];	
            [gateWidthField setStringValue:@"---"];	
            [totalSumField setStringValue:@"---"];	
            [sigmaField setStringValue:@"---"];	
            [averageField setStringValue:@"---"];	
            [centroidField setStringValue:@"---"];	
            [gatePeakXField setStringValue:@"---"];	
            [gatePeakYField setStringValue:@"---"];	
        }
        else [self updateWindow];
    }
}


- (void) gateMinChanged:(NSNotification*)aNotification
{
    if(([aNotification object] == gate)  || (aNotification == nil)){
        if([gate gateValid]){
            [gateMinField setIntValue: [gate gateMinChannel]];
            [gateWidthField setIntValue:fabs([gate gateMaxChannel]-[gate gateMinChannel])];
        }
        else {          
            [gateMinField setStringValue:@"---"];	
            [gateWidthField setStringValue:@"---"];	
        }
    }
}

- (void) gateMaxChanged:(NSNotification*)aNotification
{
    if(([aNotification object] == gate) && [gate gateValid] || (aNotification == nil)){
        if([gate gateValid]){
            [gateMaxField setIntValue: [gate gateMaxChannel]-1];
            [gateWidthField setIntValue:fabs([gate gateMaxChannel]-[gate gateMinChannel])];
        }
        else {          
            [gateMaxField setStringValue:@"---"];	
            [gateWidthField setStringValue:@"---"];	
        }
    }
}

- (void) totalSumChanged:(NSNotification*)aNotification
{
    if(([aNotification object] == gate) &&[gate gateValid] || (aNotification == nil)){
        [totalSumField setIntValue: [gate totalSum]];
    }
}

- (void) averageChanged:(NSNotification*)aNotification
{
    if(([aNotification object] == gate) &&[gate gateValid] || (aNotification == nil)){
        [averageField setFloatValue: [gate average]];
    }
}

- (void) centroidChanged:(NSNotification*)aNotification
{
    if(([aNotification object] == gate) &&[gate gateValid] || (aNotification == nil)){
        [centroidField setFloatValue: [gate centroid]];
    }
}

- (void) sigmaChanged:(NSNotification*)aNotification
{
    if(([aNotification object] == gate) &&[gate gateValid] || (aNotification == nil)){
        [sigmaField setFloatValue: [gate sigma]];
    }
}

- (void) peakxChanged:(NSNotification*)aNotification
{
    if(([aNotification object] == gate) &&[gate gateValid] || (aNotification == nil)){
        [gatePeakXField setIntValue: [gate peakx]];
    }
}
- (void) peakyChanged:(NSNotification*)aNotification
{
    if(([aNotification object] == gate) &&[gate gateValid] || (aNotification == nil)){
        [gatePeakYField setIntValue: (int)[gate peaky]];
    }
}
- (void) displayedGateChanged:(NSNotification*)aNotification
{
    if(!aNotification || [aNotification object] == gate){
        [self populateSelectGatePopup];
        [gatePopup selectItemWithTitle:[gate displayedGateName]];
    }
}

- (void) displayGateChanged:(NSNotification*)aNotification
{
    if(!aNotification || [aNotification object] == gate){
        [displayGateButton setState:[gate displayGate]];
    }
}


- (IBAction) displayGateAction:(id)sender
{
    [gate setDisplayGate:[sender intValue]];
}

- (IBAction) selectGateAction:(id)sender
{
    [gate setDisplayedGateName:[sender titleOfSelectedItem]];
}

- (IBAction) fitAction:(id)sender
{
	if(![[view window] makeFirstResponder:[view window]]){
		[[view window] endEditingFor:nil];		
	}

	NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
	
	[userInfo setObject:[NSNumber numberWithInt:fitType] forKey:ORCARootServiceFitFunctionKey];
	[userInfo setObject:[NSNumber numberWithInt:fitOrder] forKey:ORCARootServiceFitOrderKey];
	[gate doFit:userInfo];
}

- (IBAction) fftAction:(id)sender
{
	NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
	
	[userInfo setObject:[NSNumber numberWithInt:fftOption] forKey:ORCARootServiceFFTOptionKey];
	[userInfo setObject:[NSNumber numberWithInt:fftWindow] forKey:ORCARootServiceFFTWindowKey];
	[gate doFFT:userInfo];	
}


- (IBAction) deleteFitAction:(id)sender
{
	[gate removeFit];
}

- (IBAction) fitTypeAction:(id)sender
{
	[self setFitType:[sender indexOfSelectedItem]];
}

- (IBAction) fitOrderAction:(id)sender
{
	[self setFitOrder:[sender intValue]];
}

- (IBAction) fftOptionAction:(id)sender
{
	[self setFftOption:[sender indexOfSelectedItem]];
}

- (IBAction) fftWindowAction:(id)sender
{
	[self setFftWindow:[sender indexOfSelectedItem]];
}

@end

@implementation ORAnalysisPanel1D (private)
- (void) populateFitServicePopup
{
    [fitTypePopup removeAllItems];
    int i;
    for(i=0;i<kNumORCARootFitTypes;i++){
        [fitTypePopup insertItemWithTitle:kORCARootFitNames[i] atIndex:i];
    }
}

- (void) populateFFTServicePopup
{
    [fftOptionPopup removeAllItems];
    int i;
    for(i=0;i<kNumORCARootFFTOptions;i++){
        [fftOptionPopup insertItemWithTitle:kORCARootFFTNames[i] atIndex:i];
    }
}

- (void) populateFFTWindowPopup
{
    [fftWindowPopup removeAllItems];
    int i;
    for(i=0;i<kNumORCARootFFTWindows;i++){
        [fftWindowPopup insertItemWithTitle:kORCARootFFTWindowNames[i] atIndex:i];
    }
}


- (void) populateSelectGatePopup
{
    [gatePopup removeAllItems];
    ORGateGroup* gateGroup = [[[NSApp delegate] document] gateGroup];
    int i;
    for(i=0;i<[gateGroup count];i++){
        [gatePopup insertItemWithTitle:[[gateGroup objectAtIndex:i] gateName] atIndex:i];
    }
}


@end

