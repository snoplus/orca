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
#import "ORMailer.h"

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
	
	NSString* address = [[mailForm cellWithTag:0] stringValue];
	NSString* subject = [[mailForm cellWithTag:2] stringValue];
	if([address length]!=0 && [address rangeOfString:@"@"].location != NSNotFound){
		if([subject length]!=0){
			[self sendit];
		}
		else {
			NSBeginAlertSheet(@"ORCA Mail",
							  @"Cancel",
							  @"Send Anyway",
							  nil,
							  [self window],
							  self,
							  @selector(noSubjectSheetDidEnd:returnCode:contextInfo:),
							  nil,
							  nil,@"No Subject...");	
		}
	}
	else {
		NSBeginAlertSheet(@"ORCA Mail",
						  @"OK",
						  nil,
						  nil,
						  [self window],
						  self,
						  @selector(noAddressSheetDidEnd:returnCode:contextInfo:),
						  nil,
						  nil,@"No Destination Address Given");
	}
	
	
} 
	
- (void) sendit
{
	[[self window] performClose:self];

	NSData* theRTFDData = [bodyField RTFDFromRange:NSMakeRange(0,[[bodyField string] length])];;
	
	NSDictionary* attrib;
	NSMutableAttributedString* theContent = [[NSMutableAttributedString alloc] initWithRTFD:theRTFDData documentAttributes:&attrib];
	
	ORMailer* mailer = [ORMailer mailer];
	[mailer setTo:[[mailForm cellWithTag:0] stringValue]];
	[mailer setCc:[[mailForm cellWithTag:1] stringValue]];
	[mailer setSubject:[[mailForm cellWithTag:2] stringValue]];
	[mailer setBody:theContent];
	[mailer send:self];
	[theContent release];
}


- (void) noAddressSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo
{
	
}

- (void) noSubjectSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo
{
	if(returnCode == NSAlertAlternateReturn){
		[self sendit];
	}
}

@end
