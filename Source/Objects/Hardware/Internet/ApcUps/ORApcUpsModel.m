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

NSString* ORApcUpsIsConnectedChanged	= @"ORApcUpsIsConnectedChanged";
NSString* ORApcUpsIpAddressChanged		= @"ORApcUpsIpAddressChanged";
NSString* ORApcUpsRefreshTables         = @"ORApcUpsRefreshTables";
NSString* ORApcUpsPollingTimesChanged   = @"ORApcUpsPollingTimesChanged";
NSString* ORApcUpsTimedOut              = @"ORApcUpsTimedOut";
NSString* ORApcUpsLock                  = @"ORApcUpsLock";
NSString* ORApcUpsDataValidChanged      = @"ORApcUpsDataValidChanged";

@interface ORApcUpsModel (private)
- (void) clearInputBuffer;
- (void) parse:(NSString*)aResponse;
- (void) parseLine:(NSString*)aLine;
- (void) add:(NSString*)aName value:(NSString*)aValue;
- (void) startTimeout;
- (void) cancelTimeout;
- (void) timeout;
@end


@implementation ORApcUpsModel

@synthesize phaseDictionary,singleValueDictionary,lastTimePolled,nextPollScheduled,dataValid;

- (void) makeMainController
{
    [self linkToController:@"ORApcUpsController"];
}

- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[socket close];
    [socket setDelegate:nil];
	[socket release];
    [inputBuffer release];
    int i;
    for(i=0;i<8;i++){
        [timeRate[i] release];
    }
    
    [nameFromChannelTable release];
    [channelFromNameTable release];
    
    self.singleValueDictionary  = nil;
    self.phaseDictionary        = nil;
    
    [super dealloc];
}

- (void) awakeAfterDocumentLoaded
{
	@try {
        [self pollHardware];
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

- (NetSocket*) socket
{
	return socket;
}
- (void) setSocket:(NetSocket*)aSocket
{
	if(aSocket != socket)[socket close];
	[aSocket retain];
	[socket release];
	socket = aSocket;
    [socket setDelegate:self];
}

- (void) setIsConnected:(BOOL)aFlag
{
    isConnected = aFlag;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORApcUpsIsConnectedChanged object:self];
}

- (NSString*) ipAddress
{
    return ipAddress;
}

- (void) setIpAddress:(NSString*)aIpAddress
{
	if(!aIpAddress)aIpAddress = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setIpAddress:ipAddress];
    
    [ipAddress autorelease];
    ipAddress = [aIpAddress copy];    
	
    if([ipAddress length]!=0)[self pollHardware];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORApcUpsIpAddressChanged object:self];
}

- (void) setDataValid:(BOOL)aState
{
    dataValid = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORApcUpsDataValidChanged object:self];

}
- (void) connect
{
	if(!isConnected){
		[self setSocket:[NetSocket netsocketConnectedToHost:ipAddress port:kApcUpsPort]];	
	}
}

- (void) disconnect
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(disconnect) object:nil];
    [self setSocket:nil];
    [self setIsConnected:[socket isConnected]];
    statusSentOnce = NO;	
}

- (BOOL) isConnected
{
	return isConnected;
}

- (void) pollHardware
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollHardware) object:nil];
    if([ipAddress length]!=0)[self connect];
	[self performSelector:@selector(pollHardware) withObject:nil afterDelay:30];
    [self setNextPollScheduled:[NSDate dateWithTimeIntervalSinceNow:30]];
    [self performSelector:@selector(disconnect) withObject:nil afterDelay:5];
}

- (ORTimeRate*)timeRate:(int)aChannel
{
    if(aChannel>=0 && aChannel<8) return timeRate[aChannel];
    else return nil;
}

#pragma mark ***Delegate Methods
- (void) netsocketConnected:(NetSocket*)inNetSocket
{
    if(inNetSocket == socket){
        [self setIsConnected:[socket isConnected]];
    }
}

