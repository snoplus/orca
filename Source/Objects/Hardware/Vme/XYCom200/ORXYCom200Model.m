//-------------------------------------------------------------------------
//  ORXYCom200Model.h
//
//  Created by Mark A. Howe on Wednesday 02/07/2007.
//  Copyright (c) 2007 CENPA. University of Washington. All rights reserved.
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

//-------------------------------------------------------------------------

#pragma mark ***Imported Files
#import "ORXYCom200Model.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORVmeCrateModel.h"

#pragma mark ***Notification Strings
NSString*	ORXYCom200SettingsLock				= @"ORXYCom200SettingsLock";
NSString* 	ORXYCom200SelectedRegIndexChanged	= @"ORXYCom200SelectedRegIndexChanged";
NSString* 	ORXYCom200SelectedChannelChanged	= @"ORXYCom200SelectedChannelChanged";
NSString* 	ORXYCom200WriteValueChanged			= @"ORXYCom200WriteValueChanged";

@implementation ORXYCom200Model

#pragma mark •••Static Declarations

static struct {
	NSString*	  regName;
	unsigned long addressOffset;
} mIOXY200Reg[kNumRegs]={
	{@"General Control",			0x01},
	{@"Service Request",			0x03},
	{@"A Data Direction",		0x05},
	{@"B Data Direction",		0x07},
	{@"C Data Direction",		0x09},
	{@"Interrupt Vector",		0x0b},
	{@"A Control",				0x0d},
	{@"B Control",				0x0f},
	{@"A Data",					0x11},
	{@"B Data",					0x13},
	{@"C Data",					0x19},
	{@"A Alternate",				0x15},
	{@"B Alternate",				0x17},
	{@"Status",					0x1b},
	{@"Timer Control",			0x21},
	{@"Timer Interrupt Vector",	0x23},
	{@"Timer Status",			0x35},
	{@"Counter Preload High",	0x27},
	{@"Counter Preload Mid",		0x29},
	{@"Counter Preload Low",		0x2b},
	{@"Count High",				0x2f},
	{@"Count Mid",				0x31},		
	{@"Count Lo",				0x33}		
};	

#pragma mark ***Initialization
- (id) init 
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self setAddressModifier:0x29];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc 
{
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"XYCom200Card"]];	
}

- (void) makeMainController
{
    [self linkToController:@"ORXYCom200Controller"];
}

#pragma mark ***Accessors

- (unsigned short) selectedRegIndex
{
    return selectedRegIndex;
}

- (void) setSelectedRegIndex:(unsigned short) anIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedRegIndex:[self selectedRegIndex]];
    
    selectedRegIndex = anIndex;
    
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORXYCom200SelectedRegIndexChanged
                      object:self];
}

- (unsigned short) selectedChannel
{
    return selectedChannel;
}

- (void) setSelectedChannel:(unsigned short) anIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedChannel:[self selectedChannel]];
    
    selectedChannel = anIndex;
    
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORXYCom200SelectedChannelChanged
                      object:self];
}


- (unsigned long) writeValue
{
    return writeValue;
}

- (void) setWriteValue:(unsigned long) aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWriteValue:[self writeValue]];
    
    writeValue = aValue;
    
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORXYCom200WriteValueChanged
                      object:self];
}


#pragma mark •••Hardware Access

- (void) initBoard
{
}

- (void) read
{
	//read hw based on the dialog settings
    short theChannelIndex	= [self selectedChannel];
    short theRegIndex 		= [self selectedRegIndex];
    short theValue;
	
    NS_DURING
        
            [self read:theRegIndex returnValue:&theValue];
			
            NSLog(@"CAEN reg [%@]:0x%04lx\n", [self getRegisterName:theRegIndex], theValue);
        
        NS_HANDLER
            NSLog(@"Can't Read [%@] on the %@.\n",
                  [self getRegisterName:theRegIndex], [self identifier]);
            [localException raise];
        NS_ENDHANDLER
}


//--------------------------------------------------------------------------------
/*!\method  write
* \brief	Writes data out to a CAEN VME device register.
* \note
*/
//--------------------------------------------------------------------------------
- (void) write
{
     
 	//write hw based on the dialog settings
	long theValue			=  [self writeValue];
    short theChannelIndex	= [self selectedChannel];
    short theRegIndex 		= [self selectedRegIndex];
    
    NS_DURING
        
        NSLog(@"Register is:%d\n", theRegIndex);
        NSLog(@"Index is   :%d\n", theChannelIndex);
        NSLog(@"Value is   :0x%04x\n", theValue);
        
		[self write:theRegIndex sendValue:(short) theValue];
        
        NS_HANDLER
            NSLog(@"Can't write 0x%04lx to [%@] on the %@.\n",
                  theValue, [self getRegisterName:theRegIndex],[self identifier]);
            [localException raise];
        NS_ENDHANDLER
}

- (void) read:(unsigned short) pReg returnValue:(void*) pValue
{
    // Make sure that register is valid
    if (pReg >= [self getNumberRegisters]) {
        [NSException raise:@"Illegal Register" format:@"Register index out of bounds on %@",[self identifier]];
    }
    
    
	unsigned short aValue;
	[[self adapter] readWordBlock:&aValue
                        atAddress:[self baseAddress] + [self getAddressOffset:pReg]
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
					
	*((unsigned short*)pValue) = aValue;
}

- (void) write:(unsigned short) pReg sendValue:(unsigned long) pValue
{
    // Check that register is a valid register.
    if (pReg >= [self getNumberRegisters]){
        [NSException raise:@"Illegal Register" format:@"Register index out of bounds on %@",[self identifier]];
    }
    
	unsigned short aValue = (unsigned short)pValue;
	[[self adapter] writeWordBlock:&aValue
						 atAddress:[self baseAddress] + [self getAddressOffset:pReg]
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
}

#pragma mark •••HW Wizard
- (int) numberOfChannels
{
    return kNumXYCom200Channels;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];    

    
    return a;
}


- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel name:@"Crate" className:@"ORVmeCrateModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Card" className:@"ORXYCom200Model"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:@"ORXYCom200Model"]];
    return a;
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
    
    id obj = [cardDictionary objectForKey:param];
    if(obj)return obj;
    else return [[cardDictionary objectForKey:param] objectAtIndex:aChannel];
}

- (short) getNumberRegisters
{
	return kNumRegs;
}

- (NSString*) getRegisterName:(short) anIndex
{
    return mIOXY200Reg[anIndex].regName;
}

- (unsigned long) getAddressOffset:(short) anIndex
{
    return mIOXY200Reg[anIndex].addressOffset;
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];

	      
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
 
 }

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];

	//[self addCurrentState:objDictionary cArray:enabled forKey:@"Enabled"];

	
	
    return objDictionary;
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary cArray:(short*)anArray forKey:(NSString*)aKey
{
	NSMutableArray* ar = [NSMutableArray array];
	int i;
	for(i=0;i<kNumXYCom200Channels;i++){
		[ar addObject:[NSNumber numberWithShort:*anArray]];
		anArray++;
	}
	[dictionary setObject:ar forKey:aKey];
}


@end
