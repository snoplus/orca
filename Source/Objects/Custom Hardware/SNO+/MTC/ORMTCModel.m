/*
 *  ORMTCModel.cpp
 *  Orca
 *
 *  Created by Mark Howe on Fri, May 2, 2008
 *  Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
 *
 */
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
#import "ORMTCModel.h"
#import "ORVmeCrateModel.h"
#import "ORDataTypeAssigner.h"
#import "ORMTC_Constants.h"
#import "NSDictionary+Extensions.h"

#pragma mark •••Definitions

NSString* ORMTCModelESumViewTypeChanged		= @"ORMTCModelESumViewTypeChanged";
NSString* ORMTCModelNHitViewTypeChanged		= @"ORMTCModelNHitViewTypeChanged";
NSString* ORMTCModelDefaultFileChanged		= @"ORMTCModelDefaultFileChanged";
NSString* ORMTCModelLastFileChanged			= @"ORMTCModelLastFileChanged";
NSString* ORMTCModelLastFileChangedLoaded	= @"ORMTCModelLastFileLoadedChanged";
NSString* ORMTCModelBasicOpsRunningChanged	= @"ORMTCModelBasicOpsRunningChanged";
NSString* ORMTCModelAutoIncrementChanged	= @"ORMTCModelAutoIncrementChanged";
NSString* ORMTCModelUseMemoryChanged		= @"ORMTCModelUseMemoryChanged";
NSString* ORMTCModelRepeatDelayChanged		= @"ORMTCModelRepeatDelayChanged";
NSString* ORMTCModelRepeatCountChanged		= @"ORMTCModelRepeatCountChanged";
NSString* ORMTCModelWriteValueChanged		= @"ORMTCModelWriteValueChanged";
NSString* ORMTCModelMemoryOffsetChanged		= @"ORMTCModelMemoryOffsetChanged";
NSString* ORMTCModelSelectedRegisterChanged = @"ORMTCModelSelectedRegisterChanged";
NSString* ORMTCModelLoadFilePathChanged		= @"ORMTCModelLoadFilePathChanged";
NSString* ORMTCModelMtcDataBaseChanged		= @"ORMTCModelMtcDataBaseChanged";
NSString* ORMTCModelLastFileLoadedChanged	= @"ORMTCModelLastFileLoadedChanged";

NSString* ORMTCLock							= @"ORMTCLock";

static SnoMtcNamesStruct reg[kMtcNumRegisters] = {
	{ @"ControlReg"	    , 0   ,0x29,	0x01 },   //0
	{ @"SerialReg"		, 4   ,0x29,	0x01 },   //1
	{ @"DacCntReg"		, 8   ,0x29,	0x01 },   //2
	{ @"SoftGtReg"		, 12  ,0x29,	0x01 },   //3
	{ @"Pedestal Width"	, 16  ,0x29,	0x01 },   //4
	{ @"Coarse Delay"	, 20  ,0x29,	0x01 },   //5
	{ @"Fine Delay"		, 24  ,0x29,	0x01 },   //6
	{ @"ThresModReg"	, 28  ,0x29,	0x01 },   //7
	{ @"PmskReg"		, 32  ,0x29,	0x01 },   //8
	{ @"ScaleReg"		, 36  ,0x29,	0x01 },   //9
	{ @"BwrAddOutReg"	, 40  ,0x29,	0x01 },   //10
	{ @"BbaReg"			, 44  ,0x29,	0x01 },   //11
	{ @"GtLockReg"		, 48  ,0x29,	0x01 },   //12
	{ @"MaskReg"		, 52  ,0x29,	0x01 },   //13
	{ @"XilProgReg"		, 56  ,0x29,	0x01 },   //14
	{ @"GmskReg"		, 60  ,0x29,	0x01 },   //15
	{ @"OcGtReg"		, 128 ,0x29,	0x01 },   //16
	{ @"C50_0_31Reg"	, 132 ,0x29,	0x01 },   //17
	{ @"C50_32_42Reg"	, 16  ,0x29,	0x01 },   //18
	{ @"C10_0_31Reg"	, 140 ,0x29,	0x01 },   //19
	{ @"C10_32_52Reg"	, 144 ,0x29,	0x01 }	  //20
};

static SnoMtcDBInfoStruct dbLookUpTable[kDbLookUpTableSize] = {
	{ @"MTC/D,LockOutWidth",	   	@"1.1" },   //0
	{ @"MTC/D,PedestalWidth",		@"1.2" },   //1
	{ @"MTC/D,Nhit100LoPrescale",	@"1.3" },   //2
	{ @"MTC/D,PulserPeriod",		@"1.4" },   //3
	{ @"MTC/D,Low10MhzClock",		@"1.5" },   //4
	{ @"MTC/D,High10MhzClock",		@"1.6" },   //5
	{ @"MTC/D,FineSlope",			@"1.7" },   //6
	{ @"MTC/D,MinDelayOffset",		@"1.8" },   //7
	{ @"MTC/D,CoarseDelay",			@"1.9" },   //8
	{ @"MTC/D,FineDelay",			@"2.0" },   //9
	{ @"MTC/D,GtMask",				@"32000" }, //10
	{ @"MTC/D,GtCrateMask",			@"16" },	//11
	{ @"MTC/D,PEDCrateMask",		@"32" },	//12
	{ @"MTC/D,ControlMask",			@"1" },		//13
	
	//defaults for the MTC A NHit
	{ @"MTC/A,NHit100Hi,Threshold",	@"1"},		//14
	{ @"MTC/A,NHit100Med,Threshold",@"2"},		//15
	{ @"MTC/A,NHit100Lo,Threshold",	@"3"},		//16
	{ @"MTC/A,NHit20,Threshold",	@"4"},		//17
	{ @"MTC/A,NHit20LB,Threshold",	@"5"},		//18
	{ @"MTC/A,OWLN,Threshold",		@"6"},		//19
	
	{ @"MTC/A,NHit100Hi,mV/Adc",	@"10"},		//20
	{ @"MTC/A,NHit100Med,m/VAdc",	@"20"},		//21
	{ @"MTC/A,NHit100Lo,mV/Adc",	@"30"},		//22
	{ @"MTC/A,NHit20,mV/Adc",		@"40"},		//23
	{ @"MTC/A,NHit20LB,mV/Adc",		@"50"},		//24
	{ @"MTC/A,OWLN,mV/Adc",			@"60"},		//25

	{ @"MTC/A,NHit100Hi,mV/Hit",	@"10"},		//26
	{ @"MTC/A,NHit100Med,mV/Hit",	@"20"},		//27
	{ @"MTC/A,NHit100Lo,mV/Hit",	@"30"},		//28
	{ @"MTC/A,NHit20,mV/Hit",		@"40"},		//29
	{ @"MTC/A,NHit20LB,mV/Hit",		@"50"},		//30
	{ @"MTC/A,OWLN,mV/Hit",			@"60"},		//31
	
	{ @"MTC/A,NHit100Hi,dcOffset",	@"10"},		//32
	{ @"MTC/A,NHit100Med,dcOffset",	@"20"},		//33
	{ @"MTC/A,NHit100Lo,dcOffset",	@"30"},		//34
	{ @"MTC/A,NHit20,dcOffset",		@"40"},		//35
	{ @"MTC/A,NHit20LB,dcOffset",	@"50"},		//36
	{ @"MTC/A,OWLN,dcOffset",		@"60"},		//37
	
	//defaults for the MTC A ESUM
	{ @"MTC/A,ESumLow,Threshold",	@"10"},		//38
	{ @"MTC/A,ESumHi,Threshold",	@"20"},		//39
	{ @"MTC/A,OWLELo,Threshold",	@"30"},		//40
	{ @"MTC/A,OWLEHi,Threshold",	@"40"},		//41

	{ @"MTC/A,ESumLow,mV/Adc",		@"10"},		//42
	{ @"MTC/A,ESumHi,mV/Adc",		@"20"},		//43
	{ @"MTC/A,OWLELo,mV/Adc",		@"30"},		//44
	{ @"MTC/A,OWLEHi,mV/Adc",		@"40"},		//45

	{ @"MTC/A,ESumLow,mV/pC",		@"10"},		//46
	{ @"MTC/A,ESumHi,mV/pC",		@"20"},		//47
	{ @"MTC/A,OWLELo,mV/pC",		@"30"},		//48
	{ @"MTC/A,OWLEHi,mV/pC",		@"40"},		//49

	{ @"MTC/A,ESumLow,dcOffset",	@"10"},		//50
	{ @"MTC/A,ESumHi,dcOffset",		@"20"},		//51
	{ @"MTC/A,OWLELo,dcOffset",		@"30"},		//52
	{ @"MTC/A,OWLEHi,dcOffset",		@"40"},		//53
	
	{@"Comments",					@"Nothing Noted"},		//54
	{@"XilinxFilePath",				@"--"},		//55

};

