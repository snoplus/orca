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
#import "mail.h"

#if MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_4
#import <Message/NSMailDelivery.h>
#endif

@interface ORMailer (private)
- (void) sendMailEmail;
- (void) noSubjectSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo;
- (void) noAddressSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo;
- (BOOL) addressOK;
- (BOOL) subjectOK;
- (void) sendit;
@end

@implementation ORMailer

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
	[self retain];
	return self;
}

- (void)dealloc 
{
	NSFileManager* fm = [NSFileManager defaultManager];
	if([fm fileExistsAtPath:tempFilePath])[fm removeItemAtPath:tempFilePath error:nil];

	[tempFilePath release];
	[to release];
	[cc release];
	[subject release];
	[body release];
	[from release];
	[allOutput release];
	[super dealloc];
}

// accessors


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

- (void) send:(id)aDelegate
{
	@synchronized([NSApp delegate]){
		delegate = aDelegate;
		if([NSThread isMainThread])	 [self sendMailEmail];
		else						 [self performSelectorOnMainThread:@selector(sendMailEmail) withObject:nil waitUntilDone:NO];
	}
}

@end

@implementation ORMailer (private)
- (BOOL) addressOK
{
	return [to length]!=0 && [to rangeOfString:@"@"].location != NSNotFound;
}

- (BOOL) subjectOK
{
	return [subject length]!=0;
}

- (void) sendMailEmail
{
	if ([self addressOK]){
		if([self subjectOK]){
			[self sendit];
		}
		else {
			NSBeginAlertSheet(@"ORCA Mail",
				  @"Cancel",
				  @"Send Anyway",
				  nil,
				  [delegate window],
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
			  [delegate window],
			  self,
			  @selector(noAddressSheetDidEnd:returnCode:contextInfo:),
			  nil,
			  nil,@"No Destination Address Given");
	}
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

- (void) sendit
{
	@synchronized([NSApp delegate]){
#if MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_4
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
			if([delegate respondsToSelector:@selector(mailSent:)]){
				[delegate mailSent:to];
				[self autorelease];
			}
			
		}
		else {
			NSBeginAlertSheet(@"ORCA Mail",
					  @"OK",
					  nil,
					  nil,
					  nil,
					  self,
					  nil,
					  nil,
					  nil,@"e-mail could NOT be sent because eMail delivery has not been configured in Mail.app");

			NSLogColor([NSColor redColor], @"e-mail could NOT be sent because eMail delivery has not been configured in Mail.app\n");
		}
#else
	
		/* create a Scripting Bridge object for talking to the Mail application */
		MailApplication *mail = [SBApplication applicationWithBundleIdentifier:@"com.apple.Mail"];
		
        /* set ourself as the delegate to receive any errors */
	//	mail.delegate = self;
		
		/* create a new outgoing message object */
		MailOutgoingMessage *emailMessage = [[[mail classForScriptingClass:@"outgoing message"] alloc] initWithProperties:
											 [NSDictionary dictionaryWithObjectsAndKeys:
											  subject, @"subject",
											  [body string], @"content",
											  nil]];
		
		/* add the object to the mail app  */
		[[mail outgoingMessages] addObject: emailMessage];
		
		/* set the sender, don't show the message */
		emailMessage.sender = @"ORCA";
		emailMessage.visible = NO;
		
		if ( [mail lastError] != nil ){
			NSLog( @"Possible problems with sending e-mail to %@\n",to);
			return;
		}
		NSArray* people = [to componentsSeparatedByString:@","];
		int count = 0;
		for(id aPerson in people){
			if([aPerson rangeOfString:@"@"].location != NSNotFound){
				/* create a new recipient and add it to the recipients list */
				MailToRecipient *theRecipient = [[[mail classForScriptingClass:@"to recipient"] alloc] initWithProperties:
												 [NSDictionary dictionaryWithObjectsAndKeys:
												  aPerson, @"address",
												  nil]];
				[emailMessage.toRecipients addObject: theRecipient];
				[theRecipient release];
				count++;
			}
		}
		
		people = [cc componentsSeparatedByString:@","];
		for(id aPerson in people){
			if([aPerson rangeOfString:@"@"].location != NSNotFound){
				/* create a new recipient and add it to the recipients list */
				MailToRecipient *theRecipient = [[[mail classForScriptingClass:@"cc recipient"] alloc] initWithProperties:
												 [NSDictionary dictionaryWithObjectsAndKeys:
												  aPerson, @"address",
												  nil]];
				[emailMessage.ccRecipients addObject: theRecipient];
				[theRecipient release];
				count++;
			}
		}
		
		
		if ( [mail lastError] == nil && count>0){
			[emailMessage send];
			if ( [mail lastError] != nil ){
				NSLog( @"Possible problems with sending e-mail to %@\n",to);
			}
			else {
				NSLog(@"email sent to: %@\n",to);
			}
		}
		[emailMessage release];
	
#endif
		
	}
}


@end
