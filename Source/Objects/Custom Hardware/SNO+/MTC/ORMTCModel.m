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
#import "ORReadOutList.h"
#import "SBC_Config.h"
#import "VME_HW_Definitions.h"
#import "SNOCmds.h"
#import "SBC_Link.h"
#import "ORSelectorSequence.h"

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
NSString* ORMTCModelXilinxPathChanged		= @"ORMTCModelXilinxPathChanged";
NSString* ORMTCModelMtcDataBaseChanged		= @"ORMTCModelMtcDataBaseChanged";
NSString* ORMTCModelLastFileLoadedChanged	= @"ORMTCModelLastFileLoadedChanged";
NSString* ORMtcTriggerNameChanged			= @"ORMtcTriggerNameChanged";

NSString* ORMTCLock							= @"ORMTCLock";

#define kMTCRegAddressBase		0x00007000
#define kMTCRegAddressModifier	0x29
#define kMTCRegAddressSpace		0x01
#define kMTCMemAddressBase		0x03800000
#define kMTCMemAddressModifier	0x09
#define kMTCMemAddressSpace		0x02

static SnoMtcNamesStruct reg[kMtcNumRegisters] = {
{ @"ControlReg"	    , 0   ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //0
{ @"SerialReg"		, 4   ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //1
{ @"DacCntReg"		, 8   ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //2
{ @"SoftGtReg"		, 12  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //3
{ @"Pedestal Width"	, 16  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //4
{ @"Coarse Delay"	, 20  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //5
{ @"Fine Delay"		, 24  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //6
{ @"ThresModReg"	, 28  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //7
{ @"PmskReg"		, 32  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //8
{ @"ScaleReg"		, 36  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //9
{ @"BwrAddOutReg"	, 40  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //10
{ @"BbaReg"		, 44  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //11
{ @"GtLockReg"		, 48  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //12
{ @"MaskReg"		, 52  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //13
{ @"XilProgReg"		, 56  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //14
{ @"GmskReg"		, 60  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //15
{ @"OcGtReg"		, 128 ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //16
{ @"C50_0_31Reg"	, 132 ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //17
{ @"C50_32_42Reg"	, 136  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //18
{ @"C10_0_31Reg"	, 140 ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //19
{ @"C10_32_52Reg"	, 144 ,kMTCRegAddressModifier, kMTCRegAddressSpace }	//20
};

static SnoMtcDBInfoStruct dbLookUpTable[kDbLookUpTableSize] = {
{ @"MTC/D,LockOutWidth",	   	@"420" },   //0
{ @"MTC/D,PedestalWidth",		@"52" },   //1
{ @"MTC/D,Nhit100LoPrescale",	@"1" },   //2
{ @"MTC/D,PulserPeriod",		@"10.0" },   //3
{ @"MTC/D,Low10MhzClock",		@"0" },   //4
{ @"MTC/D,High10MhzClock",		@"0" },   //5
{ @"MTC/D,FineSlope",			@"0.0" },   //6
{ @"MTC/D,MinDelayOffset",		@"18.0" },   //7
{ @"MTC/D,CoarseDelay",			@"60" },   //8
{ @"MTC/D,FineDelay",			@"0" },   //9
{ @"MTC/D,GtMask",				@"0" }, //10
{ @"MTC/D,GtCrateMask",			@"0" },	//11
{ @"MTC/D,PEDCrateMask",		@"0" },	//12
{ @"MTC/D,ControlMask",			@"0" },		//13

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

{ @"MTC,tub",					@"40"},		//54

{@"Comments",					@"Nothing Noted"},		//55
{@"XilinxFilePath",				@"--"},		//56

};

int mtcDacIndexes[14]=
{
kNHit100HiThreshold,	
kNHit100MedThreshold,
kNHit100LoThreshold,	
kNHit20Threshold,	
kNHit20LBThreshold,	
kOWLNThreshold,		
kESumLowThreshold,	
kESumHiThreshold,	
kOWLELoThreshold,	
kOWLEHiThreshold,
kControlMask,
kGtMask,
kGtCrateMask,
kPEDCrateMask
};

@interface ORMTCModel (private)
- (void) doBasicOp;
- (void) setupDefaults;
@end

@interface ORMTCModel (SBC)
- (void) loadXilinxUsingSBC:(NSData*) theData;
@end

@interface ORMTCModel (LocalAdapter)
- (void) loadXilinxUsingLocalAdapter:(NSData*) theData;
@end

@implementation ORMTCModel

- (id) init //designated initializer
{
    self = [super init];
	
    [[self undoManager] disableUndoRegistration];
	[self setTriggerName:@"Trigger"];
    
    ORReadOutList* r1 = [[ORReadOutList alloc] initWithIdentifier:triggerName];
    [self setTriggerGroup:r1];
    [r1 release];
	
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void) dealloc
{
    [triggerGroup release];
    [defaultFile release];
    [lastFile release];
    [lastFileLoaded release];
    [mtcDataBase release];
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

- (unsigned short) addressModifier
{
	return 0x29;
}

- (ORReadOutList*) triggerGroup
{
    return triggerGroup;
}

- (void) setTriggerGroup:(ORReadOutList*)newTriggerGroup
{
    [triggerGroup autorelease];
    triggerGroup=[newTriggerGroup retain];
}
- (NSString *) triggerName
{
    return triggerName;
}

- (void) setTriggerName: (NSString *) aTriggerName
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerName:triggerName];
    [triggerName autorelease];
    triggerName = [aTriggerName copy];
    
    [triggerGroup setIdentifier:triggerName];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMtcTriggerNameChanged
                                                        object:self];
    
    
}

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

- (NSString*) xilinxFilePath
{
    return [self dbObjectByIndex:kXilinxFile];
}

- (void) setXilinxFilePath:(NSString*)aDefaultFile
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

- (short) repeatOpCount
{
    return repeatOpCount;
}

- (void) setRepeatOpCount:(short)aRepeatCount
{
	if(aRepeatCount<=0)aRepeatCount = 1;
    [[[self undoManager] prepareWithInvocationTarget:self] setRepeatOpCount:repeatOpCount];
    
    repeatOpCount = aRepeatCount;
	
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


//hardcoded base addresses (unlikely to ever change)
- (unsigned long) memBaseAddress
{
    return kMTCMemAddressBase;
}

- (unsigned long) memAddressModifier
{
	return kMTCMemAddressModifier;
}

- (unsigned long) baseAddress
{
    return kMTCRegAddressBase;
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
- (NSMutableArray*) children {
    //methods exists to give common interface across all objects for display in lists
    return [NSMutableArray arrayWithObjects:triggerGroup,nil];
}

- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORMTCDecoderForMTC",	@"decoder",
								 [NSNumber numberWithLong:dataId], @"dataId",
								 [NSNumber numberWithBool:NO], @"variable",
								 [NSNumber numberWithLong:7], @"length",  //****put in actual length
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"MTC"];
    
    return dataDictionary;
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{        
    if(![[self adapter] controllerCard]){
		[NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
    }
    
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORMTCModel"];
    
	
    dataTakers = [[triggerGroup allObjects] retain];	//cache of data takers.
    
    NSEnumerator* e = [dataTakers objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
		[obj runTaskStarted:aDataPacket userInfo:userInfo];
    }
	
}

//**************************************************************************************
// Function:	TakeData
// Description: Read data from a card From Mac. IfSBC is used, then this routine is NOT used.
//**************************************************************************************
-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    NSString* errorLocation = @"";
    
    @try {
		//errorLocation = @"Reading Status Reg";
		//do something to see if the fecs need to be read out.
		//if((statusReg & kTrigger1EventMask)){
		//OK finally go out and read all the data takers scheduled to be read out with a trigger 1 event.
		//errorLocation = @"Reading Children";
		//[self _readOutChildren:dataTakers1 dataPacket:aDataPacket  useParams:YES withGTID:gtid isMSAMEvent:isMSAMEvent];
		//}
		
	}
	@catch(NSException* localException) {
		NSLogError(@"",@"Mtc Error",errorLocation,nil);
		[self incExceptionCount];
		[localException raise];
	}
	
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    NSEnumerator* e = [dataTakers objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
		[obj runTaskStopped:aDataPacket userInfo:userInfo];
    }
	
    [dataTakers release];
}

- (void) saveReadOutList:(NSFileHandle*)aFile
{
    [triggerGroup saveUsingFile:aFile];
}

- (void) loadReadOutList:(NSFileHandle*)aFile
{
    [self setTriggerGroup:[[[ORReadOutList alloc] initWithIdentifier:@"Mtc Trigger"]autorelease]];
    [triggerGroup loadUsingFile:aFile];
}

//this is the data structure for the new SBCs (i.e. VX704 from Concurrent)
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
    configStruct->total_cards++;
    configStruct->card_info[index].hw_type_id		= kMtc;			//should be unique 
    configStruct->card_info[index].hw_mask[0]		= dataId;		//better be unique
    configStruct->card_info[index].slot				= [self slot];
    configStruct->card_info[index].add_mod			= [self addressModifier];
    configStruct->card_info[index].base_add			= [self baseAddress];
	configStruct->card_info[index].deviceSpecificData[0] = reg[kMtcBbaReg].addressOffset;
	configStruct->card_info[index].deviceSpecificData[1] = reg[kMtcBwrAddOutReg].addressOffset;
	configStruct->card_info[index].deviceSpecificData[2] = [self memBaseAddress];
	configStruct->card_info[index].deviceSpecificData[3] = [self memAddressModifier];	
	configStruct->card_info[index].num_Trigger_Indexes = 0; //no children
	configStruct->card_info[index].next_Card_Index = index + 1;
	
	return index + 1;

	
// this doesn't work in the XL3 push mode
// it would be great if it did
/*
	configStruct->card_info[index].num_Trigger_Indexes = 1;
	int nextIndex = index+1;
    
	configStruct->card_info[index].next_Trigger_Index[0] = -1;
	NSEnumerator* e = [dataTakers objectEnumerator];
	id obj;
	while(obj = [e nextObject]){
		if([obj respondsToSelector:@selector(load_HW_Config_Structure:index:)]){
			if(configStruct->card_info[index].next_Trigger_Index[0] == -1){
				configStruct->card_info[index].next_Trigger_Index[0] = nextIndex;
			}
			int savedIndex = nextIndex;
			nextIndex = [obj load_HW_Config_Structure:configStruct index:nextIndex];
			if(obj == [dataTakers lastObject]){
				configStruct->card_info[savedIndex].next_Card_Index = -1; //make the last object a leaf node
			}
		}
	}
	
    configStruct->card_info[index].next_Card_Index 	 = nextIndex;
    
    return nextIndex;
*/
	
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
    [self setRepeatOpCount:	[decoder decodeIntForKey:		@"ORMTCModelRepeatCount"]];
    [self setWriteValue:	[decoder decodeInt32ForKey:		@"ORMTCModelWriteValue"]];
    [self setMemoryOffset:	[decoder decodeInt32ForKey:		@"ORMTCModelMemoryOffset"]];
    [self setSelectedRegister:[decoder decodeIntForKey:		@"ORMTCModelSelectedRegister"]];
    [self setMtcDataBase:	[decoder decodeObjectForKey:	@"ORMTCModelMtcDataBase"]];
    [self setTriggerGroup:  [decoder decodeObjectForKey:    @"ORMtcTriggerGroup"]];
    [self setTriggerName:	[decoder decodeObjectForKey:	@"ORMtcTrigger1Name"]];
	
	if(!mtcDataBase)[self setupDefaults];
    if(triggerName == nil || [triggerName length]==0){
        [self setTriggerName:@"Trigger"];
    }
	
	
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
	[encoder encodeInt:repeatOpCount	forKey:@"ORMTCModelRepeatCount"];
	[encoder encodeInt32:writeValue		forKey:@"ORMTCModelWriteValue"];
	[encoder encodeInt32:memoryOffset	forKey:@"ORMTCModelMemoryOffset"];
	[encoder encodeInt:selectedRegister forKey:@"ORMTCModelSelectedRegister"];
	[encoder encodeObject:mtcDataBase	forKey:@"ORMTCModelMtcDataBase"];
    [encoder encodeObject:triggerGroup	forKey:@"ORMtcTriggerGroup"];
    [encoder encodeObject:triggerName	forKey:@"ORMtcTriggerName"];
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
	if (anIndex < kDBComments && [anObject isKindOfClass:[NSString class]]) {
		NSDecimalNumber* aValue = [NSDecimalNumber decimalNumberWithString:anObject];
		[mtcDataBase setObject:aValue forNestedKey:[self getDBKeyByIndex:anIndex]];
	}
	else {
		[mtcDataBase setObject:anObject forNestedKey:[self getDBKeyByIndex:anIndex]];
	}

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelMtcDataBaseChanged object:self];
}

- (short)     dbLookTableSize					  { return kDbLookUpTableSize; }
- (id)        dbObjectByIndex:(int)anIndex		  { return [mtcDataBase objectForNestedKey:[self getDBKeyByIndex:anIndex]]; }
- (float)     dbFloatByIndex:(int)anIndex		  { return [[mtcDataBase objectForNestedKey:[self getDBKeyByIndex:anIndex]] floatValue]; }
- (int)       dbIntByIndex:(int)anIndex			  { return [[mtcDataBase objectForNestedKey:[self getDBKeyByIndex:anIndex]] intValue]; }
- (id)        dbObjectByName:(NSString*)aKey	  { return [mtcDataBase objectForNestedKey:aKey]; }
- (NSString*) getDBKeyByIndex:(short) anIndex	  { return dbLookUpTable[anIndex].key; }
- (NSString*) getDBDefaultByIndex:(short) anIndex { return dbLookUpTable[anIndex].defaultValue;  }
- (int)       dacValueByIndex:(short)anIndex	  { return [self dbIntByIndex:mtcDacIndexes[anIndex]]; }

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
	@try {
		[[self adapter] readLongBlock:&theValue
							atAddress:[self baseAddress]+reg[aReg].addressOffset
							numToRead:1
						   withAddMod:reg[aReg].addressModifier
						usingAddSpace:reg[aReg].addressSpace];
	}
	@catch(NSException* localException) {
		NSLog(@"Couldn't read the MTC %@!\n",reg[aReg].regName);
		[localException raise];
	}
	return theValue;
}

- (void) write:(int)aReg value:(unsigned long)aValue
{
	@try {
		[[self adapter] writeLongBlock:&aValue
							 atAddress:[self baseAddress]+reg[aReg].addressOffset
							numToWrite:1
							withAddMod:reg[aReg].addressModifier
						 usingAddSpace:reg[aReg].addressSpace];
	}
	@catch(NSException* localException) {
		NSLog(@"Couldn't write %d to the MTC %@!\n",aValue,reg[aReg].regName);
		[localException raise];
	}
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
	unsigned long aValue = 0;
	@try {
		aValue =   [self read:kMtcControlReg];
	}
	@catch(NSException* localException) {
		NSLog(@"Couldn't get a MTC CSR!\n");
		NSLog(@"Exception: %@\n",localException);
	}
	return aValue;
}

- (unsigned long) getMTC_GTID
{
	unsigned long aValue = 0;
	@try {
		aValue =  [self read:kMtcOcGtReg] & 0xffffff;
	}
	@catch(NSException* localException) {
		NSLog(@"Couldn't get a MTC GTID!\n");
		NSLog(@"Exception: %@\n",localException);
	}
	return aValue;
}

- (unsigned long) getMTC_PedWidth
{
	unsigned long aValue = 0;
	@try {
		aValue =  [self read:kMtcPwIdReg] & 0xff;
	}
	@catch(NSException* localException) {
		NSLog(@"Couldn't get a MTC Ped Width!\n");
		NSLog(@"Exception: %@\n",localException);
	}
	return aValue;
}

- (unsigned long) getMTC_CoarseDelay
{
	unsigned long aValue = 0;
	@try {
		aValue = [self read:kMtcRtdelReg] & 0xff;
	}
	@catch(NSException* localException) {
		NSLog(@"Couldn't get a MTC Coarse Delay!\n");
		NSLog(@"Exception: %@\n",localException);
	}
	return aValue;
}

- (unsigned long) getMTC_FineDelay
{
	unsigned long aValue = 0;
	@try {
		aValue = [self read:kMtcAddelReg] & 0xff;
	}
	@catch(NSException* localException) {
		NSLog(@"Couldn't get a MTC Fine Delay!\n");
		NSLog(@"Exception: %@\n",localException);
	}
	return aValue;
}

- (void) sendMTC_SoftGt
{
	[self sendMTC_SoftGt:NO];
}

- (void) sendMTC_SoftGt:(BOOL) setGTMask
{
	@try {
		if(setGTMask)[self setSingleGTWordMask:MTC_SOFT_GT_MASK];   // Step 1: set the SOFT_GT mask
		[self write:kMtcSoftGtReg value:1];							// Step 2: write to the soft gt register (doesn't matter what you write to it)
		[self clearSingleGTWordMask:MTC_SOFT_GT_MASK];				// Step 3: clear the SOFT_GT mask
	}
	@catch(NSException* localException) {
		NSLog(@"Couldn't send a MTC SOFT_GT!\n");
		NSLog(@"Exception: %@\n",localException);
	}
	
}
#define uShortDBValue(A) [[mtcDataBase objectForNestedKey:[self getDBKeyByIndex: A]] unsignedShortValue]
#define uLongDBValue(A)  [[mtcDataBase objectForNestedKey:[self getDBKeyByIndex: A]] unsignedLongValue]

- (void) initializeMtc:(BOOL) loadTheMTCXilinxFile load10MHzClock:(BOOL) loadThe10MHzClock
{
	@try {		
		NSLog(@"Starting MTC init process....(load Xilinx: %@) (10MHzClock: %@)\n",loadTheMTCXilinxFile?@"YES":@"NO",loadThe10MHzClock?@"YES":@"NO");
		
		ORSelectorSequence* seq = [ORSelectorSequence selectorSequenceWithDelegate:self];
		if (loadTheMTCXilinxFile) [[seq forTarget:self] loadMTCXilinx];				// STEP 1 : Load the Xilinx
		[[seq forTarget:self] clearGlobalTriggerWordMask];							// STEP 2: Clear the GT Word Mask
		[[seq forTarget:self] clearPedestalCrateMask];								// STEP 3: Clear the Pedestal Crate Mask
		[[seq forTarget:self] clearGTCrateMask];									// STEP 4: Clear the GT Crate Mask
		[[seq forTarget:self] loadTheMTCADacs];										// STEP 5: Load the DACs	
		[[seq forTarget:self] clearTheControlRegister];								// STEP 6: Clear the Control Register
		[[seq forTarget:self] zeroTheGTCounter];									// STEP 7: Clear the GT Counter
		[[seq forTarget:self] setTheLockoutWidth:uShortDBValue(kLockOutWidth)];		// STEP 8: Set the Lockout Width	
		[[seq forTarget:self] setThePrescaleValue];									// STEP 9:  Load the NHIT 100 LO prescale value
		[[seq forTarget:self] setThePulserRate:uLongDBValue(kPulserPeriod)];		// STEP 10: Load the Pulser
		[[seq forTarget:self] setThePedestalWidth:uLongDBValue(kPedestalWidth)];	// STEP 11: Set the Pedestal Width
		[[seq forTarget:self] setupPulseGTDelaysCoarse:uLongDBValue(kCoarseDelay) fine:uLongDBValue(kFineDelay)]; // STEP 12: Setup the Pulse GT Delays
		if( loadThe10MHzClock)[[seq forTarget:self] setMtcTime];					// STEP 13: Load the 10MHz Counter
		[[seq forTarget:self] resetTheMemory];										// STEP 14: Reset the Memory	 
		//[[seq forTarget:self] setGTCrateMask];									// STEP 15: Set the GT Crate Mask from MTC database
		[[seq forTarget:self] initializeMtcDone];
		[seq startSequence];
		
	}
	@catch(NSException* localException) {
		NSLog(@"***Initialization of the MTC (%@ Xilinx, %@ 10MHz clock) failed!***\n", 
			  loadTheMTCXilinxFile?@"with":@"no", loadThe10MHzClock?@"load":@"don't load");
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}
}

- (void) initializeMtcDone
{
	NSLog(@"Initialization of the MTC complete.\n");
}

- (void) clearGlobalTriggerWordMask
{
	@try {
		[self write:kMtcMaskReg value:0];
		NSLog(@"Cleared GT Mask\n");
	}
	@catch(NSException* localException) {
		NSLog(@"Could not clear GT word mask!\n");					
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}
}

- (void) setGlobalTriggerWordMask
{
	@try {
		[self write:kMtcMaskReg value:uLongDBValue(kGtMask)];
		NSLog(@"Set GT Mask: 0x%08x\n",uLongDBValue(kGtMask));
	}
	@catch(NSException* localException) {
		NSLog(@"Could not set a set GT word mask!\n");					
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}
}


- (unsigned long) getMTC_GTWordMask
{
	unsigned long aValue = 0;
	@try {	
		aValue =  [self read:kMtcGmskReg] & 0x03FFFFFF;							
	}
	@catch(NSException* localException) {
		NSLog(@"Could not get GT word mask!\n");					
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}
	return aValue;
}

- (void) setSingleGTWordMask:(unsigned long) gtWordMask
{	
	@try {
		[self setBits:kMtcMaskReg mask:gtWordMask];
		NSLog(@"Set GT Mask: 0x%08x\n",uLongDBValue(kGtMask));
	}
	@catch(NSException* localException) {
		NSLog(@"Could not set a MTC GT word mask!\n");					
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}
}

- (void) clearSingleGTWordMask:(unsigned long) gtWordMask
{
	@try {
		[self clrBits:kMtcGmskReg mask:gtWordMask];
		NSLog(@"Set GT Mask: 0x%08x\n",uLongDBValue(kGtMask));
	}
	@catch(NSException* localException) {
		NSLog(@"Could not clear a MTC GT word mask!\n");					
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}	
}

- (void) clearPedestalCrateMask
{
	@try {
		[self write:kMtcPmskReg value:0];
		NSLog(@"Cleared Ped Mask\n");
	}
	@catch(NSException* localException) {
		NSLog(@"Could not clear a Ped mask!\n");					
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}	
}

- (void) setPedestalCrateMask
{
	@try {
		[self write:kMtcPmskReg value: uLongDBValue(kPEDCrateMask)];
		NSLog(@"Set Ped Mask: 0x%08x\n",uLongDBValue(kPEDCrateMask));
	}
	@catch(NSException* localException) {
		NSLog(@"Could not set a Ped crate mask!\n");					
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}	
}

- (void) clearGTCrateMask
{
	@try {
		[self write:kMtcGmskReg value:0];
		NSLog(@"Cleared GT Crate Mask\n");
	}
	@catch(NSException* localException) {
		NSLog(@"Could not clear GT crate mask!\n");					
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}	
}

- (void) setGTCrateMask
{
	@try {
		[self write:kMtcGmskReg value: uLongDBValue(kGtCrateMask)];
		NSLog(@"Set GT Crate Mask: 0x%08x\n",uLongDBValue(kGtCrateMask));
	}
	@catch(NSException* localException) {
		NSLog(@"Could not set GT crate mask!\n");					
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}	
}

- (unsigned long) getGTCrateMask
{
	unsigned long aValue = 0;
	@try {
		aValue =  [self read:kMtcGmskReg] & 0x01FFFFFF;	
	}
	@catch(NSException* localException) {
		NSLog(@"Could not get GT crate mask!\n");					
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}
	return aValue;	
}

- (void) clearTheControlRegister
{
	@try {
		[self write:kMtcControlReg value:0];
		NSLog(@"Cleared Control Reg\n");
	}
	@catch(NSException* localException) {
		NSLog(@"Could not clear control reg!\n");					
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}
}

- (void) resetTheMemory
{
	@try {
		//Clear the MTC/D memory, the fifo write pointer and the BBA Register
		[self write:kMtcBbaReg value:0];
		[self setBits:kMtcControlReg mask:MTC_CSR_FIFO_RESET];
		[self clrBits:kMtcControlReg mask:MTC_CSR_FIFO_RESET];
		NSLog(@"Reset MTC memory\n");
	}
	@catch(NSException* localException) {
		NSLog(@"Could not reset MTC memory!\n");					
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}
}

- (void) setTheGTCounter:(unsigned long) theGTCounterValue
{
	@try {
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
		NSLog(@"Loaded the GT counter\n");			
	}
	@catch(NSException* localException) {
		NSLog(@"Could not load the MTC GT counter!\n");			
		[localException raise];
	}
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
		theSecondsToSubtract =  (unsigned long)[[NSDate date] timeIntervalSinceDate:[NSCalendarDate dateWithYear:1996 month:1 day:1 hour:0 minute:0 second:0 timeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]]];
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
	@try {
		[self getThe10MHzCounterLow:&lower high:&upper];
		theValue =  ((double) 4294967296.0 * (double)upper + (double)lower) * 1e-7;
	}
	@catch(NSException* localException) {
		[localException raise];
	}
	return theValue;
}

- (unsigned long) getMtcTime
{
	//--get the 10MHz clock. seconds since 01/01/1904
	static unsigned long theSecondsToAdd = 0;
	
 	if( theSecondsToAdd == 0 ) {
		NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
		theSecondsToAdd =  (unsigned long)[[NSDate date] timeIntervalSinceDate:[NSCalendarDate dateWithYear:1996 month:1 day:1 hour:0 minute:0 second:0 timeZone:timeZone]];
 	}
	
    return theSecondsToAdd + (unsigned long)[self get10MHzSeconds];
	
}

- (void) load10MHzClock
{
	[self setThe10MHzCounterLow:uLongDBValue(kLow10MhzClock) high:uLongDBValue(kHigh10MhzClock)];
}

// SetThe10MHzCounter
- (void) setThe10MHzCounterLow:(unsigned long) lowerValue high:(unsigned long) upperValue
{
	unsigned long	aValue;
	
	@try {
		
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
		NSLog(@"Loaded 10MHz counter\n");
		
	}
	@catch(NSException* localException) {
		NSLog(@"Could not load the 10MHz counter!\n");
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}
}


- (void) getThe10MHzCounterLow:(unsigned long*) lowerValue high:(unsigned long*) upperValue
{
	*lowerValue = 0;
	*upperValue  = 0;
	@try {
		*lowerValue = [self read:kMtcC10_0_31Reg];
		*upperValue = [self read:kMtcC10_32_52Reg] & 0x001fffffUL;
	}
	@catch(NSException* localException) {
		NSLog(@"Could not get 10MHz counter values!\n");		
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}
}

- (void) setTheLockoutWidth:(unsigned short) theLockoutWidthValue
{
	@try {
		unsigned long lockout_index = (theLockoutWidthValue/20);
		unsigned long write_value   = (0xff - lockout_index);  //value in nano-seconds
		
		// write the GT lockout value in SMTC_GT_LOCK_REG
		[self write:kMtcGtLockReg value:write_value];
		
		// now assert and de-assert LOAD_ENLK in CONTROL REG and  
		// preserving the state of the register at the same time		
		[self clrBits:kMtcControlReg mask:MTC_CSR_LOAD_ENLK];
		[self setBits:kMtcControlReg mask:MTC_CSR_LOAD_ENLK];
		[self clrBits:kMtcControlReg mask:MTC_CSR_LOAD_ENLK];
		
		
	}
	@catch(NSException* localException) {
		NSLog(@"Could not load the MTC GT lockout width!\n");		
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}
}

- (void) setThePedestalWidth:(unsigned short) thePedestalWidthValue
{
	@try {
		unsigned long write_value = (0xff - thePedestalWidthValue/5); //value in nano-seconds
		
		// write the GT lockout value in SMTC_GT_LOCK_REG
		[self write:kMtcPwIdReg value:write_value];
		
		// now assert and de-assert LOAD_ENPW in CONTROL REG and  
		// preserving the state of the register at the same time		
		[self setBits:kMtcControlReg mask:MTC_CSR_LOAD_ENPW];
		[self clrBits:kMtcControlReg mask:MTC_CSR_LOAD_ENPW];
		
	}
	@catch(NSException* localException) {
		NSLog(@"Could not load the MTC pedestal width!\n");	
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
		
	}
}

- (void) setThePrescaleValue
{
	@try {
		//value from 1 to 65535
		unsigned long write_value = (0xffff - (uLongDBValue(kNhit100LoPrescale) - 1));// 1 prescale/~N+1 NHIT_100_LOs
		
		// write the prescale  value in MTC_SCALE_REG
		[self write:kMtcScaleReg value:write_value];
		
		// now load it : assert and de-assert LOAD_ENPR in CONTROL REG  
		// and  preserving the state of the register at the same time		
		[self clrBits:kMtcControlReg mask:MTC_CSR_LOAD_ENPR];
		[self setBits:kMtcControlReg mask:MTC_CSR_LOAD_ENPR];
		[self clrBits:kMtcControlReg mask:MTC_CSR_LOAD_ENPR];
		
	}
	@catch(NSException* localException) {
		NSLog(@"Could not load the MTC prescale value!\n");		
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
		
	}
	
}


- (void) setupPulseGTDelaysCoarse:(unsigned short) theCoarseDelay fine:(unsigned short) theAddelValue
{		
	@try {
		
		[self setupGTCorseDelay:theCoarseDelay];	
		[self setupGTFineDelay:theAddelValue];
		
		// calculate the total delay and display
		//float theTotalDelay = (theAddelValue * [parameters uLongForKey:kPed_GT_Fine_Slope])
		//				+ (float)theCoarseDelay + [parameters uLongForKey: kPed_GT_Min_Delay_Offset];
		
		//		NSLog(@"MTC total delay set to %3.2f ns.\n", theTotalDelay);
		
		
	}
	@catch(NSException* localException) {
		NSLog(@"Could not setup the MTC PULSE_GT delays!\n");	
		NSLog(@"Exception: %@\n",localException);
		[localException raise];			
		
	}
}

- (void) setupGTCorseDelay
{
	[self setupGTCorseDelay:[self dbIntByIndex:kCoarseDelay]];
}

- (void) setupGTCorseDelay:(unsigned short) theCoarseDelay
{
	@try {
		// Set the coarse GTRIG/PED delay in ns
		unsigned long aValue = (0xff - theCoarseDelay/10);
		
		[self write:kMtcRtdelReg value:aValue];
		// now load it : assert and de-assert LOAD_ENPW in CONTROL REG  
		// and  preserving the state of the register at the same time
		[self clrBits:kMtcControlReg mask:MTC_CSR_LOAD_ENPW];
		[self setBits:kMtcControlReg mask:MTC_CSR_LOAD_ENPW];
		[self clrBits:kMtcControlReg mask:MTC_CSR_LOAD_ENPW];
		NSLog(@"Set GT Coarse Delay to 0x%02x\n",aValue);
		
	}
	@catch(NSException* localException) {
		NSLog(@"Could not setup the MTC GT course delay!\n");			
		NSLog(@"Exception: %@\n",localException);
		[localException raise];			
		
	}
}

- (void) setupGTFineDelay:(unsigned short) aValue
{	
	@try {
		[self write:kMtcAddelReg value:aValue];
		NSLog(@"Set GT Fine Delay to 0x%02x\n",aValue);
	}
	@catch(NSException* localException) {
		NSLog(@"Could not set GT fine delay!\n");			
		NSLog(@"Exception: %@\n",localException);
		[localException raise];			
		
	}
}

- (void) setThePulserRate:(float) thePulserPeriodValue
{
	@try {
		[self setThePulserRate:thePulserPeriodValue setToInfinity:NO];
		NSLog(@"Set GT Pusler rate\n");			
	}
	@catch(NSException* localException) {
		NSLog(@"Could not set GT Pusler rate!\n");			
		NSLog(@"Exception: %@\n",localException);
		[localException raise];			
		
	}
}

- (void) setThePulserRate:(float) thePulserPeriodValue setToInfinity:(BOOL) setToInfinity
{
	unsigned long	pulserShiftValue;	
	
	@try {
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
		
		float frequencyValue = (float)( 781.25/((float)pulserShiftValue + 1.0) );					// in KHz
		if (frequencyValue < 0.001)		NSLog(@"Pulser frequency set @ %3.10f mHz.\n",(frequencyValue * 1000000.0));
		else if (frequencyValue <= 1.0)	NSLog(@"Pulser frequency set @ %3.10f Hz.\n",(frequencyValue * 1000.0));
		else if (frequencyValue > 1.0)	NSLog(@"Pulser frequency set @ %3.4f KHz.\n",frequencyValue);
		
		
	}
	@catch(NSException* localException) {
		NSLog(@"Could not setup the MTC pulser frequency!\n");
		[localException raise];
		
	}
}

- (void) loadEnablePulser
{
	@try {
		[self clrBits:kMtcControlReg mask:MTC_CSR_LOAD_ENPS];
		[self setBits:kMtcControlReg mask:MTC_CSR_LOAD_ENPS];
		[self clrBits:kMtcControlReg mask:MTC_CSR_LOAD_ENPS];
		NSLog(@"loaded/enabled the pulser!\n");		
	}
	@catch(NSException* localException) {
		NSLog(@"Unable to load/enable the pulser!\n");		
		[localException raise];	
	}
}

- (void) enablePulser
{
	@try {
		[self setBits:kMtcControlReg mask:MTC_CSR_PULSE_EN];
		NSLog(@"Enabled Pulser!\n");		
	}
	@catch(NSException* localException) {
		NSLog(@"Unable to enable the pulser!\n");		
		[localException raise];	
	}
}

- (void) disablePulser
{
	@try {
		[self clrBits:kMtcControlReg mask:MTC_CSR_PULSE_EN];
		NSLog(@"Disabled Pedestals!\n");		
	}
	@catch(NSException* localException) {
		NSLog(@"Unable to disable the pulser!\n");		
		[localException raise];	
	}
}

- (void)  enablePedestal
{
	@try {
		[self setBits:kMtcControlReg mask:MTC_CSR_PED_EN];
		NSLog(@"Enabled Pedestals!\n");		
	}
	@catch(NSException* localException) {
		NSLog(@"Unable to enable the Pedestals!\n");		
		[localException raise];	
	}
}

- (void)  disablePedestal
{
	@try {
		[self clrBits:kMtcControlReg mask:MTC_CSR_PED_EN];
		NSLog(@"Disabled Pedestals!\n");		
	}
	@catch(NSException* localException) {
		NSLog(@"Unable to disable the Pedestals!\n");		
		[localException raise];	
	}
}

- (void) fireMTCPedestalsFixedRate
{
	//Fire Pedestal pulses at a pecified period in ms, with a specifed 
	// 							  GT coarse delay, GT Lockout Width, pedestal width in ns and a 
	//							  specified crate mask set in MTC Databse. Trigger mask is EXT_8.
	@try {
		[self basicMTCPedestalGTrigSetup];								//STEP 1: Perfom the basic setup for pedestals and gtrigs
		[self setupPulserRateAndEnable:uLongDBValue(kPulserPeriod)];	// STEP 2 : Setup pulser rate and enable
	}
	@catch(NSException* localException) {
		NSLog(@"MTC failed to fire pedestals at the specified settings!\n");		
		[localException raise];	
	}
}

- (void) basicMTCPedestalGTrigSetup
{
	
	@try {
		//[self clearGlobalTriggerWordMask];							//STEP 0a:	//added 01/24/98 QRA
		[self enablePedestal];											// STEP 1 : Enable Pedestal	
		[self setPedestalCrateMask];									// STEP 2: Mask in crates for pedestals (PMSK)
		[self setGTCrateMask];											// STEP 3: Mask  Mask in crates fo GTRIGs (GMSK)
		[self setupPulseGTDelaysCoarse: uLongDBValue(kCoarseDelay) fine:uLongDBValue(kFineDelay)]; // STEP 4: Set thSet the GTRIG/PED delay in ns
		[self setTheLockoutWidth: uLongDBValue(kLockOutWidth)];		// STEP 5: Set the GT lockout width in ns	
		[self setThePedestalWidth: uLongDBValue(kPedestalWidth)];		// STEP 6:Set the Pedestal width in ns
		[self setSingleGTWordMask: uLongDBValue(kGtMask)];				// STEP 7:Mask in global trigger word(MASK)
	}
	@catch(NSException* localException) {
		NSLog(@"Failure during MTC pedestal setup!\n");
		[localException raise];
		
	}
}

- (void) setupPulserRateAndEnable:(double) pulserPeriodVal
{
	[self setThePulserRate:pulserPeriodVal];// STEP 1: Setup the pulser rate [pulser period in ms]
	[self loadEnablePulser];				// STEP 2 : Load Enable Pulser
	[self enablePulser];					// STEP 3 : Enable Pulser	
}

- (void) fireMTCPedestalsFixedNumber:(unsigned long) numPedestals
{
	@try {
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
	}
	@catch(NSException* localException) {
		NSLog(@"couldn't fire pedestal\n");
		[localException raise];
	}
}

- (void) basicMTCReset
{
	@try {
		
		[self disablePulser];
		[self clearGTCrateMask];
		[self clearPedestalCrateMask];		
		[self clearGlobalTriggerWordMask];
		[self resetTheMemory];
		[self zeroTheGTCounter];
		[self setTheLockoutWidth: uLongDBValue(kLockOutWidth)];		
		[self setThePrescaleValue];		
		
	}
	@catch(NSException* localException) {
		NSLog(@"Could not perform basic MTC reset!\n");
		[localException raise];
	}
}

- (void) loadTheMTCADacs
{
	
	//-------------- variables -----------------
	
	short	index, bitIndex, dacIndex;
	unsigned short	dacValues[14];
	unsigned long   aValue = 0;
	
	
	//-------------- variables -----------------
	
	@try {
		
		// STEP 3: load the DAC values from the database into dacValues[14]
		for (index = 0; index < 14 ; index++){
			dacValues[index] = [self dacValueByIndex:index];
		}
		
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
		NSLog(@"Loaded the MTC/A DACs\n");
		
	}
	@catch(NSException* localException) {
		NSLog(@"Could not load the MTC/A DACs!\n");		
		[localException raise];
	}
	
	
}

- (BOOL) adapterIsSBC
{
	return [[self adapter] isKindOfClass:NSClassFromString(@"ORVmecpuModel")];
}

- (void) loadMTCXilinx
{
	NSData* theData = [NSData dataWithContentsOfFile:[self xilinxFilePath]];
	if(![theData length]){
		NSLog(@"Couldn't open the MTC Xilinx file %@!\n",[self xilinxFilePath]);
		[NSException raise:@"Couldn't open Xilinx File" format:	@"%@",[self xilinxFilePath]];	
	}
	
	if([self adapterIsSBC]){
		[self loadXilinxUsingSBC:theData];
	}
	else {
		[self loadXilinxUsingLocalAdapter:theData];
	}
}

- (void) setTubRegister
{
	@try {
		
		unsigned long aValue = [self  dbIntByIndex:kTub];
		
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
		
	}
	@catch(NSException* localException) {
		NSLog(@"Failed to load Tub serial register\n");
		[localException raise];
	}
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
	@try {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doBasicOp) object:nil];
		if(useMemory){
			//TBD.....
			if(doReadOp){
			}
			else {
			}
		}
		else {
			if(doReadOp){
				NSLog(@"%@: 0x%08x\n",reg[selectedRegister].regName,[self read:selectedRegister]);
			}
			else {
				[self write:selectedRegister value:writeValue];
				NSLog(@"Wrote 0x%08x to %@\n",writeValue,reg[selectedRegister].regName);
			}
		}
		if(++workingCount<repeatOpCount){
			[self performSelector:@selector(doBasicOp) withObject:nil afterDelay:repeatDelay/1000.];
		}
		else {
			[self setBasicOpsRunning:NO];
		}
	}
	@catch(NSException* localException) {
		[self setBasicOpsRunning:NO];
		NSLog(@"Mtc basic op exception: %@\n",localException);
		[localException raise];
	}
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

@implementation ORMTCModel (LocalAdapter)
- (void) loadXilinxUsingLocalAdapter:(NSData*) theData
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
	
	unsigned long bitCount		= 0UL;
	unsigned long readValue		= 0UL;
	unsigned long aValue		= 0UL;
	
	BOOL firstPass = TRUE;
	
	const unsigned long DATA_HIGH_CLOCK_LOW = 0x00000001; 	 // bit 0 high and bit 1 low
	const unsigned long DATA_LOW_CLOCK_LOW  = 0x00000000;  	 // bit 0 low and bit 1 low
	
	//------------------------------------------
	
	
	//	NSLog(@"Loading the MTC Xilinx chips....\n"); 
	
	@try {
		
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
				charData++;
				NSLog(@"Invalid first character in Xilinx file.\n");
				[NSException raise:@"Xilinx load failed" format:@""];
			}
			
			if (firstPass){
				
				charData++;							// for the first slash
				i++;  									// need to keep track of i
				
				while(*charData++ != '/'){
					
					i++;
					if ( i>index ){
						NSLog(@"Comment block not delimited by a backslash.\n");	
						[NSException raise:@"Xilinx load failed" format:@""];
					}
					
				}
				
			}
			firstPass = FALSE;
			
			// strip carriage return, tabs
			if ( ((*charData =='\r') || (*charData =='\n') || (*charData =='\t' )) && (!firstPass) ){		
				charData++;
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
					NSLog(@"Invalid character in Xilinx file.\n");
					[NSException raise:@"Xilinx load failed" format:@""];
				}
				charData++;
				
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
		
		
	}
	@catch(NSException* localException) {
		
		NSLog(@"Xilinx load failed for the MTC/D.\n");
		[localException raise];
		
	}
}
@end

@implementation ORMTCModel (SBC)
- (void) loadXilinxUsingSBC:(NSData*) theData
{	
	
	NSLog(@"Sending Xilinx file to the SBC. (Can take a few seconds)\n");
	
	long errorCode = 0;
	unsigned long numLongs		= ceil([theData length]/4.0); //round up to long word boundary
	SBC_Packet aPacket;
	aPacket.cmdHeader.destination	= kSNO;
	aPacket.cmdHeader.cmdID			= kSNOMtcLoadXilinx;
	aPacket.cmdHeader.numberBytesinPayload	= sizeof(SNOMtc_XilinxLoadStruct) + numLongs*sizeof(long);
	
	SNOMtc_XilinxLoadStruct* payloadPtr = (SNOMtc_XilinxLoadStruct*)aPacket.payload;
	payloadPtr->baseAddress		= [self baseAddress];
	payloadPtr->addressModifier	= [self addressModifier];
	payloadPtr->errorCode	    = 666;
	payloadPtr->programRegOffset= reg[kMtcXilProgReg].addressOffset;
	payloadPtr->fileSize		= [theData length];
	const char* dataPtr			= (const char*)[theData bytes];
	//really should be an error check here that the file isn't bigger than the max payload size
	char* p = (char*)payloadPtr + sizeof(SNOMtc_XilinxLoadStruct);
	strncpy(p, dataPtr, [theData length]);
	
	@try {
		[[[self adapter] sbcLink] send:&aPacket receive:&aPacket];
		SNOMtc_XilinxLoadStruct *responsePtr = (SNOMtc_XilinxLoadStruct*)aPacket.payload;
		errorCode = responsePtr->errorCode;
		if(errorCode){
			NSLog(@"Error Code: %d %s\n",errorCode,aPacket.message);
			[NSException raise:@"Xilinx load failed" format:@""];
		}
		else {
			NSLog(@"Looks like success. (Program Reg reported Successful load)\n");
		}
	}
	@catch(NSException* localException) {
		NSLog(@"Xilinx load failed for the MTC/D.\n");
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}
}


@end

