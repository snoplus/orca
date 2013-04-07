//
//  HaloModel.m
//  Orca
//
//  Created by Mark Howe on Tue Jun 28 2005.
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
#import "HaloModel.h"
#import "HaloController.h"
#import "ORSegmentGroup.h"
#import "HaloSentry.h"
#import "ORMailer.h"

NSString* HaloModelHaloSentryChanged     = @"HaloModelHaloSentryChanged";
NSString* HaloModelViewTypeChanged       = @"HaloModelViewTypeChanged";
NSString* HaloModelSentryLock            = @"HaloModelSentryLock";
NSString* HaloModelEmailListChanged		 = @"HaloModelEmailListChanged";
NSString* HaloModelHeartBeatIndexChanged = @"HaloModelHeartBeatIndexChanged";
NSString* HaloModelNextHeartBeatChanged	 = @"HaloModelNextHeartBeatChanged";

static NSString* HaloDbConnector		= @"HaloDbConnector";

@implementation HaloModel

#pragma mark ¥¥¥Initialization

- (void) dealloc
{
    [emailList release];
    [haloSentry release];
	[nextHeartbeat release];
    [super dealloc];
}
- (void) sleep
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    [haloSentry sleep];
    [super sleep];
}

- (void) wakeUp
{
	[super wakeUp];
    [haloSentry wakeUp];
	if([self heartbeatSeconds]){
		[self performSelector:@selector(sendHeartbeat) withObject:nil afterDelay:[self heartbeatSeconds]];
	}
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"Halo"]];
}

- (void) awakeAfterDocumentLoaded
{
    [super awakeAfterDocumentLoaded];
    [haloSentry awakeAfterDocumentLoaded];
}

- (void) makeMainController
{
    [self linkToController:@"HaloController"];
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:HaloDbConnector];
    [aConnector setOffColor:[NSColor brownColor]];
    [aConnector setOnColor:[NSColor magentaColor]];
	[ aConnector setConnectorType: 'DB O' ];
	[ aConnector addRestrictedConnectionType: 'DB I' ]; //can only connect to DB outputs
    [aConnector release];
}

//- (NSString*) helpURL
//{
//	return @"Halo/Index.html";
//}

- (NSMutableArray*) setupMapEntries:(int) index
{
    [self setCrateIndex:6]; //default is no crate
	if(index==0){
        //default set -- subsclasses can override. first four items and the VME crate should not be moved
        NSMutableArray* mapEntries = [NSMutableArray array];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kSegmentNumber",	@"key", [NSNumber numberWithInt:0], @"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kCardSlot",      @"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kChannel",		@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kNCD",           @"key", [NSNumber numberWithInt:0], @"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kBore",          @"key", [NSNumber numberWithInt:0], @"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kClock",         @"key", [NSNumber numberWithInt:0], @"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kVME",           @"key", [NSNumber numberWithInt:0], @"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kHvCrate",       @"key", [NSNumber numberWithInt:0], @"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kHvChan",        @"key", [NSNumber numberWithInt:0], @"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kPreAmp",        @"key", [NSNumber numberWithInt:0], @"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kPulserCard",	@"key", [NSNumber numberWithInt:0], @"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kPulserChan",	@"key", [NSNumber numberWithInt:0], @"sortType", nil]];
        return mapEntries;
    }
	else if(index ==1){
        //default set -- subsclasses can override. first four items and the VME crate should not be moved
        NSMutableArray* mapEntries = [NSMutableArray array];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kSegmentNumber",	@"key", [NSNumber numberWithInt:0], @"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kCardSlot",      @"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kChannel",		@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kNCD",           @"key", [NSNumber numberWithInt:0], @"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kBore",          @"key", [NSNumber numberWithInt:0], @"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kClock",         @"key", [NSNumber numberWithInt:0], @"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kVME",           @"key", [NSNumber numberWithInt:0], @"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kHvCrate",       @"key", [NSNumber numberWithInt:0], @"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kHvChan",        @"key", [NSNumber numberWithInt:0], @"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kPreAmp",        @"key", [NSNumber numberWithInt:0], @"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kPulserCard",	@"key", [NSNumber numberWithInt:0], @"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kPulserChan",	@"key", [NSNumber numberWithInt:0], @"sortType", nil]];
        return mapEntries;
    }
    else return nil;
    

}

- (void) setCrateIndex:(int)aValue
{
    for(id aGroup in segmentGroups)[aGroup setCrateIndex:aValue]; //index from above
}

#pragma mark ¥¥¥Accessors
- (int) heartBeatIndex
{
    return heartBeatIndex;
}