@interface ORMTCModel (private)
- (void) doBasicOp;
- (void) setupDefaults;
@end

@implementation ORMTCModel

- (id) init //designated initializer
{
    self = [super init];
	
    [[self undoManager] disableUndoRegistration];
	
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void) dealloc
{
    [defaultFile release];
    [lastFile release];
    [lastFileLoaded release];
    [mtcDataBase release];
    [loadFilePath release];
	[loadFile release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"MTCCard"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORMTCController"];
}


- (void) wakeUp
{
    if(![self aWake]){
    }
    [super wakeUp];
}

- (BOOL) solitaryObject
{
    return YES;
}

#pragma mark •••Accessors

- (int) eSumViewType
{
    return eSumViewType;
}

- (void) setESumViewType:(int)aESumViewType
{
    [[[self undoManager] prepareWithInvocationTarget:self] setESumViewType:eSumViewType];
    
    eSumViewType = aESumViewType;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelESumViewTypeChanged object:self];
}

- (int) nHitViewType
{
    return nHitViewType;
}

- (void) setNHitViewType:(int)aNHitViewType
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNHitViewType:nHitViewType];
    
    nHitViewType = aNHitViewType;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelNHitViewTypeChanged object:self];
}
- (NSString*) xilinxFile
{
    return [self dbObjectByIndex:kXilinxFile];
}

- (void) setXilinxFile:(NSString*)aDefaultFile
{
 	if(!aDefaultFile)aDefaultFile = @"--";
	[self setDbObject:aDefaultFile forIndex:kXilinxFile];
}

- (NSString*) defaultFile
{
    return defaultFile;
}

- (void) setDefaultFile:(NSString*)aDefaultFile
{
 	if(!aDefaultFile)aDefaultFile = @"--";
    [[[self undoManager] prepareWithInvocationTarget:self] setDefaultFile:defaultFile];
	
    [defaultFile autorelease];
    defaultFile = [aDefaultFile copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelDefaultFileChanged object:self];
}

- (NSString*) lastFile
{
    return lastFile;
}

- (void) setLastFile:(NSString*)aLastFile
{
    [lastFile autorelease];
    lastFile = [aLastFile copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelLastFileChanged object:self];
}

- (NSString*) lastFileLoaded
{
    return lastFileLoaded;
}

- (void) setLastFileLoaded:(NSString*)aFile
{
	if(!aFile)aFile = @"--";
    [lastFileLoaded autorelease];
    lastFileLoaded = [aFile copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelLastFileLoadedChanged object:self];
}


- (BOOL) basicOpsRunning
{
    return basicOpsRunning;
}

- (void) setBasicOpsRunning:(BOOL)aBasicOpsRunning
{
    basicOpsRunning = aBasicOpsRunning;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelBasicOpsRunningChanged object:self];
}

- (BOOL) autoIncrement
{
    return autoIncrement;
}

- (void) setAutoIncrement:(BOOL)aAutoIncrement
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAutoIncrement:autoIncrement];
    
    autoIncrement = aAutoIncrement;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelAutoIncrementChanged object:self];
}

- (int) useMemory
{
    return useMemory;
}

- (void) setUseMemory:(int)aUseMemory
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUseMemory:useMemory];
    
    useMemory = aUseMemory;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelUseMemoryChanged object:self];
}

- (unsigned short) repeatDelay
{
    return repeatDelay;
}

- (void) setRepeatDelay:(unsigned short)aRepeatDelay
{
	if(aRepeatDelay<=0)aRepeatDelay = 1;
    [[[self undoManager] prepareWithInvocationTarget:self] setRepeatDelay:repeatDelay];
    
    repeatDelay = aRepeatDelay;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelRepeatDelayChanged object:self];
}

- (short) repeatCount
{
    return repeatCount;
}

- (void) setRepeatCount:(short)aRepeatCount
{
	if(aRepeatCount<=0)aRepeatCount = 1;
    [[[self undoManager] prepareWithInvocationTarget:self] setRepeatCount:repeatCount];
    
    repeatCount = aRepeatCount;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelRepeatCountChanged object:self];
}

- (unsigned long) writeValue
{
    return writeValue;
}

- (void) setWriteValue:(unsigned long)aWriteValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWriteValue:writeValue];
    
    writeValue = aWriteValue;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelWriteValueChanged object:self];
}

- (unsigned long) memoryOffset
{
    return memoryOffset;
}

- (void) setMemoryOffset:(unsigned long)aMemoryOffset
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMemoryOffset:memoryOffset];
    
    memoryOffset = aMemoryOffset;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelMemoryOffsetChanged object:self];
}

- (int) selectedRegister
{
    return selectedRegister;
}

- (void) setSelectedRegister:(int)aSelectedRegister
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedRegister:selectedRegister];
    
    selectedRegister = aSelectedRegister;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelSelectedRegisterChanged object:self];
}

- (NSMutableDictionary*) mtcDataBase
{
    return mtcDataBase;
}

- (void) setMtcDataBase:(NSMutableDictionary*)aNestedDictionary
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMtcDataBase:mtcDataBase];

    [aNestedDictionary retain];
    [mtcDataBase release];
    mtcDataBase = aNestedDictionary;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelMtcDataBaseChanged object:self];

}

- (NSString*) loadFilePath
{
    return loadFilePath;
}

- (void) setLoadFilePath:(NSString*)aLoadFilePath
{
	if(!aLoadFilePath)aLoadFilePath = @"--";
    [[[self undoManager] prepareWithInvocationTarget:self] setLoadFilePath:loadFilePath];
    
    [loadFilePath autorelease];
    loadFilePath = [aLoadFilePath copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelLoadFilePathChanged object:self];
}


//hardcoded base addresses (unlikely to ever change)
- (unsigned long) memBaseAddress
{
    return 0x03800000;
}

- (unsigned long) baseAddress
{
    return 0x00007000;
}

#pragma mark •••Converters
- (unsigned long) mVoltsToRaw:(float) mVolts
{
	return (long)(((mVolts + 5000.0)*0.4096)+.5);
}

- (float) rawTomVolts:(long) aRawValue
{
	return (aRawValue*2.44140625)-5000.0;
}

- (unsigned long) mVoltsToNHits:(float) mVolts dcOffset:(float)dcOffset mVperNHit:(float)mVperNHit
{
	float NHits_per_mVolts = 0.0;
	if(mVperNHit)NHits_per_mVolts = 1/mVperNHit;
	return (mVolts - dcOffset)*NHits_per_mVolts +.5;	
}

