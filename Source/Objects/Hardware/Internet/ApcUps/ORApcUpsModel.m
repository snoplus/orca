//
//  ORApcUpsModel.m
//  Orca
//
//  Created by Mark Howe on Mon Apr 21 2008
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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
#import "ORApcUpsModel.h"
#import "NetSocket.h"
#import "ORTimeRate.h"
#import "ORFileGetterOp.h"

NSString* ORApcUpsModelEventLogChanged  = @"ORApcUpsModelEventLogChanged";
NSString* ORApcUpsIsConnectedChanged	= @"ORApcUpsIsConnectedChanged";
NSString* ORApcUpsIpAddressChanged		= @"ORApcUpsIpAddressChanged";
NSString* ORApcUpsRefreshTables         = @"ORApcUpsRefreshTables";
NSString* ORApcUpsPollingTimesChanged   = @"ORApcUpsPollingTimesChanged";
NSString* ORApcUpsTimedOut              = @"ORApcUpsTimedOut";
NSString* ORApcUpsLock                  = @"ORApcUpsLock";
NSString* ORApcUpsDataValidChanged      = @"ORApcUpsDataValidChanged";
NSString* ORApcUpsUsernameChanged       = @"ORApcUpsUsernameChanged";
NSString* ORApcUpsPasswordChanged       = @"ORApcUpsPasswordChanged";
NSString* ORApcUpsHiLimitChanged		= @"ORApcUpsHiLimitChanged";
NSString* ORApcUpsLowLimitChanged		= @"ORApcUpsLowLimitChanged";

@interface ORApcUpsModel (private)
- (void) postCouchDBRecord;
@end

#define kApcEventsPath [@"~/ApcEvents.txt" stringByExpandingTildeInPath]
#define kApcDataPath   [@"~/ApcData.txt"   stringByExpandingTildeInPath]

@implementation ORApcUpsModel

@synthesize valueDictionary,lastTimePolled,nextPollScheduled,dataValid,password,username;

- (void) makeMainController
{
    [self linkToController:@"ORApcUpsController"];
}

- (void) dealloc
{
    [eventLog release];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    [dataInValidAlarm clearAlarm];
    [dataInValidAlarm release];
    [powerOutAlarm clearAlarm];
    [powerOutAlarm release];
    
    int i;
    for(i=0;i<8;i++){
        [timeRate[i] release];
    }
    
    [channelFromNameTable release];
    
    self.valueDictionary        = nil;
    
    [fileQueue cancelAllOperations];
    [fileQueue release];

    [super dealloc];
}

- (void) awakeAfterDocumentLoaded
{
	@try {
        [self performSelector:@selector(pollHardware) withObject:nil afterDelay:3];
	}
	@catch(NSException* localException) {
	}
}

- (void) setLastTimePolled:(NSDate *)aDate
{
    [aDate retain];
    [lastTimePolled release];
    lastTimePolled = aDate;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORApcUpsPollingTimesChanged object:self];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"ApcUpsIcon"]];
}

#pragma mark ***Accessors

- (unsigned int) pollTime
{
    if(pollTime==0)pollTime = kApcPollTime;
    else if(pollTime==20)pollTime = 20;

    return pollTime;
}

- (void) setPollTime:(unsigned int)aPollTime
{
    pollTime = aPollTime;
    if(aPollTime==0)aPollTime = kApcPollTime;
    else if(aPollTime==20)aPollTime = 20;
    [self pollHardware];
}

- (NSMutableSet*) eventLog
{
    return eventLog;
}

- (void) setEventLog:(NSMutableSet*)aEventLog
{
    [aEventLog retain];
    [eventLog release];
    eventLog = aEventLog;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORApcUpsModelEventLogChanged object:self];
}

- (NSString*) ipAddress
{
    if([ipAddress length]==0)return @"";
    else return ipAddress;
}

- (void) setIpAddress:(NSString*)aIpAddress
{
	if(!aIpAddress)aIpAddress = @"";
    if(![aIpAddress isEqualToString:ipAddress]){
        [[[self undoManager] prepareWithInvocationTarget:self] setIpAddress:ipAddress];
        
        [ipAddress autorelease];
        ipAddress = [aIpAddress copy];
	
        [self performSelector:@selector(pollHardware) withObject:nil afterDelay:5];
    
    
        [[NSNotificationCenter defaultCenter] postNotificationName:ORApcUpsIpAddressChanged object:self];
    }
}

