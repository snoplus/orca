//
//  ORFecDatabase.m
//  Orca
//
//  Created by Mark Howe on 10/29/08.
//  Copyright 2008 University of North Carolina. All rights reserved.
//

#import "ORFecDatabase.h"

NSString* ORFecDatabaseChanged = @"ORFecDatabaseChanged";

@implementation ORFecDatabase

static ORFecDatabase* sharedFecDatabase = nil;
 
#pragma mark •••Singleton methods
+ (ORFecDatabase*) sharedFecDatabase
{
    @synchronized(self) {
        if (sharedFecDatabase == nil) {
            [[self alloc] init]; // assignment not done here
        }
    }
    return sharedFecDatabase;
}
 
+ (id) allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if (sharedFecDatabase == nil) {
            sharedFecDatabase = [super allocWithZone:zone];
            return sharedFecDatabase;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
}

- (id) init
{
    Class myClass = [self class];
    @synchronized(myClass) {
        if (sharedFecDatabase == nil) {
            if (self = [super init]) {
                sharedFecDatabase = self;
            }
        }
    }
    return sharedFecDatabase;
}

- (id)		 copyWithZone:(NSZone *)zone { return self; }
- (id)		 retain						 { return self; }
- (unsigned) retainCount				 { return UINT_MAX; }  //denotes an object that cannot be released
- (void)	 release					 { /*do nothing*/ }
- (id)		 autorelease				 { return self; }

#pragma mark •••Accessors
- (NSMutableDictionary*) database
{
	return database;
}

- (void) setDatabase:(NSMutableDictionary*)aDB
{
	[aDB retain];
	[database release];
	database = aDB;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFecDatabaseChanged object:self];
}

- (id) dataForKey:(NSString*)aKey
{
	return [database objectForKey:aKey];
}

- (void) setData:(id)someData forKey:(NSString*)aKey
{
	if(!database)[self setDatabase:[NSMutableDictionary dictionary]];
	if(aKey)[database setObject:someData forKey:aKey];
}

- (void) removeDataForKey:(NSString*)aKey
{
	[database removeObjectForKey:aKey];
}

//we let the header be unique
- (id) header
{
	return [database objectForKey:@"kHeader"];
}

- (void) setHeader:(id)aHeader
{
	[self setData:aHeader forKey:@"kHeader"];
}


#pragma mark •••Archival
- (id) initWithCoder:(NSCoder*)decoder
{
	id db = [ORFecDatabase sharedFecDatabase];
    [db setDatabase:		[decoder decodeObjectForKey: @"database"]];
	return db;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
	[encoder encodeObject:database		forKey:@"database"];
}

@end
NSString* ORFecDataChanged = @"ORFecDataChanged";


//---------------------------------------------------------------------
//
//  ORFecData.m
//  Orca
//
//  Created by Mark Howe on 10/29/08.
//  Copyright 2008 University of North Carolina. All rights reserved.
//
//---------------------------------------------------------------------

@implementation ORFecData

- (NSUndoManager*) undoManager	
{ 
	return [[NSApp delegate] undoManager]; 
}

- (unsigned char) cmos:(short)anIndex
{
	return cmos[anIndex];
}

- (void) setCmos:(short)anIndex withValue:(unsigned char)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCmos:anIndex withValue:cmos[anIndex]];
	cmos[anIndex] = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFecDataChanged object:self];
}

- (float) vRes
{
	return vRes;
}

- (void) setVRes:(float)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setVRes:vRes];
	vRes = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFecDataChanged object:self];
}

- (float)	hVRef
{
	return hVRef;
}

- (void)	setHVRef:(float)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHVRef:hVRef];
	hVRef = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFecDataChanged object:self];
}

#pragma mark Converted Data Methods
- (void) setCmosVoltage:(short)n withValue:(float) value
{
	[self setCmos:n withValue:255.0*(value-kCmosMin)/(kCmosMax-kCmosMin)+0.5];
}

- (float) cmosVoltage:(short) n
{
	return ((kCmosMax-kCmosMin)/255.0)*cmos[n]+kCmosMin;
}

- (void) setVResVoltage:(float) value
{
	[self setVRes:255.0*(value-kVResMin)/(kVResMax-kVResMin)+0.5];
}