- (void) netsocketDisconnected:(NetSocket*)inNetSocket
{
    if(inNetSocket == socket){
        [self setIsConnected:NO];
		[socket autorelease];
		socket = nil;
    }
}

- (void) netsocket:(NetSocket*)inNetSocket dataAvailable:(unsigned)inAmount
{
    if(inNetSocket == socket){        
		NSString* theString = [[[[NSString alloc] initWithData:[inNetSocket readData] encoding:NSASCIIStringEncoding] autorelease] uppercaseString];
        NSLog(@"%@\n",theString);
        if(!inputBuffer)inputBuffer = [[NSMutableString alloc]initWithString:theString];
        else [inputBuffer appendString:theString];
        
        if([theString rangeOfString:@"USER NAME"].location != NSNotFound){
            [inNetSocket writeString:@"apc\r" encoding:NSASCIIStringEncoding];
            [self clearInputBuffer];
        }
        else if([theString rangeOfString:@"PASSWORD"].location != NSNotFound){
            [inNetSocket writeString:@"mjd\r" encoding:NSASCIIStringEncoding];
            [self clearInputBuffer];
        }
        else if([theString rangeOfString:@"APC>"].location != NSNotFound){
            if(!statusSentOnce){
                statusSentOnce = YES;
                [inNetSocket writeString:@"detstatus -all\r" encoding:NSASCIIStringEncoding];
                [self startTimeout];
            }
            [self parse:inputBuffer];
            [self clearInputBuffer];
            [[NSNotificationCenter defaultCenter] postNotificationName:ORApcUpsRefreshTables object:self];
        }
    }
} 

- (NSString*) keyForIndexInPowerTable:(int)i
{
    switch(i){
        case 0: return @"INPUT VOLTAGE";
        case 1: return @"BYPASS INPUT VOLTAGE";
        case 2: return @"OUTPUT VOLTAGE";
        case 3: return @"INPUT CURRENT";
        case 4: return @"INPUT FREQUENCY";
        default: return @"";
    }
}

- (NSString*) nameAtIndexInPowerTable:(int)i;
{
    switch(i){
        case 0: return @"Input Voltage";
        case 1: return @"Bypass Input Voltage";
        case 2: return @"Output Voltage";
        case 3: return @"Input Current";
        case 4: return @"Input Frequency";
        default: return @"";
    }
}

- (NSString*) keyForIndexInLoadTable:(int)i
{
    switch(i){
        case 0: return @"OUTPUT KVA";
        case 1: return @"OUTPUT VA PERCENT";
        case 2: return @"OUTPUT WATTS PERCENT";
        case 3: return @"OUTPUT CURRENT";
        case 4: return @"OUTPUT FREQUENCY";
        default: return @"";
    }
}

- (NSString*) nameForIndexInLoadTable:(int)i
{
    switch(i){
        case 0: return @"Output Load";
        case 1: return @"Output Percent Load";
        case 2: return @"Output Percent Power";
        case 3: return @"Output Current";
        case 4: return @"Output Frequency";
        default: return @"";
    }
}

- (NSString*) keyForIndexInBatteryTable:(int)i
{
    switch(i){
        case 0: return @"RUNTIME REMAINING";
        case 1: return @"BATTERY STATE OF CHARGE";
        case 2: return @"BATTERY VOLTAGE";
        case 3: return @"BATTERY CURRENT";
        default: return @"";
    } 
}

- (NSString*) nameForIndexInBatteryTable:(int)i
{
    switch(i){
        case 0: return @"Runtime Remaining";
        case 1: return @"Capacity";
        case 2: return @"Battery Voltage";
        case 3: return @"Battery Current";
        default: return @"";
    }
}

