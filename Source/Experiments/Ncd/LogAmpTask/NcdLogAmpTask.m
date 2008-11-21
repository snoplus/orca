//
//  NcdLogAmpTask.m
//  Orca
//
//  Created by Mark Howe on July 1, 2004.
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

#import "NcdLogAmpTask.h"
#import "ORPulserDistribModel.h"
#import "NcdModel.h"
#import "ORHPPulserModel.h"

#import "NcdPDSStepTask.h"

@implementation NcdLogAmpTask
-(id)	init
{
    if( self = [super init] ){
        [NSBundle loadNibNamed: @"NcdLogAmpTask" owner: self];	// We're responsible for releasing the top-level objects in the NIB (our view, right now).
        [self setTitle:@"Log Amp Calib"];
    }
    return self;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    [self addExtraPanel:extraView];
}

- (int)timeOnOneChannel 
{
    return timeOnOneChannel;
}

- (void)setTimeOnOneChannel:(int)aTimeOnOneChannel {
    [[[self undoManager] prepareWithInvocationTarget:self] setTimeOnOneChannel:timeOnOneChannel];
    timeOnOneChannel = aTimeOnOneChannel;
    if(timeOnOneChannel<1)timeOnOneChannel=1;
    [timeField setIntValue:timeOnOneChannel];
    [timeStepper setIntValue:timeOnOneChannel];
}



- (BOOL) okToRun
{
    return [[ORGlobal sharedGlobal] runInProgress];
}

#pragma mark ¥¥¥Actions
- (IBAction) timeAction:(id)sender
{
    [self setTimeOnOneChannel:[sender intValue]];
}

#pragma mark ¥¥¥Task Methods
- (void) prepare
{
    [super prepare];
    [[self undoManager] disableUndoRegistration];
    if([delegate respondsToSelector:@selector(dependentTask:)]){
        stepTask = [delegate dependentTask:self];
        [stepTask setIsSlave:YES];
        stepTaskMemento = [[stepTask memento] retain];
        [stepTask setTimeOnOneChannel:timeOnOneChannel];
        [stepTask setWillRepeat:NO];
        [stepTask setStartIsDelayed:NO];
    }       
    startedStepTask = NO;
    NSArray* objects = [[[NSApp delegate]  document] collectObjectsOfClass:NSClassFromString(@"ORPulserDistribModel")];
    if([objects count]){
        thePDSModel = [objects objectAtIndex:0];
        pdsMemento = [[thePDSModel memento] retain];  //save the old values
        [thePDSModel setDisableForPulser:YES];
    }

    objects = [[[NSApp delegate]  document] collectObjectsOfClass:NSClassFromString(@"ORHPPulserModel")];
    if([objects count]){
        thePulserModel = [objects objectAtIndex:0];
        pulserMemento = [[thePulserModel memento] retain];
        [thePulserModel setSelectedWaveform:kLogCalibrationWaveform];
        [thePulserModel setTriggerSource:kInternalTrigger];
        [thePulserModel downloadWaveform];
        [delegate shipPulserRecord:thePulserModel];
        [self setMessage:@"Set up Pulser"];
    }
    [[self undoManager] enableUndoRegistration];
}


- (void) enableGUI:(BOOL)state
{
    [timeField setEnabled:state];
    [timeStepper setEnabled:state];
}

- (BOOL)  doWork
{
    if(!stepTask){
        NSLogColor([NSColor redColor],@"No PDS stepper task defined, so nothing to do!\n");
        return NO;
    }

    if(!thePulserModel){
        NSLogColor([NSColor redColor],@"No Pulser object in config, so nothing to do!\n");
        NSLogColor([NSColor redColor],@"Start of <%@> aborted!\n",[self title]);
        [self hardHaltTask];
        return NO; //can not run if no pulser object in config
    }
    
    //must wait for the pulser to load waveform
    if(!startedStepTask){
        if(![thePulserModel loading]){
            if([stepTask numberEnabledChannels] == 0){
                NSLogColor([NSColor redColor],@"NCD PDS Step Task: No Channels selected, so nothing to do!\n");
                return NO;
            }
            [stepTask startTask];
            startedStepTask = YES;
        }
    }
    else {
        if(![[stepTask message] isEqualToString:[self message]]){
            [self setMessage:[stepTask message]];
            [[NSNotificationCenter defaultCenter] postNotificationName:ORTaskDidStepNotification object:self];
        }
        if([stepTask taskState] == eTaskStopped){
            return NO;
        }
    }
    
    return YES;
}
- (void) finishUp
{
    [self setMessage:@""];
    if(stepTask){
        [stepTask hardHaltTask];
        [stepTask setIsSlave:NO];
    }
    if(thePDSModel){
		NS_DURING
			[thePDSModel restoreFromMemento:pdsMemento];
		NS_HANDLER
		NS_ENDHANDLER
        [pdsMemento release];
        pdsMemento = nil;
    }
    if(thePulserModel){
		NS_DURING
			[thePulserModel restoreFromMemento:pulserMemento];
		NS_HANDLER
		NS_ENDHANDLER

        [pulserMemento release];
        pulserMemento = nil;
                
        [stepTask restoreFromMemento:stepTaskMemento];
        [stepTaskMemento release];
        stepTaskMemento = nil;
    }
    thePulserModel = nil;
    [self setMessage:@"Idle"];
}

- (NSString*) description
{
    NSString* s = @"\n";
    s = [s stringByAppendingFormat:@"Time/chan: %d",timeOnOneChannel];
    return s;
}

#pragma mark ¥¥¥Archival
static NSString* NcdPDSStepTaskTime  = @"NcdPDSStepTaskTime";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [NSBundle loadNibNamed: @"NcdLogAmpTask" owner: self];	

    [[self undoManager] disableUndoRegistration];
    
    [self setTimeOnOneChannel:[decoder decodeIntForKey:NcdPDSStepTaskTime]];
    
    [[self undoManager] enableUndoRegistration];    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:timeOnOneChannel forKey:NcdPDSStepTaskTime];
}


@end