- (void) setHeartBeatIndex:(int)aHeartBeatIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHeartBeatIndex:heartBeatIndex];
    heartBeatIndex = aHeartBeatIndex;
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloModelHeartBeatIndexChanged object:self];
    
	if([self heartbeatSeconds]){
		[self performSelector:@selector(sendHeartbeat) withObject:nil afterDelay:[self heartbeatSeconds]];
	}
	[self setNextHeartbeatString];
}
- (NSMutableArray*) emailList
{
    return emailList;
}

- (void) setEmailList:(NSMutableArray*)aEmailList
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEmailList:emailList];
    
    [aEmailList retain];
    [emailList release];
    emailList = aEmailList;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloModelEmailListChanged object:self];
}

- (void) addAddress:(id)anAddress atIndex:(int)anIndex
{
	if(!emailList) emailList= [[NSMutableArray array] retain];
	if([emailList count] == 0)anIndex = 0;
	anIndex = MIN(anIndex,[emailList count]);
	
	[[[self undoManager] prepareWithInvocationTarget:self] removeAddressAtIndex:anIndex];
	[emailList insertObject:anAddress atIndex:anIndex];
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloModelEmailListChanged object:self];
}

- (void) removeAddressAtIndex:(int) anIndex
{
	id anAddress = [emailList objectAtIndex:anIndex];
	[[[self undoManager] prepareWithInvocationTarget:self] addAddress:anAddress atIndex:anIndex];
	[emailList removeObjectAtIndex:anIndex];
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloModelEmailListChanged object:self];
}

- (HaloSentry*) haloSentry
{
    return haloSentry;
}

- (void) setHaloSentry:(HaloSentry*)aHaloSentry
{
    [aHaloSentry retain];
    [haloSentry release];
    haloSentry = aHaloSentry;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloModelHaloSentryChanged object:self];
}

#pragma mark ¥¥¥Segment Group Methods
- (void) makeSegmentGroups
{
    ORSegmentGroup* group = [[ORSegmentGroup alloc] initWithName:@"Halo Tubes" numSegments:kNumTubes mapEntries:[self setupMapEntries:0]];
	[self addGroup:group];
	[group release];
    
    ORSegmentGroup* group2 = [[ORSegmentGroup alloc] initWithName:@"Test Tubes" numSegments:4 mapEntries:[self setupMapEntries:1]];
	[self addGroup:group2];
	[group2 release];
    [self setupSegmentIds];
}

- (void) setupSegmentIds
{
    for(ORSegmentGroup* aGroup in segmentGroups){
        int n = [aGroup numSegments];
        int i;
        for(i=0;i<n;i++){
            ORDetectorSegment* aSegment = [aGroup segment:i];
            NSString* crateName   = [aGroup segment:i objectForKey:@"kVME"          ];
            NSString* cardName    = [aGroup segment:i objectForKey:@"kCardSlot"     ];
            NSString* chanName    = [aGroup segment:i objectForKey:@"kChannel"      ];

            NSString* anIndentifier = [NSString stringWithFormat:@"%@,%@,%@",crateName,cardName,chanName];
            [aSegment setIdentifier:anIndentifier];
        }
    }
}

- (int)  maxNumSegments
{
	return kNumTubes;
}

