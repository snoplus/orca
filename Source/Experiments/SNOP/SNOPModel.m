//
//  SNOPModel.m
//  Orca
//
//  Created by Mark Howe on Tue Apr 20, 2010.
//  Copyright (c) 2010  University of North Carolina. All rights reserved.
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
#import "SNOPModel.h"
#import "SNOPController.h"
#import "ORSegmentGroup.h"
#import "ORTaskSequence.h"
#import "ORCouchDB.h"
#import "ORXL3Model.h"

NSString* ORSNOPModelViewTypeChanged	= @"ORSNOPModelViewTypeChanged";
static NSString* SNOPDbConnector	= @"SNOPDbConnector";
NSString* ORSNOPModelMorcaIsVerboseChanged = @"ORSNOPModelMorcaIsVerboseChanged";
NSString* ORSNOPModelMorcaIsWithinRunChanged = @"ORSNOPModelMorcaIsWithinRunChanged";
NSString* ORSNOPModelMorcaUpdateTimeChanged = @"ORSNOPModelMorcaUpdateTimeChanged";
NSString* ORSNOPModelMorcaPortChanged = @"ORSNOPModelMorcaPortChanged";
NSString* ORSNOPModelMorcaStatusChanged = @"ORSNOPModelMorcaStatusChanged";
NSString* ORSNOPModelMorcaUserNameChanged = @"ORSNOPModelMorcaUserNameChanged";
NSString* ORSNOPModelMorcaPasswordChanged = @"ORSNOPModelMorcaPasswordChanged";
NSString* ORSNOPModelMorcaDBNameChanged = @"ORSNOPModelMorcaDBNameChanged";
NSString* ORSNOPModelMorcaIPAddressChanged = @"ORSNOPModelMorcaIPAddressChanged";
NSString* ORSNOPModelMorcaIsUpdatingChanged = @"ORSNOPModelMorcaIsUpdatingChanged";

#define kMorcaDocumentAdded     @"kMorcaDocumentAdded"
#define kMorcaDocumentGot       @"kMorcaDocumentGot"
#define kMorcaCrateDocGot       @"kMorcaCrateDocGot"
#define kMorcaCrateDocUpdated   @"kMorcaCrateDocUpdated"
#define kMorcaCompactDB         @"kMorcaCompactDB"

@interface SNOPModel (private)
- (void) morcaUpdateDBDict;
- (void) morcaUpdatePushDocs:(unsigned int) crate;
@end

@implementation SNOPModel

#pragma mark ¥¥¥Initialization

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"SNOP"]];
}

- (void) makeMainController
{
    [self linkToController:@"SNOPController"];
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:SNOPDbConnector];
    [aConnector setOffColor:[NSColor brownColor]];
    [aConnector setOnColor:[NSColor magentaColor]];
	[ aConnector setConnectorType: 'DB O' ];
	[ aConnector addRestrictedConnectionType: 'DB I' ]; //can only connect to DB outputs
    [aConnector release];
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [morcaUserName release];
    [morcaPassword release];
    [morcaDBName release];
    [morcaIPAddress release];
    if (morcaStatus) [morcaStatus release];
    if (morcaDBDict) [morcaDBDict release];
    
    [super dealloc];
}

- (void) sleep
{
    [super sleep];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(morcaUpdateDB) object:nil];
}

- (void) initMorcaConnectionHistory
{
	morcaIPNumberIndex = [[NSUserDefaults standardUserDefaults] integerForKey: [NSString stringWithFormat:@"orca.%@.morcaIPNumberIndex",[self className]]];
	if(!morcaConnectionHistory){
		NSArray* his = [[NSUserDefaults standardUserDefaults] objectForKey: [NSString stringWithFormat:@"orca.%@.morcaConnectionHistory",[self className]]];
		morcaConnectionHistory = [his mutableCopy];
	}
	if(!morcaConnectionHistory) morcaConnectionHistory = [[NSMutableArray alloc] init];
}

