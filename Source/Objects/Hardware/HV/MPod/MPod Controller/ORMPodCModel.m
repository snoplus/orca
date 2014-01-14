//
//  ORMPodCModel.m
//  Orca
//
//  Created by Mark Howe on Thurs Jan 6,2011
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Department of Physics and Astrophysics 
//sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark ¥¥¥Imported Files
#import "ORMPodCModel.h"
#import "ORMPodCrate.h"
#import "ORTaskSequence.h"
#import "ORSNMP.h"

NSString* ORMPodCModelVerboseChanged		 = @"ORMPodCModelVerboseChanged";
NSString* ORMPodCModelCrateStatusChanged	 = @"ORMPodCModelCrateStatusChanged";
NSString* ORMPodCModelLock					 = @"ORMPodCModelLock";
NSString* ORMPodCPingTask					 = @"ORMPodCPingTask";
NSString* MPodCIPNumberChanged				 = @"MPodCIPNumberChanged";
NSString* ORMPodCModelSystemParamsChanged	 = @"ORMPodCModelSystemParamsChanged";
NSString* MPodPowerFailedNotification		 = @"MPodPowerFailedNotification";
NSString* MPodPowerRestoredNotification		 = @"MPodPowerRestoredNotification";
NSString* ORMPodCQueueCountChanged			 = @"ORMPodCQueueCountChanged";

@implementation ORMPodCModel

- (void) dealloc
{
	[[ORSNMPQueue queue] cancelAllOperations];
	[systemParams release];
	[connectionHistory release];
    [IPNumber release];
	[dictionaryFromWebPage release];
    
	@try {
        [[ORSNMPQueue queue] removeObserver:self forKeyPath:@"operationCount"];
    }
    @catch (NSException* e){
        
    }
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[super dealloc];
}

- (void) wakeUp
{
    if([self aWake])return;
    [super wakeUp];
	[[ORSNMPQueue queue] addObserver:self forKeyPath:@"operationCount" options:0 context:NULL];
	[self pollHardwareAfterDelay];
}

- (void) sleep
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[[ORSNMPQueue queue] removeObserver:self forKeyPath:@"operationCount"];
	[[ORSNMPQueue queue] cancelAllOperations];
	[super sleep];
}
- (NSString*) helpURL
{
	return @"MPod/MPodC.html";
}
#pragma mark ¥¥¥Initialization
- (void) makeMainController
{
    [self linkToController:@"ORMPodCController"];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"MPodC"]];
}

- (void) setGuardian:(id)aGuardian
{
    if(aGuardian){
		if([aGuardian adapter] == nil){
			[aGuardian setAdapter:self];			
		}
	}
    else [[self guardian] setAdapter:nil];
	
    [super setGuardian:aGuardian];
}

- (void) initConnectionHistory
{
	ipNumberIndex = [[NSUserDefaults standardUserDefaults] integerForKey: [NSString stringWithFormat:@"orca.%@.%d.IPNumberIndex",[self className],[self slot]]];
	if(!connectionHistory){
		NSArray* his = [[NSUserDefaults standardUserDefaults] objectForKey: [NSString stringWithFormat:@"orca.%@.%d.ConnectionHistory",[self className],[self slot]]];
		connectionHistory = [his mutableCopy];
	}
	if(!connectionHistory)connectionHistory = [[NSMutableArray alloc] init];
}

#pragma mark ***Accessors

- (NSMutableDictionary*) systemParams
{
    return systemParams;
}

- (BOOL) verbose
{
    return verbose;
}

- (void) setVerbose:(BOOL)aVerbose
{
    [[[self undoManager] prepareWithInvocationTarget:self] setVerbose:verbose];
    verbose = aVerbose;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMPodCModelVerboseChanged object:self];
}

- (BOOL) power
{
    return [[[systemParams objectForKey:@"sysMainSwitch"] objectForKey:@"Value"] boolValue];
}

- (id) systemParam:(NSString*)name
{
	id result =  [[systemParams objectForKey:name] objectForKey:@"Value"];
	if(result)return result;
	else return @"";
}

- (int) systemParamAsInt:(NSString*)name
{
	return [[[systemParams objectForKey:name] objectForKey:@"Value"] intValue];
}

- (void) clearHistory
{
	[connectionHistory release];
	connectionHistory = nil;
	
	[self setIPNumber:[self IPNumber]];
}