- (float) NHitsTomVolts:(float) NHits dcOffset:(float)dcOffset mVperNHit:(float)mVperNHit
{
	return dcOffset + (mVperNHit*NHits);
}

- (long) NHitsToRaw:(float) NHits dcOffset:(float)dcOffset mVperNHit:(float)mVperNHit
{
	float mVolts = [self NHitsTomVolts:NHits dcOffset:dcOffset mVperNHit:mVperNHit];
	return [self mVoltsToRaw:mVolts];
}

- (float) mVoltsTopC:(float) mVolts dcOffset:(float)dcOffset mVperpC:(float)mVperpC
{
	float pC_per_mVolts = 0.0;
	if(mVperpC)pC_per_mVolts = 1/mVperpC;
	return (mVolts - dcOffset)*pC_per_mVolts;	
}

- (float) pCTomVolts:(float) pC dcOffset:(float)dcOffset mVperpC:(float)mVperpC
{
	return (float)dcOffset + (mVperpC*pC);
}

- (long) pCToRaw:(float) pC dcOffset:(float)dcOffset mVperpC:(float)mVperpC
{
	float mVolts = [self pCTomVolts:pC dcOffset:dcOffset mVperpC:mVperpC];
	return [self mVoltsToRaw:mVolts];
}

#pragma mark •••Data Taker
- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORMTCDecoderForMTC",								@"decoder",
        [NSNumber numberWithLong:dataId],					@"dataId",
        [NSNumber numberWithBool:NO],						@"variable",
        [NSNumber numberWithLong:10],						@"length",  //****put in actual length
        nil];
    [dataDictionary setObject:aDictionary forKey:@"MTC"];
    
    return dataDictionary;
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
}

//**************************************************************************************
// Function:	TakeData
// Description: Read data from a card
//**************************************************************************************
-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
}

//this is the data structure for the new SBCs (i.e. VX704 from Concurrent)
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	return -1; //TBD
}


#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
    [self setESumViewType:	[decoder decodeIntForKey:		@"ORMTCModelESumViewType"]];
    [self setNHitViewType:	[decoder decodeIntForKey:		@"ORMTCModelNHitViewType"]];
    [self setDefaultFile:	[decoder decodeObjectForKey:	@"ORMTCModelDefaultFile"]];
    [self setLastFile:		[decoder decodeObjectForKey:	@"ORMTCModelLastFile"]];
    [self setLastFileLoaded:[decoder decodeObjectForKey:	@"ORMTCModelLastFileLoaded"]];
    [self setAutoIncrement:	[decoder decodeBoolForKey:		@"ORMTCModelAutoIncrement"]];
    [self setUseMemory:		[decoder decodeIntForKey:		@"ORMTCModelUseMemory"]];
    [self setRepeatDelay:	[decoder decodeIntForKey:		@"ORMTCModelRepeatDelay"]];
    [self setRepeatCount:	[decoder decodeIntForKey:		@"ORMTCModelRepeatCount"]];
    [self setWriteValue:	[decoder decodeInt32ForKey:		@"ORMTCModelWriteValue"]];
    [self setMemoryOffset:	[decoder decodeInt32ForKey:		@"ORMTCModelMemoryOffset"]];
    [self setSelectedRegister:[decoder decodeIntForKey:		@"ORMTCModelSelectedRegister"]];
    [self setMtcDataBase:	[decoder decodeObjectForKey:	@"ORMTCModelMtcDataBase"]];
    [self setLoadFilePath:	[decoder decodeObjectForKey:	@"ORMTCModelLoadFilePath"]];
	
	if(!mtcDataBase)[self setupDefaults];
	
	
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	[encoder encodeInt:eSumViewType		forKey:@"ORMTCModelESumViewType"];
	[encoder encodeInt:nHitViewType		forKey:@"ORMTCModelNHitViewType"];
	[encoder encodeObject:defaultFile	forKey:@"ORMTCModelDefaultFile"];
	[encoder encodeObject:lastFile		forKey:@"ORMTCModelLastFile"];
	[encoder encodeObject:lastFileLoaded forKey:@"ORMTCModelLastFileLoaded"];
	[encoder encodeBool:autoIncrement	forKey:@"ORMTCModelAutoIncrement"];
	[encoder encodeInt:useMemory		forKey:@"ORMTCModelUseMemory"];
	[encoder encodeInt:repeatDelay		forKey:@"ORMTCModelRepeatDelay"];
	[encoder encodeInt:repeatCount		forKey:@"ORMTCModelRepeatCount"];
	[encoder encodeInt32:writeValue		forKey:@"ORMTCModelWriteValue"];
	[encoder encodeInt32:memoryOffset	forKey:@"ORMTCModelMemoryOffset"];
	[encoder encodeInt:selectedRegister forKey:@"ORMTCModelSelectedRegister"];
	[encoder encodeObject:mtcDataBase	forKey:@"ORMTCModelMtcDataBase"];
	[encoder encodeObject:loadFilePath	forKey:@"ORMTCModelLoadFilePath"];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
	return objDictionary;
}

- (void) setDataIds:(id)assigner
{
    dataId = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherMTC
{
    [self setDataId:[anotherMTC dataId]];
}

- (void) reset
{
}

#pragma mark •••DB Helpers
- (void) setDbLong:(long) aValue forIndex:(int)anIndex
{
	[self setDbObject:[NSNumber numberWithLong:aValue] forIndex:anIndex];
}
- (void) setDbFloat:(float) aValue forIndex:(int)anIndex
{
	[self setDbObject:[NSNumber numberWithFloat:aValue] forIndex:anIndex];
}

- (void) setDbObject:(id) anObject forIndex:(int)anIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDbObject:[mtcDataBase objectForNestedKey:[self getDBKeyByIndex:anIndex]] forIndex:anIndex];
	[mtcDataBase setObject:anObject forNestedKey:[self getDBKeyByIndex:anIndex]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelMtcDataBaseChanged object:self];
}

- (short)     dbLookTableSize					  { return kDbLookUpTableSize; }
- (id)        dbObjectByIndex:(int)anIndex		  { return [mtcDataBase objectForNestedKey:[self getDBKeyByIndex:anIndex]]; }
- (float)     dbFloatByIndex:(int)anIndex		  { return [[mtcDataBase objectForNestedKey:[self getDBKeyByIndex:anIndex]] floatValue]; }
- (int)       dbIntByIndex:(int)anIndex			  { return [[mtcDataBase objectForNestedKey:[self getDBKeyByIndex:anIndex]] intValue]; }
- (id)        dbObjectByName:(NSString*)aKey	  { return [mtcDataBase objectForNestedKey:aKey]; }
- (NSString*) getDBKeyByIndex:(short) anIndex	  { return dbLookUpTable[anIndex].key; }
- (NSString*) getDBDefaultByIndex:(short) anIndex { return dbLookUpTable[anIndex].defaultValue; }


#pragma mark •••HW Access
- (short) getNumberRegisters
{
    return kMtcNumRegisters;
}

- (NSString*) getRegisterName:(short) anIndex
{
    return reg[anIndex].regName;
}

- (unsigned long) read:(int)aReg
{
	unsigned long theValue = 0;
	NS_DURING
		[[self adapter] readLongBlock:&theValue
					 atAddress:[self baseAddress]+reg[aReg].addressOffset
					numToRead:1
					withAddMod:reg[aReg].addressModifier
				 usingAddSpace:reg[aReg].addressSpace];
	NS_HANDLER
		NSLog(@"Couldn't read the MTC %@!\n",reg[aReg].regName);
		[localException raise];
	NS_ENDHANDLER
	return theValue;
}

