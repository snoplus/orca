//
//  SNOModel.m
//  Orca
//
//  Created by H S  Wan Chan Tseung on 11/18/11.
//  Copyright (c) 2011 CENPA, University of Washington. All rights reserved.
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
#import "SNOModel.h"
#import "ORAxis.h"
#import "ORDataPacket.h"
#import "ORRunModel.h"
#import "OrcaObject.h"
#import "YAJL/YAJL.h"

NSString* ORSNORateColorBarChangedNotification      = @"ORSNORateColorBarChangedNotification";
NSString* ORSNOChartXChangedNotification            = @"ORSNOChartXChangedNotification";
NSString* ORSNOChartYChangedNotification            = @"ORSNOChartYChangedNotification";
NSString* slowControlTableChanged					= @"slowControlTableChanged";
NSString* slowControlConnectionStatusChanged		= @"slowControlConnectionStatusChanged";
NSString* morcaDBRead								= @"morcaDBRead";

@interface SNOModel (private)
- (void) _setUpPolling;
@end

@implementation SNOModel

#pragma mark •••Initialization

- (id) init //designated initializer
{
    self = [super init];

    colorBarAttributes = [[NSMutableDictionary dictionary] retain];
    [colorBarAttributes setObject:[NSNumber numberWithDouble:0] forKey:ORAxisMinValue];
    [colorBarAttributes setObject:[NSNumber numberWithDouble:10000] forKey:ORAxisMaxValue];
    [colorBarAttributes setObject:[NSNumber numberWithBool:NO] forKey:ORAxisUseLog];
    
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	
    [colorBarAttributes release];
    [xAttributes release];
    [yAttributes release];
	[db release];
    [super dealloc];
}

- (void) wakeUp
{
    if([self aWake])return;
    [super wakeUp];
}

- (void) sleep
{
    [super sleep];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"SNO"]];
}

- (void) makeMainController
{
    [self linkToController:@"SNOController"];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(runStatusChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(runAboutToStart:)
                         name : ORRunAboutToStartNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(runEnded:)
                         name : ORRunStoppedNotification
                       object : nil];
	
}



- (void) runStatusChanged:(NSNotification*)aNote
{
    int running = [[[aNote userInfo] objectForKey:ORRunStatusValue] intValue];
    if(running == eRunStopped){
        //[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(collectRates) object:nil];
        //[[self detector] unregisterRates];
    }
    else {
    }
}


#pragma mark •••Accessors
- (NSMutableDictionary*) colorBarAttributes
{
    return colorBarAttributes;
}
- (void) setColorBarAttributes:(NSMutableDictionary*)newColorBarAttributes
{
    [[[self undoManager] prepareWithInvocationTarget:self] setColorBarAttributes:colorBarAttributes];
    
    [newColorBarAttributes retain];
    [colorBarAttributes release];
    colorBarAttributes=newColorBarAttributes;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORSNORateColorBarChangedNotification
	 object:self];
    
}

- (NSDictionary*)   xAttributes
{
    return xAttributes;
}

- (NSDictionary*)   yAttributes
{
    return yAttributes;
}

- (void) setYAttributes:(NSDictionary*)someAttributes
{
    [yAttributes release];
    yAttributes = [someAttributes copy];
}

- (void) setXAttributes:(NSDictionary*)someAttributes
{
    [xAttributes release];
    xAttributes = [someAttributes copy];
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    
    [self setColorBarAttributes:[decoder decodeObjectForKey:@"colorBarAttributes"]];
    [self setXAttributes:[decoder decodeObjectForKey:@"xAttributes"]];
    [self setYAttributes:[decoder decodeObjectForKey:@"yAttributes"]];
    

	
    [[self undoManager] enableUndoRegistration];
    
    [self registerNotificationObservers];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    
    [encoder encodeObject:colorBarAttributes forKey:@"colorBarAttributes"];
    [encoder encodeObject:xAttributes forKey:@"xAttributes"];
    [encoder encodeObject:yAttributes forKey:@"yAttributes"];
    
}



