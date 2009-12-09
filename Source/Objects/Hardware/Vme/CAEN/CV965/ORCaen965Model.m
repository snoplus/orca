/*
 *  ORCaen965Model.m
 *  Orca
 *
 *  Created by Mark Howe on Friday June 19 2009.
 *  Copyright (c) 2009 UNC. All rights reserved.
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
#import "ORCaen965Model.h"
#import "ORBaseDecoder.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"

// Address information for this unit.
#define k965DefaultBaseAddress 		0xa0000
#define k965DefaultAddressModifier 	0x39

// Define all the registers available to this unit.
static RegisterNamesStruct reg[kNumRegisters] = {
	{@"Output Buffer",      true,	true, 	true,	0x0000,		kReadOnly,	kD32},
	{@"FirmWare Revision",	false,  false, 	false,	0x1000,		kReadOnly,	kD16},
	{@"Geo Address",		false,	false, 	false,	0x1002,		kReadWrite,	kD16},
	{@"MCST CBLT Address",	false,	false, 	true,	0x1004,		kReadWrite,	kD16},
	{@"Bit Set 1",			false,	true, 	true,	0x1006,		kReadWrite,	kD16},
	{@"Bit Clear 1",		false,	true, 	true,	0x1008,		kReadWrite,	kD16},
	{@"Interrup Level",     false,	true, 	true,	0x100A,		kReadWrite,	kD16},
	{@"Interrup Vector",	false,	true, 	true,	0x100C,		kReadWrite,	kD16},
	{@"Status Register 1",	false,	true, 	true,	0x100E,		kReadOnly,	kD16},
	{@"Control Register 1",	false,	true, 	true,	0x1010,		kReadWrite,	kD16},
	{@"ADER High",			false,	false, 	true,	0x1012,		kReadWrite,	kD16},
	{@"ADER Low",			false,	false, 	true,	0x1014,		kReadWrite,	kD16},
	{@"Single Shot Reset",	false,	false, 	false,	0x1016,		kWriteOnly,	kD16},
	{@"MCST CBLT Ctrl",     false,	false, 	true,	0x101A,		kReadWrite,	kD16},
	{@"Event Trigger Reg",	false,	true, 	true,	0x1020,		kReadWrite,	kD16},
	{@"Status Register 2",	false,	true, 	true,	0x1022,		kReadOnly,	kD16},
	{@"Event Counter L",	true,	true, 	true,	0x1024,		kReadOnly,	kD16},
	{@"Event Counter H",	true,	true, 	true,	0x1026,		kReadOnly,	kD16},
	{@"Increment Event",	false,	false, 	false,	0x1028,		kWriteOnly,	kD16},
	{@"Increment Offset",	false,	false, 	false,	0x102A,		kWriteOnly,	kD16},
	{@"Load Test Register",	false,	false, 	false,	0x102C,		kReadWrite,	kD16},
	{@"FCLR Window",		false,	true, 	true,	0x102E,		kReadWrite,	kD16},
	{@"Bit Set 2",			false,	true, 	true,	0x1032,		kReadWrite,	kD16},
	{@"Bit Clear 2",		false,	true, 	true,	0x1034,		kWriteOnly,	kD16},
	{@"W Mem Test Address",	false,	true, 	true,	0x1036,		kWriteOnly,	kD16},
	{@"Mem Test Word High",	false,	true, 	true,	0x1038,		kWriteOnly,	kD16},
	{@"Mem Test Word Low",	false,	false, 	false,	0x103A,		kWriteOnly,	kD16},
	{@"Crate Select",       false,	true, 	true,	0x103C,		kReadWrite,	kD16},
	{@"Test Event Write",	false,	false, 	false,	0x103E,		kWriteOnly,	kD16},
	{@"Event Counter Reset",false,	false, 	false,	0x1040,		kWriteOnly,	kD16},
	{@"I current pedestal", false,  true, true,		0x1060,		kReadWrite, kD16},
	{@"R Test Address",     false,	true, 	true,	0x1064,		kWriteOnly,	kD16},
	{@"SW Comm",			false,	false, 	false,	0x1068,		kWriteOnly,	kD16},
	{@"ADD",				false,	false, 	false,	0x1070,		kReadOnly,	kD16},
	{@"BADD",				false,	false, 	false,	0x1072,		kReadOnly,	kD16},
	{@"Thresholds",			false,	false, 	false,	0x1080,		kReadWrite,	kD16},
};


NSString* ORCaen965ModelCardTypeChanged = @"ORCaen965ModelCardTypeChanged";
NSString* ORCaen965ModelOnlineMaskChanged    = @"ORCaen965ModelOnlineMaskChanged";

@implementation ORCaen965Model

#pragma mark ***Initialization
- (id) init //designated initializer
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
	
    [self setBaseAddress:k965DefaultBaseAddress];
    [self setAddressModifier:k965DefaultAddressModifier];
	[self setOnlineMask:0xff];
	
    [[self undoManager] enableUndoRegistration];
   
    return self;
}

#pragma mark ***Accessors
- (unsigned short)onlineMask {
	
    return onlineMask;
}

- (void)setOnlineMask:(unsigned short)anOnlineMask {
    [[[self undoManager] prepareWithInvocationTarget:self] setOnlineMask:[self onlineMask]];
    onlineMask = anOnlineMask;	    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen965ModelOnlineMaskChanged object:self];
}

- (BOOL)onlineMaskBit:(int)bit
{
	return onlineMask&(1<<bit);
}

- (void) setOnlineMaskBit:(int)bit withValue:(BOOL)aValue
{
	unsigned short aMask = onlineMask;
	if(aValue)aMask |= (1<<bit);
	else      aMask &= ~(1<<bit);
	[self setOnlineMask:aMask];
}

- (int) cardType
{
    return cardType;
}

- (void) setCardType:(int)aCardType
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCardType:cardType];
    cardType = aCardType;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen965ModelCardTypeChanged object:self];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"Caen965"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORCaen965Controller"];
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,0x1080);
}

- (int) numberOfChannels
{
    return 16;
}

#pragma mark ***Register - General routines
- (short) getNumberRegisters
{
    return kNumRegisters;
}

- (unsigned long) getBufferOffset
{
    return reg[kOutputBuffer].addressOffset;
}

- (unsigned short) getDataBufferSize
{
    return k965OutputBufferSize;
}

- (unsigned long) getThresholdOffset
{
    return reg[kThresholds].addressOffset;
}

- (short) getStatusRegisterIndex:(short) aRegister
{
    if (aRegister == 1) return kStatusRegister1;
    else		return kStatusRegister2;
}

- (short) getThresholdIndex
{
    return(kThresholds);
}

- (short) getOutputBufferIndex
{
    return(kOutputBuffer);
}

#pragma mark ***Register - Register specific routines
- (NSString*) getRegisterName:(short) anIndex
{
    return reg[anIndex].regName;
}
- (unsigned long) getAddressOffset:(short) anIndex
{
    return(reg[anIndex].addressOffset);
}

- (short) getAccessType:(short) anIndex
{
    return reg[anIndex].accessType;
}

- (short) getAccessSize:(short) anIndex
{
    return reg[anIndex].size;
}

- (BOOL) dataReset:(short) anIndex
{
    return reg[anIndex].dataReset;
}

- (BOOL) swReset:(short) anIndex
{
    return reg[anIndex].softwareReset;
}

- (BOOL) hwReset:(short) anIndex
{
    return reg[anIndex].hwReset;
}

- (unsigned short) threshold:(unsigned short) aChnl
{
    return thresholds[aChnl] & 0xff;
}

- (void) setThreshold:(unsigned short) aChnl threshold:(unsigned short) aValue
{
    if(aValue>255)aValue = 255;
    // Set the undo manager action.  The label has already been set by the controller calling this method.
    [[[self undoManager] prepareWithInvocationTarget:self] setThreshold:aChnl threshold:[self threshold:aChnl]];
    
    // Set the new value in the model.
    thresholds[aChnl] = aValue;
    
    // Create a dictionary object that stores a pointer to this object and the channel that was changed.
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChnl] forKey:caenChnl];
    
    // Send out notification that the value has changed.
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:caenChnlThresholdChanged
	 object:self
	 userInfo:userInfo];
}

- (void) writeThreshold:(unsigned short) aChan
{
    unsigned short 	threshold = [self threshold:aChan];
	if(onlineMask & (1<<aChan)) threshold |= 0x100;
    [[self adapter] writeWordBlock:&threshold
                         atAddress:[self baseAddress] + [self getThresholdOffset] + (aChan * kD16)
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

#pragma mark ***DataTaker
- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORCaen965DecoderForQdc",							@"decoder",
								 [NSNumber numberWithLong:dataId],					@"dataId",
								 [NSNumber numberWithBool:NO],						@"variable",
								 [NSNumber numberWithLong:IsShortForm(dataId)?1:2],	@"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"Caen965"];
    
    return dataDictionary;
}

- (void) appendEventDictionary:(NSMutableDictionary*)anEventDictionary topLevel:(NSMutableDictionary*)topLevel
{
	NSDictionary* aDictionary;
	aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"Qdc",								@"name",
				   [NSNumber numberWithLong:dataId],   @"dataId",
				   [NSNumber numberWithLong:16],		@"maxChannels",
				   nil];
	
	[anEventDictionary setObject:aDictionary forKey:@"Caen965"];
}

- (void) runTaskStarted:(ORDataPacket*) aDataPacket userInfo:(id)userInfo
{
    [super runTaskStarted:aDataPacket userInfo:userInfo];
    
    // Clear unit
    [self write:kBitSet2 sendValue:kClearData];			// Clear data, 
    [self write:kBitClear2 sendValue:kClearData];       // Clear "Clear data" bit of status reg.
    [self write:kEventCounterReset sendValue:0x0000];	// Clear event counter

    //Cache some values
	statusAddress		= [self baseAddress]+reg[kStatusRegister1].addressOffset;
	dataBufferAddress   = [self baseAddress]+reg[kOutputBuffer].addressOffset;
	location      =  (([self crateNumber]&0xf)<<21) | (([self slot]& 0x0000001f)<<16) | cardType; //doesn't change so do it here.

    // Set thresholds in unit
    [self writeThresholds];
    
}

-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    @try {
		unsigned short statusValue = 0;
		[controller readWordBlock:&statusValue
						atAddress:statusAddress
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
		
		if(statusValue & 0x0001){
			
			//OK, at least one data value is ready
			unsigned short dataValue;
			[controller readWordBlock:&dataValue
							atAddress:dataBufferAddress
							numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];
			
			//if this is a header, must be valid data continue.
			BOOL validData = NO; //assume !OK until shown otherwise
			if(ShiftAndExtract(dataValue,27,0xf) == 0x010){
				//get the number of memorized channels
				int dataType			 = ShiftAndExtract(dataValue,24,0x7);
				int numMemorizedChannels = ShiftAndExtract(dataValue,8,0x3f);
				int i;
				if((numMemorizedChannels>0) && (dataType == 0x010)){
					unsigned long dataRecord[2];
					dataRecord[0] = dataId | 2;
					dataRecord[1] = location;
					int index = 2;
					for(i=0;i<numMemorizedChannels;i++){
						[controller readWordBlock:&dataValue
										atAddress:dataBufferAddress
										numToRead:1
									   withAddMod:[self addressModifier]
									usingAddSpace:0x01];
						int dataType = ShiftAndExtract(dataValue,24,0x7);
						if(dataType == 0x000){
							dataRecord[index] = dataValue;
							index++;
						}
						else {
							break;
						}
					}
					if(validData){
						//OK we read the data, get the end of block
						[controller readWordBlock:&dataValue
										atAddress:dataBufferAddress
										numToRead:1
									   withAddMod:[self addressModifier]
									usingAddSpace:0x01];
						//make sure it really is an end of block
						if(dataType == 0x100){
							dataRecord[index] = dataValue;
							index++;
						}
						//fill in the ORCA header and ship the data
						dataRecord[0] = dataId | index;
						[aDataPacket addLongsToFrameBuffer:dataRecord length:index];
						validData = YES;
					}
				}
			}
			if(!validData){
				//flush the buffer, read until not valid datum
				int i;
				for(i=0;i<0x07FC;i++) {
					unsigned short dataValue;
					[controller readWordBlock:&dataValue
									atAddress:dataBufferAddress
									numToRead:1
								   withAddMod:[self addressModifier]
								usingAddSpace:0x01];
					if(ShiftAndExtract(dataValue,24,0x7) == 0x110) break;
				}
			}
		}
	}
	@catch(NSException* localException) {
		NSLogError(@"",@"Caen965 Card Error",nil);
		[self incExceptionCount];
		[localException raise];
	}
}

- (void) runTaskStopped:(ORDataPacket*) aDataPacket userInfo:(id)userInfo
{
    [super runTaskStopped:aDataPacket userInfo:userInfo];
}
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    int i;
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:[self numberOfChannels]];
    for(i=0;i<[self numberOfChannels];i++){
        [array addObject:[NSNumber numberWithShort:thresholds[i]]];
    }
    [objDictionary setObject:array forKey:@"thresholds"];
    [objDictionary setObject:[NSNumber numberWithInt:onlineMask] forKey:@"onlineMask"];
    
    return objDictionary;
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"CAEN 965%@ QDC (Slot %d) ",[self cardType] == kV965A?@"A":@"",[self slot]];
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Threshold"];
    [p setFormat:@"##0" upperLimit:255 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setThreshold:threshold:) getMethod:@selector(threshold:)];
	[p setCanBeRamped:YES];
	[p setInitMethodSelector:@selector(writeThresholds)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Online"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setOnlineMaskBit:withValue:) getMethod:@selector(onlineMaskBit:)];
    [p setActionMask:kAction_Set_Mask|kAction_Restore_Mask];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
	[p setUseValue:NO];
	[p setName:@"Init"];
	[p setSetMethodSelector:@selector(writeThresholds)];
	[a addObject:p];
    
    return a;
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
	if([param isEqualToString:@"Threshold"])return [[cardDictionary objectForKey:@"thresholds"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"Online"]) return [cardDictionary objectForKey:@"onlineMask"];
    else return nil;
}

#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*) aDecoder
{
    self = [super initWithCoder:aDecoder];
    [[self undoManager] disableUndoRegistration];
    [self setCardType:[aDecoder decodeIntForKey:@"cardType"]];
	[self setOnlineMask:[aDecoder decodeIntForKey:@"onlineMask"]];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) encodeWithCoder:(NSCoder*) anEncoder
{
    [super encodeWithCoder:anEncoder];
    [anEncoder encodeInt:cardType forKey:@"cardType"];
    [anEncoder encodeInt:onlineMask forKey:@"onlineMask"];
}

@end