- (unsigned) connectionHistoryCount
{
	return [connectionHistory count];
}

- (id) connectionHistoryItem:(unsigned)index
{
	if(connectionHistory && index<[connectionHistory count])return [connectionHistory objectAtIndex:index];
	else return nil;
}

- (unsigned) ipNumberIndex
{
	return ipNumberIndex;
}

- (NSString*) IPNumber
{
	if(!IPNumber)return @"";
    return IPNumber;
}

- (void) setIPNumber:(NSString*)aIPNumber
{
	if([aIPNumber length]){
		
		[[[self undoManager] prepareWithInvocationTarget:self] setIPNumber:IPNumber];
		
		[IPNumber autorelease];
		IPNumber = [aIPNumber copy];    
		
		if(!connectionHistory)connectionHistory = [[NSMutableArray alloc] init];
		if(![connectionHistory containsObject:IPNumber]){
			[connectionHistory addObject:IPNumber];
		}
		ipNumberIndex = [connectionHistory indexOfObject:aIPNumber];
		
		[[NSUserDefaults standardUserDefaults] setObject:connectionHistory forKey:[NSString stringWithFormat:@"orca.%@.%d.ConnectionHistory",[self className],[self slot]]];
		[[NSUserDefaults standardUserDefaults] setInteger:ipNumberIndex forKey:[NSString stringWithFormat:@"orca.%@.%d.IPNumberIndex",[self className],[self slot]]];
		[[NSUserDefaults standardUserDefaults] synchronize];
		[[NSNotificationCenter defaultCenter] postNotificationName:MPodCIPNumberChanged object:self];
	}
}

- (void) pollHardware
{
    if([IPNumber length]){
		//to save time, we will grab the web page and scrape what values we can.
		ORHvUrlParseOp* aParseOp = [[ORHvUrlParseOp alloc] initWithDelegate:self];
		[aParseOp setIpAddress:IPNumber];
		[ORSNMPQueue addOperation:aParseOp];
		[aParseOp release];
		
        for(id aCard in [[self crate] orcaObjects]){
            [aCard updateAllValues];
        }
    }
}

- (void) pollHardwareAfterDelay
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollHardware) object:nil];
	[self performSelector:@selector(pollHardware) withObject:nil afterDelay:2];
}

- (void) updateAllValues
{
	[self getValues: [self systemUpdateList]  target:self selector:@selector(processSystemResponseArray:) priority:NSOperationQueuePriorityLow];
}

- (NSArray*) systemUpdateList
{
	NSArray* systemReadParams = [NSArray arrayWithObjects:
								 @"sysMainSwitch",
								 @"sysStatus",	
								 @"psSerialNumber",
								 @"psOperatingTime",
								 nil];
	NSMutableArray* convertedArray = [NSMutableArray array];
	for(id aParam in systemReadParams){
		[convertedArray addObject:[aParam stringByAppendingString:@".0"]];
	}
	return convertedArray;
}

- (void) processSystemResponseArray:(NSArray*)response
{
	for(id anEntry in response){
		if(!systemParams)systemParams = [[NSMutableDictionary dictionary] retain];
		NSString* error = [anEntry objectForKey:@"Error"];
		if([error length]){
			if([error rangeOfString:@"Timeout"].location != NSNotFound){
				[systemParams release];
				systemParams = nil; 
				//time out so flush the queue
				[[ORSNMPQueue queue] cancelAllOperations];
				NSLogError(@"TimeOut",[NSString stringWithFormat:@"MPod Crate %d\n",[self crateNumber]],@"HV Controller",nil);
				[[NSNotificationCenter defaultCenter] postNotificationName:@"Timeout" object:self];
			}
		}
		else {
			NSString* name  = [anEntry objectForKey:@"Name"];
			if(name)[systemParams setObject:anEntry forKey:name];
		}
	}
	
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMPodCModelSystemParamsChanged object:self];
	
}

- (void) togglePower
{
    BOOL powerState = [self power];
	NSString* cmd = [NSString stringWithFormat:@"sysMainSwitch.0 i %d",!powerState];
	[[self adapter] writeValue:cmd target:self selector:@selector(processSystemResponseArray:)];
    if(!powerState){
        [self writeMaxTemperature];
        [self writeMaxTerminalVoltage];
    }
}

#pragma mark ¥¥¥Hardware Access
- (id) controllerCard
{
	return [[self crate] controllerCard];
}

