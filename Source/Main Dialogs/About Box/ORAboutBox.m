//
//  ORAboutBox.m
//  Orca
//
//  Created by Mark Howe on Tue Jan 08 2002.
//  Copyright  © 2001 CENPA, University of Washington. All rights reserved.
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


#import "ORAboutBox.h"

@interface ORAboutBox (private)
- (void)_scrollCredits:(NSTimer *)timer;
@end

@implementation ORAboutBox

#pragma mark ¥¥¥Actions
- (IBAction)showAboutBox:(id)sender
{
    if (!appNameField) {
        NSWindow *theWindow;
        NSString *creditsPath;
        NSAttributedString *creditsString;
        NSString *appName;
        NSString *versionString;
        NSString *copyrightString;
        NSDictionary *infoDictionary;
        CFBundleRef localInfoBundle;
        NSDictionary *localInfoDict;
        if (![NSBundle loadNibNamed:@"AboutBox" owner:self]){
            // int NSRunCriticalAlertPanel(NSString *title,
            //		NSString *msg, NSString *defaultButton,
            //		NSString *alternateButton, NSString *otherButton, ...);
            NSLog( @"Failed to load ORAboutBox.nib" );
            NSBeep();
            return;
        }
        theWindow = [appNameField window];
                // Get the info dictionary (Info.plist)
        infoDictionary = [[NSBundle mainBundle] infoDictionary];

        // Get the localized info dictionary (InfoPlist.strings)
        localInfoBundle = CFBundleGetMainBundle();
        localInfoDict = (NSDictionary *)
            CFBundleGetLocalInfoDictionary( localInfoBundle );

        // Setup the app name field
        appName = [localInfoDict objectForKey:@"CFBundleName"];
        [appNameField setStringValue:appName];
                // Set the about box window title
        [theWindow setTitle:[NSString stringWithFormat:@"About %@", appName]];
                // Setup the version field
        versionString = [infoDictionary objectForKey:@"CFBundleVersion"];
		
		NSFileManager* fm = [NSFileManager defaultManager];
		NSString* svnVersionPath = [[NSBundle mainBundle] pathForResource:@"svnversion"ofType:nil];
		NSMutableString* svnVersion = [NSMutableString stringWithString:@""];
		if([fm fileExistsAtPath:svnVersionPath])svnVersion = [NSMutableString stringWithContentsOfFile:svnVersionPath encoding:NSASCIIStringEncoding error:nil];
		if([svnVersion hasSuffix:@"\n"]){
			[svnVersion replaceCharactersInRange:NSMakeRange([svnVersion length]-1, 1) withString:@""];
		}

        [versionField setStringValue:[NSString stringWithFormat:@"Version %@%@%@",
            versionString,[svnVersion length]?@":":@"",[svnVersion length]?svnVersion:@""]];

        // Setup our credits
        creditsPath = [[NSBundle mainBundle] pathForResource:@"Credits"
                                                      ofType:@"rtf"];
        creditsString = [[NSAttributedString alloc] initWithPath:creditsPath
                                              documentAttributes:nil];
        [creditsField replaceCharactersInRange:NSMakeRange( 0, 0 )
                                       withRTF:[creditsString RTFFromRange:
                                           NSMakeRange( 0, [creditsString length] )
                            documentAttributes:nil]];

        // Setup the copyright field
        copyrightString = [localInfoDict objectForKey:@"NSHumanReadableCopyright"];
        [copyrightField setStringValue:copyrightString];
                // Prepare some scroll info
        maxScrollHeight = [[creditsField string] length];
                // Setup the window
        [theWindow setExcludedFromWindowsMenu:YES];
        [theWindow setMenu:nil];
        [theWindow center];
        [creditsString release];
		
    }

    if (![[appNameField window] isVisible]){
        currentPosition = 0;
        restartAtTop = NO;
        startTime = [NSDate timeIntervalSinceReferenceDate] + 3.0;
        [creditsField scrollPoint:NSMakePoint( 0, 0 )];
    }
        // Show the window
    [[appNameField window] makeKeyAndOrderFront:nil];
}

#pragma mark ¥¥¥Delegate Methods
- (void)windowDidBecomeKey:(NSNotification *)notification
{
	if(!scrollTimer) scrollTimer = [[NSTimer scheduledTimerWithTimeInterval:0.01
                                                   target:self
                                                 selector:@selector(_scrollCredits:)
                                                 userInfo:nil
                                                  repeats:YES]retain];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
    [scrollTimer invalidate];
    [scrollTimer release];
	scrollTimer = nil;
}

#pragma mark ¥¥¥Private Methods
- (void)_scrollCredits:(NSTimer *)timer
{
    if ([NSDate timeIntervalSinceReferenceDate] >= startTime){

        if (restartAtTop){
            // Reset the startTime
            startTime = [NSDate timeIntervalSinceReferenceDate] + 3.0;
            restartAtTop = NO;
	    // Set the position
            [creditsField scrollPoint:NSMakePoint( 0, 0 )];
	    return;
        }

        if (currentPosition >= maxScrollHeight){
            // Reset the startTime
            startTime = [NSDate timeIntervalSinceReferenceDate] + 10.0;
                        // Reset the position
            currentPosition = 0;
            restartAtTop = YES;
        }
        else{
            // Scroll to the position
            [creditsField scrollPoint:NSMakePoint( 0, currentPosition )];
                        // Increment the scroll position
            currentPosition += 0.2;
        }
    }
}
@end