- (void) showDataSetForSet:(int)aSet segment:(int)index
{
	if(aSet>=0 && aSet < [segmentGroups count]){
		ORSegmentGroup* aGroup = [segmentGroups objectAtIndex:aSet];
        NSString* cardName       = [ aGroup segment:index objectForKey:@"kCardSlot"     ];
		NSString* chanName       = [ aGroup segment:index objectForKey:@"kChannel"      ];
        NSString* vmeCrateName   = [ aGroup segment:index objectForKey:@"kVME"          ];
        
		if(cardName && chanName && vmeCrateName && ![cardName hasPrefix:@"-"] && ![chanName hasPrefix:@"-"] && ![vmeCrateName hasPrefix:@"-"]){
			ORDataSet* aDataSet = nil;
			[[[self document] collectObjectsOfClass:NSClassFromString(@"OrcaObject")] makeObjectsPerformSelector:@selector(clearLoopChecked)];
			NSArray* objs = [[self document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
			if([objs count]){
				NSArray* arrayOfHistos = [[objs objectAtIndex:0] collectConnectedObjectsOfClass:NSClassFromString(@"ORHistoModel")];
				if([arrayOfHistos count]){
					id histoObj = [arrayOfHistos objectAtIndex:0];
					aDataSet = [histoObj objectForKeyArray:[NSMutableArray arrayWithObjects:@"Shaper" ,
                                                            [NSString stringWithFormat:@"Crate %2d",[vmeCrateName intValue]],
                                                            [NSString stringWithFormat:@"Card %2d",[cardName intValue]],
															[NSString stringWithFormat:@"Channel %2d",[chanName intValue]],
															nil]];
					
					[aDataSet doDoubleClick:nil];
				}
			}
		}
	}
}

- (NSString*) dataSetNameGroup:(int)aGroup segment:(int)index
{
	ORSegmentGroup* theGroup = [segmentGroups objectAtIndex:aGroup];
	
    NSString* crateName      = [ theGroup segment:index objectForKey:@"kCrate"       ];
	NSString* cardName       = [ theGroup segment:index objectForKey:@"kCardSlot"    ];
	NSString* chanName       = [ theGroup segment:index objectForKey:@"kChannel"     ];
    
    
    return [NSString stringWithFormat:@"FLT,Energy,Crate %2d,Card %2d,Channel %2d",[crateName intValue],[cardName intValue],[chanName intValue]];
}
#pragma mark ¥¥¥Specific Dialog Lock Methods
- (NSString*) experimentMapLock
{
	return @"HaloMapLock";
}

- (NSString*) experimentDetectorLock
{
	return @"HaloDetectorLock";
}

- (NSString*) secondaryMapLock;
{
    return @"HaloSecondaryMapLockChanged";
}

- (NSString*) experimentDetailsLock
{
	return @"HaloDetailsLock";
}

- (void) setViewType:(int)aViewType
{
	[[[self undoManager] prepareWithInvocationTarget:self] setViewType:aViewType];
	viewType = aViewType;
	[[NSNotificationCenter defaultCenter] postNotificationName:HaloModelViewTypeChanged object:self userInfo:nil];
}

- (int) viewType
{
	return viewType;
}

- (BOOL) sentryIsRunning
{
    return [haloSentry sentryIsRunning];
}

- (void) takeOverRunning
{
    [haloSentry takeOverRunning:YES];
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setHaloSentry:[decoder decodeObjectForKey:@"haloSentry"]];
    [self setViewType:  [decoder decodeIntForKey:   @"viewType"]];
    [self setEmailList: [decoder decodeObjectForKey:@"emailList"]];
    [self setHeartBeatIndex:[decoder decodeIntForKey:@"heartBeatIndex"]];
	[[self undoManager] enableUndoRegistration];
    
    if(!haloSentry){
        haloSentry = [[HaloSentry alloc] init];
    }
    [haloSentry registerNotificationObservers];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:haloSentry    forKey:@"haloSentry"];
    [encoder encodeInt:viewType         forKey:@"viewType"];
    [encoder encodeObject:emailList     forKey:@"emailList"];
    [encoder encodeInt:heartBeatIndex forKey:@"heartBeatIndex"];
}

- (void) sendHeartbeat
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(sendHeartbeat) object:nil];
	if([self heartbeatSeconds]==0)return;
	[self setNextHeartbeatString];
    
	NSString* theContent = @"";
	theContent = [theContent stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];
	theContent = [theContent stringByAppendingFormat:@"This report was generated automatically by HALO at:\n"];
	theContent = [theContent stringByAppendingFormat:@"%@ (Local time of ORCA machine)\n",[[NSDate date]descriptionWithCalendarFormat:nil timeZone:nil locale:nil]];
	theContent = [theContent stringByAppendingFormat:@"Unless changed in ORCA, it will be repeated at:\n"];
    theContent = [theContent stringByAppendingFormat:@"%@ (Local time of ORCA machine)\n%@ (UTC)\n",
                  [nextHeartbeat descriptionWithCalendarFormat:nil timeZone:nil locale:nil], [nextHeartbeat descriptionWithCalendarFormat:nil timeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"] locale:nil]];
	theContent = [theContent stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];
    NSString* haloReport = [haloSentry report];
    if([haloReport length] == 0)haloReport = @"Halo report was empty of content";
	theContent = [theContent stringByAppendingFormat:@"%@\n",haloReport];
	theContent = [theContent stringByAppendingString:@"\n\n+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];
	theContent = [theContent stringByAppendingString:@"The following people received this message:\n"];
	for(id address in emailList) theContent = [theContent stringByAppendingFormat:@"%@\n",address];
	theContent = [theContent stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];
	
	NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[self cleanupAddresses:emailList],@"Address",theContent,@"Message",nil];
	[self sendMail:userInfo];
	
	if([self heartbeatSeconds]){
		[self performSelector:@selector(sendHeartbeat) withObject:nil afterDelay:[self heartbeatSeconds]];
	}
	else {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(sendHeartbeat) object:nil];
	}
}