- (void) setUsername:(NSString *)aName
{
	if(!aName)aName = @"";
    if(![aName isEqualToString:username]){
        [[[self undoManager] prepareWithInvocationTarget:self] setUsername:username];
        [username autorelease];
        username = [aName copy];
        [self performSelector:@selector(pollHardware) withObject:nil afterDelay:5];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORApcUpsUsernameChanged object:self];
    }
}

- (void) setPassword:(NSString *)aPassword
{
 	if(!aPassword)aPassword = @"";
    if(![aPassword isEqualToString:password]){
        [[[self undoManager] prepareWithInvocationTarget:self] setPassword:password];
        [password autorelease];
        password = [aPassword copy];
        [self performSelector:@selector(pollHardware) withObject:nil afterDelay:5];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORApcUpsPasswordChanged object:self];
    }
}


- (void) setDataValid:(BOOL)aState
{
    dataValid = aState;
    [self checkAlarms];
    if(!dataValid){
        //clear the variables that are being monitored
        [valueDictionary release];
        valueDictionary = nil;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:ORApcUpsDataValidChanged object:self];
}

- (void) checkAlarms
{
    if(dataValid || ([ipAddress length]!=0 && [password length]!=0 && [username length]!=0)){
        if([dataInValidAlarm isPosted]){
            [dataInValidAlarm clearAlarm];
            [dataInValidAlarm release];
            dataInValidAlarm = nil;
        }
    }
    else {
        if([ipAddress length]!=0 && [password length]!=0 && [username length]!=0){
            if(!dataInValidAlarm){
                dataInValidAlarm = [[ORAlarm alloc] initWithName:@"UPS Data Invalid" severity:kHardwareAlarm];
                [dataInValidAlarm setSticky:YES];
            }
            [dataInValidAlarm postAlarm];
        }
    }
    if(dataValid){
        float Vin1 = [[self valueForPowerPhase:1  powerTableIndex:0] floatValue];
        float Vin2 = [[self valueForPowerPhase:2  powerTableIndex:0] floatValue];
        float Vin3 = [[self valueForPowerPhase:3  powerTableIndex:0] floatValue];
        float bat  = [[self valueForBattery:0 batteryTableIndex:0] intValue];
        if((Vin1<110) || (Vin2<110) || (Vin3<110)){
            if(!powerOutAlarm){
                powerOutAlarm = [[ORAlarm alloc] initWithName:@"Davis Power Failure" severity:kEmergencyAlarm];
                [powerOutAlarm setHelpString:@"The Davis UPS is reporting that the input voltage is less then 110V on one or more of the three phases. This Alarm can be silenced by acknowledging it, but it will not be cleared until power is restored."];
                [powerOutAlarm setSticky:YES];
                [powerOutAlarm postAlarm];
            }
            if(lastBatteryValue != bat){
                NSLog(@"The Main Davis UPS is reporting a power failure. Battery capacity is now %.0f%%\n",bat);
                lastBatteryValue = bat;
            }
        }
        else {
            if([powerOutAlarm isPosted]){
                [powerOutAlarm clearAlarm];
                [powerOutAlarm release];
                powerOutAlarm = nil;
                lastBatteryValue = 0;
                NSLog(@"The Main Davis UPS is restored. Battery capacity is now %.0f%%\n",bat);
            }
        }
    }
}

- (void) pollHardware
{
    if([ipAddress length]!=0 && [password length]!=0 && [username length]!=0){
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollHardware) object:nil];
        [self performSelector:@selector(pollHardware) withObject:nil afterDelay:[self pollTime]];
        [self setNextPollScheduled:[NSDate dateWithTimeIntervalSinceNow:[self pollTime]]];
        [self setLastTimePolled:[NSDate date]];
        
        [self getEvents];
        [self getData];

    }
    else [self setDataValid:NO];
}

- (void) setUpQueue
{
    if(!fileQueue){
        fileQueue = [[NSOperationQueue alloc] init];
        [fileQueue setMaxConcurrentOperationCount:1];
        [fileQueue addObserver:self forKeyPath:@"operations" options:0 context:NULL];
    }
}

- (void) getEvents
{
    [self setUpQueue];
   
    ORFileGetterOp* mover = [[[ORFileGetterOp alloc] init] autorelease];
    mover.delegate     = self;
    [mover setUseFTP:YES];
    [mover setParams:@"logs/event.txt" localPath:kApcEventsPath ipAddress:ipAddress userName:username passWord:password];
    [mover setDoneSelectorName:@"eventsFileArrived"];
    [fileQueue addOperation:mover];
}

