//
//  ORFecDatabase.h
//  Orca
//
//  Created by Mark Howe on 10/29/08.
//  Copyright 2008 University of North Carolina. All rights reserved.
//

@interface ORFecDatabase : NSObject {
	NSMutableDictionary* database;
}

#pragma mark •••Singleton methods
+ (ORFecDatabase*) sharedFecDatabase;
+ (id)		 allocWithZone:(NSZone*) zone;

- (id)		 copyWithZone:(NSZone*) zone;
- (id)		 retain;
- (unsigned) retainCount;
- (void)	 release;
- (id)		 autorelease;

#pragma mark •••Accessors

- (NSMutableDictionary*) database;
- (void)				 setDatabase:(NSMutableDictionary*)aDB;

- (void) setData:(id)someData forKey:(NSString*)aKey;
- (void) removeDataForKey:(NSString*)aKey;

- (id)	 header;
- (void) setHeader:(id)aHeader;

#pragma mark •••Archival
- (id) initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORFecDatabaseChanged;


#define kNumFecMonitorAdcs 21

//--------------------------------------------------------------------------
#define kISetA1 0
#define kISetA0	1
#define kISetM1	2
#define kISetM0	3
#define kTACRef	4
#define kVMax	5

#define kCmosMin		0.0
#define kCmosMax		5.0
#define kCmosStep 		((kCmosMax-kCmosMin)/255.0)

#define kVResMin		0.0
#define kVResMax		5.0
#define kVResStep 		((kVResMax-kVResMin)/255.0)

#define kHVRefMin		0.0
#define kHVRefMax		5.0
#define kHVResStep 		((kHVRefMax-kHVRefMin)/255.0)

@interface ORFecData : NSObject
{
	unsigned char  cmos[6];	//board related	0-ISETA1 1-ISETA0 2-ISETM1 3-ISETM0 4-TACREF 5-VMAX
	unsigned char  vRes;	//VRES for bipolar chip
	unsigned char  hVRef;	//HVREF for high voltage
}
#pragma mark •••Accessors
- (NSUndoManager*) undoManager;
- (unsigned char)  cmos:(short)anIndex;
- (void)	setCmos:(short)anIndex withValue:(unsigned char)aValue;
- (float)	vRes;
- (void)	setVRes:(float)aValue;
- (float)	hVRef;
- (void)	setHVRef:(float)aValue;

#pragma mark Converted Data Methods
- (void) setCmosVoltage:(short)anIndex withValue:(float) value;
- (float) cmosVoltage:(short) n;
- (void) setVResVoltage:(float) value;
- (float) VRES_Voltage;
- (void) setHVRefVoltage:(float) value;
- (float) hVRefVoltage;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORFecDataChanged;

//---------------------------------------------------------------------
//
//  ORFecHeader.h
//  Orca
//
//  Created by Mark Howe on 10/29/08.
//  Copyright 2008 University of North Carolina. All rights reserved.
//
//---------------------------------------------------------------------
#define kNumFecMonitorAdcs 21

@interface ORFecHeader : NSObject
{
	NSString*	xilinxFile;
	float		adcClock;
	float		sequencerClock;
	float		memoryClock;
	float		adcAllowedError[kNumFecMonitorAdcs];
}

#pragma mark •••Accessors
- (NSUndoManager*) undoManager;
- (NSString*)	xilinxFile;
- (void)		setXilinxFile:(NSString*)aFilePath;
- (float)		adcClock;
- (void)		setAdcClock:(float)aValue;
- (float)		sequencerClock;
- (void)		setSequencerClock:(float)aValue;
- (float)		memoryClock;
- (void)		setMemoryClock:(float)aValue;
- (float)		adcAllowedError:(short)anIndex;
- (void)		setAdcAllowedError:(short)anIndex withValue:(float)aValue;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORFecHeaderChanged;

