//
//  ORAlarmCollection.m
//  Orca
//
//  Created by Mark Howe on Fri Jan 17 2003.
//  Copyright © 2003 CENPA, University of Washington. All rights reserved.
//
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

#pragma mark •••Imported Files
#import "ORAlarmCollection.h"
#import "ORAlarmController.h"
#import "CTBadge.h"
#define __CARBONSOUND__ 
#import <Carbon/Carbon.h>
#import "SynthesizeSingleton.h"
#import "ORMailer.h"

NSString* ORAlarmCollectionEmailEnabledChanged = @"ORAlarmCollectionEmailEnabledChanged";

@implementation ORAlarmCollection

#pragma mark •••Inialization

SYNTHESIZE_SINGLETON_FOR_ORCLASS(AlarmCollection);

- (id) init
{
    self = [super init];
    
    [self registerNotificationObservers];
	myBadge = [[CTBadge alloc] init];
    return self;
}


- (void) dealloc
{
    [eMailList release];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[self beepTimer] invalidate];
    [beepTimer release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [alarms release];
	[myBadge release];
    [super dealloc];
}


#pragma mark •••Accessors

- (BOOL) emailEnabled
{
    return emailEnabled;
}

- (void) setEmailEnabled:(BOOL)aEmailEnabled
{
    [[[[NSApp delegate] undoManager] prepareWithInvocationTarget:self] setEmailEnabled:emailEnabled];
    
    emailEnabled = aEmailEnabled;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORAlarmCollectionEmailEnabledChanged object:self];
}

- (NSMutableArray*) eMailList
{
    return eMailList;
}

- (void) setEMailList:(NSMutableArray*)aEMailList
{
    [aEMailList retain];
    [eMailList release];
    eMailList = aEMailList;
}


- (NSMutableArray*) alarms
{
    return alarms;
}

- (void) setAlarms:(NSMutableArray*)someAlarms
{
    [someAlarms retain];
    [alarms release];
    alarms = someAlarms;
}

- (NSTimer*) beepTimer
{
    return beepTimer;
}

- (void) setBeepTimer:(NSTimer*)aTimer
{
    [[self beepTimer] invalidate];
    [aTimer retain];
    [beepTimer release];
    beepTimer=aTimer;
}


- (NSEnumerator*) alarmEnumerator
{
    return [alarms objectEnumerator];
}

- (int) alarmCount
{
    return [alarms count];
}

- (ORAlarm*) objectAtIndex:(int)index
{
    return [alarms objectAtIndex:index];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter addObserver : self
                     selector : @selector(alarmWasPosted:)
                         name : ORAlarmWasPostedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(alarmWasCleared:)
                         name : ORAlarmWasClearedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(alarmWasAcknowledged:)
                         name : ORAlarmWasAcknowledgedNotification
                       object : nil];
}

#pragma mark •••Alarm Management
- (void) alarmWasPosted:(NSNotification*)aNotification
{
    [self addAlarm:[aNotification object]];
    [self setBeepTimer:[NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(beep:) userInfo:nil repeats:YES]];
    [self beep:nil];
    [[aNotification object] setIsPosted:YES];
    [[[ORAlarmController sharedAlarmController] window]orderFront:self];
	[myBadge badgeApplicationDockIconWithValue:[alarms count] insetX:0 y:0];
}

- (void) alarmWasCleared:(NSNotification*)aNotification
{
    [[aNotification object] setIsPosted:NO];
    [self removeAlarm:[aNotification object]];
    if([alarms count] == 0){
        [self setBeepTimer:nil];
		RestoreApplicationDockTileImage();
		[[[ORAlarmController sharedAlarmController] window]orderOut:self];
    }
	else {
		[myBadge badgeApplicationDockIconWithValue:[alarms count] insetX:0 y:0];
	}
}

- (void) alarmWasAcknowledged:(NSNotification*)aNotification
{
    
    [self setBeepTimer:nil];
    NSEnumerator* e = [alarms objectEnumerator];
    ORAlarm* alarm;
    while(alarm = [e nextObject]){
        if(![alarm acknowledged]){
            [self setBeepTimer:[NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(beep:) userInfo:nil repeats:YES]];
            break;
        }
    }
    
}

- (void) beep:(NSTimer*)aTimer
{
    NSBeep();
}

- (void) addAlarm:(ORAlarm*)anAlarm
{
    if(!alarms)		  [self setAlarms:[NSMutableArray array]];
	
    if(![alarms containsObject:anAlarm]){
		BOOL added = NO;
		NSEnumerator* e = [alarms objectEnumerator];
		ORAlarm* alarm;
		while(alarm = [e nextObject]){
			if([anAlarm severity]>=[alarm severity]){
				[alarms insertObject:anAlarm atIndex:[alarms indexOfObject:alarm]];
				added = YES;
				break;
			}
		}
		if(!added){
			[alarms insertObject:anAlarm atIndex:[alarms count]];
		}
				
		NSLogColor([NSColor redColor],@" Alarm: [%@] Posted\n",[anAlarm name]);

    }
}

