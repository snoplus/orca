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


@implementation ORHelpCenter
- (id)init
{
    self = [super initWithWindowNibName:@"HelpCenter"];
    return self;
}

- (void) awakeFromNib
{
	[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[self homeURL]]]];
}

- (NSString*) homeURL
{
	NSString* homeURL =  [NSString stringWithFormat:@"file://localhost%@/OrcaHelp/index.html",[[NSBundle mainBundle] resourcePath]];
	return homeURL;
}

#pragma mark ¥¥¥Actions
- (IBAction) showHelpCenter:(id)sender
{
    [[self window] makeKeyAndOrderFront:nil];
}

- (IBAction) goHome:(id)sender
{
	[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[self homeURL]]]];
}
@end
