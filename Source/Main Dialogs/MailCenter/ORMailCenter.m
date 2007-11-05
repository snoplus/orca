//----------------------------------------------------------
//  ORMailCenter.h
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
#import "ORMailCenter.h"
#import <Message/NSMailDelivery.h>

@implementation ORMailCenter

#pragma mark ¥¥¥Initialization

+ (id) mailCenter
{
	ORMailCenter* mailCenter = [[[ORMailCenter alloc] init] autorelease];

	[[NSNotificationCenter defaultCenter] addObserver:mailCenter selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object:nil];
	return mailCenter;
}

#pragma mark ***Accessors


- (id)init
{
    self = [super initWithWindowNibName:@"MailCenter"];
	[self retain];
	selfRetained = YES;
    return self;
}


- (void) dealloc
{
    [fileToAttach release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void) windowWillClose:(NSNotification*)aNote
{
	if([aNote object] == [self window] && selfRetained){
		selfRetained = NO;
		[self autorelease];
	}
}

- (void) awakeFromNib 
{
	[[self window] setReleasedWhenClosed:YES]; 
}

//this method is needed so the global menu commands will be passes on correctly.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow*)window
{
    return [[NSApp delegate]  undoManager];
}

#pragma mark ¥¥¥Accessors
- (void) setFileToAttach:(NSString*)aFileToAttach
{
	[bodyField readRTFDFromFile:[aFileToAttach stringByExpandingTildeInPath]];
}

- (void) setTextBodyToRTFData:(NSData*)rtfdata
{
	[bodyField replaceCharactersInRange:NSMakeRange(0,0) withRTF:rtfdata];
}


#pragma mark ¥¥¥Actions
- (IBAction) send:(id)sender
{
	if(![[self window] makeFirstResponder:[self window]]){
		[[self window] endEditingFor:nil];		
	}
	
	BOOL okToSend = YES;
	if(![[mailForm cellWithTag:0] stringValue] || [[[mailForm cellWithTag:0] stringValue] rangeOfString:@"@"].location == NSNotFound){
		okToSend = NO;
		NSRunAlertPanel(@"Mail Center",@"No Destination Address Given", nil, nil, nil);
	}
	if(okToSend){
		if([[[mailForm cellWithTag:2] stringValue] length] == 0){
			int choice = NSRunAlertPanel(@"Mail Center",@"\nNo Subject...",@"Cancel",@"Send Anyway",nil);
			if(choice != NSAlertAlternateReturn){		
				okToSend = NO;
			}
		}
	}
	
	if(okToSend){
		NSData* theRTFDData = [bodyField RTFDFromRange:NSMakeRange(0,[[bodyField string] length])];;

		NSDictionary* attrib;
		NSMutableAttributedString* theContent = [[NSMutableAttributedString alloc] initWithRTFD:theRTFDData documentAttributes:&attrib];
		
		NSMutableDictionary* headerDict = [NSMutableDictionary dictionary];
		[headerDict setObject:[[mailForm cellWithTag:0] stringValue]  forKey:@"To"];
		NSString* processedCCString = [[[[mailForm cellWithTag:1] stringValue] componentsSeparatedByString:@","] componentsJoinedByString:@""];
		NSArray* ccArray = [processedCCString componentsSeparatedByString:@" "];
		[headerDict setObject:ccArray  forKey:@"Cc"];
		[headerDict setObject:[[mailForm cellWithTag:2] stringValue]  forKey:@"Subject"];
		
		@synchronized([NSApp delegate]){
			[NSMailDelivery deliverMessage:theContent headers:headerDict format:NSMIMEMailFormat protocol:nil];	
		}
		[theContent release];
		
		[[self window] performClose:self];
	}
}

@end