- (void) write:(int)aReg value:(unsigned long)aValue
{
	NS_DURING
		[[self adapter] writeLongBlock:&aValue
					 atAddress:[self baseAddress]+reg[aReg].addressOffset
					numToWrite:1
					withAddMod:reg[aReg].addressModifier
				 usingAddSpace:reg[aReg].addressSpace];
	NS_HANDLER
		NSLog(@"Couldn't write %d to the MTC %@!\n",aValue,reg[aReg].regName);
		[localException raise];
	NS_ENDHANDLER
}

- (void) setBits:(int)aReg mask:(unsigned long)aMask
{
	unsigned long old_value = [self read:aReg];
	unsigned long new_value = (old_value & ~aMask) | aMask;
	[self write:aReg value:new_value];
}

- (void) clrBits:(int)aReg mask:(unsigned long)aMask
{
	unsigned long old_value = [self read:aReg];
	unsigned long new_value = (old_value & ~aMask);
	[self write:aReg value:new_value];
}


- (unsigned long) getMTC_CSR
{
	return [self read:kMtcControlReg];
}

- (unsigned long) getMTC_GTID
{
	return [self read:kMtcOcGtReg] & 0xffffff;
}

- (unsigned long) getMTC_PedWidth
{
	return [self read:kMtcPwIdReg] & 0xff;
}

- (unsigned long) getMTC_CoarseDelay
{
	return [self read:kMtcRtdelReg] & 0xff;
}

- (unsigned long) getMTC_FineDelay
{
	return [self read:kMtcAddelReg] & 0xff;
}

- (void) sendMTC_SoftGt
{
	[self sendMTC_SoftGt:NO];
}

- (void) sendMTC_SoftGt:(BOOL) setGTMask
{
	NS_DURING
		if(setGTMask)[self setSingleGTWordMask:MTC_SOFT_GT_MASK];   // Step 1: set the SOFT_GT mask
		[self write:kMtcSoftGtReg value:1];							// Step 2: write to the soft gt register (doesn't matter what you write to it)
		[self clearSingleGTWordMask:MTC_SOFT_GT_MASK];				// Step 3: clear the SOFT_GT mask
	NS_HANDLER
		NSLog(@"Couldn't send a MTC SOFT_GT!\n");
	NS_ENDHANDLER
	
}
#define uShortDBValue(A) [[mtcDataBase objectForNestedKey:[self getDBKeyByIndex: A]] unsignedShortValue]
#define uLongDBValue(A)  [[mtcDataBase objectForNestedKey:[self getDBKeyByIndex: A]] unsignedLongValue]

- (void) initializeMtc:(BOOL) loadTheMTCXilinxFile load10MHzClock:(BOOL) loadThe10MHzClock
{
	NS_DURING
		if (!mtcDataBase)[self loadMtcDataBase];						// STEP 0 : Open the MTC Database
		if (loadTheMTCXilinxFile) [self loadMTCXilinx];				// STEP 1 : Load the Xilinx
		[self clearGlobalTriggerWordMask];							// STEP 2: Clear the GT Word Mask
		[self clearPedestalCrateMask];								// STEP 3: Clear the Pedestal Crate Mask
		[self clearGTCrateMask];									// STEP 4: Clear the GT Crate Mask
		[self loadTheMTCADacs];										// STEP 5: Load the DACs	
		[self clearTheControlRegister];								// STEP 6: Clear the Control Register
		[self zeroTheGTCounter];									// STEP 7: Clear the GT Counter
		[self setTheLockoutWidth:uShortDBValue(kLockOutWidth)];	// STEP 8: Set the Lockout Width	
		[self setThePrescaleValue];									// STEP 9:  Load the NHIT 100 LO prescale value
		[self setThePulserRate:uLongDBValue(kPulserPeriod)];		// STEP 10: Load the Pulser
		[self setThePedestalWidth:uLongDBValue(kPedestalWidth)];	// STEP 11: Set the Pedestal Width
		[self setupPulseGTDelaysCoarse:uLongDBValue(kCoarseDelay) fine:uLongDBValue(kFineDelay)]; // STEP 12: Setup the Pulse GT Delays
		if( loadThe10MHzClock)[self setMtcTime];					// STEP 13: Load the 10MHz Counter
		[self resetTheMemory];										// STEP 14: Reset the Memory	 
		//[self setGTCrateMask];									// STEP 15: Set the GT Crate Mask from MTC database
		NSLog(@"Initialization of the MTC complete.\n");

	NS_HANDLER
		NSLog(@"***Initialization of the MTC (%s Xilinx, %s 10MHz clock) failed!***\n", 
			loadTheMTCXilinxFile?"with":"no", loadThe10MHzClock?"load":"don't load");
	NS_ENDHANDLER
}

- (void) clearGlobalTriggerWordMask
{
	[self write:kMtcMaskReg value:0];
}

- (void) setGlobalTriggerWordMask
{
	if (!mtcDataBase) [self loadMtcDataBase];
	[self write:kMtcMaskReg value:uLongDBValue(kGtMask)];
}


- (unsigned long) getMTC_GTWordMask
{
	return [self read:kMtcGmskReg] & 0x03FFFFFF;							
}

- (void) setSingleGTWordMask:(unsigned long) gtWordMask
{	
	NS_DURING
		[self setBits:kMtcGmskReg mask:gtWordMask];
	NS_HANDLER
		NSLog(@"Could not set a MTC GT word mask!\n");					
	NS_ENDHANDLER
}

- (void) clearSingleGTWordMask:(unsigned long) gtWordMask
{
	NS_DURING
		[self clrBits:kMtcGmskReg mask:gtWordMask];
	NS_HANDLER
		NSLog(@"Could not clear a MTC GT word mask!\n");					
	NS_ENDHANDLER	
}

- (void) clearPedestalCrateMask
{
	[self write:kMtcPmskReg value:0];
}

- (void) setPedestalCrateMask
{
	if (!mtcDataBase)[self loadMtcDataBase];
	[self write:kMtcPmskReg value: uLongDBValue(kPEDCrateMask)];
}

- (void) clearGTCrateMask
{
	[self write:kMtcGmskReg value:0];
}

- (void) setGTCrateMask
{
	if (!mtcDataBase)[self loadMtcDataBase];
	[self write:kMtcGmskReg value: uLongDBValue(kGtCrateMask)];
}

- (unsigned long) getGTCrateMask
{
	return [self read:kMtcGmskReg] & 0x01FFFFFF;	
}

- (void) clearTheControlRegister
{
	[self write:kMtcControlReg value:0];
}

- (void) resetTheMemory
{
	//Clear the MTC/D memory, the fifo write pointer and the BBA Register
	[self write:kMtcBbaReg value:0];
	[self setBits:kMtcControlReg mask:MTC_CSR_FIFO_RESET];
	[self clrBits:kMtcControlReg mask:MTC_CSR_FIFO_RESET];
}

- (void) setTheGTCounter:(unsigned long) theGTCounterValue
{
	NS_DURING
		// Load the serial shift register, 24 bits for the GT Counter
		short j;
		for (j = 23; j >= 0; j--){							
			if ( (1UL << j ) & theGTCounterValue ){
				[self write:kMtcSerialReg value:MTC_SERIAL_REG_DIN + MTC_SERIAL_REG_SEN];	// Bit 0 is always high
				[self write:kMtcSerialReg value:MTC_SERIAL_REG_DIN + MTC_SERIAL_SHFTCLKGT];	// clock in data value, BIT 0 = high 
			}
			else{
				[self write:kMtcSerialReg value:0UL + MTC_SERIAL_REG_SEN];		// Bit 0 is always high
				[self write:kMtcSerialReg value:0UL + MTC_SERIAL_SHFTCLKGT];	// clock in data value, BIT 0 = high 
			}
		}
		
		// Now load enable by clearing and setting the appropriate bit
		[self clrBits:kMtcControlReg mask:MTC_CSR_LOAD_ENGT];
		[self setBits:kMtcControlReg mask:MTC_CSR_LOAD_ENGT];
		[self clrBits:kMtcControlReg mask:MTC_CSR_LOAD_ENGT];
	
	NS_HANDLER
		NSLog(@"Could not load the MTC GT counter!\n");			
	
	NS_ENDHANDLER
}