- (void) runAboutToStart:(NSNotification*)aNote
{
}

- (void) runEnded:(NSNotification*)aNote
{		
}

//monitor
- (void) getDataFromMorca
{
	if (db) [db release];
	db = [SNOMonitoredHardware sharedSNOMonitoredHardware];
	[db readXL3StateDocumentFromMorca];
	NSLog(@"cmosrate polled %f\n",[db cmosRate:0 card:0 channel:0]);
	[[NSNotificationCenter defaultCenter] postNotificationName:morcaDBRead object:self];
	
	if (xl3PollingState !=0 && pollXl3) 
		[self performSelector:@selector(getDataFromMorca) withObject:nil afterDelay:xl3PollingState];
}

- (void) setXl3Polling:(int)aState
{
	xl3PollingState = aState;
}

- (void) startXl3Polling
{   
	if (xl3PollingState == 0){
		NSLog(@"polling Morca once\n");
		pollXl3 = false;
		[self getDataFromMorca];
	} else if (xl3PollingState > 0 && !pollXl3){
		NSLog(@"Polling from Morca database...\n");
		pollXl3 = true;
		[self performSelector:@selector(getDataFromMorca) withObject:nil afterDelay:xl3PollingState];
	}
}

- (void) stopXl3Polling
{
	pollXl3 = false;
	NSLog(@"Stopped polling Morca database\n");
}

//slow control
- (void) setSlowControlPolling:(int)aState
{
	slowControlPollingState = aState;
}

- (void) startSlowControlPolling
{
	if (slowControlPollingState > 0 && !pollSlowControl){
		NSLog(@"Monitoring slow control...\n");
		pollSlowControl = true;
		
		[self performSelector:@selector(readAllVoltagesFromIOServers) 
				   withObject:nil afterDelay:slowControlPollingState];
	}
}

- (void) stopSlowControlPolling
{
	pollSlowControl = false;
	NSLog(@"Stopped monitoring slow control\n");
}

