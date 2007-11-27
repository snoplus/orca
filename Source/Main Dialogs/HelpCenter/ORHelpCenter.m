//----------------------------------------------------------
//  ORHelpCenter.h
//
//  Created by Mark Howe on Wed Mar 29, 2006.
//  Copyright  © 2002 CENPA. All rights reserved.
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

#pragma mark ¥¥¥Imported Files
#import <WebKit/WebKit.h>
#import "ORHelpCenter.h"

#define kORCAHelpURL @"http://128.95.100.177/~markhowe"

@implementation ORHelpCenter
- (id)init
{
    self = [super initWithWindowNibName:@"HelpCenter"];
	[[NSNotificationCenter defaultCenter] addObserver : self
											 selector : @selector(defaultPathChanged:)
												 name :	ORHelpFilesPathChanged
											   object : nil];
    return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (NSString *) helpFilePath 
{
	NSString* theHelpFilePath;
	BOOL useCustomLocation = [[[NSUserDefaults standardUserDefaults] objectForKey:ORHelpFilesUseDefault] boolValue];
	if(useCustomLocation){
		theHelpFilePath = [[NSUserDefaults standardUserDefaults] objectForKey:ORHelpFilesPath];
		if(![[theHelpFilePath lastPathComponent] isEqualToString:@"index.html"]){
			theHelpFilePath = [theHelpFilePath stringByAppendingString:@"/index.html"];
		}
	}
	else {
		theHelpFilePath = kORCAHelpURL;
	}
	return theHelpFilePath;
}

- (void) awakeFromNib
{
	[self defaultPathChanged:nil];
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
	NSBeginAlertSheet (@"Load Failed",@"OK",nil,nil,[self window],self,nil,nil,nil,@"Check Internet Connection");
}

- (void) defaultPathChanged:(NSNotification*) aNote
{
	[defaultPathField setStringValue:[self helpFilePath]];
	if([[self helpFilePath] length]){
		[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[self helpFilePath]]]];
	}
}

#pragma mark ¥¥¥Actions
- (IBAction) showHelpCenter:(id)sender
{
    [[self window] makeKeyAndOrderFront:nil];
}

- (IBAction) goHome:(id)sender
{
	if([[self helpFilePath] length]){
		[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[self helpFilePath]]]];
	}
}
@end