- (NSString*) reformatSelectionString:(NSString*)aString forSet:(int)aSet
{
	if([aString length] == 0)return @"Not Mapped";
	
	NSString* finalString = @"";
	NSArray* parts = [aString componentsSeparatedByString:@"\n"                                                          ];
	finalString = [ finalString stringByAppendingString:@"\n-----------------------\n"                                   ];
	finalString = [ finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Segment"    parts:parts]       ];
    finalString = [ finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Bore"       parts:parts]          ];
    finalString = [ finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" NCD"        parts:parts]           ];
    finalString = [ finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Clock"      parts:parts]         ];
	finalString = [ finalString stringByAppendingString:@"-----------------------\n"                                     ];
	finalString = [ finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" CardSlot"   parts:parts]      ];
	finalString = [ finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Channel"    parts:parts]       ];
    finalString = [ finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" VME"        parts:parts]       ];
	finalString = [ finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Threshold"  parts:parts]     ];
	finalString = [ finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Gain"       parts:parts]          ];
	finalString = [ finalString stringByAppendingString:@"-----------------------\n"                                     ];
    finalString = [ finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" HvCrate"    parts:parts]       ];
    finalString = [ finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" HvChan"     parts:parts]        ];
    finalString = [ finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" PreAmp"     parts:parts]        ];
    finalString = [ finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" PulserCard" parts:parts]    ];
    finalString = [ finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" PulserChan" parts:parts]    ];
	return finalString;
}

- (NSString*) getPartStartingWith:(NSString*)aLabel parts:(NSArray*)parts
{
	for(id aLine in parts){
		if([aLine rangeOfString:aLabel].location != NSNotFound) return aLine;
	}
	return @"";
}
- (int) heartbeatSeconds
{
	switch(heartBeatIndex){
		case 0: return 0;
		case 1: return 30*60;
		case 2: return 60*60;
		case 3: return 2*60*60;
		case 4: return 8*60*60;
		case 5: return 12*60*60;
		case 6: return 24*60*60;
		default: return 0;
	}
	return 0;
}

- (void) setNextHeartbeatString
{
	if([self heartbeatSeconds]){
		[nextHeartbeat release];
#if defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6 // 10.6-specific
		nextHeartbeat = [[[NSDate date] dateByAddingTimeInterval:[self heartbeatSeconds]] retain];
#else
		nextHeartbeat = [[[NSDate date] addTimeInterval:[self heartbeatSeconds]] retain];
#endif
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:HaloModelNextHeartBeatChanged object:self];
	
}

- (NSDate*) nextHeartbeat
{
	return nextHeartbeat;
}


#pragma mark ¥¥¥EMail
- (void) mailSent:(NSString*)address
{
	NSLog(@"Process Center status was sent to:\n%@\n",address);
}

- (void) sendMail:(id)userInfo
{
	NSString* address =  [userInfo objectForKey:@"Address"];
	NSString* content = [NSString string];
	NSString* hostAddress = @"<Unable to get host address>";
	NSArray* names =  [[NSHost currentHost] addresses];
	for(id aName in names){
		if([aName rangeOfString:@"::"].location == NSNotFound){
			if([aName rangeOfString:@".0.0."].location == NSNotFound){
				hostAddress = aName;
				break;
			}
		}
	}
	content = [content stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];
	content = [content stringByAppendingFormat:@"ORCA Message From Host: %@\n",hostAddress];
	content = [content stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n\n"];
	NSString* theMessage = [userInfo objectForKey:@"Message"];
	if(theMessage){
		content = [content stringByAppendingString:theMessage];
	}
	NSString* shutDownWarning = [userInfo objectForKey:@"Shutdown"];
	if(shutDownWarning){
		//generated from a manual shutdown of the email system.
		//don't send out any other info.
	}
	
	NSAttributedString* theContent = [[NSAttributedString alloc] initWithString:content];
	ORMailer* mailer = [ORMailer mailer];
	[mailer setTo:address];
	[mailer setSubject:@"Orca Message"];
	[mailer setBody:theContent];
	[mailer send:self];
	[theContent release];
}
- (NSString*) cleanupAddresses:(NSArray*)aListOfAddresses
{
	NSMutableArray* listCopy = [NSMutableArray array];
	for(id anAddress in aListOfAddresses){
		if([anAddress length] && [anAddress rangeOfString:@"@"].location!= NSNotFound){
			[listCopy addObject:anAddress];
		}
	}
	return [listCopy componentsJoinedByString:@","];
}
@end

