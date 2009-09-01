//
//  ORAlarm.m
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


NSString* ORAlarmWasPostedNotification 			= @"Alarm Posted Notification";
NSString* ORAlarmWasClearedNotification 		= @"Alarm Cleared Notification";
NSString* ORAlarmWasAcknowledgedNotification 	= @"ORAlarmWasAcknowledgedNotification";

NSString* severityName[kNumAlarmSeverityTypes] = {
	@"Information",	
	@"Setup",
	@"Out of Range",			
	@"Hardware",			
	@"RunInhibitor",		
	@"DataFlow",		
	@"Important",	
	@"Emergency",
};


@implementation ORAlarm

#pragma mark •••Initialization
- (id) initWithName:(NSString*)aName severity:(AlarmSeverityTypes)aSeverity
{
    self = [super init];
    
    [self setName:aName];
    [self setSeverity:aSeverity];
    [self setSticky:NO];
    return self;
}

- (void) dealloc
{
    [timePosted release];
    [name release];
    [self setSeverity:kInformationAlarm];
    [helpString release];
    [super dealloc];
}

#pragma mark •••Accessors

- (NSTimeInterval) timeSincePosted
{
	return [[NSDate date] timeIntervalSinceDate:timePosted];
}

- (NSString*) timePosted
{
	return [timePosted descriptionWithCalendarFormat:@"%a %m/%d/%y %I:%M  %p"];
}

- (void) setTimePosted:(NSCalendarDate*)aDate
{
    [aDate retain];
    [timePosted release];
    timePosted = aDate;
}

- (NSString*) name
{
    return name;
}

- (void) setName:(NSString*)aName
{
    [name autorelease];
    name = [aName copy];    
}

- (int) severity
{
    return severity;
}

- (NSString*) severityName
{
	if(severity>=0 && severity<kNumAlarmSeverityTypes) return severityName[severity];
	else return @"Illegal Severity";
}


- (void) setSeverity:(int)aValue
{
    severity = aValue;
}

- (void) setHelpString:(NSString*)aString
{
    [helpString autorelease];
    helpString = [aString copy];    
}

- (NSString*) helpString
{
	if(helpString && [helpString length]){
		return [[self genericHelpString] stringByAppendingString:helpString];
	}
    else return [self genericHelpString];
}

- (NSString*) acknowledgedString
{
    return acknowledged?@"Yes":@"No";
}

- (BOOL) acknowledged
{
    return acknowledged;
}

- (NSString*) alarmWasAcknowledged
{
    return acknowledged?@"YES":@"NO";
}

- (void) setAcknowledged:(BOOL)aState
{
    acknowledged = aState;
}

- (void) setSticky:(BOOL)aState
{
    sticky = aState;
}

- (BOOL) sticky
{
    return sticky;
}
- (NSString*) genericHelpString
{
	return [NSString stringWithFormat:@"Name:%@  Severity:%@ Posted:%@\n",[self name],[self severityName],[self timePosted]];
}

#pragma mark •••Alarm Management
- (void) postAlarm
{
    [self setTimePosted:[NSCalendarDate date]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAlarmWasPostedNotification object:self];
}

- (void) clearAlarm
{
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAlarmWasClearedNotification object:self];
}

- (void) setIsPosted:(BOOL)state
{
	isPosted = state;
}

- (BOOL) isPosted
{
	return isPosted;
}

- (void) acknowledge
{
    [self setAcknowledged:YES];
    if(!sticky){
        [self clearAlarm];
    }
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORAlarmWasAcknowledgedNotification object:self];
    NSLog(@" Alarm: [%@] Acknowledged\n",[self name]);
}

- (void) setHelpStringFromFile:(NSString*)fileName
{
	
    NSBundle* mainBundle = [NSBundle mainBundle];
	NSString*   path = [mainBundle pathForResource: fileName ofType: @"plist"];
    if([[NSFileManager defaultManager] fileExistsAtPath:path]){
        NSArray* tempArray = [NSArray arrayWithContentsOfFile:path];
        if([tempArray count]){
            [self setHelpString:[tempArray objectAtIndex:0]];
        }
    }
    else {    
        NSString* resourcePath = [[mainBundle resourcePath] stringByAppendingString:@"/Alarm Help Files/"];
        NSString* fullPath = [resourcePath stringByAppendingString:fileName];
        if([[NSFileManager defaultManager] fileExistsAtPath:fullPath]){
            [self setHelpString:[NSString stringWithContentsOfFile:fullPath encoding:NSASCIIStringEncoding error:nil]];
        }
    }
}

@end