//- (NSString*) helpURL
//{
//	return @"SNO/Index.html";
//}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(runStateChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];    
}

- (void) runStateChanged:(NSNotification*)aNote
{
    int running = [[[aNote userInfo] objectForKey:ORRunStatusValue] intValue];
    if(running == eRunStopped){
        if (morcaIsWithinRun) {
            [self setMorcaIsUpdating:NO];
        }
    }
    else if(running == eRunStarting) {
        if (morcaIsWithinRun) {
            [self setMorcaIsUpdating:YES];
            [self morcaUpdateDB];
        }
    }
}

#pragma mark ¥¥¥Accessors
- (NSString*) morcaUserName
{
    if (!morcaUserName) return @"";
    return morcaUserName;
}

- (void) setMorcaUserName:(NSString *)aMorcaUserName
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMorcaUserName:morcaUserName];
    [morcaUserName autorelease];
    morcaUserName = [aMorcaUserName copy];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelMorcaUserNameChanged object:self];
}

- (NSString*) morcaPassword
{
    if (!morcaPassword) return @"";
    return morcaPassword;
}

- (void) setMorcaPassword:(NSString *)aMorcaPassword
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMorcaPassword:morcaPassword];
    [morcaPassword autorelease];
    morcaPassword = [aMorcaPassword copy];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelMorcaPasswordChanged object:self];        
}

- (NSString*) morcaDBName
{
    if (!morcaDBName) return @"";
    return morcaDBName;
}

- (void) setMorcaDBName:(NSString *)aMorcaDBName
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMorcaDBName:morcaDBName];
    [morcaDBName autorelease];
    morcaDBName = [aMorcaDBName copy];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelMorcaDBNameChanged object:self];        
}

- (void) clearMorcaConnectionHistory
{
	[morcaConnectionHistory release];
	morcaConnectionHistory = nil;
	
	[self setMorcaIPAddress:[self morcaIPAddress]];
}

- (unsigned int) morcaConnectionHistoryCount
{
	return [morcaConnectionHistory count];
}

- (id) morcaConnectionHistoryItem:(unsigned int)index
{
	if(morcaConnectionHistory && index<[morcaConnectionHistory count])return [morcaConnectionHistory objectAtIndex:index];
	else return nil;
}

- (NSString*) morcaIPAddress
{
    if (!morcaIPAddress) return @"";
    return morcaIPAddress;
}

- (void) setMorcaIPAddress:(NSString*)aMorcaIPAddress
{
	if([aMorcaIPAddress length]){
		
		[[[self undoManager] prepareWithInvocationTarget:self] setMorcaIPAddress:morcaIPAddress];
		
		[morcaIPAddress autorelease];
		morcaIPAddress = [aMorcaIPAddress copy];    
		
		if(!morcaConnectionHistory) morcaConnectionHistory = [[NSMutableArray alloc] init];
		if(![morcaConnectionHistory containsObject:morcaIPAddress]){
			[morcaConnectionHistory addObject:morcaIPAddress];
		}
		morcaIPNumberIndex = [morcaConnectionHistory indexOfObject:morcaIPAddress];
		
		[[NSUserDefaults standardUserDefaults] setObject:morcaConnectionHistory forKey:[NSString stringWithFormat:@"orca.%@.morcaConnectionHistory",[self className]]];
		[[NSUserDefaults standardUserDefaults] setInteger:morcaIPNumberIndex forKey:[NSString stringWithFormat:@"orca.%@.morcaIPNumberIndex",[self className]]];
		[[NSUserDefaults standardUserDefaults] synchronize];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelMorcaIPAddressChanged object:self];
	}
}

- (unsigned int) morcaPort;
{
    return morcaPort;
}

- (void) setMorcaPort:(unsigned int)aMorcaPort
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMorcaPort:aMorcaPort];
    morcaPort = aMorcaPort;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelMorcaPortChanged object:self];        
}

- (unsigned int) morcaUpdateTime;
{
    return morcaUpdateTime;
}