- (void) setUpTagDictionaries
{
    if(!nameFromChannelTable){
        //order must be the same in these tables
        channelFromNameTable = [[NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithInt:0], @"RUNTIME REMAINING",
                                 [NSNumber numberWithInt:1], @"BATTERY CURRENT",
                                 [NSNumber numberWithInt:2], @"INPUT VOLTAGE L1",
                                 [NSNumber numberWithInt:3], @"INPUT VOLTAGE L2",
                                 [NSNumber numberWithInt:4], @"INPUT VOLTAGE L3",
                                 [NSNumber numberWithInt:5], @"OUTPUT CURRENT L1",
                                 [NSNumber numberWithInt:6], @"OUTPUT CURRENT L2",
                                 [NSNumber numberWithInt:7], @"OUTPUT CURRENT L3",
                                 nil] retain];
        
        nameFromChannelTable = [[NSDictionary dictionaryWithObjectsAndKeys:
                                 @"RUNTIME REMAINING",  [NSNumber numberWithInt:0], 
                                 @"BATTERY CURRENT",    [NSNumber numberWithInt:1], 
                                 @"INPUT VOLTAGE L1",   [NSNumber numberWithInt:2], 
                                 @"INPUT VOLTAGE L2",   [NSNumber numberWithInt:3], 
                                 @"INPUT VOLTAGE L3",   [NSNumber numberWithInt:4], 
                                 @"OUTPUT CURRENT L1",  [NSNumber numberWithInt:5], 
                                 @"OUTPUT CURRENT L2",  [NSNumber numberWithInt:6], 
                                 @"OUTPUT CURRENT L3",  [NSNumber numberWithInt:7], 
                                nil] retain];
    }
}

- (id) nameForChannel:(int)aChannel
{
    [self setUpTagDictionaries];
    return [nameFromChannelTable objectForKey:[NSNumber numberWithInt:aChannel]];
}

- (float) valueForChannel:(int)aChannel
{
    NSString* aName = [self nameForChannel:aChannel];
    if([aName hasSuffix:@"L1"] || [aName hasSuffix:@"L2"] || [aName hasSuffix:@"L3"]){
        NSString* aShortName = [[aName substringToIndex:[aName length]-2] trimSpacesFromEnds];
        NSString* aKey = [[aName substringFromIndex:[aName length]-2] trimSpacesFromEnds];
        return [[[phaseDictionary objectForKey:aKey] objectForKey:aShortName] floatValue];
    }
    else return [[singleValueDictionary objectForKey:aName] floatValue];
}

- (int) channelForName:(NSString*)aName
{
    [self setUpTagDictionaries];
    NSNumber* aChannelNumber = [channelFromNameTable objectForKey:aName];
    if(aChannelNumber)return [aChannelNumber intValue];
    else return -1;
}

- (id) phaseKey:(NSString*)aPhaseKey valueKey:(NSString*)aValueKey
{
    return [[phaseDictionary objectForKey:aPhaseKey] objectForKey:aValueKey];
}

- (id) valueForKeyInSingleValueDictionary:(NSString*)aKey
{
    return [singleValueDictionary objectForKey:aKey];
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
	[self setIpAddress:[decoder decodeObjectForKey:@"ipAddress"]];
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:ipAddress forKey:@"ipAddress"];
}

@end

@implementation ORApcUpsModel (private)