- (void)  checkCratePower
{
	NSString* noteName;
	BOOL currentPower = [self power];
	if(currentPower != oldPower){
		if([self power]) noteName = MPodPowerRestoredNotification;
		else			 noteName = MPodPowerFailedNotification;
		[[NSNotificationCenter defaultCenter] postNotificationName:noteName object:self];
	}
	oldPower = currentPower;
}

- (void) getValue:(NSString*)aCmd target:(id)aTarget selector:(SEL)aSelector priority:(NSOperationQueuePriority)aPriority
{
	[self getValues:[NSArray arrayWithObject:aCmd] target:aTarget selector:aSelector priority:aPriority];
}

- (void) getValue:(NSString*)aCmd target:(id)aTarget selector:(SEL)aSelector
{
	[self getValues:[NSArray arrayWithObject:aCmd] target:aTarget selector:aSelector priority:NSOperationQueuePriorityHigh];
}

- (void) getValues:(NSArray*)cmds target:(id)aTarget selector:(SEL)aSelector
{
    [self getValues:cmds target:aTarget selector:aSelector priority:NSOperationQueuePriorityLow];
}

- (void) getValues:(NSArray*)cmds target:(id)aTarget selector:(SEL)aSelector priority:(NSOperationQueuePriority)aPriority
{
	
	for(id aCmd in cmds){
		if(aSelector != NSSelectorFromString(@"processSyncResponseArray:")){
			//before staring a operation on the queue, see if the parameter is in the web page results
			@synchronized(self){
				NSRange r = [aCmd rangeOfString:@"."];
				if(r.location!=NSNotFound){
					NSString* paramKey = [aCmd substringToIndex:r.location];
					NSString* chanKey  = [aCmd substringFromIndex:r.location+1];
					id cardDict = [dictionaryFromWebPage objectForKey:chanKey];
					id val  = [cardDict objectForKey:paramKey];
					if([paramKey isEqualToString:@"outputStatus"]){
						if([val isEqualToString:@"ON"])val = @"1";
						else val = @"0";
					}
					if(val){
						/* must convert to the key/value pairs. for example
						 Channel = 1;
						 Name = outputMeasurementCurrent;
						 Slot = 1;
						 Units = A;
						 Value = "-1.549e-09";
						 */
						NSMutableDictionary* anEntry = [NSMutableDictionary dictionary];
						id theChan = [cardDict objectForKey:@"Channel"];
						id theSlot = [cardDict objectForKey:@"Slot"];
						if(theChan && theSlot){
							[anEntry setObject:theChan forKey:@"Channel"];
							[anEntry setObject:theSlot forKey:@"Slot"];
							if(paramKey)[anEntry setObject:paramKey							  forKey:@"Name"];
							
							NSString* theValueString = [cardDict objectForKey:paramKey];
							NSArray* parts = [theValueString componentsSeparatedByString:@" "];
							if([parts count]==2){
								NSString* units = [parts objectAtIndex:1];
								float theValue = [[parts objectAtIndex:0]floatValue];
								if([units isEqualToString:@"mV"]){
									theValue = theValue/1000.;
									units    = @"V";
								}
								else if([units isEqualToString:@"nA"]){
									theValue = theValue/1000.;
									units    = @"uA";
								}
								else if([units isEqualToString:@"mA"]){
									theValue = theValue*1000.;
									units    = @"uA";
								}
												
								
								[anEntry setObject:[NSNumber numberWithFloat:theValue] forKey:@"Value"];
								[anEntry setObject:units forKey:@"Units"];
							}
							else {
								if(theValueString)[anEntry setObject:theValueString forKey:@"Value"];
							}
							[aTarget processReadResponseArray:[NSArray arrayWithObject:anEntry]]; 
							//NSLog(@"%@\n",anEntry);
							continue;
						}
					}
				}
			}
		}
		
		ORSNMPReadOperation* aReadOp = [[ORSNMPReadOperation alloc] initWithDelegate:aTarget];
		aReadOp.mib			= @"WIENER-CRATE-MIB";
		aReadOp.ipNumber	= IPNumber;
		aReadOp.selector	= aSelector;
		aReadOp.cmds		= [NSArray arrayWithObject:aCmd];
		aReadOp.queuePriority	= aPriority;
		aReadOp.verbose	= verbose;
		[ORSNMPQueue addOperation:aReadOp];
		[aReadOp release];
		
	}
}