- (void) connectToIOServer
{   
	//NSLog(@"Connecting to IO servers...\n");
	NSString *aString=[[NSString alloc] initWithString:@"Connecting..."];
	[self setSlowControlMonitorStatusString:aString];
	[self setSlowControlMonitorStatusStringColor:[NSColor blackColor]];
	[[NSNotificationCenter defaultCenter] postNotificationName:slowControlConnectionStatusChanged object:self];

	if (tableEntries) [tableEntries release];
	tableEntries = [[NSMutableArray alloc] initWithCapacity:kNumSlowControlParameters];	

	pollSlowControl=false;
	
	//get parameter name list, including units and display indices
	NSHTTPURLResponse *response = nil;
	NSError *connectionError = [[NSError alloc] init];
	
	NSString *urlName=[[NSString alloc] initWithFormat:@"http://localhost:5984/slow_control/_design/testdesign/_list/testlist/collatedview?include_docs=true"];	
	NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:urlName]];	
	NSData *responseData = [[NSData alloc] initWithData:[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&connectionError]];
    NSString *jsonStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
	NSDictionary *jsonSlowControlVariablesView = [[NSDictionary alloc] initWithDictionary:[jsonStr yajl_JSON]];
	NSArray *slowControlVariablesView = [[NSArray alloc] initWithArray:[jsonSlowControlVariablesView objectForKey:@"rows"]];
	
	int i;
	for(i=0;i<[[jsonSlowControlVariablesView objectForKey:@"total_rows"] intValue];++i){
		SNOSlowControl *slowControlEntry = [[SNOSlowControl alloc] init];
		[slowControlEntry setParameterNumber:[[[slowControlVariablesView objectAtIndex:i] objectForKey:@"key"] intValue]];
	    [slowControlEntry setParameterName:[[[slowControlVariablesView objectAtIndex:i] objectForKey:@"value"] objectAtIndex:0]];
		[slowControlEntry setUnits:[[[slowControlVariablesView objectAtIndex:i] objectForKey:@"value"] objectAtIndex:5]];
		[slowControlEntry setLoThresh:[[[[slowControlVariablesView objectAtIndex:i] objectForKey:@"value"] objectAtIndex:7] floatValue]];
		[slowControlEntry setHiThresh:[[[[slowControlVariablesView objectAtIndex:i] objectForKey:@"value"] objectAtIndex:8] floatValue]];
		[slowControlEntry setLoLoThresh:[[[[slowControlVariablesView objectAtIndex:i] objectForKey:@"value"] objectAtIndex:6] floatValue]];
		[slowControlEntry setHiHiThresh:[[[[slowControlVariablesView objectAtIndex:i] objectForKey:@"value"] objectAtIndex:9] floatValue]];	
		[slowControlEntry setCardName:[[[slowControlVariablesView objectAtIndex:i] objectForKey:@"value"] objectAtIndex:2]];
		[slowControlEntry setChannelNumber:[[[[slowControlVariablesView objectAtIndex:i] objectForKey:@"value"] objectAtIndex:3] intValue]];
		[slowControlEntry setParameterEnabled:YES];
		[slowControlEntry setParameterConnected:YES];
		[slowControlEntry setIPAddress:[[[slowControlVariablesView objectAtIndex:i] objectForKey:@"value"] objectAtIndex:11]];
		[slowControlEntry setPort:[[[[slowControlVariablesView objectAtIndex:i] objectForKey:@"value"] objectAtIndex:12] intValue]];
		[slowControlEntry setIosName:[[[slowControlVariablesView objectAtIndex:i] objectForKey:@"value"] objectAtIndex:1]];
		[slowControlEntry setIoChannelDocId:[[[slowControlVariablesView objectAtIndex:i] objectForKey:@"value"] objectAtIndex:4]];
		[tableEntries insertObject:slowControlEntry atIndex:i];
		[slowControlEntry release];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:slowControlTableChanged object:self];

	[aString release];
	[jsonStr release];
	[responseData release];
	[slowControlVariablesView release];
	[jsonSlowControlVariablesView release];
	[urlName release];
	[request release];
	//[response release];
	[connectionError release];
	
	// Now establish and monitor voltages according to polling frequency.
	[self readAllVoltagesFromIOServers];
}

