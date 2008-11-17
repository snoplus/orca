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
- (void) taskDataAvailable:(NSNotification*)aNotification;
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
	if([fm fileExistsAtPath:tempFilePath])[fm removeFileAtPath:tempFilePath handler:nil];

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
	delegate = aDelegate;
	[self sendMailEmail];
}

- (NSArray *)ccArray {
	NSArray *array = [[self cc] componentsSeparatedByString:@","];
	return array;
}
- (void) mailDone:(NSNotification*)aNote
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[mailTask release];
	mailTask = nil;
	if([delegate respondsToSelector:@selector(mailSent)]){
		[delegate performSelector:@selector(mailSent) withObject:nil afterDelay:0];
	}
	[self autorelease];
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
			if([delegate respondsToSelector:@selector(mailSent)]){
				[delegate performSelector:@selector(mailSent) withObject:nil afterDelay:0];
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
		NSMutableString* recipents   = [@"make new to recipient at end of to recipients with properties {address:\"</address/>\"}" mutableCopy];
		NSMutableString* ccrecipents = [@"make new to recipient at end of cc recipients with properties {address:\"</cc/>\"}" mutableCopy];
		NSString* mailScriptPath = [[NSBundle mainBundle] pathForResource: @"MailScript" ofType: @"txt"];
		NSMutableString* script = [NSMutableString stringWithContentsOfFile:mailScriptPath];
		[script replaceOccurrencesOfString:@"</subject/>" withString:subject options:NSLiteralSearch range:NSMakeRange(0,[script length])];
		[script replaceOccurrencesOfString:@"</body/>" withString:[body string] options:NSLiteralSearch range:NSMakeRange(0,[script length])];
		[recipents replaceOccurrencesOfString:@"</address/>" withString:to options:NSLiteralSearch range:NSMakeRange(0,[recipents length])];
		[script replaceOccurrencesOfString:@"</addressLine/>" withString:recipents options:NSLiteralSearch range:NSMakeRange(0,[script length])];
		
		 if([cc length]){
			[ccrecipents replaceOccurrencesOfString:@"</cc/>" withString:cc options:NSLiteralSearch range:NSMakeRange(0,[ccrecipents length])];
			[script replaceOccurrencesOfString:@"</ccLine/>" withString:ccrecipents options:NSLiteralSearch range:NSMakeRange(0,[script length])];
		}
		else [script replaceOccurrencesOfString:@"</ccLine/>" withString:@"" options:NSLiteralSearch range:NSMakeRange(0,[script length])];
		NSFileManager* fm = [NSFileManager defaultManager];
		
		char* tmpName = tempnam([[@"~" stringByExpandingTildeInPath]cStringUsingEncoding:NSASCIIStringEncoding] ,"aMailScriptXXX");
		tempFilePath = [[NSString stringWithCString:tmpName] retain];
		free(tmpName);
		
		
		[fm createFileAtPath:tempFilePath contents:[script dataUsingEncoding:NSASCIIStringEncoding] attributes:nil];
		mailTask = [[NSTask alloc] init];
		
		NSPipe *newPipe = [NSPipe pipe];
		NSFileHandle *readHandle = [newPipe fileHandleForReading];
		
		NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
		
		[nc addObserver:self 
			   selector:@selector(taskDataAvailable:) 
				   name:NSFileHandleReadCompletionNotification 
				 object:readHandle];
		
		[nc addObserver:self 
			   selector:@selector(mailDone:) 
				   name:NSTaskDidTerminateNotification 
				 object:mailTask];
		
		[readHandle readInBackgroundAndNotify];
		
		[mailTask setLaunchPath:@"/usr/bin/osascript"];
		[mailTask setArguments:[NSArray arrayWithObject:tempFilePath]];
		[mailTask setStandardOutput:newPipe];
		[mailTask setStandardError:newPipe];
		[mailTask launch];
		[recipents release];
		[ccrecipents release];
		
#endif
		
	}
}

- (void) taskDataAvailable:(NSNotification*)aNotification
{
	if(!allOutput)allOutput = [[NSMutableString stringWithCapacity:512] retain];
    NSData *incomingData = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    if (incomingData && [incomingData length]) {
        // Note:  if incomingData is nil, the filehandle is closed.
        NSString *incomingText = [[NSString alloc] initWithData:incomingData encoding:NSASCIIStringEncoding];
		
        [allOutput appendString:incomingText];
        		
        [[aNotification object] readInBackgroundAndNotify];  // go back for more.
        [incomingText release];
    }  
	else {
		if([allOutput rangeOfString:@"true"].location != NSNotFound){
			NSLog( @"e-mail was sent to %@\n",to);
		}
		else {
			NSLog( @"Possible problems with sending e-mail to %@\n",to);
			NSLog(@"%@\n",allOutput);
		}
	}
}

@end