- (void) setMorcaUpdateTime:(unsigned int)aMorcaUpdateTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMorcaUpdateTime:morcaUpdateTime];
    morcaUpdateTime = aMorcaUpdateTime;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelMorcaUpdateTimeChanged object:self];        
}

- (BOOL) morcaIsVerbose
{
    return morcaIsVerbose;
}

- (void) setMorcaIsVerbose:(BOOL)aMorcaIsVerbose
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMorcaIsVerbose:morcaIsVerbose];
    morcaIsVerbose = aMorcaIsVerbose;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelMorcaIsVerboseChanged object:self];        
}

- (BOOL) morcaIsWithinRun
{
    return morcaIsWithinRun;
}

- (void) setMorcaIsWithinRun:(BOOL)aMorcaIsWithinRun
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMorcaIsWithinRun:morcaIsWithinRun];
    morcaIsWithinRun = aMorcaIsWithinRun;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelMorcaIsWithinRunChanged object:self];        
}

- (BOOL) morcaIsUpdating
{
    return morcaIsUpdating;
}

- (void) setMorcaIsUpdating:(BOOL)aMorcaIsUpdating
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMorcaIsUpdating:morcaIsUpdating];
    morcaIsUpdating = aMorcaIsUpdating;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelMorcaIsUpdatingChanged object:self];        
}

- (NSString*) morcaStatus
{
    if (!morcaStatus) {
        return @"Status unknown";
    }
    return morcaStatus;
}

- (void) setMorcaStatus:(NSString*)aMorcaStatus
{
    if (morcaStatus) [morcaStatus autorelease];
    if (aMorcaStatus) morcaStatus = [aMorcaStatus copy];
    
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelMorcaStatusChanged object:self];        
}

- (void) morcaPing
{
    if(!morcaPingTask){
		ORTaskSequence* aSequence = [ORTaskSequence taskSequenceWithDelegate:self];
		morcaPingTask = [[NSTask alloc] init];
		
		[morcaPingTask setLaunchPath:@"/sbin/ping"];
		[morcaPingTask setArguments: [NSArray arrayWithObjects:@"-c",@"2",@"-t",@"5",@"-q",morcaIPAddress,nil]];
		
		[aSequence addTaskObj:morcaPingTask];
		[aSequence setVerbose:YES];
		[aSequence setTextToDelegate:YES];
		[aSequence launch];
	}
	else {
		[morcaPingTask terminate];
	}
}

- (void) taskFinished:(NSTask*)aTask
{
	if(aTask == morcaPingTask){
		[morcaPingTask release];
		morcaPingTask = nil;
	}
}

- (ORCouchDB*) morcaDBRef
{
	return [ORCouchDB couchHost:[self morcaIPAddress] port:[self morcaPort] username:[self morcaUserName]
                            pwd:[self morcaPassword] database:[self morcaDBName] delegate:self];    
}

- (void) morcaUpdateDB {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(morcaUpdateDB) object:nil];
    [self morcaUpdateDBDict];
//    [self performSelector:@selector(morcaUpdatePushDocs) withObject:nil afterDelay:0.2];
}

- (void) morcaCompactDB {
    [[self morcaDBRef] compactDatabase:self tag:kMorcaCompactDB];
}

