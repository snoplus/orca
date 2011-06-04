//
//  ORAlarmElementModel.m
//  Orca
//
//  Created by Mark Howe on Sat Nov 18 2005.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORAlarmElementModel.h"


NSString* ORAlarmElementModelNoAlarmNameChanged     = @"ORAlarmElementModelNoAlarmNameChanged";
NSString* ORAlarmElementNameChangedNotification     = @"ORAlarmElementNameChangedNotification";
NSString* ORAlarmElementHelpChangedNotification     = @"ORAlarmElementHelpChangedNotification";
NSString* ORAlarmElementSeverityChangedNotification = @"ORAlarmElementSeverityChangedNotification";

@interface ORAlarmElementModel (private)
- (NSImage*) composeIcon;
- (NSImage*) composeLowLevelIcon;
- (NSImage*) composeHighLevelIcon;
@end

@implementation ORAlarmElementModel

#pragma mark ¥¥¥Initialization

- (void) dealloc
{
    [noAlarmName release];
    [alarm clearAlarm];
    [alarm release];
    [alarmName release];
    [alarmHelp release];
    [super dealloc];
}

#pragma mark ***Accessors

- (NSString*) noAlarmName
{
	if(!noAlarmName)return @"";
    else return noAlarmName;
}

- (void) setNoAlarmName:(NSString*)aNoAlarmName
{
	if(!aNoAlarmName)aNoAlarmName = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setNoAlarmName:noAlarmName];
    
    [noAlarmName autorelease];
    noAlarmName = [aNoAlarmName copy];  
	
	[self setUpImage];
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORAlarmElementNameChangedNotification
	 object:self];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAlarmElementModelNoAlarmNameChanged object:self];
}

- (BOOL) canBeInAltView
{
	return YES;
}

-(void) makeConnectors
{
    [super makeConnectors];
    ORConnector* aConnector;
    aConnector = [[self connectors] objectForKey:OROutputElementInConnection];
    [aConnector setLocalFrame: NSMakeRect(10,5,kConnectorSize,kConnectorSize)];
    
    aConnector = [[self connectors] objectForKey:OROutputElementOutConnection];
    [aConnector setLocalFrame: NSMakeRect([self frame].size.width - kConnectorSize ,5,kConnectorSize,kConnectorSize)];
}

- (NSString*) elementName
{
	return @"Alarm";
}
- (NSString*) fullHwName
{
	if(!alarmName)return @"";
	else return alarmName;
}

- (id) stateValue
{
	if([self state])return @"Posted";
	else			return @"-";
}

- (void) setUpImage
{
	[self setImage:[self composeIcon]];
	
	if([self state]) {
        if(!alarm){
            alarm = [[ORAlarm alloc] initWithName:[self alarmName] severity:alarmSeverity];
            [alarm setSticky:YES];
        }
        [alarm setHelpString:[self alarmHelp]];
        [alarm postAlarm];
	}
	else {
		[alarm clearAlarm];
        [alarm release];
        alarm = nil;		
	}
}

- (void) makeMainController
{
    [self linkToController:@"ORAlarmElementController"];
}

- (NSString*) alarmName
{
	if(!alarmName)return @"";
    else return alarmName;
}

- (NSString*) alarmHelp
{
	if(!alarmHelp)return @"";
   else return alarmHelp;
}

- (int) alarmSeverity
{
    return alarmSeverity;
}

- (void)setAlarmName:(NSString*)aName
{
    if(aName == nil)aName = @"Process Alarm";
    [[[self undoManager] prepareWithInvocationTarget:self] setAlarmName:[self alarmName]];
	
    [aName retain];
    [alarmName release];
    alarmName = aName;

    if(alarm){
        [alarm setName:aName];
        if([alarm isPosted]){
            [alarm clearAlarm];
            [alarm postAlarm];
        }
    }
	[self setUpImage];
    [[NSNotificationCenter defaultCenter]
		postNotificationName:ORAlarmElementNameChangedNotification
					  object:self];
    
}

- (void)setAlarmHelp:(NSString*)aName
{
    if(aName == nil)aName = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setAlarmHelp:alarmHelp];
	
    [alarmHelp autorelease];
    alarmHelp = [aName copy];    

    if(alarm){
        [alarm setHelpString:alarmHelp];
    }
	
    [[NSNotificationCenter defaultCenter]
		postNotificationName:ORAlarmElementHelpChangedNotification
					  object:self];
}

