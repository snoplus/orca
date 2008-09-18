//-------------------------------------------------------------------------
//  ORXYCom200Model.h
//
//  Created by Mark A. Howe on Wednesday 9/18/2008.
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

#pragma mark ***Imported Files
#import "ORXYCom200Model.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORVmeCrateModel.h"

#pragma mark ***Notification Strings
NSString*	ORXYCom200SettingsLock				= @"ORXYCom200SettingsLock";
NSString* 	ORXYCom200SelectedRegIndexChanged	= @"ORXYCom200SelectedRegIndexChanged";
NSString* 	ORXYCom200WriteValueChanged			= @"ORXYCom200WriteValueChanged";

@implementation ORXYCom200Model

#pragma mark •••Static Declarations

static struct {
	NSString*	  regName;
	unsigned long addressOffset;
} mIOXY200Reg[kNumRegs]={
	{@"General Control",		0x01},
	{@"Service Request",		0x03},
	{@"A Data Direction",		0x05},
	{@"B Data Direction",		0x07},
	{@"C Data Direction",		0x09},
	{@"Interrupt Vector",		0x0b},
	{@"A Control",				0x0d},
	{@"B Control",				0x0f},
	{@"A Data",					0x11},
	{@"B Data",					0x13},
	{@"C Data",					0x19},
	{@"A Alternate",			0x15},
	{@"B Alternate",			0x17},
	{@"Status",					0x1b},
	{@"Timer Control",			0x21},
	{@"Timer Interrupt Vector",	0x23},
	{@"Timer Status",			0x35},
	{@"Counter Preload High",	0x27},
	{@"Counter Preload Mid",	0x29},
	{@"Counter Preload Low",	0x2b},
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
- (void) read
{
	//read hw based on the dialog settings
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
    short theRegIndex 		= [self selectedRegIndex];
    
    NS_DURING
        
        NSLog(@"Register is:%d\n", theRegIndex);
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
    
    
	unsigned char aValue;
	[[self adapter] readByteBlock:&aValue
                        atAddress:[self baseAddress] + [self getAddressOffset:pReg]
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
					
	*((unsigned short*)pValue) = aValue;
}

- (void) write:(unsigned short) pReg sendValue:(unsigned char) pValue
{
    // Check that register is a valid register.
    if (pReg >= [self getNumberRegisters]){
        [NSException raise:@"Illegal Register" format:@"Register index out of bounds on %@",[self identifier]];
    }
    
	unsigned char aValue = pValue;
	[[self adapter] writeByteBlock:&aValue
						 atAddress:[self baseAddress] + [self getAddressOffset:pReg]
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
}

#pragma mark •••HW Wizard
- (int) numberOfChannels
{
	return 0;
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
    return a;
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
    
    id obj = [cardDictionary objectForKey:param];
    if(obj)return obj;
    else return [[cardDictionary objectForKey:param] objectAtIndex:0];
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

/*
OSErr CIOXY200Core::InitOutA(unsigned short regSet)
{

	Write(regSet, kAData, 0x00);			// all A output lines will be low
	Write(regSet, kCData, 0xff);			// all C (control) output lines will be high
	Write(regSet, kCDataDirection, 0x1b);	// manual rec. for control register direction
	Write(regSet, kGeneralControl, 0x00);	
	Write(regSet, kAControl, 0xa0);			// setup in mode 0, submode 1x, negated asserted
	Write(regSet, kADataDirection, 0xff);	// define A lines as output
	Write(regSet, kCData, 0x00);			// set Control data
				
}


// Function:	InitSqWave
// Description: Setup the Xycom clock on the I/O Register to run as a square wave
//              the period is based on the internal VME clock speed
//				The period should be passed as a unsigned short in 10ths of seconds
//              The fundamental clock period is 8 micro seconds per "tick" where
//               a tick is for the Preload Low.  Hence for the mid value, a tick
//               is worth 2.048 msecs.  So to convert 10ths of seconds to ticks
//               one multiplies by 48.828125
//              The tick is for the complete square wave period.
OSErr CIOXY200Core::InitSqWave(unsigned short regSet, unsigned short period)
{
	

	// convert time to upper and lower ticks
	const double kTICKConv = 48.828125;
	double d_ticks = (double) period * kTICKConv + 0.5;
	unsigned short CounterLoadVal = (unsigned short) d_ticks;
	unsigned char CounterValHigh = ((0xff00 & CounterLoadVal) >> 8);
	unsigned char CounterValMid = CounterLoadVal;


	Write(regSet, kCounterPreloadLow, 0x00);			// write low register with 00
	Write(regSet, kCounterPreloadMid, CounterValMid);	// write mid register
	Write(regSet, kCounterPreloadHigh, CounterValHigh);	// write high register
	Write(regSet, kTimerControl, 0x41);					// init for clock and start
}
*/


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


@end
