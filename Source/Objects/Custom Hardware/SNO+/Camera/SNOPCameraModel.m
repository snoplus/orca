//
//  CameraModel.m
//  Orca
//
//  Created by Joulien on 5/7/14.
//
//

#import "SNOPCameraModel.h"
#import "SBC_Link.h"
#import "SNOCmds.h"
#import "ORTaskSequence.h"

@implementation SNOPCameraModel


- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"CameraPic"]];
}


- (void) makeMainController
{
    [self linkToController:@"SNOPCameraController"];
}


- (void) wakeUp
{
    if( [self aWake] )
        return;
    
    [super wakeUp];
}


- (void) sleep
{
    [super sleep];
}


- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}


- (id) sbcLink
{
    NSArray* theSBCs = [[self document] collectObjectsOfClass:NSClassFromString(@"ORVmecpuModel")];
    
    NSLog(@"Found %d SBCs.\n", theSBCs.count);
    
    for(id anSBC in theSBCs)
    {
        return [anSBC sbcLink];
    }
    
    return nil;
}

/*
 - (void) killPTPCameraProcess
 {
 // Kill PTPCamera Process
 NSTask* task = [[NSTask alloc] init];
 
 task.launchPath = @"/usr/bin/killall";
 
 NSString* arg   = @"PTPCamera";
 task.arguments  = @[arg];
 
 [task launch];
 
 [task waitUntilExit];
 
 [task release];
 }
 */

- (void) powerCamera
{
    if( !cameraCaptureTask )
    {
        SBC_Link* sbcLink = [self sbcLink];
        
        if( sbcLink != nil )
        {
            NSLog(@"Made SBC Link.\n");
            
            long errorCode = 0;
            SBC_Packet aPacket;
            
            aPacket.cmdHeader.destination           = kSNO;
            aPacket.cmdHeader.cmdID                 = kSNOCameraResetAll;
            aPacket.cmdHeader.numberBytesinPayload  = 1 * sizeof( long );
            
            unsigned long* payloadPtr   = (unsigned long*) aPacket.payload;
            payloadPtr[0]               = 0;
            
            @try
            {
                [sbcLink send: &aPacket receive: &aPacket];
                unsigned long* responsePtr  = (unsigned long*) aPacket.payload;
                errorCode                   = responsePtr[0];
                
                if( errorCode )
                {
                    @throw [NSException exceptionWithName:@"Reset All Camera error" reason:@"SBC and/or LabJack failed.\n" userInfo:nil];
                }
            }
            
            @catch( NSException* e )
            {
                NSLog( @"SBC failed reset Cameras\n" );
                NSLog( @"Error: %@ with reason: %@\n", [e name], [e reason] );
                //@throw e;
            }
        }
        else
        {
            NSLog( @"Not implemented. Requires SBC with LabJack\n" );
        }
    }
}


-( BOOL ) cameraCaptureTaskRunning
{
    return( cameraCaptureTask != nil );
}


- (void) runCaptureScript
{
    if( ![self cameraCaptureTaskRunning] )
    {
        ORTaskSequence* aSequence =
        [ORTaskSequence taskSequenceWithDelegate:self];
        
        cameraCaptureTask = [[NSTask alloc] init];
        [cameraCaptureTask setLaunchPath  :@"/usr/bin/python"];
        [cameraCaptureTask setArguments   :@[@"/Users/snotdaq/Dev/cameracode/capture_script.py", @"-r"]];
        
        [NSThread sleepForTimeInterval:10.0];
        
        [aSequence addTaskObj:cameraCaptureTask];
        [aSequence setVerbose:YES];
        [aSequence setTextToDelegate:YES];
        
        [aSequence launch];
        
		[[NSNotificationCenter defaultCenter] postNotificationName:@"cameraCaptureNotification" object:self];
    }
    else
    {
        [cameraCaptureTask terminate];
        cameraCaptureTask = nil;
        
		[[NSNotificationCenter defaultCenter] postNotificationName:@"cameraCaptureNotification" object:self];
    }
}


-( void ) tasksCompleted:(id)sender
{
    [cameraCaptureTask release];
    
    cameraCaptureTask = nil;
}


@end