- (void) removeAlarm:(ORAlarm*)anAlarm
{
    if([alarms containsObject:anAlarm]){
		NSLog(@" Alarm: [%@] Cleared\n",[anAlarm name]);
		[alarms removeObject:anAlarm];
    }
}

- (void) removeAlarmWithName:(NSString*)aName
{
    NSEnumerator* e = [alarms objectEnumerator];
	NSMutableArray* alarmsToClear = [NSMutableArray array];
    ORAlarm* alarm;
    while(alarm = [e nextObject]){
		[[alarm retain] autorelease];
		if([[alarm name] isEqualToString:aName]){
			[alarmsToClear addObject:alarm];
		}
	}
	[alarmsToClear makeObjectsPerformSelector:@selector(clearAlarm)];
}

#pragma mark •••EMail Management
- (int) eMailCount
{
    return [eMailList count];
}

- (void) decodeEMailList:(NSCoder*) aDecoder
{
	[self setEMailList:[aDecoder decodeObjectForKey:@"AlarmEMailList"]];
    [self setEmailEnabled:[aDecoder decodeBoolForKey:@"EmailEnabled"]];
}

- (void) encodeEMailList:(NSCoder*) anEncoder
{
    [[[NSApp delegate] undoManager] disableUndoRegistration];
	[anEncoder encodeObject:eMailList forKey:@"AlarmEMailList"];
    [anEncoder encodeBool:emailEnabled forKey:@"EmailEnabled"];
    [[[NSApp delegate] undoManager] enableUndoRegistration];
}

- (void) addAddress
{
	if(!eMailList)[self setEMailList:[NSMutableArray array]];
	[eMailList addObject:[[[ORAlarmEMailDestination alloc] init] autorelease]];
}

- (void) removeAddress:(int) anIndex
{
	[eMailList removeObjectAtIndex:anIndex];
}

- (ORAlarmEMailDestination*) addressAtIndex:(int)anIndex
{
	if(anIndex>=0 && anIndex<[eMailList count])return [eMailList objectAtIndex:anIndex];
	else return nil;
}

@end

//-----------------------------------------------------------------------------------
//ORAlarmEMailDestination------------------------------------------------------------
//-----------------------------------------------------------------------------------

NSString* ORAlarmSeveritySelectionChanged = @"ORAlarmSeveritySelectionChanged";
NSString* ORAlarmAddressChanged			  = @"ORAlarmAddressChanged";

@implementation ORAlarmEMailDestination
- (id) init
{
	self = [super init];
	eMailLock = [[NSLock alloc] init];
	[self setMailAddress:@"<eMail>"];
	
	if(alarms)[alarms release];
	alarms = [[NSMutableArray arrayWithArray:[[ORAlarmCollection sharedAlarmCollection] alarms]] retain];
	if([alarms count] && [[ORAlarmCollection sharedAlarmCollection] emailEnabled]){
		[NSThread detachNewThreadSelector:@selector(eMailThread) toTarget:self withObject:nil];
	}
	
    [self registerNotificationObservers];
	return self;
}

- (void) dealloc
{
	eMailThreadRunning = NO;
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[mailAddress release];
	[eMailLock release];
	[hostAddress release];
	[super dealloc];
}

- (void) setMailAddress:(NSString*)anAddress
{
    [[[[NSApp delegate] undoManager] prepareWithInvocationTarget:self] setMailAddress:mailAddress];

	[mailAddress autorelease];
	mailAddress = [anAddress copy];
 
	[[NSNotificationCenter defaultCenter] postNotificationName:ORAlarmAddressChanged object:self];
	
}

- (NSString*) mailAddress
{
	return mailAddress;
}

- (BOOL) wantsAlarmSeverity:(AlarmSeverityTypes)aType
{
	return (severityMask & (0x1L<<aType)) != 0;
}

- (void) setSeverityMask:(unsigned long)aMask
{
    [[[[NSApp delegate] undoManager] prepareWithInvocationTarget:self] setSeverityMask:severityMask];

	severityMask = aMask;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAlarmSeveritySelectionChanged object:self];
}

- (unsigned long) severityMask
{
	return severityMask;
}

- (NSMutableArray*) alarms
{
    return alarms;
}