- (void)setAlarmSeverity:(int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAlarmSeverity:alarmSeverity];
	
    alarmSeverity = aValue;

    if(alarm){
        [alarm setSeverity:aValue];
        if([alarm isPosted]){
            [alarm clearAlarm];
            [alarm postAlarm];
        }
    }
    
    [[NSNotificationCenter defaultCenter]
		postNotificationName:ORAlarmElementSeverityChangedNotification
					  object:self];
}

- (NSString*) description:(NSString*)prefix
{
    NSString* s = [super description:prefix];
    id obj1 = [self objectConnectedTo:OROutputElementInConnection];
    NSString* nextPrefix = [prefix stringByAppendingString:@"  "];
    NSString* noConnectionString = [NSString stringWithFormat:@"%@--",nextPrefix];
    return [NSString stringWithFormat:@"%@\n%@",s,
                                    obj1?[obj1 description:nextPrefix]:noConnectionString];
}

- (id) description
{
	NSString* s =  [super description];
	s =  [s stringByAppendingFormat:@" Name: %@",[self alarmName]];		
	if([alarm isPosted]){
		s =  [s stringByAppendingFormat:@" **ALARM IN PROGRESS**\n"];		
		s =  [s stringByAppendingFormat:@"\tPosted: %@  [type: %@]\n",[alarm timePosted],[alarm severityName]];		
	}
	else {
		s =  [s stringByAppendingString:@" No Alarm"];		
	}
	return s;
}

- (void) processIsStopping
{
    [super processIsStopping];
    [self setState:NO];
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setNoAlarmName:[decoder decodeObjectForKey:@"noAlarmName"]];
    [self setAlarmSeverity:[decoder decodeIntForKey:@"alarmSeverity"]];
    [self setAlarmName:[decoder decodeObjectForKey: @"alarmName"]];
    [self setAlarmHelp:[decoder decodeObjectForKey: @"alarmHelp"]];
    
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:noAlarmName forKey:@"noAlarmName"];
    [encoder encodeInt:alarmSeverity forKey:@"alarmSeverity"];
    [encoder encodeObject:alarmName forKey:@"alarmName"];
    [encoder encodeObject:alarmHelp forKey:@"alarmHelp"];
    
}

@end
@implementation ORAlarmElementModel (private)
- (NSImage*) composeIcon
{
	if(![self useAltView])	return [self composeLowLevelIcon];
	else					return [self composeHighLevelIcon];
}

- (NSImage*) composeLowLevelIcon
{
	NSImage* anImage;

	if([self state]) {
        anImage = [NSImage imageNamed:@"AlarmElementOn"];
    }
    else {
         anImage = [NSImage imageNamed:@"AlarmElementOff"];
    }
	return anImage;
}

- (NSImage*) composeHighLevelIcon
{		
	NSImage* anImage;
	NSColor* theColor;
	NSString* theNameToUse = [self alarmName];
	if([self state]) {
		anImage = [NSImage imageNamed:@"BlankRed"];
		theColor = [NSColor blackColor];
	}
	else {
		anImage = [NSImage imageNamed:@"BlankGreen"];
		theColor = [NSColor colorWithCalibratedWhite:.2 alpha:1];
		if([noAlarmName length])theNameToUse = noAlarmName;
	}
	
	NSFont* theFont = [NSFont fontWithName:@"Geneva" size:10];
	NSAttributedString* s = [[NSAttributedString alloc] 
							   initWithString:theNameToUse
							   attributes:	[NSDictionary dictionaryWithObjectsAndKeys:
											 theFont,NSFontAttributeName,
											 theColor,NSForegroundColorAttributeName,nil]];
	NSSize textSize = [s size];
	NSSize theIconSize = [anImage size];

	NSImage* finalImage = [[NSImage alloc] initWithSize:theIconSize];

	[finalImage lockFocus];
    [anImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
	float y = theIconSize.height/2 - textSize.height/2;
	float x;
	if([self state]) {
		NSImage* alarmImage = [[NSImage imageNamed:@"AlarmIcon"] copy];
		[alarmImage compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver];
		x = 53/2.+(theIconSize.width-53/2.)/2 - textSize.width/2;
		[alarmImage release];
	}
	else {
		x = theIconSize.width/2 - textSize.width/2;
	}
	
	[s drawInRect:NSMakeRect(x,y,textSize.width,textSize.height)];
	[finalImage unlockFocus];
	[s release];
	
	return [finalImage autorelease];
}
@end