- (void) zeroTheGTCounter
{
	[self setTheGTCounter:0UL];
}

- (void) setMtcTime
{
	//set the 10MHz counter to a time based on the number of seconds since 1/1/1996 (GMT)
	static unsigned long theSecondsToSubtract = 0;

 	if( theSecondsToSubtract == 0 ) {
		theSecondsToSubtract =  (unsigned long)[[NSDate date] timeIntervalSinceDate:[NSCalendarDate dateWithYear:1996 month:1 day:1 hour:0 minute:0 second:0 timeZone:@"GMT"]];
 	}
/* 
 	//load the 10MHz clock from mac time....eventually we will 
	//get the time from the GPS.
	time_t theGPSSeconds = 0;
	time_t theMacSeconds = 0;
	short theGPSAddress = 0;
	unsigned long theMacMtcSetTimeInSeconds = 0;
	unsigned long theGPSMtcSetTimeInSeconds = 0;
	CDatumGPS *theGPS = NULL;
	if( gConfiguration->GetObject('SC1A' ) ) {
		CRunControl * theRunControl = (CRunControl *)(gConfiguration->GetTheObject());
		theGPSAddress = theRunControl->GetGPSAddress();
		if( theGPSAddress > 0 ) {
			// load from GPS if the GPS exists
			// note if the GPS has already been created with the correct address
			// then the method just returns mDatumGPS otherwise it creates a new one
			theGPS = theRunControl->CreateDatumGPS();
			if( theGPS ) {
				if( theGPS->ReadTime(&theGPSSeconds ) == noErr) {
					theGPSMtcSetTimeInSeconds = theGPSSeconds + kDelaySetTime - theSecondsToSubtract;
				}
				else {
					theGPS = NULL;
				}
			}
		}
	}
	time(&theMacSeconds);
	theMacMtcSetTimeInSeconds = theMacSeconds - theSecondsToSubtract - OffsetFromGMT();

	unsigned long theSeconds = 0;
	if( theGPS == NULL && (theGPSAddress > 0) ) {
		SysBeep(10);
		NSLog(@"Communication with the GPS at address %d failed.\n",theGPSAddress);
		NSLog(@"Can not set the 10MHz clock!\n");
	}
	else {
		if( theGPS == NULL )	theSeconds = theMacMtcSetTimeInSeconds;
		else					theSeconds = theGPSMtcSetTimeInSeconds;
	  	double        theTicks10MHz = theSeconds/100.E-9;
	  	unsigned long theLowerBits  = (unsigned long) fmod(theTicks10MHz,4294967296.0);
	  	unsigned long theUpperBits  = (unsigned long)(theTicks10MHz/4294967296.0);
	 	[self setThe10MHzCounterLow:theLowerBits high:theUpperBits];
		if( theGPS != NULL ) {
			if( theGPS->WritePresetCoincidence(theGPSSeconds + kDelaySetTime) != noErr ) {
	 			NSLog(@"The preset write to the GPS failed\n" );
	 			NSLog(@"The MTC 10MHz clock has been loaded but not set\n" );
	 			NSLog(@"The MTC MUST receive a sync pulse for the clock to latch\n" );
			}
			else {
				NSLog(@"The MTC 10MHz clock will be loaded within %d seconds\n", kDelaySetTime);
			}
		}
		else {
	 		NSLog(@"The MTC 10MHz clock has been set to the Mac time\n" );
	 		NSLog(@"The sync cable on the GPS MUST be connected to 1pps for this to work\n" );
	 	}
	 }
*/
}

- (double) get10MHzSeconds
{
	//get the 10MHz clock time expressed in seconds relative to SNO time zero
	unsigned long	lower, upper;
	double theValue = 0;
	NS_DURING
		[self getThe10MHzCounterLow:&lower high:&upper];
		theValue =  ((double) 4294967296.0 * (double)upper + (double)lower) * 1e-7;
	NS_HANDLER
	NS_ENDHANDLER
	return theValue;
}

- (unsigned long) getMtcTime
{
	//--get the 10MHz clock. seconds since 01/01/1904
	static unsigned long theSecondsToAdd = 0;

 	if( theSecondsToAdd == 0 ) {
		theSecondsToAdd =  (unsigned long)[[NSDate date] timeIntervalSinceDate:[NSCalendarDate dateWithYear:1996 month:1 day:1 hour:0 minute:0 second:0 timeZone:@"GMT"]];
 	}
    	
    return theSecondsToAdd + (unsigned long)[self get10MHzSeconds];

}


// SetThe10MHzCounter
- (void) setThe10MHzCounterLow:(unsigned long) lowerValue high:(unsigned long) upperValue
{
	unsigned long	aValue;
	
	NS_DURING
	
		// Now load the serial shift register	
		short j;
		for (j = 52; j >= 0; j--){							
		
			aValue = 0UL;

			if ( j < 32) {
				if ( (1UL << j ) & lowerValue ) aValue |= ( 1UL << 1 );		// build the data word
			}
 			else {
				if ( (1UL << (j - 32) ) & upperValue ) aValue |= ( 1UL << 1 );		// build the data word
			}
			[self write:kMtcSerialReg value:aValue + MTC_SERIAL_REG_SEN];	// Bit 0 is always high
			[self write:kMtcSerialReg value:aValue + MTC_SERIAL_SHFTCLK10];	// clock in data value, BIT 0 = high
		}

		// Now load enable by clearing and setting the appropriate bit		
		[self clrBits:kMtcControlReg mask:MTC_CSR_LOAD_EN10];
		[self setBits:kMtcControlReg mask:MTC_CSR_LOAD_EN10];
		[self clrBits:kMtcControlReg mask:MTC_CSR_LOAD_EN10];

	NS_HANDLER
		NSLog(@"Could not load the 10MHz counter!\n");
	NS_ENDHANDLER
}


- (void) getThe10MHzCounterLow:(unsigned long*) lowerValue high:(unsigned long*) upperValue
{
	*lowerValue = [self read:kMtcC10_0_31Reg];
	*upperValue = [self read:kMtcC10_32_52Reg] & 0x001fffffUL;
}

- (void) setTheLockoutWidth:(unsigned short) theLockoutWidthValue
{
	NS_DURING
		unsigned long lockout_index = (theLockoutWidthValue/20);
		unsigned long write_value   = (0xff - lockout_index);  //value in nano-seconds

		// write the GT lockout value in SMTC_GT_LOCK_REG
		[self write:kMtcGtLockReg value:write_value];
		
		// now assert and de-assert LOAD_ENLK in CONTROL REG and  
		// preserving the state of the register at the same time		
		[self clrBits:kMtcControlReg mask:MTC_CSR_LOAD_ENLK];
		[self setBits:kMtcControlReg mask:MTC_CSR_LOAD_ENLK];
		[self clrBits:kMtcControlReg mask:MTC_CSR_LOAD_ENLK];

	
	NS_HANDLER
		NSLog(@"Could not load the MTC GT lockout width!\n");		
	
	NS_ENDHANDLER
}