- (void) couchDBResult:(id)aResult tag:(NSString*)aTag
{
	@synchronized(self){
		if([aResult isKindOfClass:[NSDictionary class]]){
			NSString* message = [aResult objectForKey:@"Message"];
			if(message){
				if([aTag isEqualToString:kMorcaCrateDocGot]){
					NSLog(@"CouchDB Message getting a crate doc:");
				}
				[aResult prettyPrint:@"CouchDB Message:"];
			}
			else {
				if([aTag isEqualToString:kMorcaDocumentAdded]){
                    if ([self morcaIsVerbose]) {
                        [aResult prettyPrint:@"CouchDB push doc to DB"];
                    }
					//ignore
				}
				else if([aTag isEqualToString:kMorcaDocumentGot]){
					//[aResult prettyPrint:@"CouchDB Sent Doc:"];
				}
				else if([aTag rangeOfString:kMorcaCrateDocGot].location != NSNotFound){
                    //int key = [[[aResult objectForKey:@"rows"] objectAtIndex:0] objectForKey:@"key"];
                    if ([[aResult objectForKey:@"rows"] count] && [[[aResult objectForKey:@"rows"] objectAtIndex:0] objectForKey:@"key"]){
                        [morcaDBDict setObject:[[[aResult objectForKey:@"rows"] objectAtIndex:0] objectForKey:@"doc"]
                            forKey:[[[[aResult objectForKey:@"rows"] objectAtIndex:0] objectForKey:@"key"] stringValue]];
                    }
                    else {
                        [morcaDBDict removeObjectForKey:[[aTag componentsSeparatedByString:@"."] objectAtIndex:1]];
                    }
                    if ([self morcaIsVerbose]) {
                        [aResult prettyPrint:@"CouchDB pull doc from DB"];
                    }
                    [self morcaUpdatePushDocs:[[[aTag componentsSeparatedByString:@"."] objectAtIndex:1] intValue]];
				}
                else if([aTag isEqualToString:kMorcaCrateDocUpdated]){
                    if ([self morcaIsVerbose]) {                    
                        [aResult prettyPrint:@"CouchDB Compacted:"];
                    }
				}
                else if([aTag isEqualToString:kMorcaCompactDB]){
                    if ([self morcaIsVerbose]) {                    
                        [aResult prettyPrint:@"CouchDB Compacted:"];
                    }
				}
				else if([aTag isEqualToString:@"Message"]){
					[aResult prettyPrint:@"CouchDB Message:"];
				}
				else {
					[aResult prettyPrint:@"CouchDB"];
				}
			}
		}
		else if([aResult isKindOfClass:[NSArray class]]){
            /*
			if([aTag isEqualToString:kListDB]){
				[aResult prettyPrint:@"CouchDB List:"];
			else [aResult prettyPrint:@"CouchDB"];
             */
            [aResult prettyPrint:@"CouchDB"];
		}
		else {
			NSLog(@"%@\n",aResult);
		}
	}
}


#pragma mark ¥¥¥Segment Group Methods
- (void) makeSegmentGroups
{
    ORSegmentGroup* group = [[ORSegmentGroup alloc] initWithName:@"SNO+ Detector" numSegments:kNumTubes mapEntries:[self initMapEntries:0]];
	[self addGroup:group];
	[group release];
}

- (int)  maxNumSegments
{
	return kNumTubes;
}