- (void) readAllVoltagesFromIOServers
{
	//read data from all IOS, cards and store in dictionary.
	NSURLRequest *request;
	NSHTTPURLResponse *response;
	NSError *connectionError;
	NSString *urlName, *keyname, *cardLetter;
	NSData *responseData;
	
	urlName=[NSString stringWithFormat:@"http://localhost:5984/slow_control/_design/testdesign/_view/iocardview"];
	request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlName]];
	responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&connectionError];
	NSString *jsonStr1 = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
	NSDictionary *jsonCard = [jsonStr1 yajl_JSON];
	[jsonStr1 release];
	NSArray *cardRows = [jsonCard objectForKey:@"rows"]; 		
	
	urlName=[NSString stringWithFormat:@"http://localhost:5984/slow_control/_design/testdesign/_view/ioserverview"];
	request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlName]];
	responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&connectionError];
	NSString *jsonStr2 = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
	NSDictionary *jsonServer = [jsonStr2 yajl_JSON];
	[jsonStr2 release];
	NSArray *serverRows = [jsonServer objectForKey:@"rows"];
	
	NSMutableDictionary *allIosData = [[NSMutableDictionary alloc] init];
	NSMutableDictionary *allIosConfig = [[NSMutableDictionary alloc] init];
	
	int i, j;
	for(i=0;i<[[jsonCard objectForKey:@"total_rows"] intValue];++i){
		NSString *hostid, *hostname;
		cardLetter=[[[cardRows objectAtIndex:i] objectForKey:@"value"] objectForKey:@"cardname"];
		hostid=[[[cardRows objectAtIndex:i] objectForKey:@"value"] objectForKey:@"hostid"];
		
		for(j=0;j<[[jsonServer objectForKey:@"total_rows"] intValue];++j){
			if([hostid isEqualToString:[[serverRows objectAtIndex:j] valueForKey:@"id"]]){
				hostname=[[[serverRows objectAtIndex:j] objectForKey:@"value"] valueForKey:@"hostname"];
				urlName=[NSString stringWithFormat:@"http://%@:%i/data/card%@/",
						 [[[serverRows objectAtIndex:j] objectForKey:@"value"] valueForKey:@"ipaddr"],
						 [[[[serverRows objectAtIndex:j] objectForKey:@"value"] valueForKey:@"wmport"] intValue],
						 cardLetter];
				request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlName]];
				responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&connectionError];
				NSString *jsonStr3 = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
				keyname =[NSString stringWithFormat:@"%@%@",hostname,cardLetter];
				NSDictionary *json = [jsonStr3 yajl_JSON];
				[jsonStr3 release];
				
				if (json != nil) {
					NSString *aString=[NSString stringWithString:@"Connection established."];
					[self setSlowControlMonitorStatusString:aString];
					[self setSlowControlMonitorStatusStringColor:[NSColor blueColor]];
					[[NSNotificationCenter defaultCenter] postNotificationName:slowControlConnectionStatusChanged object:self];
				} else if (json == nil) {
					NSString *aString=[NSString stringWithString:@"Connection failed."];
					[self setSlowControlMonitorStatusString:aString];	
					[self setSlowControlMonitorStatusStringColor:[NSColor redColor]];
					[[NSNotificationCenter defaultCenter] postNotificationName:slowControlConnectionStatusChanged object:self];
				}					
				
				[allIosData setObject:json forKey:keyname];	
				
				urlName=[NSString stringWithFormat:@"http://%@:%i/config/card%@/",
						 [[[serverRows objectAtIndex:j] objectForKey:@"value"] valueForKey:@"ipaddr"],
						 [[[[serverRows objectAtIndex:j] objectForKey:@"value"] valueForKey:@"wmport"] intValue],
						 cardLetter];
				request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlName]];
				responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&connectionError];
				NSString* jsonStr4 = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];			
				[allIosConfig setObject:[jsonStr4 yajl_JSON] forKey:keyname];
				[jsonStr4 release];
			}			
		}
	}
	
	//now display the data into table entries
	NSString *channelName, *cardName;
	for(i=0;i<[tableEntries count];++i){
		if ([[tableEntries objectAtIndex:i] parameterEnabled] && [[tableEntries objectAtIndex:i] parameterConnected]) {
			channelName = [NSString stringWithFormat:@"channel%i",[[tableEntries objectAtIndex:i] parameterChannel]];
			cardName = [NSString stringWithFormat:@"card%@",[[tableEntries objectAtIndex:i] parameterCard]];
			keyname = [NSString stringWithFormat:@"%@%@",[[tableEntries objectAtIndex:i] parameterIos],[[tableEntries objectAtIndex:i] parameterCard]];
			float channelVoltage = [[[[[allIosData objectForKey:keyname] objectForKey:cardName] objectForKey:channelName] objectForKey:@"voltage"] floatValue];
			float channelGain = [[[[[allIosConfig objectForKey:keyname] objectForKey:cardName] objectForKey:channelName] objectForKey:@"gain"] floatValue];
			[[tableEntries objectAtIndex:i] setParameterValue:channelVoltage];
			[[tableEntries objectAtIndex:i] setChannelGain:channelGain];
			
			if (channelVoltage > [[tableEntries objectAtIndex:i] parameterLoThreshold] 
				&& channelVoltage < [[tableEntries objectAtIndex:i] parameterHiThreshold]) {
				[[tableEntries objectAtIndex:i] setStatus:@"OK"];
			}else if (channelVoltage > [[tableEntries objectAtIndex:i] parameterHiThreshold] 
					  && channelVoltage < [[tableEntries objectAtIndex:i] parameterHiHiThreshold]) {
				[[tableEntries objectAtIndex:i] setStatus:@"Hi"];
			}else if (channelVoltage > [[tableEntries objectAtIndex:i] parameterHiHiThreshold]) {
				[[tableEntries objectAtIndex:i] setStatus:@"HiHi"];
			}else if (channelVoltage < [[tableEntries objectAtIndex:i] parameterLoThreshold] 
					  && channelVoltage > [[tableEntries objectAtIndex:i] parameterLoLoThreshold]) {
				[[tableEntries objectAtIndex:i] setStatus:@"Lo"];
			}else if (channelVoltage < [[tableEntries objectAtIndex:i] parameterLoLoThreshold]) {
				[[tableEntries objectAtIndex:i] setStatus:@"LoLo"];
			}			
		}else{
			[[tableEntries objectAtIndex:i] setParameterValue:nan("")];
			[[tableEntries objectAtIndex:i] setStatus:@"disabled"];
		}
	}	
	[[NSNotificationCenter defaultCenter] postNotificationName:slowControlTableChanged object:self];
	
	[allIosData release];
	[allIosConfig release];
	
	//poll according to delay specified by user
	if (slowControlPollingState !=0 && pollSlowControl) 
		[self performSelector:@selector(readAllVoltagesFromIOServers) withObject:nil afterDelay:slowControlPollingState];	
}