- (float) VRES_Voltage
{
	return ((kVResMax-kVResMin)/255.0)*vRes+kVResMin;
}

- (void) setHVRefVoltage:(float) value
{
	[self setHVRef:(255.0*(value-kHVRefMin)/(kHVRefMax-kHVRefMin)+0.5)];
}

- (float) hVRefVoltage
{
	return ((kHVRefMax-kHVRefMin)/255.0)*hVRef+kHVRefMin;
}

#pragma mark •••Archival
- (id) initWithCoder:(NSCoder*)decoder
{
    self = [super init];
	
    [[self undoManager] disableUndoRegistration];

    [self setVRes:	 [decoder decodeFloatForKey: @"vRes"]];
    [self setHVRef:	 [decoder decodeFloatForKey: @"hVRef"]];
	int i;
	for(i=0;i<6;i++){
		[self setCmos:i withValue: [decoder decodeFloatForKey: [NSString stringWithFormat:@"cmos%d",i]]];
	}	
	
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
	[encoder encodeFloat:vRes	forKey:@"vRes"];
	[encoder encodeFloat:hVRef	forKey:@"hVRef"];
	int i;
	for(i=0;i<6;i++){
		[encoder encodeFloat:cmos[i] forKey:[NSString stringWithFormat:@"cmos%d",i]];
	}	
}
@end

//---------------------------------------------------------------------
//
//  ORFecHeader.m
//  Orca
//
//  Created by Mark Howe on 10/29/08.
//  Copyright 2008 University of North Carolina. All rights reserved.
//
//---------------------------------------------------------------------
NSString* ORFecHeaderChanged = @"ORFecHeaderChanged";

@implementation ORFecHeader
- (NSUndoManager*) undoManager	
{ 
	return [[NSApp delegate] undoManager]; 
}

- (NSString*) xilinxFile 
{
	return xilinxFile;
}
- (void)setXilinxFile:(NSString*)aFilePath;
{
    [[[self undoManager] prepareWithInvocationTarget:self] setXilinxFile:xilinxFile];
	
	[aFilePath retain];
	[xilinxFile release];
	aFilePath = xilinxFile;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFecHeaderChanged object:self];
}

- (float) adcClock
{
	return adcClock;
}
- (void) setAdcClock:(float)aValue;
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAdcClock:adcClock];
	
	adcClock = aValue;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFecHeaderChanged object:self];
}

- (float) sequencerClock
{
	return sequencerClock;
}
- (void) setSequencerClock:(float)aValue;
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSequencerClock:sequencerClock];
	
	sequencerClock = aValue;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFecHeaderChanged object:self];
}

- (float) memoryClock
{
	return memoryClock;
}
- (void) setMemoryClock:(float)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMemoryClock:memoryClock];
	
	memoryClock = aValue;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFecHeaderChanged object:self];
}

- (float) adcAllowedError:(short)anIndex
{
	return adcAllowedError[anIndex];
}
- (void) setAdcAllowedError:(short)anIndex withValue:(float)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAdcAllowedError:anIndex withValue:adcAllowedError[anIndex]];
	
	adcAllowedError[anIndex] = aValue;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFecHeaderChanged object:self];
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
	
    [[self undoManager] disableUndoRegistration];

    [self setXilinxFile:	 [decoder decodeObjectForKey: @"xilinxFile"]];
    [self setAdcClock:		 [decoder decodeFloatForKey: @"adcClock"]];
    [self setSequencerClock: [decoder decodeFloatForKey: @"sequencerClock"]];
    [self setMemoryClock:	 [decoder decodeFloatForKey: @"memoryClock"]];
	int i;
	for(i=0;i<kNumFecMonitorAdcs;i++){
		[self setAdcAllowedError:i withValue: [decoder decodeFloatForKey: [NSString stringWithFormat:@"adcAllowedError%d",i]]];
	}	
	
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
	[encoder encodeObject:xilinxFile	forKey:@"xilinxFile"];
	[encoder encodeFloat:adcClock		forKey:@"adcClock"];
	[encoder encodeFloat:sequencerClock	forKey:@"sequencerClock"];
	int i;
	for(i=0;i<kNumFecMonitorAdcs;i++){
		[encoder encodeFloat:adcAllowedError[i] forKey:[NSString stringWithFormat:@"adcAllowedError%d",i]];
	}	
}

@end