- (void) setDictionaryFromWebPage:(NSMutableDictionary*)aDictionary
{
	@synchronized(self){
		[aDictionary retain];
		[dictionaryFromWebPage release];
		dictionaryFromWebPage = aDictionary;
		//NSLog(@"%@\n",dictionaryFromWebPage);
	}
}

- (void) writeMaxTerminalVoltage
{
    [[self adapter] writeValue:@"outputConfigMaxTerminalVoltage F 5000.0" target:self selector:@selector(processWriteResponseArray:) priority:NSOperationQueuePriorityVeryHigh];
}

- (void) writeMaxTemperature
{
    [[self adapter] writeValue:@"outputSupervisionMaxTemperature i 5000" target:self selector:@selector(processWriteResponseArray:) priority:NSOperationQueuePriorityVeryHigh];
}

- (void) writeValue:(NSString*)aCmd target:(id)aTarget selector:(SEL)aSelector priority:(NSOperationQueuePriority)aPriority
{
    [self writeValues:[NSArray arrayWithObject:aCmd] target:aTarget selector:aSelector priority:aPriority];
}

- (void) writeValue:(NSString*)aCmd target:(id)aTarget selector:(SEL)aSelector
{
	[self writeValues:[NSArray arrayWithObject:aCmd] target:aTarget selector:aSelector priority:NSOperationQueuePriorityLow];
}

- (void) writeValues:(NSArray*)cmds target:(id)aTarget selector:(SEL)aSelector priority:(NSOperationQueuePriority)aPriority
{	 
	ORSNMPWriteOperation* aWriteOP = [[ORSNMPWriteOperation alloc] initWithDelegate:self];	
	for(id aCmd in cmds){
		
		aWriteOP.mib		= @"WIENER-CRATE-MIB";
		aWriteOP.target		= aTarget;
		aWriteOP.ipNumber	= IPNumber;
		aWriteOP.selector	= aSelector;
		aWriteOP.cmds		= [NSArray arrayWithObject:aCmd];
		aWriteOP.verbose	= verbose;
		aWriteOP.queuePriority	= aPriority;
		[ORSNMPQueue addOperation:aWriteOP];
		[aWriteOP release];
	}
}

- (void) callBackToTarget:(id)aTarget selector:(SEL)aSelector userInfo:(id)userInfo
{
	//just a fancy way to sync something back in the target with activities in the queue
	ORSNMPCallBackOperation* anOP = [[ORSNMPCallBackOperation alloc] initWithDelegate:self];
	anOP.target		= aTarget;
	anOP.userInfo	= userInfo;
	anOP.selector	= aSelector;
	anOP.verbose	= verbose;
	[ORSNMPQueue addOperation:anOP];
	[anOP release];
	
}

#pragma mark ¥¥¥Tasks
- (void) taskFinished:(NSTask*)aTask
{
	if(aTask == pingTask){
		[pingTask release];
		pingTask = nil;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORMPodCPingTask object:self];
	}
}

- (void) ping
{
	if(!pingTask){
		ORTaskSequence* aSequence = [ORTaskSequence taskSequenceWithDelegate:self];
		pingTask = [[NSTask alloc] init];
		
		[pingTask setLaunchPath:@"/sbin/ping"];
		[pingTask setArguments: [NSArray arrayWithObjects:@"-c",@"5",@"-t",@"10",@"-q",IPNumber,nil]];
		
		[aSequence addTaskObj:pingTask];
		[aSequence setVerbose:YES];
		[aSequence setTextToDelegate:YES];
		[aSequence launch];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORMPodCPingTask object:self];
	}
	else {
		[pingTask terminate];
	}
}

- (BOOL) pingTaskRunning
{
	return pingTask != nil;
}

- (void) tasksCompleted:(id)sender
{
}

- (void) taskData:(NSString*)text
{
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object 
                         change:(NSDictionary *)change context:(void *)context
{
	NSOperationQueue* queue = [[ORSNMPQueue sharedSNMPQueue] queue];
    if (object == queue && [keyPath isEqual:@"operationCount"]) {
		NSNumber* n = [NSNumber numberWithInt:[[[ORSNMPQueue queue] operations] count]];
		[self performSelectorOnMainThread:@selector(setQueCount:) withObject:n waitUntilDone:NO];
		if ([[queue operations] count] == 0) {
			[self performSelectorOnMainThread:@selector(pollHardwareAfterDelay) withObject:nil waitUntilDone:NO];
		}
	}
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void) setQueCount:(NSNumber*)n
{
	queueCount = [n intValue];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMPodCQueueCountChanged object:self];
}