- (void) setAlarms:(NSMutableArray*)someAlarms
{
    [someAlarms retain];
    [alarms release];
    alarms = someAlarms;
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [self init];
    
    [[[NSApp delegate] undoManager] disableUndoRegistration];
        
    [self setMailAddress:[decoder decodeObjectForKey:@"Address"]];
    [self setSeverityMask:[decoder decodeInt32ForKey:@"SeverityMask"]];
    
    [[[NSApp delegate] undoManager] enableUndoRegistration];
	
	if(alarms)[alarms release];
	alarms = [[NSMutableArray arrayWithArray:[[ORAlarmCollection sharedAlarmCollection] alarms]] retain];
	if([alarms count] && [[ORAlarmCollection sharedAlarmCollection] emailEnabled]){
		[NSThread detachNewThreadSelector:@selector(eMailThread) toTarget:self withObject:nil];
	}
	
	[self registerNotificationObservers];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:mailAddress forKey:@"Address"];
    [encoder encodeInt32:severityMask forKey:@"SeverityMask"];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter addObserver : self
                     selector : @selector(alarmWasPosted:)
                         name : ORAlarmWasPostedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(alarmWasCleared:)
                         name : ORAlarmWasClearedNotification
                       object : nil];
        
}

#pragma mark •••Alarm Management
- (void) alarmWasPosted:(NSNotification*)aNotification
{
	[eMailLock lock];
	ORAlarm* theAlarm = [aNotification object];
    if([self wantsAlarmSeverity:[theAlarm severity]] && ![alarms containsObject:theAlarm]){
		if(!alarms)	[self setAlarms:[NSMutableArray array]];
		[alarms addObject:theAlarm];
		if([[ORAlarmCollection sharedAlarmCollection] emailEnabled]){
			[NSThread detachNewThreadSelector:@selector(eMailThread) toTarget:self withObject:nil];
		}
	}
	[eMailLock unlock];
}

- (void) alarmWasCleared:(NSNotification*)aNotification
{
	[eMailLock lock];
    [alarms removeObject:[aNotification object]];
	[eMailLock unlock];
}


- (void) eMailThread
{
	if(eMailThreadRunning)return;
	
	eMailThreadRunning = YES;
				
	while(eMailThreadRunning){
	
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:11.0]];
		[eMailLock lock];

		if(!mailAddress || 
		   [mailAddress length] == 0 ||
		   [mailAddress isEqualToString:@"<eMail>"] ||
		   ![[ORAlarmCollection sharedAlarmCollection] emailEnabled] ||
		   !eMailThreadRunning || 
		   ![alarms count]){
		   
			[pool release];
			[eMailLock unlock];
			break;
			
		}
								
		NSMutableArray* alarmsSent = [NSMutableArray array];
										
		BOOL subscribedToAtleastOne = NO;
		//make the email header stuff
		ORAlarm* tempAlarm = [[ORAlarm alloc] initWithName:@"junk" severity:0];
		int i;
		NSString* emailHeader = @"You are subscribed to the following ORCA alarm types:\n";
		for(i=0;i<kNumAlarmSeverityTypes;i++){
			if([self wantsAlarmSeverity:i]){
				[tempAlarm setSeverity:i];
				emailHeader = [emailHeader stringByAppendingFormat:@" %@\n",[tempAlarm severityName]];
				subscribedToAtleastOne = YES;
			}
		}
		[tempAlarm release];

		if(subscribedToAtleastOne){
		
			if(!hostAddress){
				NSArray* names =  [[NSHost currentHost] addresses];
				id aName;
				int index = 0;
				int n = [names count];
				for(i=0;i<n;i++){
					aName = [names objectAtIndex:i];
					if([aName rangeOfString:@"::"].location == NSNotFound){
						if([aName rangeOfString:@".0.0."].location == NSNotFound){
							hostAddress = [aName copy];
							break;
						}
						index++;
					}
				}
			}
			
			NSString* content = [NSString string];
			
			NSEnumerator* alarmEnummy = [alarms objectEnumerator];
			id anAlarm;
			while(anAlarm = [alarmEnummy nextObject]){
				if([anAlarm timeSincePosted] > 60 && [self wantsAlarmSeverity:[anAlarm severity]]){
					content = [content stringByAppendingFormat:@"+++++++++++++++++++++++++++++++++++\n%@",[anAlarm helpString]];
					[alarmsSent addObject:anAlarm];
				}
			}
			if([content length] != 0){
				content = [content stringByAppendingFormat:@"\n+++++++++++++++++++++++++++++++++++\n\nAutomatically generated by ORCA\nHost machine:%@",hostAddress!=nil?hostAddress:@"<Unable to get host address>"];
		
				@synchronized([NSApp delegate]){
					if(content){
						NSAttributedString* theContent = [[NSAttributedString alloc] initWithString:content];
						ORMailer* mailer = [ORMailer mailer];
						[mailer setTo:mailAddress];
						[mailer setSubject:@"Orca Alarms"];
						[mailer setBody:theContent];
						[mailer send:self];
						[alarms removeObjectsInArray: alarmsSent];
					}
					
				}
			}
		}
		[eMailLock unlock];
		[pool release];
	}
		
	eMailThreadRunning = NO;
}

- (void) mailSent:(NSString*)address
{
	NSLog(@"ORCA alarm report was sent to: %@\n",address);
}

@end