- (void) getData
{
    [self setUpQueue];
    
    ORFileGetterOp* mover = [[[ORFileGetterOp alloc] init] autorelease];
     mover.delegate     = self;
    [mover setUseFTP:YES];
    [mover setParams:@"logs/data.txt" localPath:kApcDataPath ipAddress:ipAddress userName:username passWord:password];
    [mover setDoneSelectorName:@"dataFileArrived"];
    [fileQueue addOperation:mover];
    
}

- (BOOL) isConnected
{
    return [fileQueue operationCount]!=0;
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                         change:(NSDictionary *)change context:(void *)context
{
    if (object == fileQueue && [keyPath isEqual:@"operations"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ORApcUpsIsConnectedChanged object:self];
    }
}

- (void) eventsFileArrived
{
    NSStringEncoding* en=nil;
    NSString* contents = [NSString stringWithContentsOfFile:kApcEventsPath usedEncoding:en error:nil];
    NSArray* lines = [contents componentsSeparatedByString:@"\n"];
    int i=0;
    if(!eventLog)[self setEventLog:[NSMutableSet setWithCapacity:500]];
    for(id aLine in lines){
        if(i>=7){
            if([aLine rangeOfString:@"logged"].location != NSNotFound) continue;
            else {
                aLine = [aLine stringByReplacingOccurrencesOfString:@"\t" withString:@" "];
                int len = [aLine length];
                if(len>6) aLine = [aLine substringToIndex:len-6];
                [eventLog addObject:aLine];
            }
        }
        i++;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:ORApcUpsModelEventLogChanged object:self];
    [self postCouchDBRecord];

}

- (void) dataFileArrived
{
    NSStringEncoding* en=nil;
    NSString* contents = [NSString stringWithContentsOfFile:kApcDataPath usedEncoding:en error:nil];
    NSArray* lines = [contents componentsSeparatedByString:@"\n"];
    NSArray* headerNames = nil;
    NSArray* values      = nil;
    NSArray* header0Names = nil;
    NSArray* values0      = nil;
    if([lines count]==0)[self setDataValid:NO];
    for(id aLine in lines){
        aLine = [aLine trimSpacesFromEnds];
        NSArray* parts = [aLine componentsSeparatedByString:@"\t"];
        int numParts = [parts count];
        if(numParts == 6){
            if(!header0Names){
                header0Names = parts ;
            }
            else {
                values0 = parts;
                if(header0Names){
                    if(!valueDictionary)self.valueDictionary = [NSMutableDictionary dictionary];
                    
                    int i;
                    for(i=0;i<numParts;i++){
                        NSString* key = [header0Names objectAtIndex:i];
                        key = [key trimSpacesFromEnds];
                        if([key isEqualToString:@"Date"])continue;
                        [valueDictionary setObject:[values0 objectAtIndex:i] forKey:key];
                    }
                }
            }

        }
        else if(numParts == 31){
            if(!headerNames){
                headerNames = parts ;
            }
            else {
                values = parts;
                if(headerNames){
                    if(!valueDictionary)self.valueDictionary = [NSMutableDictionary dictionary];
                    [self setDataValid:YES];

                    int i;
                    for(i=0;i<numParts;i++){
                        NSString* key = [headerNames objectAtIndex:i];
                        key = [key trimSpacesFromEnds];
                        key = [key stringByReplacingOccurrencesOfString:@"%" withString:@""];
                       [valueDictionary setObject:[values objectAtIndex:i] forKey:key];
                    }

                }
                break;
            }
        }
        [self postCouchDBRecord];

        int i;
        for(i=0;i<8;i++){
            if(timeRate[i] == nil){
                timeRate[i] = [[ORTimeRate alloc] init];
                [timeRate[i] setSampleTime: [self pollTime]];
            }
            [timeRate[i] addDataToTimeAverage:[self valueForChannel:i]];
        }
    }
}

- (void) clearEventLog
{
    NSLog(@"Cleared UPS Event Log\n");
    [self setEventLog:nil];
    [self pollHardware];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORApcUpsModelEventLogChanged object:self];

}

- (ORTimeRate*)timeRate:(int)aChannel
{
    if(aChannel>=0 && aChannel<8) return timeRate[aChannel];
    else return nil;
}