- (void) setThePedestalWidth:(unsigned short) thePedestalWidthValue
{
	NS_DURING
		unsigned long write_value = (0xff - thePedestalWidthValue/5); //value in nano-seconds
		
		// write the GT lockout value in SMTC_GT_LOCK_REG
		[self write:kMtcPwIdReg value:write_value];
		
		// now assert and de-assert LOAD_ENPW in CONTROL REG and  
		// preserving the state of the register at the same time		
		[self setBits:kMtcControlReg mask:MTC_CSR_LOAD_ENPW];
		[self clrBits:kMtcControlReg mask:MTC_CSR_LOAD_ENPW];
	
	NS_HANDLER
		NSLog(@"Could not load the MTC pedestal width!\n");	
		[localException raise];
	
	NS_ENDHANDLER
}

- (void) setThePrescaleValue
{
	NS_DURING
		//value from 1 to 65535
		unsigned long write_value = (0xffff - (uLongDBValue(kNhit100LoPrescale) - 1));// 1 prescale/~N+1 NHIT_100_LOs

		// write the prescale  value in MTC_SCALE_REG
		[self write:kMtcScaleReg value:write_value];
		
		// now load it : assert and de-assert LOAD_ENPR in CONTROL REG  
		// and  preserving the state of the register at the same time		
		[self clrBits:kMtcControlReg mask:MTC_CSR_LOAD_ENPR];
		[self setBits:kMtcControlReg mask:MTC_CSR_LOAD_ENPR];
		[self clrBits:kMtcControlReg mask:MTC_CSR_LOAD_ENPR];

	
	NS_HANDLER
		NSLog(@"Could not load the MTC prescale value!\n");		
		[localException raise];
	
	NS_ENDHANDLER
	
}


- (void) setupPulseGTDelaysCoarse:(unsigned short) theCoarseDelay fine:(unsigned short) theAddelValue
{		
	NS_DURING

		if (!mtcDataBase) [self loadMtcDataBase];
		
		[self setupGTCorseDelay:theCoarseDelay];	
		[self setupGTFineDelay:theAddelValue];

		// calculate the total delay and display
		//float theTotalDelay = (theAddelValue * [parameters uLongForKey:kPed_GT_Fine_Slope])
		//				+ (float)theCoarseDelay + [parameters uLongForKey: kPed_GT_Min_Delay_Offset];
			
//		NSLog(@"MTC total delay set to %3.2f ns.\n", theTotalDelay);

	
	NS_HANDLER
		NSLog(@"Could not setup the MTC PULSE_GT delays!\n");	
		[localException raise];			
	
	NS_ENDHANDLER
}

- (void) setupGTCorseDelay:(unsigned short) theCoarseDelay
{
	NS_DURING
		// Set the coarse GTRIG/PED delay in ns
		unsigned long aValue = (0xff - theCoarseDelay/10);

		[self write:kMtcRtdelReg value:aValue];
		// now load it : assert and de-assert LOAD_ENPW in CONTROL REG  
		// and  preserving the state of the register at the same time
		[self clrBits:kMtcControlReg mask:MTC_CSR_LOAD_ENPW];
		[self setBits:kMtcControlReg mask:MTC_CSR_LOAD_ENPW];
		[self clrBits:kMtcControlReg mask:MTC_CSR_LOAD_ENPW];

	NS_HANDLER
		NSLog(@"Could not setup the MTC GT course delay!\n");			
		[localException raise];			
	
	NS_ENDHANDLER
}

- (void) setupGTFineDelay:(unsigned short) theAddelValue
{	
	[self write:kMtcAddelReg value:theAddelValue];
}

- (void) setThePulserRate:(float) thePulserPeriodValue
{
	[self setThePulserRate:thePulserPeriodValue setToInfinity:NO];
}

- (void) setThePulserRate:(float) thePulserPeriodValue setToInfinity:(BOOL) setToInfinity
{
	unsigned long	pulserShiftValue;	

	NS_DURING
		// STEP 1: Load the shift register
		if(setToInfinity)pulserShiftValue =  0;  
		else {
			// calculate the value to be shifted into SMTC_SERIAL_REG
			float pulserShiftFValue =  (thePulserPeriodValue/0.001280) - 1.0;  // max pulser period = (0.00128ms * 0x00ffffff) = 21474.8532ms 
			pulserShiftValue = (unsigned long)pulserShiftFValue;
		}
		
		// STEP 2: Now serially shift into SMTC_SERIAL_REG the value 'pulserShiftValue'
		short j;
		for ( j = 23; j >= 0; j--){							
		
			unsigned long aValue = 0UL;
			if ( (1UL << j ) & pulserShiftValue ) aValue |= ( 1UL << 1 );		// build the data word

			[self write:kMtcSerialReg value:aValue + 1]; // Bit 0 is always high
			// clock in data value, BIT 0 = high
			[self write:kMtcSerialReg value:((aValue | MTC_SERIAL_SHFTCLKPS) | 0x000000001)]; 	

		}		

//		float frequencyValue = (float)( 781.25/((float)pulserShiftValue + 1.0) );					// in KHz
//		if (frequencyValue < 0.001)
//			NSLog(@"Pulser frequency set @ %3.10f mHz.\n",(frequencyValue * 1000000.0));
//		else if (frequencyValue <= 1.0)
//			NSLog(@"Pulser frequency set @ %3.10f Hz.\n",(frequencyValue * 1000.0));
//		else if (frequencyValue > 1.0)		
//			NSLog(@"Pulser frequency set @ %3.4f KHz.\n",frequencyValue);

	
	NS_HANDLER
		NSLog(@"Could not setup the MTC pulser frequency!\n");
		[localException raise];
	
	NS_ENDHANDLER
}

- (void) loadEnablePulser
{
	[self clrBits:kMtcControlReg mask:MTC_CSR_LOAD_ENPS];
	[self setBits:kMtcControlReg mask:MTC_CSR_LOAD_ENPS];
	[self clrBits:kMtcControlReg mask:MTC_CSR_LOAD_ENPS];
}

- (void) enablePulser
{
	[self setBits:kMtcControlReg mask:MTC_CSR_PULSE_EN];
}

- (void) disablePulser
{
	[self clrBits:kMtcControlReg mask:MTC_CSR_PULSE_EN];
}

- (void)  enablePedestal
{
	[self setBits:kMtcControlReg mask:MTC_CSR_PED_EN];
}

- (void)  disablePedestal
{
	[self clrBits:kMtcControlReg mask:MTC_CSR_PED_EN];
}

- (void) fireMTCPedestalsFixedRate
{
//Fire Pedestal pulses at a pecified period in ms, with a specifed 
// 							  GT coarse delay, GT Lockout Width, pedestal width in ns and a 
//							  specified crate mask set in MTC Databse. Trigger mask is EXT_8.
	NS_DURING
		if (!mtcDataBase)[self loadMtcDataBase];									//STEP 0 : Open the MTC Database
		[self basicMTCPedestalGTrigSetup];										//STEP 1: Perfom the basic setup for pedestals and gtrigs
		[self setupPulserRateAndEnable:uLongDBValue(kPulserPeriod)];	// STEP 2 : Setup pulser rate and enable

	
	NS_HANDLER
		NSLog(@"MTC failed to fire pedestals at the specified settings!\n");		
		[localException raise];	
	
	NS_ENDHANDLER
}