- (void) setSlowControlParameterThresholds
{
	NSError *connectionError;
    NSHTTPURLResponse *response;

	NSLog(@"setting thresholds\n");
	
 	int i;
	for(i=0;i<[tableEntries count];++i){
        NSMutableDictionary *copiedFile; 
		BOOL isSelected=[[[tableEntries objectAtIndex:i] valueForKey:@"parameterSelected"] boolValue];
		if (isSelected){
			NSString* urlName=[NSString stringWithFormat:@"http://localhost:5984/slow_control/%@",[[tableEntries objectAtIndex:i] parameterIoChannelDocId]];
			NSMutableURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlName]];
			NSData* responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&connectionError];
			NSString *jsonStr1 = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
			copiedFile = [[(NSDictionary *)[jsonStr1 yajl_JSON] mutableCopy] autorelease];			
			[jsonStr1 release];
			
			NSNumber *lothresholdValue = [[NSNumber alloc] initWithFloat:[[tableEntries objectAtIndex:i] parameterLoThreshold]];
			[copiedFile setObject:lothresholdValue forKey:@"lothresh"];
			[lothresholdValue release];
			NSNumber *hithresholdValue = [[NSNumber alloc] initWithFloat:[[tableEntries objectAtIndex:i] parameterHiThreshold]];					 
			[copiedFile setObject:hithresholdValue forKey:@"hithresh"];
			[hithresholdValue release];
			NSNumber *lolothresholdValue = [[NSNumber alloc] initWithFloat:[[tableEntries objectAtIndex:i] parameterLoLoThreshold]];					 
			[copiedFile setObject:lolothresholdValue forKey:@"lolothresh"];
			[lolothresholdValue release];
			NSNumber *hihithresholdValue = [[NSNumber alloc] initWithFloat:[[tableEntries objectAtIndex:i] parameterHiHiThreshold]];	
			[copiedFile setObject:hihithresholdValue forKey:@"hihithresh"];
			[hihithresholdValue release];
			[copiedFile removeObjectForKey:@"_rev"];
			
			NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
			NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
			[dateFormatter setTimeZone:timeZone];
			[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
			NSDate *now = [NSDate date];
			NSString *dateString = [dateFormatter stringFromDate:now];
			[dateFormatter release];	
			NSNumber *timestamp=[[[NSNumber alloc] initWithInt:[now timeIntervalSince1970]] autorelease];
			[copiedFile setObject:dateString forKey:@"datetime"];
			[copiedFile setObject:timestamp forKey:@"timestamp"];
			NSLog(@"%f %i\n",FLT_MAX, INT_MAX);
			
			//get new id for doc with changed threshold
			urlName=[NSString stringWithFormat:@"http://localhost:5984/_uuids"];
			request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlName]];
			responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&connectionError];
			NSString *jsonStr2 = [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease];
			NSString* uuidstr=[NSString stringWithString:[[[jsonStr2 yajl_JSON] objectForKey:@"uuids"] objectAtIndex:0]];
			[copiedFile setObject:uuidstr forKey:@"_id"];
			jsonStr2=[copiedFile yajl_JSONString];
			NSData* postBody=[jsonStr2 dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
			
			urlName=[NSString stringWithFormat:@"http://localhost:5984/slow_control/%@",uuidstr];
			NSMutableURLRequest *sendrequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlName]];
			[sendrequest setValue:@"application/json" forHTTPHeaderField: @"Content-Type"];
			[sendrequest setValue:[NSString stringWithFormat:@"%d", [postBody length]] forHTTPHeaderField:@"Content-Length"];
			[sendrequest setHTTPMethod:@"PUT"];
			[sendrequest setHTTPBody:postBody];
			responseData=[NSURLConnection sendSynchronousRequest:sendrequest returningResponse:&response error:&connectionError];		
			
			//NSString *path = @"/Users/wan/Orca/dev/Orca/Source/Experiments/SNO/testchannelwrite.json";
			//[jsonStr writeToFile:path atomically:YES];
		}
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:slowControlTableChanged object:self];
}

