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
#import "ORCARootServiceDefs.h"
#import "ORCurve1D.h"
#import "ORPlotter1D.h"

#define kAnalysisPanelExpandedHeight  255
#define kAnalysisPanelCollapsedHeight 100

@interface ORAnalysisPanel1D (private)
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
        [NSBundle loadNibNamed: @"Analysis1D" owner: self];	// We're responsible for releasing the top-level objects in the NIB (our analysisView, right now).
		RemoveORCARootWarnings; //a #define from ORCARootServiceDefs.h 
    }
    return self;
}


- (void)awakeFromNib
{	
    [self gateValidChanged:nil];
    [analysisView setAutoresizingMask:NSViewNotSizable];
	[analysisView setBoxType:NSBoxCustom];
	[analysisView setBorderType:NSBezelBorder];
	[self populateFitServicePopup];
	[self populateFFTServicePopup];
	[self populateFFTWindowPopup];
    [self setFitOrder:1];
    [self setFitFunction:@""];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[fitFunction release];
    [analysisView removeFromSuperview];
    [super dealloc];
}


- (NSView*) view
{
    return analysisView;
}

- (void) setGate:(id)aGate
{
    gate = aGate;
    
    if(gate)[self registerNotificationObservers];
	else     [[NSNotificationCenter defaultCenter] removeObserver:self];

	[[NSNotificationCenter defaultCenter] postNotificationName:ORCARootServiceBroadcastConnection object: self];
    [self updateWindow];
}

- (void) registerNotificationObservers
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	if(!gate){
        return;
    }
    
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(gateValidChanged:)
                         name : ORGateValidChangedNotification
                       object : nil];
    
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
    [self totalSumChanged:nil];
    [self averageChanged:nil]; 
    [self peakyChanged:nil];
    [self displayGateChanged:nil];
    [self fitOrderChanged];
    [self fitFunctionChanged];
    [self fitTypeChanged];
    [self fftOptionChanged];
    [self fftWindowChanged];
    [self orcaRootServiceConnectionChanged:nil];
	[self orcaRootServiceFitChanged:nil];
	[self activeGateChanged:nil];

	//-----------------------------------------------------------
	//these can not be called here.... causes nasty crash bug 
	//because of a deep - level call to a free data source
	//after a window is closed.
	//[self gateMinChanged:nil];
	//[self gateMaxChanged:nil];
	//[self centroidChanged:nil];
	//[self sigmaChanged:nil];
	//[self peakxChanged:nil];
	//-----------------------------------------------------------
}

- (int) fitOrder
{
	return fitOrder;
}

- (void) setFitOrder:(int)order
{
	if(order<0)order = 0;
	else if(order>10)order = 10;
	fitOrder = order;
	[self fitOrderChanged];
}

- (void) setFitFunction:(NSString*)aFunction
{
	if(!aFunction)aFunction = @"";
	
    [fitFunction autorelease];
	fitFunction = [aFunction copy];
	
	[self fitFunctionChanged];
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

- (void) fitFunctionChanged
{
	if(fitFunction) [fitFunctionField setObjectValue:fitFunction];
	else [fitFunctionField setObjectValue:@""];
}

- (void) fitOrderChanged
{
	[polyOrderField setIntValue:fitOrder];	
}

- (void) fitTypeChanged
{
	[fitTypePopup selectItemAtIndex:fitType];	
	[polyOrderField setEnabled: serviceAvailable && [gate gateIsActive] && fitType == 2];
	[fitFunctionField setEnabled: serviceAvailable && [gate gateIsActive] && fitType == 4];
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
	[activeField setStringValue:[gate gateIsActive] ? @"Selected":@""];
	if([gate gateIsActive]){
		[analysisView setFillColor:[NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:.7]];
	}
	else {
		[analysisView setFillColor:[NSColor colorWithCalibratedRed:.9 green:.9 blue:.9 alpha:1]];
	}
}

- (void) adjustSize
{
	NSSize oldSize = [analysisView frame].size;
	if([gate gateIsActive]) oldSize.height = kAnalysisPanelExpandedHeight;
	else					oldSize.height = kAnalysisPanelCollapsedHeight;
	[analysisView setFrameSize:oldSize];
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
	[fitFunctionField setEnabled: okToEnable && fitType == 4];
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


- (void) gateMinChanged:(NSNotification*)aNotification
{
    if(([aNotification object] == gate)  || (aNotification == nil)){
        if([gate gateValid]){
            [gateMinField setFloatValue: [gate gateMinValue]];
            [gateWidthField setFloatValue:fabs([gate gateMaxValue]-[gate gateMinValue])];
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
            [gateMaxField setFloatValue: [gate gateMaxValue]];
            [gateWidthField setFloatValue:fabs([gate gateMaxValue]-[gate gateMinValue])];
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
        [centroidField setFloatValue: [gate gateCentroid]];
    }
}

- (void) sigmaChanged:(NSNotification*)aNotification
{
    if(([aNotification object] == gate) &&[gate gateValid] || (aNotification == nil)){
        [sigmaField setFloatValue: [gate gateSigma]];
    }
}

- (void) peakxChanged:(NSNotification*)aNotification
{
    if(([aNotification object] == gate) &&[gate gateValid] || (aNotification == nil)){
        [gatePeakXField setFloatValue: [gate gatePeakValue]];
    }
}
- (void) peakyChanged:(NSNotification*)aNotification
{
    if(([aNotification object] == gate) &&[gate gateValid] || (aNotification == nil)){
        [gatePeakYField setIntValue: (int)[gate peaky]];
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


- (IBAction) fitAction:(id)sender
{
	if(![[analysisView window] makeFirstResponder:[analysisView window]]){
		[[analysisView window] endEditingFor:nil];		
	}

	NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
	
	[userInfo setObject:[NSNumber numberWithInt:fitType] forKey:ORCARootServiceFitFunctionKey];
	[userInfo setObject:[NSNumber numberWithInt:fitOrder] forKey:ORCARootServiceFitOrderKey];
	[userInfo setObject:fitFunction forKey:ORCARootServiceFitFunction];
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

- (IBAction) fitFunctionAction:(id)sender
{
	[self setFitFunction:[sender stringValue]];
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

@end
	