- (NSString*) valueForPowerPhase:(int)aPhaseIndex powerTableIndex:(int)aRowIndex
{
    switch (aRowIndex){
        case 0:
            return [valueDictionary objectForKey:[NSString stringWithFormat:@"Vmin%d",aPhaseIndex]];
            break;
        case 1:
            return [valueDictionary objectForKey:[NSString stringWithFormat:@"Vbp%d",aPhaseIndex]];
            break;
        case 2:
            return [valueDictionary objectForKey:[NSString stringWithFormat:@"Vout%d",aPhaseIndex]];
            break;
        case 3:
            return [valueDictionary objectForKey:[NSString stringWithFormat:@"Iin%d",aPhaseIndex]];
            break;
   }
    return @"?";
}

- (NSString*) valueForLoadPhase:(int)aLoadIndex loadTableIndex:(int)aRowIndex
{
    switch (aRowIndex){
        case 0:
            return [valueDictionary objectForKey:[NSString stringWithFormat:@"kVAout%d",aLoadIndex]];
            break;
        case 1:
            return [valueDictionary objectForKey:[NSString stringWithFormat:@"Iout%d",aLoadIndex]];
            break;
    }
    return @"?";
}

- (NSString*) valueForBattery:(int)aLoadIndex batteryTableIndex:(int)aRowIndex
{
    switch (aRowIndex){
        case 0:
            return [valueDictionary objectForKey:@"Cap"];
            break;
        case 1:
            return [valueDictionary objectForKey:@"Vbat"];
            break;
        case 2:
            return [valueDictionary objectForKey:@"Ibat"];
            break;
    }
    return @"?";
}

- (NSString*) nameAtIndexInPowerTable:(int)i;
{
    switch(i){
        case 0: return @"Input Voltage (VAC)";
        case 1: return @"Bypass Voltage (VAC)";
        case 2: return @"Output Voltage (VAC)";
        case 3: return @"Input Current (A)";
        case 4: return @"Input Frequency (Hz)";
        default: return @"";
    }
}

- (NSString*) nameForIndexInLoadTable:(int)i
{
    switch(i){
        case 0: return @"Output Load (KVA)";
        case 1: return @"Output Current (A)";
        case 2: return @"Temperature (C)";
        default: return @"";
    }
}

- (NSString*) nameForIndexInBatteryTable:(int)i
{
    switch(i){
        case 0: return @"Capacity (%)";
        case 1: return @"Battery Voltage (VDC)";
        case 2: return @"Battery Current (A)";
        default: return @"";
    }
}

- (NSString*) nameForIndexInProcessTable:(int)i
{
    switch(i){
        case 0: return @"Battery Current";
        case 1: return @"Battery Voltage";
        case 2: return @"Input Voltage L1";
        case 3: return @"Input Voltage L2";
        case 4: return @"Input Voltage L3";
        case 5: return @"Output Current L1";
        case 6: return @"Output Current L2";
        case 7: return @"Output Current L3";
        default: return @"";
    }
}

- (id) nameForChannel:(int)aChannel
{
    switch(aChannel){
        case 0:return @"BATTERY CURRENT"; break;
        case 1:return @"BATTERY VOLTAGE"; break;
        case 2:return @"INPUT VOLTAGE L1"; break;
        case 3:return @"INPUT VOLTAGE L2"; break;
        case 4:return @"INPUT VOLTAGE L3"; break;
        case 5:return @"OUTPUT CURRENT L1"; break;
        case 6:return @"OUTPUT CURRENT L2"; break;
        case 7:return @"OUTPUT CURRENT L3"; break;
        default: return @"";
    }
}

- (float) valueForChannel:(int)aChannel
{
    NSString* key = nil;
    switch(aChannel){
        case 0:key = @"Ibat"; break;
        case 1:key = @"Vbat"; break;
        case 2:key = @"Vmin1"; break;
        case 3:key = @"Vmin2"; break;
        case 4:key = @"Vmin3"; break;
        case 5:key = @"Iout1"; break;
        case 6:key = @"Iout2"; break;
        case 7:key = @"Iout3"; break;
    }
    if(key)return [[valueDictionary objectForKey:key]floatValue];
    else return 0;
}

- (int) channelForName:(NSString*)aName
{
    NSNumber* aChannelNumber = [channelFromNameTable objectForKey:aName];
    if(aChannelNumber)return [aChannelNumber intValue];
    else return -1;
}

- (id) valueForKeyInValueDictionary:(NSString*)aKey
{
    return [valueDictionary objectForKey:aKey];
}

#pragma mark •••Process Limits
- (float) lowLimit:(int)i
{
	if(i>=0 && i<kNumApcUpsAdcChannels)return lowLimit[i];
	else return 0;
}

