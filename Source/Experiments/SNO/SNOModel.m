//
//  SNOModel.m
//  Orca
//
//  Created by Mark Howe on Mon Nov 18 2002.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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
#import "SNOModel.h"
#import "SNOController.h"
#import "ORAxis.h"
#import "ORDataPacket.h"
#import "ORRunModel.h"

NSString* ORSNORateColorBarChangedNotification      = @"ORSNORateColorBarChangedNotification";
NSString* ORSNOChartXChangedNotification            = @"ORSNOChartXChangedNotification";
NSString* ORSNOChartYChangedNotification            = @"ORSNOChartYChangedNotification";

@implementation SNOModel

#pragma mark •••Initialization

- (id) init //designated initializer
{
    self = [super init];
    
    colorBarAttributes = [[NSMutableDictionary dictionary] retain];
    [colorBarAttributes setObject:[NSNumber numberWithDouble:0] forKey:ORAxisMinValue];
    [colorBarAttributes setObject:[NSNumber numberWithDouble:10000] forKey:ORAxisMaxValue];
    [colorBarAttributes setObject:[NSNumber numberWithBool:NO] forKey:ORAxisUseLog];
    
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	
    [colorBarAttributes release];
    [xAttributes release];
    [yAttributes release];
          
    [super dealloc];
}

- (void) wakeUp
{
    if([self aWake])return;
    [super wakeUp];
}

- (void) sleep
{
    [super sleep];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"SNO"]];
}

- (void) makeMainController
{
    [self linkToController:@"SNOController"];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(runStatusChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(runAboutToStart:)
                         name : ORRunAboutToStartNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(runEnded:)
                         name : ORRunStoppedNotification
                       object : nil];
	
}



- (void) runStatusChanged:(NSNotification*)aNote
{
    int running = [[[aNote userInfo] objectForKey:ORRunStatusValue] intValue];
    if(running == eRunStopped){
        //[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(collectRates) object:nil];
        //[[self detector] unregisterRates];
    }
    else {
    }
}


#pragma mark •••Accessors
- (NSMutableDictionary*) colorBarAttributes
{
    return colorBarAttributes;
}
- (void) setColorBarAttributes:(NSMutableDictionary*)newColorBarAttributes
{
    [[[self undoManager] prepareWithInvocationTarget:self] setColorBarAttributes:colorBarAttributes];
    
    [newColorBarAttributes retain];
    [colorBarAttributes release];
    colorBarAttributes=newColorBarAttributes;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORSNORateColorBarChangedNotification
	 object:self];
    
}

- (NSDictionary*)   xAttributes
{
    return xAttributes;
}

- (NSDictionary*)   yAttributes
{
    return yAttributes;
}

- (void) setYAttributes:(NSDictionary*)someAttributes
{
    [yAttributes release];
    yAttributes = [someAttributes copy];
}

- (void) setXAttributes:(NSDictionary*)someAttributes
{
    [xAttributes release];
    xAttributes = [someAttributes copy];
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    
    [self setColorBarAttributes:[decoder decodeObjectForKey:@"colorBarAttributes"]];
    [self setXAttributes:[decoder decodeObjectForKey:@"xAttributes"]];
    [self setYAttributes:[decoder decodeObjectForKey:@"yAttributes"]];
    

	
    [[self undoManager] enableUndoRegistration];
    
    [self registerNotificationObservers];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    
    [encoder encodeObject:colorBarAttributes forKey:@"colorBarAttributes"];
    [encoder encodeObject:xAttributes forKey:@"xAttributes"];
    [encoder encodeObject:yAttributes forKey:@"yAttributes"];
    
}



- (void) runAboutToStart:(NSNotification*)aNote
{
}

- (void) runEnded:(NSNotification*)aNote
{		
}

@end