- (void) setSlowControlChannelGain
{
	NSHTTPURLResponse *response;
	NSError *connectionError;
	
	NSLog(@"setting gain\n");
	
 	int i;
	for(i=0;i<[tableEntries count];++i){
        NSMutableDictionary *copiedFile; 
		BOOL isSelected=[[[tableEntries objectAtIndex:i] valueForKey:@"parameterSelected"] boolValue];
		if (isSelected){
			NSString* channelName = [NSString stringWithFormat:@"channel%i",[[tableEntries objectAtIndex:i] parameterChannel]];
			NSString* cardName = [NSString stringWithFormat:@"card%@",[[tableEntries objectAtIndex:i] parameterCard]];
			
			NSString* urlName=[NSString stringWithFormat:@"http://%@:%i/config/card%@/",
					 [[tableEntries objectAtIndex:i] IPAddress],
					 [[tableEntries objectAtIndex:i] Port],
					 [[tableEntries objectAtIndex:i] parameterCard]];
			NSMutableURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlName]];
			NSData* responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&connectionError];
			NSString* jsonStr = [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease];
			copiedFile = [[(NSDictionary *)[jsonStr yajl_JSON] mutableCopy] autorelease];			
			
			NSNumber* gainValue = [[[NSNumber alloc] initWithFloat:[[tableEntries objectAtIndex:i] parameterGain]]autorelease];
			[[[copiedFile objectForKey:cardName] objectForKey:channelName] setObject:gainValue forKey:@"gain"];
			
			jsonStr=[copiedFile yajl_JSONString];
			NSData* postBody=[jsonStr dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
			
			NSMutableURLRequest* sendrequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlName]];
			[sendrequest setValue:@"application/json" forHTTPHeaderField: @"Content-Type"];
			[sendrequest setValue:[NSString stringWithFormat:@"%d", [postBody length]] forHTTPHeaderField:@"Content-Length"];
			[sendrequest setHTTPMethod:@"POST"];
			[sendrequest setHTTPBody:postBody];
			responseData=[NSURLConnection sendSynchronousRequest:sendrequest returningResponse:&response error:&connectionError];		
			
			//NSString *path = @"/Users/wan/Orca/dev/Orca/Source/Experiments/SNO/testchannelgainwrite.json";
			//[jsonStr writeToFile:path atomically:YES];
		}
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:slowControlTableChanged object:self];
}

- (void) enableSlowControlParameter
{
	int i;
	for(i=0;i<kNumSlowControlParameters;++i){
		BOOL isSelected=[[[tableEntries objectAtIndex:i] valueForKey:@"parameterSelected"] boolValue];
		if (isSelected && ![[tableEntries objectAtIndex:i] parameterEnabled] ){
			[[tableEntries objectAtIndex:i] setParameterEnabled:YES];
		}else if (isSelected && [[tableEntries objectAtIndex:i] parameterEnabled] ) {
			[[tableEntries objectAtIndex:i] setParameterEnabled:NO];
		}
	}
}