#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];
	[[self undoManager] disableUndoRegistration];
	
	[self initConnectionHistory];
	[self setIPNumber:		[decoder decodeObjectForKey:@"IPNumber"]];
	[[self undoManager] enableUndoRegistration];
	return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
	[super encodeWithCoder:encoder];
 	[encoder encodeObject:IPNumber		forKey:@"IPNumber"];
}

@end


@implementation ORHvUrlParseOp

@synthesize ipAddress,delegate;

- (id) initWithDelegate:(id)aDelegate
{
    self = [super init];
	delegate = aDelegate;
    return self;
}

- (void) dealloc
{        	
    self.ipAddress      = nil;    
    self.delegate      = nil;    
    [super dealloc];
}

- (void) main
{
    if([self isCancelled])return;
    
    NSError * error = nil;
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@",ipAddress]];
    NSStringEncoding usedEncoding;
    NSString* htmlString = [NSString stringWithContentsOfURL:url
                                                usedEncoding:&usedEncoding
                                                       error:&error];
	
    NSMutableArray* tables = [NSString extractArrayFromString:htmlString
                                                     startTag:@"<table"
                                                       endTag:@"</table>"];
    
    //should be three tables
    //don't care about the first one. just process the last two
    if([tables count] == 3){
        [self processSystemTable: [tables objectAtIndex:1]];
		if([delegate respondsToSelector:@selector(setDictionaryFromWebPage:)]){
			[delegate setDictionaryFromWebPage: [self processHVTable:     [tables objectAtIndex:2]]];
		}
    }
}

- (void) processSystemTable:(NSString*)aTable
{
    
}

- (NSMutableDictionary*) processHVTable:(NSString*)aTable
{
	NSDictionary* translateDict = [NSDictionary dictionaryWithObjectsAndKeys:
								  @"outputSwitch",					@"outputStatus",
								  @"outputCurrent",					@"Measured Current",
								  @"outputVoltage",					@"Voltage",
								  @"outputMeasurementSenseVoltage",	@"Measured Sense Voltage",
								  nil];
								  
	NSMutableDictionary* HVDictionary = [NSMutableDictionary dictionary];
	
	//pull out the HV param names from the table header
	NSString* header = [NSString scanString:aTable
								   startTag:@"<thead"
									 endTag:@"</thead>"];
	NSMutableArray* paramNames = [NSString extractArrayFromString:header
														 startTag:@"<th"
														   endTag:@"</th>"];
	
	NSUInteger numParamsNames = [paramNames count];
	if(numParamsNames){
		
		NSArray* paramRows= [NSString extractArrayFromString:aTable
													startTag:@"<tr"
													  endTag:@"</tr>"];
		for(id aRow in paramRows){
			
			NSArray* itemArray = [NSString extractArrayFromString:aRow
														 startTag:@"<td"
														   endTag:@"</td>"];
			
			NSUInteger numItems = [itemArray count];
			if(numItems == numParamsNames){
				NSMutableDictionary* channelDictionary = [NSMutableDictionary dictionary];
				
				NSUInteger i;
				for(i=0;i<numItems;i++){
					NSString* key   = [paramNames objectAtIndex:i];
					NSString* value = [itemArray objectAtIndex:i];
					if([key isEqualToString:@"Channel"]){
						value = [[value removeSpaces] lowercaseString];
						[channelDictionary setObject:value forKey:@"ChannelSlotId"];
						int num		=  [[value substringFromIndex:1] intValue];
						int slot	= num/100 + 1;
						int channel = num%100;
						[channelDictionary setObject:[NSNumber numberWithInt:slot]    forKey:@"Slot"];
						[channelDictionary setObject:[NSNumber numberWithInt:channel] forKey:@"Channel"];
					}
					else {
						id translatedKey = [translateDict objectForKey:key];
						if(translatedKey)key = translatedKey;
						value = [value removeExtraSpaces];

						[channelDictionary setObject:value forKey:key];
					}
					
				}
				[HVDictionary setObject:channelDictionary forKey:[channelDictionary objectForKey:@"ChannelSlotId"]];
			}
		}
	}
	return HVDictionary;
}

@end