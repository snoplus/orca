//
//  ORAnalysisPanel2D.m
//  
//
//  Created by Mark Howe on Mon, Mar 17 2008.
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


#import "ORAnalysisPanel2D.h"
#import "ORGate2D.h"
#import "ORGateGroup.h"
#import "ORGate.h"
#import "ORCurve2D.h"

@implementation ORAnalysisPanel2D

+ (id) panel
{
    return [[[ORAnalysisPanel2D alloc] init]autorelease];
}

-(id)	init
{
    if( self = [super init] ){
        [NSBundle loadNibNamed: @"Analysis2D" owner: self];	// We're responsible for releasing the top-level objects in the NIB (our view, right now).
    }
    return self;
}


- (void)awakeFromNib
{
    [self updateWindow];
    [self gateValidChanged:nil];
    [view setAutoresizingMask:NSViewNotSizable];
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
                         name : ORGate2DValidChangedNotification
                       object : gate];
    
	[notifyCenter addObserver : self
                     selector : @selector(totalSumChanged:)
                         name : ORGate2DTotalSumChangedNotification
                       object : gate];
    
    [notifyCenter addObserver : self
                     selector : @selector(gateNumberChanged:)
                         name : ORGate2DNumberChangedNotification
                       object : gate];
    
    [notifyCenter addObserver : self
                     selector : @selector(peakxChanged:)
                         name : ORGate2DPeakXChangedNotification
                       object : gate];

    [notifyCenter addObserver : self
                     selector : @selector(peakyChanged:)
                         name : ORGate2DPeakYChangedNotification
                       object : gate];

   [notifyCenter addObserver: self
                     selector: @selector(activeGateChanged:)
                         name: ORCurve2DActiveGateChanged
                       object: nil];

  [notifyCenter addObserver: self
                     selector: @selector(averageChanged:)
                         name: ORGate2DAverageChangedNotification
                       object: gate];

}

- (void) updateWindow
{
    [self gateNumberChanged:nil];
    [self totalSumChanged:nil];
    [self peakxChanged:nil];
    [self peakyChanged:nil];
    [self averageChanged:nil];
 	[self activeGateChanged:nil];
}


- (void)  activeGateChanged:(NSNotification*)aNote
{
	[activeField setStringValue:[gate gateIsActive]?@"Selected":@""];
}

- (void) gateNumberChanged:(NSNotification*)aNotification
{
    [gateField setIntValue:[gate gateNumber]];
}

- (void) gateValidChanged:(NSNotification*)aNotification
{
    if(([aNotification object] == gate) || (aNotification == nil)){
        if(![gate gateValid]){
            [totalSumField setStringValue:@"---"];	
			[averageField setStringValue:@"---"];	
            [gatePeakXField setStringValue:@"---"];	
            [gatePeakYField setStringValue:@"---"];	
        }
        else [self updateWindow];
    }
}


- (void) totalSumChanged:(NSNotification*)aNote
{
    if([gate gateValid] || (aNote == nil)){
        [totalSumField setIntValue: [gate totalSum]];
    }
}

- (void) averageChanged:(NSNotification*)aNote
{
    if([gate gateValid] || (aNote == nil)){
        [averageField setFloatValue: [gate average]];
    }
}
- (void) peakxChanged:(NSNotification*)aNote
{
    if([gate gateValid] || (aNote == nil)){
        [gatePeakXField setIntValue: [gate peakx]];
    }
}

- (void) peakyChanged:(NSNotification*)aNote
{
    if([gate gateValid] || (aNote == nil)){
        [gatePeakYField setIntValue: (int)[gate peaky]];
    }
}


@end