- (void) clearInputBuffer
{
    [inputBuffer release];
    inputBuffer = nil;
    
}
- (void) parse:(NSString*)aResponse
{
    if(!phaseDictionary){
        self.phaseDictionary = [NSMutableDictionary dictionary];
        [phaseDictionary setObject:[NSMutableDictionary dictionary] forKey:@"L1"];
        [phaseDictionary setObject:[NSMutableDictionary dictionary] forKey:@"L2"];
        [phaseDictionary setObject:[NSMutableDictionary dictionary] forKey:@"L3"];
    }
    aResponse = [aResponse stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    NSArray* lines = [aResponse componentsSeparatedByString:@"\r"];
    for(NSString* aLine in lines){
        aLine = [aLine removeNLandCRs];
        if([aLine rangeOfString:@":"].location != NSNotFound){
            //special cases
            if([aLine hasPrefix:@"NAME"]     ||
               [aLine hasPrefix:@"CONTACT"]  ||
               [aLine hasPrefix:@"LOCATION"] ||
               [aLine hasPrefix:@"UP TIME"]){
                [self parseLine:[aLine substringToIndex:46]];
                [self parseLine:[aLine substringFromIndex:46]];
            }
            else [self parseLine:aLine];
        }
    }
}
- (void) parseLine:(NSString*)aLine
{
    NSArray* parts = [aLine componentsSeparatedByString:@":"];
    if([parts count]==2){
        NSString* varName = [[parts objectAtIndex:0] removeNLandCRs];
        varName = [varName trimSpacesFromEnds];
        
        NSString* value = [[parts objectAtIndex:1] removeNLandCRs];
        value = [value trimSpacesFromEnds];
        
        [self add:varName value:value];
    }
    else  if([parts count]==4){
        //special case TIME
        NSString* varName = [[parts objectAtIndex:0] trimSpacesFromEnds];
        varName = [varName removeNLandCRs];
        if([varName isEqualToString:@"TIME"]){
            NSString* time = [NSString stringWithFormat:@"%@:%@:%@",
                              [[parts objectAtIndex:1] trimSpacesFromEnds],
                              [[parts objectAtIndex:2] trimSpacesFromEnds],
                              [[parts objectAtIndex:3] trimSpacesFromEnds]
                              ];
            time = [time removeNLandCRs];
            [self add:varName value:time];
        }
    }
}

- (void) add:(NSString*)aName value:(NSString*)aValue
{
    //collect L1,L2,L3 parameters into an Array
    if([aName hasSuffix:@"L1"]){
        NSString* aShortName = [[aName substringToIndex:[aName length]-2] trimSpacesFromEnds] ;
        [[phaseDictionary objectForKey:@"L1"] setObject:aValue forKey:aShortName];
    }
    else if([aName hasSuffix:@"L2"]){
        NSString* aShortName = [[aName substringToIndex:[aName length]-2] trimSpacesFromEnds] ;
        [[phaseDictionary objectForKey:@"L2"] setObject:aValue forKey:aShortName];
    }
    else if([aName hasSuffix:@"L3"]){
        NSString* aShortName = [[aName substringToIndex:[aName length]-2] trimSpacesFromEnds] ;
        [[phaseDictionary objectForKey:@"L3"] setObject:aValue forKey:aShortName];
    }
    //do the other parameters
    else  {
        //a couple of special cases
        if([aName rangeOfString:@"RUNTIME REMAINING"].location!=NSNotFound){
            int hr = [aValue intValue];
            int min = [[aValue substringFromIndex:4] intValue];
            aValue = [NSString stringWithFormat:@"%d min",(60*hr)+min];
            //we'll use this important parameter as a successfull poll indicator
            [self setLastTimePolled:[NSDate date]];
            [self cancelTimeout];
            [self setDataValid:YES];
        }
        else if([aName rangeOfString:@"INTERNAL TEMPERATURE"].location!=NSNotFound){
            NSArray* parts = [aValue componentsSeparatedByString:@","];
            if([parts count]>=1){
                aValue = [parts objectAtIndex:0];
                aValue = [aValue trimSpacesFromEnds];
            }
        }
        
        if(!singleValueDictionary)self.singleValueDictionary = [NSMutableDictionary dictionary];
        [singleValueDictionary setObject:aValue forKey:aName];
    }
    int i = [self channelForName:aName];
    if(i>=0 && i<8){
        if(timeRate[i] == nil) timeRate[i] = [[ORTimeRate alloc] init];
        [timeRate[i] addDataToTimeAverage:[self valueForChannel:i]];
    }
}

- (void) startTimeout
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
   	[self performSelector:@selector(timeout) withObject:nil afterDelay:3];
}

- (void) cancelTimeout
{
   	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
}

- (void) timeout
{
    [self setDataValid:NO];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
	NSLogError(@"command timeout",[self fullID],nil);
    [[NSNotificationCenter defaultCenter] postNotificationName:ORApcUpsTimedOut object:self];
}

@end