- (void) basicMTCPedestalGTrigSetup
{

	NS_DURING
		if (!mtcDataBase)[self loadMtcDataBase];							//STEP 0 : Open the MTC Database
		//[self clearGlobalTriggerWordMask];							//STEP 0a:	//added 01/24/98 QRA
		[self enablePedestal];											// STEP 1 : Enable Pedestal	
		[self setPedestalCrateMask];									// STEP 2: Mask in crates for pedestals (PMSK)
		[self setGTCrateMask];											// STEP 3: Mask  Mask in crates fo GTRIGs (GMSK)
		[self setupPulseGTDelaysCoarse: uLongDBValue(kCoarseDelay) fine:uLongDBValue(kFineDelay)]; // STEP 4: Set thSet the GTRIG/PED delay in ns
		[self setTheLockoutWidth: uLongDBValue(kLockOutWidth)];		// STEP 5: Set the GT lockout width in ns	
		[self setThePedestalWidth: uLongDBValue(kPedestalWidth)];		// STEP 6:Set the Pedestal width in ns
		[self setSingleGTWordMask: uLongDBValue(kGtMask)];				// STEP 7:Mask in global trigger word(MASK)
	
	
	NS_HANDLER
		NSLog(@"Failure during MTC pedestal setup!\n");
		[localException raise];
	
	NS_ENDHANDLER
}

- (void) setupPulserRateAndEnable:(double) pulserPeriodVal
{
	[self setThePulserRate:pulserPeriodVal];// STEP 1: Setup the pulser rate [pulser period in ms]
	[self loadEnablePulser];				// STEP 2 : Load Enable Pulser
	[self enablePulser];					// STEP 3 : Enable Pulser	
}

- (void) fireMTCPedestalsFixedNumber:(unsigned long) numPedestals
{
	NS_DURING
		short j;
		for (j = 23; j >= 0; j--){							
			unsigned long aValue = 0UL;
			[self write:kMtcSerialReg value:aValue | MTC_SERIAL_REG_SEN];
			[self write:kMtcSerialReg value:aValue | MTC_SERIAL_SHFTCLKPS];
		}
		[self loadEnablePulser];
		[self enablePulser];
		[self basicMTCPedestalGTrigSetup];

		[self setSingleGTWordMask:MTC_EXT_8_MASK];	
			
		short i;
		for (i = 0; i < numPedestals; i++){
			[ORTimer delay:0.005];					// 5 ms delay
			[self write:kMtcSoftGtReg value:0];		//value doesn't matter
		}
		
		[self clearSingleGTWordMask:MTC_EXT_8_MASK];
		[self disablePulser];
		[self disablePedestal];
	
	NS_HANDLER
		NSLog(@"couldn't fire pedestal\n");
		[localException raise];
	NS_ENDHANDLER
}

- (void) basicMTCReset
{
	NS_DURING
		if (!mtcDataBase)			
			[self loadMtcDataBase];
	
		[self disablePulser];
		[self clearGTCrateMask];
		[self clearPedestalCrateMask];		
		[self clearGlobalTriggerWordMask];
		[self resetTheMemory];
		[self zeroTheGTCounter];
		[self setTheLockoutWidth: uLongDBValue(kLockOutWidth)];		
		[self setThePrescaleValue];		
	
	NS_HANDLER
		NSLog(@"Could not perform basic MTC reset!\n");
	
	NS_ENDHANDLER
}


- (void) loadMtcDataBase
{
/*
	// check to see the database pointers exist, if not create them										  
	if (the_mtc_db == NIL_POINTER){
		the_mtc_db = new CMTC_DB;
		the_mtc_db -> IMTC_DB();
		openedMtc_Database = TRUE;
	}
	
	// STEP 2: Read the database file
	// the MTC four letter code for now is hardwired to be kDefaultMtcRecord --- QRA: 5/11/97			
	the_mtc_db->Read_Data(kDefaultMtcRecord);				
	if ( the_mtc_db -> Key() == 0 ){ 	// not a valid key

		the_mtc_db->SetToDefaultVals();
		//load default values
		the_mtc_db->Write_Data(the_mtc_db->Key());

		the_mtc_db->Read_Data(the_mtc_db->Key());
		if(the_mtc_db->Key() != kDefaultMtcRecord){
			//still did not read back the proper key
			//nothing more to be done..give up
			Failure(kSilentErr,0);
			NSLog(@"MTC database not found!\n");
		}

	}
*/
}

- (void) loadTheMTCADacs
{
/*
	//-------------- variables -----------------

	short	index, bitIndex, dacIndex;
	unsigned short	dacValues[14];
	unsigned long   aValue = 0;


	//-------------- variables -----------------

	NS_DURING
		
		// STEP 1: Open the database file if not already opened
		if (!parameters)[self loadParameters];
					
		// STEP 3: load the DAC values from the database into dacValues[14]
		for (index = 0; index < 14 ; index++)
			dacValues[index] = the_mtc_db -> Trigger_DAC(CMTC_DB::sMTCTriggerInfo[index].db_index);
			dacValues[index] = [parameters uLongForKey: index:index]; -> Trigger_DAC(CMTC_DB::sMTCTriggerInfo[index].db_index);

		// STEP 4: Set DACSEL in Register 2 high[in hardware it's inverted -- i.e. it is set low]
		[self write:kMtcDacCntReg value:MTC_DAC_CNT_DACSEL];
		
		// STEP 5: now parallel load the 16bit word into the serial shift register
		// STEP 5a: the first 4 bits are loaded zeros 
		aValue = 0UL;
		for (index = 0; index < 4 ; index++){

			// data bit, with DACSEL high, clock low
			[self write:kMtcDacCntReg value:aValue | MTC_DAC_CNT_DACSEL];

			// clock high
			[self write:kMtcDacCntReg value:aValue | MTC_DAC_CNT_DACSEL | MTC_DAC_CNT_DACCLK];

			// clock low
			[self write:kMtcDacCntReg value:aValue | MTC_DAC_CNT_DACSEL];
		}

		//STEP 5b:  now build the word and load the next 12 bits, load MSB first
		for (bitIndex = 11; bitIndex >= 0 ; bitIndex--){

			aValue = 0UL;

			for (dacIndex = 0; dacIndex < 14 ; dacIndex++){

				if ( dacValues[dacIndex] & (1UL << bitIndex) )
					aValue |= (1UL << dacIndex);
			}

			// data bit, with DACSEL high, clock low
			[self write:kMtcDacCntReg value:aValue | MTC_DAC_CNT_DACSEL];

			// clock high
			[self write:kMtcDacCntReg value:aValue | MTC_DAC_CNT_DACSEL | MTC_DAC_CNT_DACCLK];

			// clock low
			[self write:kMtcDacCntReg value:aValue | MTC_DAC_CNT_DACSEL];
		}

		// STEP 5: Set DACSEL in Register 2 low[in hardware it's inverted -- i.e. it is set high], with all other bits low
		[self write:kMtcDacCntReg value:0];
	
	NS_HANDLER
		NSLog(@"Could not load the MTC/A DACs!\n");
	
	
	NS_ENDHANDLER
		
*/
}

