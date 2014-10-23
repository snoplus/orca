//
//  CameraController.m
//  Orca
//
//  Created by Joulien on 5/4/14.
//
//

#import "SNOPCameraController.h"
#import "SNOPCameraModel.h"


@implementation SNOPCameraController

-( id ) init
{
    self = [super initWithWindowNibName:@"SNOPCamera"];
    
    return self;
}


-( void ) dealloc
{
    [super dealloc];
}


-( void ) updateWindow
{
    [super updateWindow];
    
    [self cameraCaptureTaskChanged:nil];
}


-( void ) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
    
	[notifyCenter addObserver : self
                     selector : @selector(cameraCaptureTaskChanged:)
                         name : @"cameraCaptureNotification"
                       object : nil];
}


-( void ) cameraCaptureTaskChanged:(NSNotification*) aNote
{
    BOOL captureRunning = [model cameraCaptureTaskRunning];
    
    [takePicButton setTitle:captureRunning?@"Stop":@"Take Photo"];
    [runStateField setStringValue:captureRunning?@"Taking photos...":@"Ready to take photos."];
}


-(IBAction)onTakePicAction:(id)sender
{
    [model powerCamera];
    // Send a notification that cameras are being powered.
    
    [runStateField setStringValue:@"Powering Camera."];
    
    //    [model killPTPCameraProcess];
    
    [runStateField setStringValue:@"Preparing to take photos.  Wait."];
    
    if( ![model cameraCaptureTaskRunning] )
    {
        // Send a notification that we are here and waiting for 15 seconds.  If we are here, don't allow button to be pressed again to start another camera capture process.
        // In python script, make sure to iterate through all capture_script processes and kill them by PID otherwise it thinks that the processes are not killed because they are not owned by snotdaq but by python.
        
        // Wait for 15 sec so PTPCamera process has enough time to start up so we can kill it.
        [model performSelector:@selector(runCaptureScript) withObject:nil afterDelay:15.0];
    }
    else
    {
        [model runCaptureScript];
    }
    
    //    [runStateField setStringValue:@"Taking photos..."];
}
@end