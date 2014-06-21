//
//  relaunch.m
//  Relaunch Demo
//
//  Created by Matt Patenaude on 4/16/09.
//  Copyright 2009 Matt Patenaude. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//This is a separate XCode target in the ORCA build. Used to relaunch the ORCA applicatin from the Archive Center
int main(int argc, char *argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	pid_t parentPID = atoi(argv[2]);
    while([NSRunningApplication runningApplicationWithProcessIdentifier:parentPID]!=nil){
        sleep(1);
	}
	NSString *appPath = [NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding];
	BOOL success = [[NSWorkspace sharedWorkspace] openFile:[appPath stringByExpandingTildeInPath]];
	
	if (!success) NSLog(@"Error: could not relaunch application at %@", appPath);
	
	[pool drain];
	return success ? 0 : 1;
}