- (void) loadMTCXilinx
{

	//--------------------------- The file format as of 1/7/97 -------------------------------------
	//
	// 1st field: Beginning of the comment block -- /
	//			  If no backslash then you will get an error message and Xilinx load will abort
	// Now include your comment.
	// The comment block is delimited by another backslash.
	// If no backslash at the end of the comment block then you will get error message.
	//
	// After the comment block include the data in ACSII binary.
	// No spaces or other characters in between data. It will complain otherwise.
	//
	//----------------------------------------------------------------------------------------------

	//-------------- variables -----------------
	NSData* theData;	

	unsigned long bitCount		= 0UL;
	unsigned long readValue		= 0UL;
	unsigned long aValue		= 0UL;
	
	BOOL firstPass = TRUE;

	const unsigned long DATA_HIGH_CLOCK_LOW = 0x00000001; 	 // bit 0 high and bit 1 low
	const unsigned long DATA_LOW_CLOCK_LOW  = 0x00000000;  	 // bit 0 low and bit 1 low

	//------------------------------------------
	

//	NSLog(@"Loading the MTC Xilinx chips....\n"); 
	
	NS_DURING
		
		// setup the file name 		
		[self setUpTheFile];
		theData = [loadFile readDataToEndOfFile];			// load the entire content of the file
		char* charData = (char*)[theData bytes];

		long index = [theData length];	// total number of charcters 
		
		// set  all bits, except bit 3[PROG_EN], low -- new step 1/16/97
		aValue = 0x00000008;
		[self write:kMtcXilProgReg value:aValue];

		// set  all bits, except bit 1[CCLK], low
		aValue = 0x00000002;						
		[self write:kMtcXilProgReg value:aValue];

		[ORTimer delay:.1]; // 100 msec delay
		unsigned long i;
		for (i = 1;i < index;i++){

			if ( (firstPass) && (*charData != '/') ){
				*charData++;
				[self finishXilinxLoad];
				[theData release];
				theData = nil;				
				NSLog(@"Invalid first character in Xilinx file.\n");
				[NSException raise:@"Xilinx load failed" format:@""];
			}
			
			if (firstPass){

				*charData++;							// for the first slash
				i++;  									// need to keep track of i
	   							 
				while(*charData++ != '/'){

					i++;
					if ( i>index ){
						[self finishXilinxLoad];				
						[theData release];
						theData = nil;				
						NSLog(@"Comment block not delimited by a backslash.\n");	
						[NSException raise:@"Xilinx load failed" format:@""];
					}

				}

			}
			firstPass = FALSE;

			// strip carriage return, tabs
			if ( ((*charData =='\r') || (*charData =='\n') || (*charData =='\t' )) && (!firstPass) ){		
				*charData++;
			}
			else{

				bitCount++;

				if ( *charData == '1' ) {
					aValue = DATA_HIGH_CLOCK_LOW;	// bit 0 high and bit 1 low
				}
				else if ( *charData == '0' ) {
					aValue = DATA_LOW_CLOCK_LOW;	// bit 0 low and bit 1 low
				}
				else {
					[self finishXilinxLoad];				
					[theData release];
					theData = nil;				
					NSLog(@"Invalid character in Xilinx file.\n");
					[NSException raise:@"Xilinx load failed" format:@""];
				}
				*charData++;
												
				[self write:kMtcXilProgReg value:aValue];
			    // perform bitwise OR to set the bit 1 high[toggle clock high] 
				aValue |= (1UL << 1);		

				[self write:kMtcXilProgReg value:aValue];
				
			}
			
		}

		[ORTimer delay:.100]; // 100 msec delay

		// check to see if the Xilinx was loaded properly 
		// read the bit 2, this should be high if the Xilinx was loaded
		readValue = [self read:kMtcXilProgReg];

		if (!(readValue & 0x000000010))	// bit 4, PROGRAM*, should be high for Xilinx success		
			NSLog(@"Xilinx load failed for the MTC/D!\n");

		[self finishXilinxLoad];
		[theData release];
		theData = nil;				
		
	NS_HANDLER
	
		[self finishXilinxLoad];
		[theData release];
		theData = nil;				
		NSLog(@"Xilinx load failed for the MTC/D.\n");
	
	NS_ENDHANDLER
}

- (void) setUpTheFile
{
	//setup the file parameters for the xilinx load operation	
	if([[NSFileManager defaultManager] fileExistsAtPath:loadFilePath]){
		loadFile = [[NSFileHandle fileHandleForReadingAtPath:loadFilePath] retain];
	}
	else NSLog(@"Couldn't open the MTC Xilinx file %s!\n",loadFilePath);
}

- (void) finishXilinxLoad
{
	[loadFile closeFile];
	[loadFile release];
	loadFile = nil;
}

- (void) setTubRegister
{
	NS_DURING

		if (!mtcDataBase) [self loadMtcDataBase];
	//	unsigned long aValue = [parameters uLongForKey:kTubRegister];
	unsigned long aValue =0;   ////remove and reinstate above line+++++++++++++++++++++++++++++++
		
		unsigned long shift_value;
		unsigned long theRegValue;
		theRegValue = [self read:kMtcDacCntReg];
		short j;
		for ( j = 0; j < 32; j++) {
			shift_value = ((aValue >> j) & 0x01) == 1 ? TUB_SDATA : 0;
			theRegValue &= ~0x00001c00;   // only alter in TUB prog bits
			[self write:kMtcDacCntReg value:theRegValue];
			theRegValue |= shift_value;
			[self write:kMtcDacCntReg value:theRegValue];
			theRegValue |= TUB_SCLK;      // clock in SDATA
			[self write:kMtcDacCntReg value:theRegValue];
		}
	
		theRegValue = [self read:kMtcDacCntReg];
		theRegValue &= ~0x00001c00;
		[self write:kMtcDacCntReg value:theRegValue];
		theRegValue |= TUB_SLATCH;
		[self write:kMtcDacCntReg value:theRegValue];
		theRegValue &= ~0x00001c00;
		[self write:kMtcDacCntReg value:theRegValue];
				
		NSLog(@"0x%x was shifted into the TUB serial register\n", aValue);
	
	NS_HANDLER
		NSLog(@"Failed to load Tub serial register\n");
	NS_ENDHANDLER
}

#pragma mark •••BasicOps
- (void) readBasicOps
{
	doReadOp = YES;
	workingCount = 0;
	[self setBasicOpsRunning:YES];
	[self doBasicOp];
}

- (void) writeBasicOps
{
	doReadOp = NO;
	workingCount = 0;
	[self setBasicOpsRunning:YES];
	[self doBasicOp];
}

- (void) stopBasicOps
{
	[self setBasicOpsRunning:NO];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doBasicOp) object:nil];
}

- (void) reportStatus
{
	NSLog(@"Mtc control reg: 0x%0x\n", [self getMTC_CSR]);
}

- (void) saveSet:(NSString*)filePath
{
	[mtcDataBase writeToFile:filePath atomically:NO];
} 

- (void) loadSet:(NSString*)filePath
{	
	[self setMtcDataBase:[NSMutableDictionary dictionaryWithContentsOfFile: filePath]];
	[self setLastFileLoaded:filePath];
}

@end

@implementation ORMTCModel (private)

- (void) doBasicOp
{
	NS_DURING
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doBasicOp) object:nil];
		if(useMemory){
			if(doReadOp){
				NSLog(@"%@: %d\n",reg[selectedRegister].regName,[self read:selectedRegister]);
			}
			else {
				[self write:selectedRegister value:writeValue];
				NSLog(@"Wrote %d to %@\n",writeValue,reg[selectedRegister].regName);
			}
		}
		else {
			//TBD.....
			if(doReadOp){
			}
			else {
			}
		}
		if(++workingCount<repeatCount){
			[self performSelector:@selector(doBasicOp) withObject:nil afterDelay:repeatDelay/1000.];
		}
		else {
			[self setBasicOpsRunning:NO];
		}
	NS_HANDLER
		NSLog(@"Mtc basic op exception: %@\n",localException);
	NS_ENDHANDLER
}

- (void) setupDefaults
{
	NSMutableDictionary* aDictionary = [NSMutableDictionary dictionaryWithCapacity:100];
	int i;
	for(i=0;i<kDBComments;i++){
		NSDecimalNumber* defaultValue = [NSDecimalNumber decimalNumberWithString:[self getDBDefaultByIndex:i]];
		[aDictionary setObject:defaultValue forNestedKey:[self getDBKeyByIndex:i]];
	}
	for(i=kDBComments;i<kDbLookUpTableSize;i++){
		[aDictionary setObject:[self getDBDefaultByIndex:i] forNestedKey:[self getDBKeyByIndex:i]];
	}
	[self setMtcDataBase:aDictionary];

}



@end

