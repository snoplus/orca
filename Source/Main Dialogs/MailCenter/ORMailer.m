//----------------------------------------------------------
//  ORMailer.m
//
//  Created by Mark Howe on Wed Apr 9, 2008.
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

#import "ORMailer.h"
#import <Message/NSMailDelivery.h>

@interface ORMailer (private)
- (BOOL) sendUrlEmail:(NSWindow*) aWindow;
- (BOOL) sendMailEmail:(NSWindow*) aWindow;
- (void) noAddressSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo;
- (void) noSubjectSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo;
@end

@implementation ORMailer

NSString *ORMailerUrlType  = @"ORMailerURLType";
NSString *ORMailerMailType = @"ORMailerNSMailDeliveryType";

+ (ORMailer *) mailer {
	return [[[ORMailer alloc] init] autorelease];
}

- (id)init 
{	
	self = [super init];
	[self setTo:@""];
	[self setCc:@""];
	[self setSubject:@""];
	[self setFrom:@""];
	[self setBody:[[[NSAttributedString alloc] initWithString:@""] autorelease]];
	[self setType: ORMailerMailType];
	return self;
}

- (void)dealloc 
{
	[type release];
	[to release];
	[cc release];
	[subject release];
	[body release];
	[from release];
	[super dealloc];
}

// accessors
- (NSString *)type 
{
	return type;
}

- (void)setType:(NSString *)value 
{
    [type release];
    type = [value copy];
}

- (NSString *)to 
{
	return to;
}

- (void)setTo:(NSString *)value 
{
    [to release];
    to = [value copy];
}

- (NSString *)cc 
{
	return cc;
}

- (void)setCc:(NSString *)value 
{
    [cc release];
    cc = [value copy];
}

- (NSString *)subject 
{
	return subject;
}

- (void)setSubject:(NSString *)value 
{
    [subject release];
    subject = [value copy];
}

- (NSAttributedString *)body 
{
	return body;
}

- (NSString *)bodyString 
{
	return [body string];
}

- (void)setBody:(NSAttributedString *)value 
{
    [body release];
    body = [value copy];
}

- (NSString *)from 
{
	return from;
}

- (void)setFrom:(NSString *)value 
{
	[from release];
	from = [value copy];
}

- (BOOL) send:(NSWindow*) aWindow 
{
	if ([type isEqualToString:ORMailerUrlType]) {
		return [self sendUrlEmail:aWindow];
	}
	if ([type isEqualToString:ORMailerMailType]) {
		return [self sendMailEmail:aWindow];
	}
	// better not get here
	return NO;
}

- (NSArray *)ccArray {
	NSArray *array = [[self cc] componentsSeparatedByString:@","];
	return array;
}
@end

@implementation ORMailer (private)

- (BOOL) sendUrlEmail:(NSWindow*) aWindow
{
	NSString *encodedSubject	= [NSString stringWithFormat:@"SUBJECT=%@",[subject stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
	NSString *encodedBody		= [NSString stringWithFormat:@"BODY=%@",[[self bodyString] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
	NSString *encodedTo			= [to stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
	NSString *encodedURLString	= [NSString stringWithFormat:@"mailto:%@?%@&%@", encodedTo, encodedSubject, encodedBody];
	NSURL *mailtoURL			= [NSURL URLWithString:encodedURLString];
	@synchronized([NSApp delegate]){
		[[NSWorkspace sharedWorkspace] openURL:mailtoURL];
	}
	return YES;
}

- (BOOL) sendMailEmail:(NSWindow*) aWindow
{
	BOOL okToSend = YES;
	@synchronized([NSApp delegate]){

		if(!to || [to rangeOfString:@"@"].location == NSNotFound){
			okToSend = NO;
			NSBeginAlertSheet(@"ORCA Mail",
                      @"OK",
                      nil,
                      nil,
					  aWindow,
                      self,
                      @selector(noAddressSheetDidEnd:returnCode:contextInfo:),
                      nil,
                      nil,@"No Destination Address Given");
			session = [NSApp beginModalSessionForWindow:aWindow];
			[NSApp runModalSession:session];
		}
		if(okToSend){
			if([subject length] == 0){
				NSDictionary* userInfo = [NSDictionary dictionaryWithObject:aWindow forKey:@"Window"];
				NSBeginAlertSheet(@"ORCA Mail",
                      @"Cancel",
                      @"Send Anyway",
                      nil,
					  aWindow,
                      self,
                      @selector(noSubjectSheetDidEnd:returnCode:contextInfo:),
                      nil,
                      userInfo,@"No Subject...");
			}
		}
	}
	return okToSend;
}

- (void) noAddressSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo
{
	[NSApp endModalSession:session];
}

- (void) noSubjectSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo
{
	if(returnCode != NSAlertAlternateReturn){		
		BOOL configured = [NSMailDelivery hasDeliveryClassBeenConfigured];
		if(configured){
			NSMutableDictionary *headersDict = [NSMutableDictionary dictionary];
			[headersDict setObject:to forKey:@"To"];
			[headersDict setObject:cc forKey:@"Cc"];
			[headersDict setObject:subject forKey:@"Subject"];
			[NSMailDelivery deliverMessage:body
										headers:headersDict
										format:NSMIMEMailFormat
									protocol:nil];
			NSLog(@"email sent to: %@\n",to);
		}
		else {
			NSBeginAlertSheet(@"ORCA Mail",
                      @"OK",
                      nil,
                      nil,
					  [userInfo objectForKey:@"window"],
                      self,
                      nil,
                      nil,
                      nil,@"e-mail could NOT be sent because eMail delivery has not been configured in Mail.app");

			NSLogColor([NSColor redColor], @"e-mail could NOT be sent because eMail delivery has not been configured in Mail.app\n");
		}
	}
}


@end