- (void) showDataSetForSet:(int)aSet segment:(int)index
{ 
	if(aSet>=0 && aSet < [segmentGroups count]){
		ORSegmentGroup* aGroup = [segmentGroups objectAtIndex:aSet];
		NSString* cardName = [aGroup segment:index objectForKey:@"kCardSlot"];
		NSString* chanName = [aGroup segment:index objectForKey:@"kChannel"];
		if(cardName && chanName && ![cardName hasPrefix:@"-"] && ![chanName hasPrefix:@"-"]){
			ORDataSet* aDataSet = nil;
			[[[self document] collectObjectsOfClass:NSClassFromString(@"OrcaObject")] makeObjectsPerformSelector:@selector(clearLoopChecked)];
			NSArray* objs = [[self document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
			if([objs count]){
				NSArray* arrayOfHistos = [[objs objectAtIndex:0] collectConnectedObjectsOfClass:NSClassFromString(@"ORHistoModel")];
				if([arrayOfHistos count]){
					id histoObj = [arrayOfHistos objectAtIndex:0];
					aDataSet = [histoObj objectForKeyArray:[NSMutableArray arrayWithObjects:@"SIS3302", @"Crate  0",
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
	
	NSString* crateName = [theGroup segment:index objectForKey:@"kCrate"];
	NSString* cardName  = [theGroup segment:index objectForKey:@"kCardSlot"];
	NSString* chanName  = [theGroup segment:index objectForKey:@"kChannel"];
	
	return [NSString stringWithFormat:@"SIS3302,Energy,Crate %2d,Card %2d,Channel %2d",[crateName intValue],[cardName intValue],[chanName intValue]];
}
#pragma mark ¥¥¥Specific Dialog Lock Methods
- (NSString*) experimentMapLock
{
	return @"SNOPMapLock";
}

- (NSString*) experimentDetectorLock
{
	return @"SNOPDetectorLock";
}

- (NSString*) experimentDetailsLock	
{
	return @"SNOPDetailsLock";
}

- (void) setViewType:(int)aViewType
{
	[[[self undoManager] prepareWithInvocationTarget:self] setViewType:aViewType];
	viewType = aViewType;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelViewTypeChanged object:self userInfo:nil];
}

- (int) viewType
{
	return viewType;
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
	[self initMorcaConnectionHistory];
    
    [self setViewType:[decoder decodeIntForKey:@"viewType"]];
    [self setMorcaUserName:         [decoder decodeObjectForKey:@"ORSNOPModelMorcaUserName"]];
    [self setMorcaPassword:         [decoder decodeObjectForKey:@"ORSNOPModelMorcaPassword"]];
    [self setMorcaDBName:           [decoder decodeObjectForKey:@"ORSNOPModelMorcaDBName"]];
    [self setMorcaPort:             [decoder decodeIntForKey:@"ORSNOPModelMorcaPort"]];
    [self setMorcaIPAddress:        [decoder decodeObjectForKey:@"ORSNOPModelMorcaIPAddress"]];
    [self setMorcaUpdateTime:       [decoder decodeIntForKey:@"ORSNOPModelMorcaUpdateTime"]];
    [self setMorcaIsVerbose:        [decoder decodeBoolForKey:@"ORSNOPModelMorcaIsVerbose"]];
    [self setMorcaIsWithinRun:      [decoder decodeBoolForKey:@"ORSNOPModelMorcaIsWithinRun"]];
    [self setMorcaIsUpdating:       [decoder decodeBoolForKey:@"ORSNOPModelMorcaIsUpdating"]];

    if (morcaIsUpdating == YES) [self setMorcaIsUpdating:NO];
	
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:viewType forKey:@"viewType"];
    [encoder encodeObject:morcaUserName     forKey:@"ORSNOPModelMorcaUserName"];
    [encoder encodeObject:morcaPassword     forKey:@"ORSNOPModelMorcaPassword"];
    [encoder encodeObject:morcaDBName       forKey:@"ORSNOPModelMorcaDBName"];
    [encoder encodeInt:morcaPort            forKey:@"ORSNOPModelMorcaPort"];
    [encoder encodeObject:morcaIPAddress    forKey:@"ORSNOPModelMorcaIPAddress"];
    [encoder encodeInt:morcaUpdateTime      forKey:@"ORSNOPModelMorcaUpdateTime"];
    [encoder encodeBool:morcaIsVerbose      forKey:@"ORSNOPModelMorcaIsVerbose"];
    [encoder encodeBool:morcaIsWithinRun    forKey:@"ORSNOPModelMorcaIsWithinRun"];
    [encoder encodeBool:morcaIsUpdating     forKey:@"ORSNOPModelMorcaIsUpdating"];
}

- (NSString*) reformatSelectionString:(NSString*)aString forSet:(int)aSet
{
	if([aString length] == 0)return @"Not Mapped";
	
	NSString* finalString = @"";
	NSArray* parts = [aString componentsSeparatedByString:@"\n"];
	finalString = [finalString stringByAppendingString:@"\n-----------------------\n"];
	finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Detector" parts:parts]];
	finalString = [finalString stringByAppendingString:@"-----------------------\n"];
	finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" CardSlot" parts:parts]];
	finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Channel" parts:parts]];
	finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Threshold" parts:parts]];
	finalString = [finalString stringByAppendingString:@"-----------------------\n"];
	return finalString;
}

- (NSString*) getPartStartingWith:(NSString*)aLabel parts:(NSArray*)parts
{
	for(id aLine in parts){
		if([aLine rangeOfString:aLabel].location != NSNotFound) return aLine;
	}
	return @"";
}

@end

@implementation SNOPModel (private)
- (void) morcaUpdateDBDict
{
    if (!morcaDBDict) morcaDBDict = [[NSMutableDictionary alloc] initWithCapacity:20];
    NSArray* objs = [[self document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")];
    ORXL3Model* xl3;
    for (xl3 in objs) {
        [[self morcaDBRef] getDocumentId:[NSString stringWithFormat:@"_design/xl3_status/_view/xl3_num?descending=True&start_key=%d&end_key=%d&limit=1&include_docs=True",[xl3 crateNumber], [xl3 crateNumber]]
                                     tag:[NSString stringWithFormat:@"%@.%d", kMorcaCrateDocGot, [xl3 crateNumber]]];
    }
    //?
    if ([self morcaIsUpdating]) {
        if ([self morcaUpdateTime] == 0) {
            [self performSelector:@selector(morcaUpdateDB) withObject:nil afterDelay:0.1];
        }
        else {
            [self performSelector:@selector(morcaUpdateDB) withObject:nil afterDelay:[self morcaUpdateTime] - 0.2];
        }
    }
}

- (void) morcaUpdatePushDocs:(unsigned int) crate
{
    NSArray* objs = [[self document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")];
    ORXL3Model* xl3;
    for (xl3 in objs) {
        if ([xl3 crateNumber] == crate) break;
    }
        
    BOOL updateDoc = NO;
    if ([[morcaDBDict objectForKey:[NSString stringWithFormat:@"%d",[xl3 crateNumber]]] objectForKey:@"_id"]){
        [[xl3 pollDict] setObject:[[morcaDBDict objectForKey:[NSString stringWithFormat:@"%d",[xl3 crateNumber]]] objectForKey:@"_id"] forKey:@"_id"];
        updateDoc = YES;
    }
    else {
        if ([[xl3 pollDict] objectForKey:@"_id"]) {
            [[xl3 pollDict] removeObjectForKey:@"_id"];
        }
        if ([[xl3 pollDict] objectForKey:@"_rev"]) {
            [[xl3 pollDict] removeObjectForKey:@"_rev"];
        }
    }
    if ([[morcaDBDict objectForKey:[NSString stringWithFormat:@"%d",[xl3 crateNumber]]] objectForKey:@"_rev"]){
        [[xl3 pollDict] setObject:[[morcaDBDict objectForKey:[NSString stringWithFormat:@"%d",[xl3 crateNumber]]] objectForKey:@"_rev"] forKey:@"_rev"];
    }
    [[xl3 pollDict] setObject:[NSNumber numberWithInt:[xl3 crateNumber]] forKey:@"xl3_num"];
    NSDateFormatter* iso = [[NSDateFormatter alloc] init];
    [iso setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    iso.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    iso.calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
    iso.locale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease];
    NSString* str = [iso stringFromDate:[NSDate date]];
    [[xl3 pollDict] setObject:str forKey:@"time_stamp"];
    if (updateDoc) {
        [[self morcaDBRef] updateDocument:[xl3 pollDict] documentId:[[xl3 pollDict] objectForKey:@"_id"] tag:kMorcaCrateDocUpdated];
    }
    else{
        [[self morcaDBRef] addDocument:[xl3 pollDict] tag:kMorcaCrateDocUpdated];
    }
    [iso release];
    iso = nil;
    if (xl3 == [objs lastObject] && [self morcaIsUpdating]) {
        if ([self morcaUpdateTime] == 0) {
            [self performSelector:@selector(morcaUpdateDB) withObject:nil afterDelay:0.2];
        }
        else {
            [self performSelector:@selector(morcaUpdateDB) withObject:nil afterDelay:[self morcaUpdateTime] - 0.2];
        }
    }
}

@end