- (void) setLowLimit:(int)i value:(float)aValue
{
	if(i>=0 && i<kNumApcUpsAdcChannels){
		[[[self undoManager] prepareWithInvocationTarget:self] setLowLimit:i value:lowLimit[i]];
		
		lowLimit[i] = aValue;
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORApcUpsLowLimitChanged object:self userInfo:userInfo];
		
	}
}

- (float) hiLimit:(int)i
{
	if(i>=0 && i<kNumApcUpsAdcChannels)return hiLimit[i];
	else return 0;
}

- (void) setHiLimit:(int)i value:(float)aValue
{
	if(i>=0 && i<kNumApcUpsAdcChannels){
		[[[self undoManager] prepareWithInvocationTarget:self] setHiLimit:i value:lowLimit[i]];
		
		hiLimit[i] = aValue;
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORApcUpsHiLimitChanged object:self userInfo:userInfo];
		
	}
}

#pragma mark •••Bit Processing Protocol
- (void) startProcessCycle { }
- (void) endProcessCycle   { }
- (void) processIsStarting { }
- (void) processIsStopping {}


- (NSString*) identifier
{
	NSString* s;
 	@synchronized(self){
		s= [NSString stringWithFormat:@"ApcUps,%lu",[self uniqueIdNumber]];
	}
	return s;
}

- (NSString*) processingTitle
{
	NSString* s;
 	@synchronized(self){
		s= [self identifier];
	}
	return s;
}

- (BOOL) processValue:(int)channel
{
	BOOL theValue = 0;
	@synchronized(self){
        return [self convertedValue:channel];
	}
	return theValue;
}

- (double) convertedValue:(int)aChan
{
	double theValue = 0;
	@synchronized(self){
        return [self valueForChannel:aChan];
    }
	return theValue;
}

- (void) setProcessOutput:(int)aChan value:(int)aValue
{ /*nothing to do*/ }

- (double) maxValueForChan:(int)aChan
{
    switch(aChan){
        case 0: return 50;  //battery amps
            
        case 1:
        case 2:
        case 3: return 130; //Input voltages

        case 4:
        case 5:
        case 6: return 50; //Output current
            
        default: return 0;
    }
}

- (double) minValueForChan:(int)aChan
{
    return 0;
}

- (void) getAlarmRangeLow:(double*)theLowLimit high:(double*)theHighLimit channel:(int)channel
{
	@synchronized(self){
		if(channel < kNumApcUpsAdcChannels){
			*theLowLimit  = lowLimit[channel];
			*theHighLimit =  hiLimit[channel];
		}
	}
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    pollTime = kApcPollTime;
    
    [[self undoManager] disableUndoRegistration];
    [self setEventLog: [decoder decodeObjectForKey:@"eventLog"]];
	[self setIpAddress:[decoder decodeObjectForKey:@"ipAddress"]];
	[self setUsername: [decoder decodeObjectForKey:@"username"]];
	[self setPassword: [decoder decodeObjectForKey:@"password"]];
    int i;
    for(i=0;i<kNumApcUpsAdcChannels;i++) {

		[self setLowLimit:i value:[decoder decodeFloatForKey:[NSString stringWithFormat:@"lowLimit%d",i]]];
		[self setHiLimit:i value:[decoder decodeFloatForKey:[NSString stringWithFormat:@"hiLimit%d",i]]];
	}

    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:eventLog  forKey:@"eventLog"];
    [encoder encodeObject:ipAddress forKey:@"ipAddress"];
    [encoder encodeObject:username  forKey:@"username"];
    [encoder encodeObject:password  forKey:@"password"];
    int i;
	for(i=0;i<kNumApcUpsAdcChannels;i++) {
		[encoder encodeFloat:lowLimit[i] forKey:[NSString stringWithFormat:@"lowLimit%d",i]];
		[encoder encodeFloat:hiLimit[i] forKey:[NSString stringWithFormat:@"hiLimit%d",i]];
	}
}

@end

@implementation ORApcUpsModel (private)
- (void) postCouchDBRecord
{
    NSMutableDictionary* values = [NSMutableDictionary dictionaryWithDictionary:valueDictionary];
    [values setObject:[NSNumber numberWithInt:30] forKey:@"pollTime"];
    
    NSSet* events = [self eventLog];
    NSMutableString* eventLogString = [NSMutableString stringWithString:@""];
    for (NSString *anEvent in events) {
        [eventLogString appendFormat:@"%@\n",anEvent];
    }
    [values setObject:eventLogString forKey:@"eventLog"];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddObjectRecord" object:self userInfo:values];
}
@end