//obsolete - has to be updated.
- (void) setSlowControlMapping
{
	NSString *jsonStr = [NSString stringWithContentsOfFile:@"/Users/Wan/Orca/Source/Experiments/SNO/testCard.json" 
												  encoding:NSUTF8StringEncoding error:nil];
	NSMutableDictionary *copiedFile = [[(NSDictionary *)[jsonStr yajl_JSON] mutableCopy] autorelease];	
	
	NSString *cardLetter;
	NSMutableString *cardName, *channelName;
	NSDictionary *card, *channel;
	NSNumber *Value;
	
	int i, j, ichan, channelNumber;
	for(i=0;i<kNumSlowControlParameters;++i){
		BOOL isSelected=[[[tableEntries objectAtIndex:i] valueForKey:@"parameterSelected"] boolValue];
		if (isSelected){
			//get card and channel displayed in table
			cardLetter=[[tableEntries objectAtIndex:i] parameterCard];
			channelNumber=[[tableEntries objectAtIndex:i] parameterChannel];
			cardName=[NSMutableString stringWithString:@"card"];
			channelName=[NSMutableString stringWithString:@"channel"];		
			[cardName appendString:[NSString stringWithFormat:@"%@",cardLetter]];
			[channelName appendString:[NSString stringWithFormat:@"%i",channelNumber]];
			
			//set parameter connected bit to yes
			[[tableEntries objectAtIndex:i] setParameterConnected:YES];
			
			//new channel's deprecated parameter in latest db has to be disconnected
			//get channel's previous parameter index
			int oldparameterindex=[[[[copiedFile objectForKey:cardName] objectForKey:channelName] objectForKey:@"index"] intValue];
			//if the channel was previously associated to a parameter, dissociate the latter from it
			if (oldparameterindex > 0 && [[tableEntries objectAtIndex:oldparameterindex-1] parameterConnected]
				&& ![[tableEntries objectAtIndex:oldparameterindex-1] parameterSelected]){
				[[tableEntries objectAtIndex:oldparameterindex-1] setParameterConnected:NO];
				[[tableEntries objectAtIndex:oldparameterindex-1] setCardName:@"N/A"];
				[[tableEntries objectAtIndex:oldparameterindex-1] setChannelNumber:0];
				//[[tableEntries objectAtIndex:oldparameterindex-1] setChannelGain:0.0];
			}
			
			//selected variable's deprecated channel in latest db has to be emptied.
			//loop through to find card and channel that was previously associated to parameter.
			for(j=65;j<65+kMaxNumCards;++j){
				NSString *cardLetter2=[NSString stringWithFormat:@"%c", j];
				NSMutableString *cardName2=[NSMutableString stringWithString:@"card"];
				[cardName2 appendString:[NSString stringWithFormat:@"%@",cardLetter2]];
				for(ichan=0;ichan<kMaxNumChannels;++ichan){
					NSMutableString *channelName2=[NSMutableString stringWithString:@"channel"];			
					[channelName2 appendString:[NSString stringWithFormat:@"%i",ichan+1]];
					
					card = [copiedFile objectForKey:cardName2];
					channel = [copiedFile objectForKey:channelName2];
					
					if([[[[copiedFile objectForKey:cardName2] objectForKey:channelName2] objectForKey:@"index"] intValue] == i+1){
						//if found, reset the channel and don't associate it to any slow control parameter
						[[[copiedFile objectForKey:cardName2] objectForKey:channelName2] setObject:@"" forKey:@"name"];
						[[[copiedFile objectForKey:cardName2] objectForKey:channelName2] setObject:@"" forKey:@"units"];
						Value=[[NSNumber alloc] initWithFloat:0.0];
						[[[copiedFile objectForKey:cardName2] objectForKey:channelName2] setObject:Value forKey:@"conversion factor"];
						[[[copiedFile objectForKey:cardName2] objectForKey:channelName2] setObject:Value forKey:@"lo threshold"];
						[[[copiedFile objectForKey:cardName2] objectForKey:channelName2] setObject:Value forKey:@"hi threshold"];
						[[[copiedFile objectForKey:cardName2] objectForKey:channelName2] setObject:Value forKey:@"lolo threshold"];
						[[[copiedFile objectForKey:cardName2] objectForKey:channelName2] setObject:Value forKey:@"hihi threshold"];
						[[[copiedFile objectForKey:cardName2] objectForKey:channelName2] setObject:@"" forKey:@"status"];
						Value=[[NSNumber alloc] initWithInt:-1];
						[[[copiedFile objectForKey:cardName2] objectForKey:channelName2] setObject:Value forKey:@"index"];
					}
				}
				
			}
			
			//set parameter's properties to selected channel
			[[[copiedFile objectForKey:cardName] objectForKey:channelName] 
			 setObject:[[tableEntries objectAtIndex:i] parameterName] forKey:@"name"];
			[[[copiedFile objectForKey:cardName] objectForKey:channelName] 
			 setObject:[[tableEntries objectAtIndex:i] parameterUnits] forKey:@"units"];		
			Value = [[NSNumber alloc] initWithFloat:[[tableEntries objectAtIndex:i] parameterLoThreshold]];
			[[[copiedFile objectForKey:cardName] objectForKey:channelName] setObject:Value forKey:@"lo threshold"];
			Value = [[NSNumber alloc] initWithFloat:[[tableEntries objectAtIndex:i] parameterHiThreshold]];
			[[[copiedFile objectForKey:cardName] objectForKey:channelName] setObject:Value forKey:@"hi threshold"];
			Value = [[NSNumber alloc] initWithFloat:[[tableEntries objectAtIndex:i] parameterLoLoThreshold]];
			[[[copiedFile objectForKey:cardName] objectForKey:channelName] setObject:Value forKey:@"lolo threshold"];
			Value = [[NSNumber alloc] initWithFloat:[[tableEntries objectAtIndex:i] parameterHiHiThreshold]];
			[[[copiedFile objectForKey:cardName] objectForKey:channelName] setObject:Value forKey:@"hihi threshold"];
			Value = [[NSNumber alloc] initWithFloat:[[tableEntries objectAtIndex:i] parameterGain]];
			[[[copiedFile objectForKey:cardName] objectForKey:channelName] setObject:Value forKey:@"gain"];
			Value = [[NSNumber alloc] initWithInt:i+1]; //[NSNumber numberWithInteger:i+1];
			[[[copiedFile objectForKey:cardName] objectForKey:channelName] setObject:Value forKey:@"index"];
			//NSLog(@"test %i %@ %@ %@ %i %i\n",i,[[tableEntries objectAtIndex:i] parameterName],
			//	  cardName,channelName,
			//	  [[[[copiedFile objectForKey:cardName] objectForKey:channelName] objectForKey:@"index"] intValue],
			//	  oldparameterindex);
		}
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:slowControlTableChanged object:self];
	
	//NSString *path = @"/Users/wan/Orca/Source/Experiments/SNO/testCard.json";
	//[[copiedFile yajl_JSONString] writeToFile:path atomically:YES];	
}

- (SNOSlowControl *) getSlowControlVariable:(int)index
{
	return [tableEntries objectAtIndex:index];
}

- (void) setSlowControlMonitorStatusString:(NSString *)aString
{
	[aString retain];
	[slowControlMonitorStatusString release];
	slowControlMonitorStatusString = aString;
}

- (void) setSlowControlMonitorStatusStringColor:(NSColor *)aColor
{
	slowControlMonitorStatusStringColor = aColor;
}

- (NSString *) getSlowControlMonitorStatusString
{
	return slowControlMonitorStatusString;
}

- (NSColor *) getSlowControlMonitorStatusStringColor
{
	return slowControlMonitorStatusStringColor;
}

@end


