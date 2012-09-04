//
//  OREdelweissSLTModel.m
//  Orca
//
//  Created by Mark Howe on Wed Aug 24 2005.
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

//#import "ORIpeDefs.h"
#import "ORGlobal.h"
#import "ORCrate.h"
#import "OREdelweissSLTModel.h"
//#import "ORIpeFLTModel.h"
//#import "ORIpeCrateModel.h"
#import "ORIpeV4CrateModel.h"
#import "OREdelweissSLTDefs.h"
#import "ORReadOutList.h"
#import "unistd.h"
#import "TimedWorker.h"
#import "ORDataTypeAssigner.h"
#import "PMC_Link.h"               //this is taken from IpeV4 SLT !!  -tb-
#import "EdelweissSLTv4_HW_Definitions.h"
#import "ORPMCReadWriteCommand.h"  //this is taken from IpeV4 SLT !!  -tb-
#import "EdelweissSLTv4GeneralOperations.h"

#import "ORTaskSequence.h"
#import "ORFileMover.h"


//IPE V4 register definitions
enum IpeV4Enum {
	kSltV4ControlReg,
	kSltV4StatusReg,
	kSltV4CommandReg,
	kSltV4InterruptMaskReg,
	kSltV4InterruptRequestReg,
	//kSltV4RequestSemaphoreReg,
	kSltV4RevisionReg,
	kSltV4PixelBusErrorReg,
	kSltV4PixelBusEnableReg,
	//kSltV4PixelBusTestReg,
	//kSltV4AuxBusTestReg,
	//kSltV4DebugStatusReg,
kSltV4BBOpenedReg,
kSltV4SemaphoreReg,
kSltV4CmdFIFOReg,
kSltV4CmdFIFOStatusReg,
kSltV4OperaStatusReg0Reg,
kSltV4OperaStatusReg1Reg,
kSltV4OperaStatusReg2Reg,
kSltV4TimeLowReg,
kSltV4TimeHighReg,
	
kSltV4EventFIFOReg,
kSltV4EventFIFOStatusReg,
kSltV4EventNumberReg,
	/*
	kSltV4VetoCounterHiReg,		//TODO: the LSB and MSB part of this SLT registers is confused (according to the SLT doc 2.13/2010-May) -tb-
	kSltV4VetoCounterLoReg,		//TODO: the LSB and MSB part of this SLT registers is confused (according to the SLT doc 2.13/2010-May) -tb-
	kSltV4DeadTimeCounterHiReg,	//TODO: the LSB and MSB part of this SLT registers is confused (according to the SLT doc 2.13/2010-May) -tb-
	kSltV4DeadTimeCounterLoReg,	//TODO: the LSB and MSB part of this SLT registers is confused (according to the SLT doc 2.13/2010-May) -tb-
								//TODO: and dead time and veto time counter are confused, too -tb-
	kSltV4RunCounterHiReg,		//TODO: the LSB and MSB part of this SLT registers is confused (according to the SLT doc 2.13/2010-May) -tb-
	kSltV4RunCounterLoReg,		//TODO: the LSB and MSB part of this SLT registers is confused (according to the SLT doc 2.13/2010-May) -tb-
	kSltV4SecondSetReg,
	kSltV4SecondCounterReg,
	kSltV4SubSecondCounterReg,
	kSltV4PageManagerReg,
	kSltV4TriggerTimingReg,
	kSltV4PageSelectReg,
	kSltV4NumberPagesReg,
	kSltV4PageNumbersReg,
	kSltV4EventStatusReg,
	kSltV4ReadoutCSRReg,
	kSltV4BufferSelectReg,
	kSltV4ReadoutDefinitionReg,
	kSltV4TPTimingReg,
	kSltV4TPShapeReg,
	*/
	
	kSltV4I2CCommandReg,
	kSltV4EPCCommandReg,
	kSltV4BoardIDLoReg,
	kSltV4BoardIDHiReg,
	kSltV4PROMsControlReg,
	kSltV4PROMsBufferReg,
	//kSltV4TriggerDataReg,
	//kSltV4ADCDataReg,
kSltV4BBxDataFIFOReg,
kSltV4BBxFIFOModeReg,
kSltV4BBxFIFOStatusReg,
kSltV4BBxFIFOPAEOffsetReg,
kSltV4BBxFIFOPAFOffsetReg,
kSltV4BBxcsrReg,
kSltV4BBxRequestReg,
kSltV4BBxMaskReg,
	
	
	kSltV4NumRegs //must be last
};

static IpeRegisterNamesStruct regV4[kSltV4NumRegs] = {
{@"Control",			0xa80000,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"Status",				0xa80004,		1,			kIpeRegReadable },
{@"Command",			0xa80008,		1,			kIpeRegWriteable },
{@"Interrupt Mask",		0xA8000C,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"Interrupt Request",	0xA80010,		1,			kIpeRegReadable },
//HEAT {@"Request Semaphore",	0xA80014,		3,			kIpeRegReadable },
{@"Revision",			0xa80020,		1,			kIpeRegReadable },
{@"Pixel Bus Error",	0xA80024,		1,			kIpeRegReadable },			
{@"Pixel Bus Enable",	0xA80028,		1, 			kIpeRegReadable | kIpeRegWriteable },
//HEAT {@"Pixel Bus Test",		0xA8002C, 		1, 			kIpeRegReadable | kIpeRegWriteable },
//HEAT {@"Aux Bus Test",		0xA80030, 		1, 			kIpeRegReadable | kIpeRegWriteable },
//HEAT {@"Debug Status",		0xA80034,  		1, 			kIpeRegReadable | kIpeRegWriteable },
{@"BB Opened",			0xA80034,  		1, 			kIpeRegReadable },
{@"Semaphore",			0xB00000,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"CmdFIFO",			0xB00004,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"CmdFIFOStatus",		0xB00008,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"OperaStatusReg0",	0xB0000C,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"OperaStatusReg1",	0xB00010,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"OperaStatusReg2",	0xB00014,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"TimeLow",			0xB00018,		1,			kIpeRegReadable },
{@"TimeHigh",			0xB0001C,		1,			kIpeRegReadable },

{@"EventFIFO",			0xB80000,  		1, 			kIpeRegReadable },
{@"EventFIFOStatus",	0xB80004,  		1, 			kIpeRegReadable },
{@"EventNumber",		0xB80008, 		1,			kIpeRegReadable },
/*HEAT
{@"Veto Counter (MSB)",	0xA80080, 		1,			kIpeRegReadable },	
{@"Veto Counter (LSB)",	0xA80084,		1,			kIpeRegReadable },	
{@"Dead Counter (MSB)",	0xA80088, 		1,			kIpeRegReadable },	
{@"Dead Counter (LSB)",	0xA8008C, 		1,			kIpeRegReadable },	
{@"Run Counter  (MSB)",	0xA80090,		1,			kIpeRegReadable },	
{@"Run Counter  (LSB)",	0xA80094, 		1,			kIpeRegReadable },	
{@"Second Set",			0xB00000,  		1, 			kIpeRegReadable | kIpeRegWriteable }, 
{@"Second Counter",		0xB00004, 		1,			kIpeRegReadable },
{@"Sub-second Counter",	0xB00008, 		1,			kIpeRegReadable }, 
{@"Page Manager",		0xB80000,  		1, 			kIpeRegReadable | kIpeRegWriteable },
{@"Trigger Timing",		0xB80004,  		1, 			kIpeRegReadable | kIpeRegWriteable },
{@"Page Select",		0xB80008, 		1,			kIpeRegReadable },
{@"Number of Pages",	0xB8000C, 		1,			kIpeRegReadable },
{@"Page Numbers",		0xB81000,		64, 		kIpeRegReadable | kIpeRegWriteable },
{@"Event Status",		0xB82000,		64,			kIpeRegReadable },
{@"Readout CSR",		0xC00000,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"Buffer Select",		0xC00004,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"Readout Definition",	0xC10000,	  2048,			kIpeRegReadable | kIpeRegWriteable },			
{@"TP Timing",			0xC80000,	   128,			kIpeRegReadable | kIpeRegWriteable },	
{@"TP Shape",			0xC81000,	   512,			kIpeRegReadable | kIpeRegWriteable },	
*/
{@"I2C Command",		0xC00000,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"EPC Command",		0xC00004,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"Board ID (LSB)",		0xC00008,		1,			kIpeRegReadable },
{@"Board ID (MSB)",		0xC0000C,		1,			kIpeRegReadable },
{@"PROMs Control",		0xC00010,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"PROMs Buffer",		0xC00100,		256/*252? ask Sascha*/,		kIpeRegReadable | kIpeRegWriteable },
//HEAT {@"Trigger Data",		0xD80000,	  14000,		kIpeRegReadable | kIpeRegWriteable },
//TODO: 0xEXxxxx, "needs FIFO num" implementieren!!! -tb-
{@"BBxDataFIFO",			0xD00000,	 1,		kIpeRegReadable | kIpeRegWriteable | kIpeRegNeedsIndex }, //BBx -> x=num./index of FIFO   -tb-
{@"BBxFIFOMode",			0xE00000,	 1,		kIpeRegReadable | kIpeRegWriteable | kIpeRegNeedsIndex }, //BBx -> x=num./index of FIFO (2012: this was equal to index FLTx), adress: 0xEX0000 -tb-
{@"BBxFIFOStatus",			0xE00004,	 1,		kIpeRegReadable |                    kIpeRegNeedsIndex }, 
{@"BBxFIFOPAEOffset",		0xE00008,	 1,		kIpeRegReadable | kIpeRegWriteable | kIpeRegNeedsIndex }, 
{@"BBxFIFOPAFOffset",		0xE0000C,	 1,		kIpeRegReadable | kIpeRegWriteable | kIpeRegNeedsIndex }, 
{@"BBx csr",				0xE00010,	 1,		kIpeRegReadable | kIpeRegWriteable | kIpeRegNeedsIndex }, 
{@"BBx Request",			0xE00014,	 1,		kIpeRegReadable | kIpeRegWriteable | kIpeRegNeedsIndex }, 
{@"BBx Mask",				0xE00018,	 1,		kIpeRegReadable | kIpeRegWriteable | kIpeRegNeedsIndex }, 
//{@"Data Block RW",		0xF00000 Data Block RW
//{@"Data Block Length",	0xF00004 Data Block Length 
//{@"Data Block Address",	0xF00008 Data Block Address
};


#pragma mark ***External Strings

NSString* OREdelweissSLTModelNumRequestedUDPPacketsChanged = @"OREdelweissSLTModelNumRequestedUDPPacketsChanged";
NSString* OREdelweissSLTModelIsListeningOnDataServerSocketChanged = @"OREdelweissSLTModelIsListeningOnDataServerSocketChanged";
NSString* OREdelweissSLTModelCrateUDPDataReplyPortChanged = @"OREdelweissSLTModelCrateUDPDataReplyPortChanged";
NSString* OREdelweissSLTModelCrateUDPDataIPChanged = @"OREdelweissSLTModelCrateUDPDataIPChanged";
NSString* OREdelweissSLTModelCrateUDPDataPortChanged = @"OREdelweissSLTModelCrateUDPDataPortChanged";
NSString* OREdelweissSLTModelEventFifoStatusRegChanged = @"OREdelweissSLTModelEventFifoStatusRegChanged";
NSString* OREdelweissSLTModelPixelBusEnableRegChanged = @"OREdelweissSLTModelPixelBusEnableRegChanged";
NSString* OREdelweissSLTModelSelectedFifoIndexChanged = @"OREdelweissSLTModelSelectedFifoIndexChanged";
NSString* OREdelweissSLTModelIsListeningOnServerSocketChanged = @"OREdelweissSLTModelIsListeningOnServerSocketChanged";
NSString* OREdelweissSLTModelCrateUDPCommandChanged = @"OREdelweissSLTModelCrateUDPCommandChanged";
NSString* OREdelweissSLTModelCrateUDPReplyPortChanged = @"OREdelweissSLTModelCrateUDPReplyPortChanged";
NSString* OREdelweissSLTModelCrateUDPCommandIPChanged = @"OREdelweissSLTModelCrateUDPCommandIPChanged";
NSString* OREdelweissSLTModelCrateUDPCommandPortChanged = @"OREdelweissSLTModelCrateUDPCommandPortChanged";
NSString* OREdelweissSLTModelSecondsSetInitWithHostChanged = @"OREdelweissSLTModelSecondsSetInitWithHostChanged";
NSString* OREdelweissSLTModelSltScriptArgumentsChanged = @"OREdelweissSLTModelSltScriptArgumentsChanged";

NSString* OREdelweissSLTModelClockTimeChanged = @"OREdelweissSLTModelClockTimeChanged";
NSString* OREdelweissSLTModelRunTimeChanged = @"OREdelweissSLTModelRunTimeChanged";
NSString* OREdelweissSLTModelVetoTimeChanged = @"OREdelweissSLTModelVetoTimeChanged";
NSString* OREdelweissSLTModelDeadTimeChanged = @"OREdelweissSLTModelDeadTimeChanged";
NSString* OREdelweissSLTModelSecondsSetChanged		= @"OREdelweissSLTModelSecondsSetChanged";
NSString* OREdelweissSLTModelStatusRegChanged		= @"OREdelweissSLTModelStatusRegChanged";
NSString* OREdelweissSLTModelControlRegChanged		= @"OREdelweissSLTModelControlRegChanged";
NSString* OREdelweissSLTModelFanErrorChanged		= @"OREdelweissSLTModelFanErrorChanged";
NSString* OREdelweissSLTModelVttErrorChanged		= @"OREdelweissSLTModelVttErrorChanged";
NSString* OREdelweissSLTModelGpsErrorChanged		= @"OREdelweissSLTModelGpsErrorChanged";
NSString* OREdelweissSLTModelClockErrorChanged		= @"OREdelweissSLTModelClockErrorChanged";
NSString* OREdelweissSLTModelPpsErrorChanged		= @"OREdelweissSLTModelPpsErrorChanged";
NSString* OREdelweissSLTModelPixelBusErrorChanged	= @"OREdelweissSLTModelPixelBusErrorChanged";
NSString* OREdelweissSLTModelHwVersionChanged		= @"OREdelweissSLTModelHwVersionChanged";

NSString* OREdelweissSLTModelPatternFilePathChanged		= @"OREdelweissSLTModelPatternFilePathChanged";
NSString* OREdelweissSLTModelInterruptMaskChanged		= @"OREdelweissSLTModelInterruptMaskChanged";
NSString* OREdelweissSLTPulserDelayChanged				= @"OREdelweissSLTPulserDelayChanged";
NSString* OREdelweissSLTPulserAmpChanged				= @"OREdelweissSLTPulserAmpChanged";
NSString* OREdelweissSLTSettingsLock					= @"OREdelweissSLTSettingsLock";
NSString* OREdelweissSLTStatusRegChanged				= @"OREdelweissSLTStatusRegChanged";
NSString* OREdelweissSLTControlRegChanged				= @"OREdelweissSLTControlRegChanged";
NSString* OREdelweissSLTSelectedRegIndexChanged			= @"OREdelweissSLTSelectedRegIndexChanged";
NSString* OREdelweissSLTWriteValueChanged				= @"OREdelweissSLTWriteValueChanged";
NSString* OREdelweissSLTModelNextPageDelayChanged		= @"OREdelweissSLTModelNextPageDelayChanged";
NSString* OREdelweissSLTModelPollRateChanged			= @"OREdelweissSLTModelPollRateChanged";

NSString* OREdelweissSLTModelPageSizeChanged			= @"OREdelweissSLTModelPageSizeChanged";
NSString* OREdelweissSLTModelDisplayTriggerChanged		= @"OREdelweissSLTModelDisplayTrigerChanged";
NSString* OREdelweissSLTModelDisplayEventLoopChanged	= @"OREdelweissSLTModelDisplayEventLoopChanged";
NSString* OREdelweissSLTV4cpuLock							= @"OREdelweissSLTV4cpuLock";

@interface OREdelweissSLTModel (private)
- (unsigned long) read:(unsigned long) address;
- (void) write:(unsigned long) address value:(unsigned long) aValue;
@end

@implementation OREdelweissSLTModel

- (id) init
{
    self = [super init];
	ORReadOutList* readList = [[ORReadOutList alloc] initWithIdentifier:@"ReadOut List"];	
	[self setReadOutGroup:readList];
    [self makePoller:0];
	[readList release];
	pmcLink = [[PMC_Link alloc] initWithDelegate:self];
	[self setSecondsSetInitWithHost: YES];
	[self registerNotificationObservers];
	//some defaults
	crateUDPCommandPort = 9940;
	crateUDPCommandIP = @"localhost";
	crateUDPReplyPort = 9940;
    crateUDPDataPort = 994;
    crateUDPDataIP = @"192.168.1.100";
    crateUDPDataReplyPort = 12345;
	
    return self;
}

-(void) dealloc
{
    [crateUDPDataIP release];
    [crateUDPCommand release];
    [crateUDPCommandIP release];
    [sltScriptArguments release];
    [patternFilePath release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[readOutGroup release];
    [poller stop];
    [poller release];
	[pmcLink setDelegate:nil];
	[pmcLink release];
    [super dealloc];
}

- (void) wakeUp
{
    if([self aWake])return;
	[pmcLink wakeUp];
    [super wakeUp];
    if(![gOrcaGlobals runInProgress]){
        [poller runWithTarget:self selector:@selector(readAllStatus)];
    }
}

- (void) sleep
{
    [super sleep];
	[pmcLink sleep];
    [poller stop];
}

- (void) awakeAfterDocumentLoaded
{
	@try {
		if(!pmcLink){
			pmcLink = [[PMC_Link alloc] initWithDelegate:self];
		}
		[pmcLink connect];
	}
	@catch(NSException* localException) {
	}
}

- (void) setUpImage			{ [self setImage:[NSImage imageNamed:@"EdelweissSLTCard"]]; }
- (void) makeMainController	{ [self linkToController:@"OREdelweissSLTController"];		}
- (Class) guardianClass		{ return NSClassFromString(@"ORIpeV4CrateModel");		}

- (void) setGuardian:(id)aGuardian //-tb-
{
	if(aGuardian){
		if([aGuardian adapter] == nil){
			[aGuardian setAdapter:self];			
		}
	}
	else {
		[[self guardian] setAdapter:nil];
	}
	[super setGuardian:aGuardian];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	[notifyCenter removeObserver:self];

    [notifyCenter addObserver : self
                     selector : @selector(runIsAboutToStart:)
                         name : ORRunAboutToStartNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(runIsStopped:)
                         name : ORRunStoppedNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(runIsBetweenSubRuns:)
                         name : ORRunBetweenSubRunsNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(runIsStartingSubRun:)
                         name : ORRunStartSubRunNotification
                       object : nil];


}

#pragma mark •••Accessors

- (int) numRequestedUDPPackets
{
    return numRequestedUDPPackets;
}

- (void) setNumRequestedUDPPackets:(int)aNumRequestedUDPPackets
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNumRequestedUDPPackets:numRequestedUDPPackets];
    
    numRequestedUDPPackets = aNumRequestedUDPPackets;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelNumRequestedUDPPacketsChanged object:self];
}

- (int) isListeningOnDataServerSocket
{
    return isListeningOnDataServerSocket;
}

- (void) setIsListeningOnDataServerSocket:(int)aIsListeningOnDataServerSocket
{
    isListeningOnDataServerSocket = aIsListeningOnDataServerSocket;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelIsListeningOnDataServerSocketChanged object:self];
}


- (int) crateUDPDataReplyPort
{
    return crateUDPDataReplyPort;
}

- (void) setCrateUDPDataReplyPort:(int)aCrateUDPDataReplyPort
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCrateUDPDataReplyPort:crateUDPDataReplyPort];
    
    crateUDPDataReplyPort = aCrateUDPDataReplyPort;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelCrateUDPDataReplyPortChanged object:self];
}

- (NSString*) crateUDPDataIP
{
    return crateUDPDataIP;
}

- (void) setCrateUDPDataIP:(NSString*)aCrateUDPDataIP
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCrateUDPDataIP:crateUDPDataIP];
    
    [crateUDPDataIP autorelease];
    crateUDPDataIP = [aCrateUDPDataIP copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelCrateUDPDataIPChanged object:self];
}

- (int) crateUDPDataPort
{
    return crateUDPDataPort;
}

- (void) setCrateUDPDataPort:(int)aCrateUDPDataPort
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCrateUDPDataPort:crateUDPDataPort];
    
    crateUDPDataPort = aCrateUDPDataPort;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelCrateUDPDataPortChanged object:self];
}

- (unsigned long) eventFifoStatusReg
{
    return eventFifoStatusReg;
}

- (void) setEventFifoStatusReg:(unsigned long)aEventFifoStatusReg
{
    eventFifoStatusReg = aEventFifoStatusReg;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelEventFifoStatusRegChanged object:self];
}

- (unsigned long) pixelBusEnableReg
{
    return pixelBusEnableReg;
}

- (void) setPixelBusEnableReg:(unsigned long)aPixelBusEnableReg
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPixelBusEnableReg:pixelBusEnableReg];
    pixelBusEnableReg = aPixelBusEnableReg;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelPixelBusEnableRegChanged object:self];
}

- (int) selectedFifoIndex
{
    return selectedFifoIndex;
}

- (void) setSelectedFifoIndex:(int)aSelectedFifoIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedFifoIndex:selectedFifoIndex];
    
    selectedFifoIndex = aSelectedFifoIndex;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelSelectedFifoIndexChanged object:self];
}

- (int) isListeningOnServerSocket
{
    return isListeningOnServerSocket;
}

- (void) setIsListeningOnServerSocket:(int)aIsListeningOnServerSocket
{
    isListeningOnServerSocket = aIsListeningOnServerSocket;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelIsListeningOnServerSocketChanged object:self];
}

- (NSString*) crateUDPCommand
{
	if(!crateUDPCommand) return @"";
    return crateUDPCommand;
}

- (void) setCrateUDPCommand:(NSString*)aCrateUDPCommand
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCrateUDPCommand:crateUDPCommand];
    
    [crateUDPCommand autorelease];
    crateUDPCommand = [aCrateUDPCommand copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelCrateUDPCommandChanged object:self];
}

- (int) crateUDPReplyPort
{
    return crateUDPReplyPort;
}

- (void) setCrateUDPReplyPort:(int)aCrateUDPReplyPort
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCrateUDPReplyPort:crateUDPReplyPort];
    
    crateUDPReplyPort = aCrateUDPReplyPort;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelCrateUDPReplyPortChanged object:self];
}

- (NSString*) crateUDPCommandIP
{
	if(!crateUDPCommandIP) return @"";
    return crateUDPCommandIP;
}

- (void) setCrateUDPCommandIP:(NSString*)aCrateUDPCommandIP
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCrateUDPCommandIP:crateUDPCommandIP];
    
    //crateUDPCommandIP = aCrateUDPCommandIP;
    [crateUDPCommandIP autorelease];
    crateUDPCommandIP = [aCrateUDPCommandIP copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelCrateUDPCommandIPChanged object:self];
}

- (int) crateUDPCommandPort
{
    return crateUDPCommandPort;
}

- (void) setCrateUDPCommandPort:(int)aCrateUDPCommandPort
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCrateUDPCommandPort:crateUDPCommandPort];
    
    crateUDPCommandPort = aCrateUDPCommandPort;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelCrateUDPCommandPortChanged object:self];
}
- (BOOL) secondsSetInitWithHost
{
    return secondsSetInitWithHost;
}

- (void) setSecondsSetInitWithHost:(BOOL)aSecondsSetInitWithHost
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSecondsSetInitWithHost:secondsSetInitWithHost];
    secondsSetInitWithHost = aSecondsSetInitWithHost;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelSecondsSetInitWithHostChanged object:self];
}

- (NSString*) sltScriptArguments
{
	if(!sltScriptArguments)return @"";
    return sltScriptArguments;
}

- (void) setSltScriptArguments:(NSString*)aSltScriptArguments
{
	if(!aSltScriptArguments)aSltScriptArguments = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setSltScriptArguments:sltScriptArguments];
    
    [sltScriptArguments autorelease];
    sltScriptArguments = [aSltScriptArguments copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelSltScriptArgumentsChanged object:self];
	
	//NSLog(@"%@::%@  is %@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),sltScriptArguments);//TODO: debug -tb-
}

- (unsigned long long) clockTime //TODO: rename to 'time' ? -tb-
{
    return clockTime;
}

- (void) setClockTime:(unsigned long long)aClockTime
{
    clockTime = aClockTime;
 	//NSLog(@"   %@::%@:   clockTime: 0x%016qx from aClockTime: 0x%016qx   \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),clockTime , aClockTime);//TODO: DEBUG testing ...-tb-

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelClockTimeChanged object:self];
}


- (unsigned long) statusReg
{
    return statusReg;
}

- (void) setStatusReg:(unsigned long)aStatusReg
{
    statusReg = aStatusReg;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelStatusRegChanged object:self];
}

- (unsigned long) controlReg
{
    return controlReg;
}

- (void) setControlReg:(unsigned long)aControlReg
{
    [[[self undoManager] prepareWithInvocationTarget:self] setControlReg:controlReg];
    controlReg = aControlReg;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelControlRegChanged object:self];
}

- (unsigned long) projectVersion  { return (hwVersion & kRevisionProject)>>28;}
- (unsigned long) documentVersion { return (hwVersion & kDocRevision)>>16;}
- (unsigned long) implementation  { return hwVersion & kImplemention;}

- (void) setHwVersion:(unsigned long) aVersion
{
	hwVersion = aVersion;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelHwVersionChanged object:self];	
}


- (void) writeEvRes				{ [self writeReg:kSltV4CommandReg value:kCmdEvRes];   }
- (void) writeFwCfg				{ [self writeReg:kSltV4CommandReg value:kCmdFwCfg];   }
- (void) writeSltReset			{ [self writeReg:kSltV4CommandReg value:kCmdSltReset];   }
- (void) writeFltReset			{ [self writeReg:kSltV4CommandReg value:kCmdFltReset];   }

- (id) controllerCard		{ return self;	  }
- (SBC_Link*)sbcLink		{ return pmcLink; } 
- (TimedWorker *) poller	{ return poller;  }

- (void) setPoller: (TimedWorker *) aPoller
{
    if(aPoller == nil){
        [poller stop];
    }
    [aPoller retain];
    [poller release];
    poller = aPoller;
}

- (void) setPollingInterval:(float)anInterval
{
	[self readAllStatus];
    if(!poller){
        [self makePoller:(float)anInterval];
    }
    else [poller setTimeInterval:anInterval];
    
	[poller stop];
    [poller runWithTarget:self selector:@selector(readAllStatus)];
}


- (void) makePoller:(float)anInterval
{
    [self setPoller:[TimedWorker TimeWorkerWithInterval:anInterval]];
}


- (void) runIsAboutToStart:(NSNotification*)aNote
{
	//TODO: reset of timers probably should be done here -tb-2011-01
	#if 0 
		NSLog(@"%@::%@  called!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: debug -tb-
	#endif
}

- (void) runIsStopped:(NSNotification*)aNote
{	
	//NSLog(@"%@::%@  called!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: debug -tb-
	//NSLog(@"%@::%@  [readOutGroup count] is %i!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),[readOutGroup count]);//TODO: debug -tb-

	//writing the SLT time counters is done in runTaskStopped:userInfo:   -tb-
	//see SBC_Link.m, runIsStopping:userInfo:: if(runInfo.amountInBuffer > 0)... this is data sent out during 'Stop()...' of readout code, e.g.
	//the histogram (2060 int32_t's per histogram and one extra word) -tb-

	// Stop all activities by software inhibit
	if([readOutGroup count] == 0){//TODO: I don't understand this - remove it? -tb-
		//[self writeSetInhibit];
        //TODO: maybe set OnLine bit to 0????? But: this is for steam mode ... -tb- 2012-July
	}
	
	// TODO: Save dead time counters ?!
	// Is it sensible to send a new package here?
	// ak 18.7.07
	// run counter is shipped in runTaskStopped:userInfo: -tb-
	
	//NSLog(@"Deadtime: %lld\n", [self readDeadTime]);
}

- (void) runIsBetweenSubRuns:(NSNotification*)aNote
{
	//NSLog(@"%@::%@  called!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: debug -tb-
	[self shipSltSecondCounter: kStopSubRunType];
	//TODO: I could set inhibit to measure the 'netto' run time precisely -tb-
}


- (void) runIsStartingSubRun:(NSNotification*)aNote
{
	//NSLog(@"%@::%@  called!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
	[self shipSltSecondCounter: kStartSubRunType];
}


#pragma mark •••Accessors

- (NSString*) patternFilePath
{
    return patternFilePath;
}

- (void) setPatternFilePath:(NSString*)aPatternFilePath
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPatternFilePath:patternFilePath];
	
	if(!aPatternFilePath)aPatternFilePath = @"";
    [patternFilePath autorelease];
    patternFilePath = [aPatternFilePath copy];    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelPatternFilePathChanged object:self];
}

- (unsigned long) nextPageDelay
{
	return nextPageDelay;
}

- (void) setNextPageDelay:(unsigned long)aDelay
{	
	if(aDelay>102400) aDelay = 102400;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setNextPageDelay:nextPageDelay];
    
    nextPageDelay = aDelay;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelNextPageDelayChanged object:self];
	
}

- (unsigned long) interruptMask
{
    return interruptMask;
}

- (void) setInterruptMask:(unsigned long)aInterruptMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInterruptMask:interruptMask];
    interruptMask = aInterruptMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelInterruptMaskChanged object:self];
}

- (ORReadOutList*) readOutGroup
{
	return readOutGroup;
}

- (void) setReadOutGroup:(ORReadOutList*)newReadOutGroup
{
	[readOutGroup autorelease];
	readOutGroup=[newReadOutGroup retain];
}

- (NSMutableArray*) children 
{
	//method exists to give common interface across all objects for display in lists
	return [NSMutableArray arrayWithObject:readOutGroup];
}


- (float) pulserDelay
{
    return pulserDelay;
}

- (void) setPulserDelay:(float)aPulserDelay
{
	if(aPulserDelay<100)		 aPulserDelay = 100;
	else if(aPulserDelay>3276.7) aPulserDelay = 3276.7;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setPulserDelay:pulserDelay];
    
    pulserDelay = aPulserDelay;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTPulserDelayChanged object:self];
}

- (float) pulserAmp
{
    return pulserAmp;
}

- (void) setPulserAmp:(float)aPulserAmp
{
	if(aPulserAmp>4)aPulserAmp = 4;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setPulserAmp:pulserAmp];
    
    pulserAmp = aPulserAmp;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTPulserAmpChanged object:self];
}

- (short) getNumberRegisters			
{ 
    return kSltV4NumRegs; 
}

- (NSString*) getRegisterName: (short) anIndex
{
    return regV4[anIndex].regName;
}

- (unsigned long) getAddress: (short) anIndex
{
    return( regV4[anIndex].addressOffset>>2);
}

- (short) getAccessType: (short) anIndex
{
	return regV4[anIndex].accessType;
}

- (unsigned short) selectedRegIndex
{
    return selectedRegIndex;
}

- (void) setSelectedRegIndex:(unsigned short) anIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedRegIndex:selectedRegIndex];
    
    selectedRegIndex = anIndex;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:OREdelweissSLTSelectedRegIndexChanged
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
	 postNotificationName:OREdelweissSLTWriteValueChanged
	 object:self];
}


- (BOOL) displayTrigger
{
	return displayTrigger;
}

- (void) setDisplayTrigger:(BOOL) aState
{
	[[[self undoManager] prepareWithInvocationTarget:self] setDisplayTrigger:displayTrigger];
	displayTrigger = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelDisplayTriggerChanged object:self];
	
}

- (BOOL) displayEventLoop
{
	return displayEventLoop;
}

- (void) setDisplayEventLoop:(BOOL) aState
{
	[[[self undoManager] prepareWithInvocationTarget:self] setDisplayEventLoop:displayEventLoop];
	
	displayEventLoop = aState;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelDisplayEventLoopChanged object:self];
	
}

- (unsigned long) pageSize
{
	return pageSize;
}

- (void) setPageSize: (unsigned long) aPageSize
{
	
	[[[self undoManager] prepareWithInvocationTarget:self] setPageSize:pageSize];
	
    if (aPageSize > 100) pageSize = 100;
	else pageSize = aPageSize;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelPageSizeChanged object:self];
	
}  

/*! Send a script to the PrPMC which will configure the PrPMC.
 *
 */
- (void) sendSimulationConfigScriptON
{
	NSLog(@"%@::%@: invoked.\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
	//example code to send a script:  SBC_Link.m: - (void) installDriver:(NSString*)rootPwd 
	
	//[self sendPMCCommandScript: @"SimulationConfigScriptON"];
	[self sendPMCCommandScript: [NSString stringWithFormat:@"%@ %i",@"SimulationConfigScriptON",[pmcLink portNumber]]];//send the port number, too

	#if 0
	NSString *scriptName = @"EdelweissSLTScript";
		ORTaskSequence* aSequence;	
		aSequence = [ORTaskSequence taskSequenceWithDelegate:self];
		NSString* resourcePath = [[NSBundle mainBundle] resourcePath];
		
		NSString* driverCodePath; //[pmcLink ]
		if([pmcLink loadMode])driverCodePath = [[pmcLink filePath] stringByAppendingPathComponent:[self sbcLocalCodePath]];
		else driverCodePath = [resourcePath stringByAppendingPathComponent:[self codeResourcePath]];
		//driverCodePath = [driverCodePath stringByAppendingPathComponent:[delegate driverScriptName]];
		driverCodePath = [driverCodePath stringByAppendingPathComponent: scriptName];
		ORFileMover* driverScriptFileMover = [[ORFileMover alloc] init];//TODO: keep it as object in the class variables -tb-
		[driverScriptFileMover setDelegate:aSequence];
NSLog(@"loadMode: %i driverCodePath: %@ \n",[pmcLink loadMode], driverCodePath);		
		[driverScriptFileMover setMoveParams:[driverCodePath stringByExpandingTildeInPath]
										to:@"" 
								remoteHost:[pmcLink IPNumber] 
								  userName:[pmcLink userName] 
								  passWord:[pmcLink passWord]];
		[driverScriptFileMover setVerbose:YES];
		[driverScriptFileMover doNotMoveFilesToSentFolder];
		[driverScriptFileMover setTransferType:eUseSCP];
		[aSequence addTaskObj:driverScriptFileMover];
		
		//NSString* scriptRunPath = [NSString stringWithFormat:@"/home/%@/%@",[pmcLink userName],scriptName];
		NSString* scriptRunPath = [NSString stringWithFormat:@"~/%@",scriptName];
NSLog(@"  scriptRunPath: %@ \n" , scriptRunPath);		
		[aSequence addTask:[resourcePath stringByAppendingPathComponent:@"loginScript"] 
				 arguments:[NSArray arrayWithObjects:[pmcLink userName],[pmcLink passWord],[pmcLink IPNumber],scriptRunPath,
				 //@"arg1",@"arg2",nil]];
				 //@"shellcommand",@"ls",@"&&",@"date",@"&&",@"ps",nil]];
				 //@"shellcommand",@"ls",@"-laF",nil]];
				 @"shellcommand",@"ls",@"-l",@"-a",@"-F",nil]];  //limited to 6 arguments (see loginScript)
				 //TODO: use sltScriptArguments -tb-
		
		[aSequence launch];
		#endif

}

/*! Send a script to the PrPMC which will configure the PrPMC.
 */
- (void) sendSimulationConfigScriptOFF
{
	//NSLog(@"%@::%@: invoked.\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
	//example code to send a script:  SBC_Link.m: - (void) installDriver:(NSString*)rootPwd 
	
	[self sendPMCCommandScript: @"SimulationConfigScriptOFF"];
}

/*! Send a script to the PrPMC which will configure the PrPMC.
 *
 */
- (void) sendPMCCommandScript: (NSString*)aString;
{
	NSLog(@"%@::%@: invoked.\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
	//example code to send a script:  SBC_Link.m: - (void) installDriver:(NSString*)rootPwd 


	NSArray *scriptcommands = nil;//limited to 6 arguments (see loginScript)
	if(aString) scriptcommands = [aString componentsSeparatedByCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if([scriptcommands count] >6) NSLog(@"WARNING: too much arguments in sendPMCConfigScript:\n");
	
	NSString *scriptName = @"EdelweissSLTScript";
		ORTaskSequence* aSequence;	
		aSequence = [ORTaskSequence taskSequenceWithDelegate:self];
		NSString* resourcePath = [[NSBundle mainBundle] resourcePath];
		
		NSString* driverCodePath; //[pmcLink ]
		if([pmcLink loadMode])driverCodePath = [[pmcLink filePath] stringByAppendingPathComponent:[self sbcLocalCodePath]];
		else driverCodePath = [resourcePath stringByAppendingPathComponent:[self codeResourcePath]];
		//driverCodePath = [driverCodePath stringByAppendingPathComponent:[delegate driverScriptName]];
		driverCodePath = [driverCodePath stringByAppendingPathComponent: scriptName];
		ORFileMover* driverScriptFileMover = [[ORFileMover alloc] init];//TODO: keep it as object in the class variables -tb-
		[driverScriptFileMover setDelegate:aSequence];
NSLog(@"loadMode: %i driverCodePath: %@ \n",[pmcLink loadMode], driverCodePath);		
		[driverScriptFileMover setMoveParams:[driverCodePath stringByExpandingTildeInPath]
										to:@"" 
								remoteHost:[pmcLink IPNumber] 
								  userName:[pmcLink userName] 
								  passWord:[pmcLink passWord]];
		[driverScriptFileMover setVerbose:YES];
		[driverScriptFileMover doNotMoveFilesToSentFolder];
		[driverScriptFileMover setTransferType:eUseSCP];
		[aSequence addTaskObj:driverScriptFileMover];
		
		//NSString* scriptRunPath = [NSString stringWithFormat:@"/home/%@/%@",[pmcLink userName],scriptName];
		NSString* scriptRunPath = [NSString stringWithFormat:@"~/%@",scriptName];
NSLog(@"  scriptRunPath: %@ \n" , scriptRunPath);	

	    //prepare script commands/arguments
		NSMutableArray *arguments = nil;
		arguments = [NSMutableArray arrayWithObjects:[pmcLink userName],[pmcLink passWord],[pmcLink IPNumber],scriptRunPath,nil];
		[arguments addObjectsFromArray:	scriptcommands];
NSLog(@"  arguments: %@ \n" , arguments);	
	
		//add task
		[aSequence addTask:[resourcePath stringByAppendingPathComponent:@"loginScript"] 
				 arguments: arguments];  //limited to 6 arguments (see loginScript)

		
		[aSequence launch];

}





#pragma mark ***UDP Communication

//  UDP K command connection   -------------------------------
//reply socket (server)
- (int) startListeningServerSocket
{
	NSLog(@"Called %@::%@!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-

    int status, retval=0;

	if(UDP_REPLY_SERVER_SOCKET>0) [self stopListeningServerSocket];//still open, first close the socket
	UDP_REPLY_SERVER_SOCKET = socket ( AF_INET, SOCK_DGRAM, IPPROTO_UDP );
	if (UDP_REPLY_SERVER_SOCKET==-1){
        //fprintf(stderr, "initUDPServerSocket: socket(...) failed\n");
	    NSLog(@" %@::%@  socket(...) failed!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
        //diep("socket");
	    return 1;
    }
	//fprintf(stderr, "initGlobalUDPServerSocket: socket(...) created socket %i\n",GLOBAL_UDP_SERVER_SOCKET);
	NSLog(@" %@::%@  created socket %i  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) ,UDP_REPLY_SERVER_SOCKET);//TODO: DEBUG -tb-


	UDP_REPLY_servaddr.sin_family = AF_INET; 
	UDP_REPLY_servaddr.sin_port = htons (crateUDPReplyPort);

	char  GLOBAL_UDP_SERVER_IP_ADDR[1024]="0.0.0.0";//TODO: this might be necessary for hosts with several network adapters -tb-


	retval=inet_aton(GLOBAL_UDP_SERVER_IP_ADDR,&UDP_REPLY_servaddr.sin_addr);
	int GLOBAL_UDP_SERVER_IP = UDP_REPLY_servaddr.sin_addr.s_addr;//this is already in network byte order!!!
	printf("  inet_aton: retval: %i,IP_ADDR: %s, IP %i (0x%x)\n",retval,GLOBAL_UDP_SERVER_IP_ADDR,crateUDPReplyPort,GLOBAL_UDP_SERVER_IP);
	//GLOBAL_servaddr.sin_addr.s_addr =  htonl(GLOBAL_UDP_SERVER_IP);// INADDR_ANY = 0x00000000 = 0  ;   192.168.1.9  = 0xc0a80109  ;   192.168.1.34   = 0xc0a80122
	status = bind(UDP_REPLY_SERVER_SOCKET,(struct sockaddr *) &UDP_REPLY_servaddr,sizeof(UDP_REPLY_servaddr));
	if (status==-1) {
		printf("    ERROR starting UDP server .. -tb- continue, ignore error -tb-\n");
	    NSLog(@"    ERROR starting UDP server (bind: err %i) .. probably port already used ! (-tb- continue, ignore error -tb-)\n", status);//TODO: DEBUG -tb-
		//return 2 ; //-tb- continue, ignore error -tb-
	}
	printf("  serveur udp ouvert avec servaddr.sin_addr.s_addr=%s \n",inet_ntoa(UDP_REPLY_servaddr.sin_addr));
	listen(UDP_REPLY_SERVER_SOCKET,5);  //TODO: is this necessary? what does it mean exactly? -tb-
	                                    //TODO: is this necessary? what does it mean exactly? -tb-
 printf("  UDP SERVER is listening for K command reply on port %u\n",crateUDPReplyPort);
   if(crateUDPReplyPort<1024) printf("  NOTE,WARNING: initUDPServerSocket: UDP SERVER is listening on port %u, using ports below 1024 requires to run as 'root'!\n",crateUDPReplyPort);


    retval=0;//no error


	[self setIsListeningOnServerSocket: 1];
	//start polling
	if(	[self isListeningOnServerSocket]) [self performSelector:@selector(receiveFromReplyServer) withObject:nil afterDelay: 0];

    return retval;//retval=0: OK, else error
	
	return 0;
}

- (void) stopListeningServerSocket
{
	NSLog(@"Called %@::%@!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
    if(UDP_REPLY_SERVER_SOCKET>-1) close(UDP_REPLY_SERVER_SOCKET);
    UDP_REPLY_SERVER_SOCKET = -1;
	
	[self setIsListeningOnServerSocket: 0];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(receiveFromReplyServer) object:nil];
}

- (int) openServerSocket
{
	NSLog(@"Called %@::%@!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
	
	return 0;
}

- (void) closeServerSocket
{
	NSLog(@"Called %@::%@!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
}



- (int) receiveFromReplyServer
{

	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(receiveFromReplyServer) object:nil];

    const int maxSizeOfReadbuffer=4096;
    char readBuffer[maxSizeOfReadbuffer];

	int retval=-1;
    sockaddr_fromLength = sizeof(sockaddr_from);
    //while( (retval = recvfrom(MY_UDP_SERVER_SOCKET, (char*)InBuffer,sizeof(InBuffer) , MSG_DONTWAIT,(struct sockaddr *) &servaddr, &AddrLength)) >0 ){
    retval = recvfrom(UDP_REPLY_SERVER_SOCKET, readBuffer, maxSizeOfReadbuffer, MSG_DONTWAIT,(struct sockaddr *) &sockaddr_from, &sockaddr_fromLength);
	    //printf("recvfromGlobalServer retval:  %i, maxSize %i\n",retval,maxSizeOfReadbuffer);
	    if(retval>=0){
	        //printf("recvfromGlobalServer retval:  %i (bytes), maxSize %i, from IP %s\n",retval,maxSizeOfReadbuffer,inet_ntoa(sockaddr_from.sin_addr));
			//printf("Got UDP data from %s\n", inet_ntoa(sockaddr_from.sin_addr));
			//NSLog(@"Got UDP data from %s\n", inet_ntoa(sockaddr_from.sin_addr));
	        NSLog(@" %@::%@ Got UDP data from %s!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) ,inet_ntoa(sockaddr_from.sin_addr));//TODO: DEBUG -tb-

	    }
	//handle K commands
	if(retval>0){
	    //check for K command replies:
	    switch(readBuffer[0]){
	    case 'K':
	        readBuffer[retval]='\0';//make null terminated string for printf
	        //printf("Received reply to K command: >%s<\n",readBuffer);
	        NSLog(@"    Received reply to K command: >%s<\n", readBuffer);//TODO: DEBUG -tb-
	        //handleKCommand(readBuffer, retval, &sockaddr_from);
	        break;
	    default:
	        readBuffer[retval]='\0';//make null terminated string for printf
	        //printf("Received unknown command: >%s<\n",readBuffer);
			if(retval < 100)
	            NSLog(@"    Received message with length %i: >%s<\n", retval, readBuffer);//TODO: DEBUG -tb-
			else
	            NSLog(@"    Received message with length %i: first 4 bytes 0x%08x\n", retval, *((uint16_t*)readBuffer));//TODO: DEBUG -tb-
	        break;
	    }
		
		//if(   *((uint16_t*)readBuffer) & 0xFFD0    )
		
		
		//check for data packets:
		if(   *((uint16_t*)readBuffer) == 0xFFD0   /*&&  retval==1480*/){// reply to KRC_IPECrateStatus command
	        NSLog(@"    Received IPECrateStatus message with length %i\n", retval);//TODO: DEBUG -tb-
			UDPStructIPECrateStatus *status = (UDPStructIPECrateStatus *)readBuffer;
			NSLog(@"    Header0: 0x%04x,  Header1: 0x%04x\n",status->id0, status->id1);
			NSLog(@"    presentFLTMap: 0x%08x \n",status->presentFLTMap );
			NSLog(@"    reserved0: 0x%08x,  reserved1: 0x%08x\n",status->reserved0, status->reserved1);
			
			int i;
			NSLog(@"    SLT Block: \n");
			for(i=0; i<IPE_BLOCK_SIZE; i++){
			    NSLog(@"        SLT[%i]: 0x%08x \n",i,status->SLT[i] );
			}
			int f;
			for(f=0; f<MAX_NUM_FLT_CARDS; f++){
			    if(status->presentFLTMap & (0x1 <<f)){
    			    NSLog(@"    FLT #%i Block: \n",f);
	    		    for(i=0; i<IPE_BLOCK_SIZE; i++){
		    	        NSLog(@"        FLT #%i [%i]: 0x%08x \n",f,i,status->FLT[f][i] );
			        }
				}
				else
				{
		    	        NSLog(@"     FLT #%i not present \n",f);
				}

			}

			NSLog(@"    IPAdressMap: \n");
			for(i=0; i<MAX_NUM_FLT_CARDS; i++){
			    NSLog(@"        IPAdressMap[%i]: 0x%08x    Port: %i (0x%04x)\n",i,status->IPAdressMap[i], status->PortMap[i], status->PortMap[i]);
			}
		}
	}
	
	if(	[self isListeningOnServerSocket]) [self performSelector:@selector(receiveFromReplyServer) withObject:nil afterDelay: 0];

    return retval;
}



//command socket (client)
- (int) openCommandSocket
{
	NSLog(@"Called %@::%@!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
	//[model setCrateUDPCommand:[sender stringValue]];	
	
	if(UDP_COMMAND_CLIENT_SOCKET>0) [self closeCommandSocket];//still open, first close the socket
	
	//almost a copy from ipe4reader6.cpp
    int retval=0;
    if ((UDP_COMMAND_CLIENT_SOCKET=socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP))==-1){
        //fprintf(stderr, "initGlobalUDPClientSocket: socket(...) failed\n");
	    NSLog(@" %@::%@  socket(...) failed!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
        //diep("socket");
	    return 1;
    }
	NSLog(@" %@::%@  created socket %i  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) ,UDP_COMMAND_CLIENT_SOCKET);//TODO: DEBUG -tb-
	
  #if 1 //do it in sendToGlobalClient3 again?
    sockaddrin_to_len=sizeof(UDP_COMMAND_sockaddrin_to);
  memset((char *) &UDP_COMMAND_sockaddrin_to, 0, sizeof(UDP_COMMAND_sockaddrin_to));
  UDP_COMMAND_sockaddrin_to.sin_family = AF_INET;
  UDP_COMMAND_sockaddrin_to.sin_port = htons(crateUDPCommandPort); //take global variable MY_UDP_CLIENT_PORT //TODO: was PORT, remove PORT
  if (inet_aton([crateUDPCommandIP cStringUsingEncoding:NSASCIIStringEncoding], &UDP_COMMAND_sockaddrin_to.sin_addr)==0) {
	NSLog(@" %@::%@  inet_aton() failed \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
    //fprintf(stderr, "inet_aton() failed\n");
	return 2;
    //exit(1);
  }
	NSLog(@" %@::%@  UDP Client: IP: %s, port: %i \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) ,[crateUDPCommandIP cStringUsingEncoding:NSASCIIStringEncoding] /*crateUDPCommandIP oder %@ benutzen*/,	crateUDPCommandPort);//TODO: DEBUG -tb-
    //fprintf(stderr, "    initGlobalUDPClientSocket: UDP Client: IP: %s, port: %i\n",[crateUDPCommandIP cStringUsingEncoding:NSASCIIStringEncoding] /*crateUDPCommandIP oder %@ benutzen*/,	crateUDPCommandPort);
  #endif
  
	
	
	return retval;
}

- (void) closeCommandSocket
{
	NSLog(@"Called %@::%@!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
	//[model setCrateUDPCommand:[sender stringValue]];	
      if(UDP_COMMAND_CLIENT_SOCKET>-1) close(UDP_COMMAND_CLIENT_SOCKET);
      UDP_COMMAND_CLIENT_SOCKET = -1;
}

- (int) isOpenCommandSocket
{
	if(UDP_COMMAND_CLIENT_SOCKET>0) return 1; else return 0;
}





- (int) sendUDPCommand
#if 1
{
    return [self sendUDPCommandString: crateUDPCommand];
}
#else
{ //this was the first version, moved everything to 'sendUDPCommandString:' -tb-
    //taken from ipe4reader6.cpp, function int sendtoGlobalClient3(const void *buffer, size_t length, char* receiverIPAddr, uint32_t port)
	NSLog(@"Called %@::%@! Send string: >%@<\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),  [self crateUDPCommand]);//TODO: DEBUG -tb-
	//[model setCrateUDPCommand:[sender stringValue]];	
    if(UDP_COMMAND_CLIENT_SOCKET<=0){ NSLog(@"   socket not open\n"); return 1;}


    //const char *buffer   = [crateUDPCommand cStringUsingEncoding: NSASCIIStringEncoding];  //TODO: maybe use NSData and NSString::dataUsingEncoding:allowLossyConversion: ??? -tb-
    const void *buffer   = [[crateUDPCommand dataUsingEncoding: NSASCIIStringEncoding allowLossyConversion: YES] bytes]; 
	size_t length        = [crateUDPCommand lengthOfBytesUsingEncoding: NSASCIIStringEncoding];
	const char* receiverIPAddr = [crateUDPCommandIP cStringUsingEncoding: NSASCIIStringEncoding];;

	int retval=0;
	
  //	if(port==0) port = GLOBAL_UDP_CLIENT_PORT;//use default port
	
  memset((char *) &UDP_COMMAND_sockaddrin_to, 0, sizeof(UDP_COMMAND_sockaddrin_to));
  UDP_COMMAND_sockaddrin_to.sin_family = AF_INET;
  UDP_COMMAND_sockaddrin_to.sin_port = htons(crateUDPCommandPort);
  if (inet_aton([crateUDPCommandIP cStringUsingEncoding:NSASCIIStringEncoding], &UDP_COMMAND_sockaddrin_to.sin_addr)==0) {
	NSLog(@" %@::%@  inet_aton() failed \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
    //fprintf(stderr, "ERROR: sendtoGlobalClient3: inet_aton() failed\n");
	return 2;
    //exit(1);
  }
    fprintf(stderr, "    sendtoGlobalClient3: UDP Client: IP: %s, port: %i\n",receiverIPAddr,crateUDPCommandPort);
    //TODO: only recommended when using a char buffer ...  ((char*)buffer)[length]=0;    fprintf(stderr, "    sendtoGlobalClient3: %s\n",buffer); //DEBUG
	
	retval = sendto(UDP_COMMAND_CLIENT_SOCKET, buffer, length, 0 /*flags*/, (struct sockaddr *)&UDP_COMMAND_sockaddrin_to, sockaddrin_to_len);
    return retval;

}
#endif


- (int) sendUDPCommandString:(NSString*)aString
{
    //taken from ipe4reader6.cpp, function int sendtoGlobalClient3(const void *buffer, size_t length, char* receiverIPAddr, uint32_t port)
	NSLog(@"Called %@::%@! Send string: >%@<\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),  [self crateUDPCommand]);//TODO: DEBUG -tb-
	//[model setCrateUDPCommand:[sender stringValue]];	
    if(UDP_COMMAND_CLIENT_SOCKET<=0){ NSLog(@"   socket not open\n"); return 1;}


    //const char *buffer   = [crateUDPCommand cStringUsingEncoding: NSASCIIStringEncoding];  //TODO: maybe use NSData and NSString::dataUsingEncoding:allowLossyConversion: ??? -tb-
    const void *buffer   = [[aString dataUsingEncoding: NSASCIIStringEncoding allowLossyConversion: YES] bytes]; 
	size_t length        = [aString lengthOfBytesUsingEncoding: NSASCIIStringEncoding];
	const char* receiverIPAddr = [crateUDPCommandIP cStringUsingEncoding: NSASCIIStringEncoding];;

	int retval=0;
	
  //	if(port==0) port = GLOBAL_UDP_CLIENT_PORT;//use default port
	
  memset((char *) &UDP_COMMAND_sockaddrin_to, 0, sizeof(UDP_COMMAND_sockaddrin_to));
  UDP_COMMAND_sockaddrin_to.sin_family = AF_INET;
  UDP_COMMAND_sockaddrin_to.sin_port = htons(crateUDPCommandPort);
  if (inet_aton([crateUDPCommandIP cStringUsingEncoding:NSASCIIStringEncoding], &UDP_COMMAND_sockaddrin_to.sin_addr)==0) {
	NSLog(@" %@::%@  inet_aton() failed \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
    //fprintf(stderr, "ERROR: sendtoGlobalClient3: inet_aton() failed\n");
	return 2;
    //exit(1);
  }
    fprintf(stderr, "    sendtoGlobalClient3: UDP Client: IP: %s, port: %i\n",receiverIPAddr,crateUDPCommandPort);
    //TODO: only recommended when using a char buffer ...  ((char*)buffer)[length]=0;    fprintf(stderr, "    sendtoGlobalClient3: %s\n",buffer); //DEBUG
	
	retval = sendto(UDP_COMMAND_CLIENT_SOCKET, buffer, length, 0 /*flags*/, (struct sockaddr *)&UDP_COMMAND_sockaddrin_to, sockaddrin_to_len);
    return retval;

}






//  UDP data packet connection ---------------------
//reply socket (server)
- (int) startListeningDataServerSocket
{
	NSLog(@"Called %@::%@!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-

    int status, retval=0;

	if(UDP_DATA_REPLY_SERVER_SOCKET>0) [self stopListeningDataServerSocket];//still open, first close the socket
	UDP_DATA_REPLY_SERVER_SOCKET = socket ( AF_INET, SOCK_DGRAM, IPPROTO_UDP );
	if (UDP_DATA_REPLY_SERVER_SOCKET==-1){
        //fprintf(stderr, "initUDPServerSocket: socket(...) failed\n");
	    NSLog(@" %@::%@  socket(...) failed!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
        //diep("socket");
	    return 1;
    }
	//fprintf(stderr, "initGlobalUDPServerSocket: socket(...) created socket %i\n",GLOBAL_UDP_SERVER_SOCKET);
	NSLog(@" %@::%@  created socket %i  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) ,UDP_DATA_REPLY_SERVER_SOCKET);//TODO: DEBUG -tb-


	UDP_DATA_REPLY_servaddr.sin_family = AF_INET; 
	UDP_DATA_REPLY_servaddr.sin_port = htons (crateUDPDataReplyPort);

	char  GLOBAL_UDP_SERVER_IP_ADDR[1024]="0.0.0.0";//TODO: this might be necessary for hosts with several network adapters -tb-


	retval=inet_aton(GLOBAL_UDP_SERVER_IP_ADDR,&UDP_DATA_REPLY_servaddr.sin_addr);
	int GLOBAL_UDP_SERVER_IP = UDP_DATA_REPLY_servaddr.sin_addr.s_addr;//this is already in network byte order!!!
	printf("  inet_aton: retval: %i,IP_ADDR: %s, IP %i (0x%x)\n",retval,GLOBAL_UDP_SERVER_IP_ADDR,crateUDPDataReplyPort,GLOBAL_UDP_SERVER_IP);
	//GLOBAL_servaddr.sin_addr.s_addr =  htonl(GLOBAL_UDP_SERVER_IP);// INADDR_ANY = 0x00000000 = 0  ;   192.168.1.9  = 0xc0a80109  ;   192.168.1.34   = 0xc0a80122
	status = bind(UDP_DATA_REPLY_SERVER_SOCKET,(struct sockaddr *) &UDP_DATA_REPLY_servaddr,sizeof(UDP_DATA_REPLY_servaddr));
	if (status==-1) {
		printf("    ERROR starting UDP server .. -tb- continue, ignore error -tb-\n");
	    NSLog(@"    ERROR starting UDP server (bind: err %i) .. probably port already used ! (-tb- continue, ignore error -tb-)\n", status);//TODO: DEBUG -tb-
		//return 2 ; //-tb- continue, ignore error -tb-
	}
	printf("  serveur udp ouvert avec servaddr.sin_addr.s_addr=%s \n",inet_ntoa(UDP_DATA_REPLY_servaddr.sin_addr));
	listen(UDP_DATA_REPLY_SERVER_SOCKET,5);  //TODO: is this necessary? what does it mean exactly? -tb-
	                                    //TODO: is this necessary? what does it mean exactly? -tb-
 printf("  UDP DATA SERVER is listening for data packets (data and status) on port %u\n",crateUDPDataReplyPort);
   if(crateUDPDataReplyPort<1024) printf("  NOTE,WARNING: startListeningDataServerSocket: UDP DATA SERVER is listening on port %u, using ports below 1024 requires to run as 'root'!\n",crateUDPDataReplyPort);


    retval=0;//no error


	[self setIsListeningOnDataServerSocket: 1];
	//start polling
	if(	[self isListeningOnDataServerSocket]) 
	[self performSelector:@selector(receiveFromDataReplyServer) withObject:nil afterDelay: 0];

    return retval;//retval=0: OK, else error
	
	return 0;
}


- (void) stopListeningDataServerSocket
{
	NSLog(@"Called %@::%@!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
    if(UDP_DATA_REPLY_SERVER_SOCKET>-1) close(UDP_DATA_REPLY_SERVER_SOCKET);
    UDP_DATA_REPLY_SERVER_SOCKET = -1;
	
	[self setIsListeningOnDataServerSocket: 0];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(receiveFromDataReplyServer) object:nil];
}

- (int) receiveFromDataReplyServer
{

	static int counterStatusPacket=0;
	static int counterData1444Packet=0;
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(receiveFromDataReplyServer) object:nil];

    const int maxSizeOfReadbuffer=4096;
    char readBuffer[maxSizeOfReadbuffer];

	int retval=-1;
	
	
int l;
for(l=0;l<20;l++){
	//init
	retval=-1;
    sockaddr_data_fromLength = sizeof(sockaddr_data_from);
	
	
    //while( (retval = recvfrom(MY_UDP_SERVER_SOCKET, (char*)InBuffer,sizeof(InBuffer) , MSG_DONTWAIT,(struct sockaddr *) &servaddr, &AddrLength)) >0 ){
    retval = recvfrom(UDP_DATA_REPLY_SERVER_SOCKET, readBuffer, maxSizeOfReadbuffer, MSG_DONTWAIT,(struct sockaddr *) &sockaddr_data_from, &sockaddr_data_fromLength);
	    //printf("recvfromGlobalServer retval:  %i, maxSize %i\n",retval,maxSizeOfReadbuffer);
	if(retval==-1) break;
	    if(retval>=0 && retval != 1444){
	        //printf("recvfromGlobalServer retval:  %i (bytes), maxSize %i, from IP %s\n",retval,maxSizeOfReadbuffer,inet_ntoa(sockaddr_from.sin_addr));
			//printf("Got UDP data from %s\n", inet_ntoa(sockaddr_from.sin_addr));
			//NSLog(@"Got UDP data from %s\n", inet_ntoa(sockaddr_from.sin_addr));
	        NSLog(@" %@::%@ Got UDP data from %s!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) ,inet_ntoa(sockaddr_data_from.sin_addr));//TODO: DEBUG -tb-

	    }
	    if(retval == 1444 && counterData1444Packet==0){
	        NSLog(@" %@::%@ Got UDP data packet from %s!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) ,inet_ntoa(sockaddr_data_from.sin_addr));//TODO: DEBUG -tb-
			int i;
			uint16_t *shorts=(uint16_t *)readBuffer;
			NSMutableString *s = [[NSMutableString alloc] init];
			[s setString:@""];
			for(i=0;i<16;i++){
			    [s appendFormat:@" 0x%04x",shorts[i]];
			}
			NSLog(@"%@\n",s);
		}
		
	//give some debug output
	if(retval>0){
	
	    if(retval>=4){
		    uint32_t *hptr = (uint32_t *)(readBuffer);
		    uint16_t *h16ptr = (uint16_t *)(readBuffer);
		    uint16_t *h16ptr2 = (uint16_t *)(&readBuffer[2]);
			if(retval==1444) counterData1444Packet++;
			else{
		        if(counterData1444Packet>0) NSLog(@"  received %i data packets with 1444 bytes  \n",counterData1444Packet);
		        NSLog(@"  received data packet w header 0x%08x, 0x%04x,0x%04x, length %i\n",*hptr,*h16ptr,*h16ptr2,retval);
		        NSLog(@"  bytes: %i\n",counterData1444Packet * 1440 + retval -4);
				counterData1444Packet=0;
			}
		}

	
	
	}
}//for(l ...
//NSLog(@"retval: %i, l=%i\n",retval,l); with one fiber we had ca. 12 packets per loop ...
	if(	[self isListeningOnDataServerSocket]) [self performSelector:@selector(receiveFromDataReplyServer) withObject:nil afterDelay: 0];

    return retval;
}





//command data socket (client)
- (int) openDataCommandSocket
{
	NSLog(@"Called %@::%@!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
	//[model setCrateUDPCommand:[sender stringValue]];	
	
	if(UDP_DATA_COMMAND_CLIENT_SOCKET>0) [self closeDataCommandSocket];//still open, first close the socket
	
	//almost a copy from ipe4reader6.cpp
    int retval=0;
    if ((UDP_DATA_COMMAND_CLIENT_SOCKET=socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP))==-1){
        //fprintf(stderr, "openDataCommandSocket: socket(...) failed\n");
	    NSLog(@" %@::%@  socket(...) failed!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
        //diep("socket");
	    return 1;
    }
	NSLog(@" %@::%@  created socket %i  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) ,UDP_DATA_COMMAND_CLIENT_SOCKET);//TODO: DEBUG -tb-
	
  #if 1 //do it in sendToGlobalClient... again?
  memset((char *) &UDP_DATA_COMMAND_sockaddrin_to, 0, sizeof(UDP_DATA_COMMAND_sockaddrin_to));
  UDP_DATA_COMMAND_sockaddrin_to.sin_family = AF_INET;
  UDP_DATA_COMMAND_sockaddrin_to.sin_port = htons(crateUDPDataPort); //take global variable MY_UDP_CLIENT_PORT //TODO: was PORT, remove PORT
  if (inet_aton([crateUDPDataIP cStringUsingEncoding:NSASCIIStringEncoding], &UDP_DATA_COMMAND_sockaddrin_to.sin_addr)==0) {
	NSLog(@" %@::%@  inet_aton() failed \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
    //fprintf(stderr, "inet_aton() failed\n");
	return 2;
    //exit(1);
  }
	NSLog(@" %@::%@  UDP Client: IP: %s, port: %i \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) ,[crateUDPDataIP cStringUsingEncoding:NSASCIIStringEncoding] /*crateUDPCommandIP oder %@ benutzen*/,	crateUDPCommandPort);//TODO: DEBUG -tb-
    //fprintf(stderr, "    initGlobalUDPClientSocket: UDP Client: IP: %s, port: %i\n",[crateUDPCommandIP cStringUsingEncoding:NSASCIIStringEncoding] /*crateUDPCommandIP oder %@ benutzen*/,	crateUDPCommandPort);
  #endif
  
	
	
	return retval;
}



- (void) closeDataCommandSocket
{
	NSLog(@"Called %@::%@!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
	//[model setCrateUDPCommand:[sender stringValue]];	
      if(UDP_DATA_COMMAND_CLIENT_SOCKET>-1) close(UDP_DATA_COMMAND_CLIENT_SOCKET);
      UDP_DATA_COMMAND_CLIENT_SOCKET = -1;
}

- (int) isOpenDataCommandSocket
{
	if(UDP_DATA_COMMAND_CLIENT_SOCKET>0) return 1; else return 0;
}

- (int) sendUDPDataCommand:(char*)data length:(int) len
{
    //taken from ipe4reader6.cpp, function int sendtoGlobalClient3(const void *buffer, size_t length, char* receiverIPAddr, uint32_t port)
	NSLog(@"Called %@::%@! Send data ... len %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) , len);//TODO: DEBUG -tb-
	int i;
	for(i=0; i<len;i++) NSLog(@"0x%02x  ",data[i]);
	NSLog(@"\n");



	//[model setCrateUDPCommand:[sender stringValue]];	
    if(UDP_DATA_COMMAND_CLIENT_SOCKET<=0){ NSLog(@"   socket not open\n"); return 1;}


    //const char *buffer   = [crateUDPCommand cStringUsingEncoding: NSASCIIStringEncoding];  //TODO: maybe use NSData and NSString::dataUsingEncoding:allowLossyConversion: ??? -tb-
    //const void *buffer   = [[aString dataUsingEncoding: NSASCIIStringEncoding allowLossyConversion: YES] bytes]; 
	//size_t length        = [aString lengthOfBytesUsingEncoding: NSASCIIStringEncoding];
    const void *buffer   = data; 
	size_t length        = len;
	const char* receiverIPAddr = [crateUDPDataIP cStringUsingEncoding: NSASCIIStringEncoding];;

	int retval=0;
	
  //	if(port==0) port = GLOBAL_UDP_CLIENT_PORT;//use default port
	
  memset((char *) &UDP_DATA_COMMAND_sockaddrin_to, 0, sizeof(UDP_DATA_COMMAND_sockaddrin_to));
  UDP_DATA_COMMAND_sockaddrin_to.sin_family = AF_INET;
  UDP_DATA_COMMAND_sockaddrin_to.sin_port = htons(crateUDPDataPort);
  if (inet_aton([crateUDPDataIP cStringUsingEncoding:NSASCIIStringEncoding], &UDP_DATA_COMMAND_sockaddrin_to.sin_addr)==0) {
	NSLog(@" %@::%@  inet_aton() failed \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
    //fprintf(stderr, "ERROR: sendtoGlobalClient3: inet_aton() failed\n");
	return 2;
    //exit(1);
  }
    fprintf(stderr, "    sendtoGlobalClient3: UDP Client: IP: %s, port: %i\n",receiverIPAddr,crateUDPDataPort);
    //TODO: only recommended when using a char buffer ...  ((char*)buffer)[length]=0;    fprintf(stderr, "    sendtoGlobalClient3: %s\n",buffer); //DEBUG
	
	retval = sendto(UDP_DATA_COMMAND_CLIENT_SOCKET, buffer, length, 0 /*flags*/, (struct sockaddr *)&UDP_DATA_COMMAND_sockaddrin_to, sizeof(UDP_DATA_COMMAND_sockaddrin_to));
    return retval;


}


#pragma mark ***HW Access
- (void)		  writeMasterMode
{
//DEBUG OUTPUT: 	
NSLog(@"WARNING: %@::%@: STILL UNDER CONSTRUCTION! \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
}

- (void)		  writeSlaveMode
{
//DEBUG OUTPUT: 	
NSLog(@"WARNING: %@::%@: STILL UNDER CONSTRUCTION! \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
}


- (void) checkPresence
{
	@try {
		[self readStatusReg];
		[self setPresent:YES];
	}
	@catch(NSException* localException) {
		[self setPresent:NO];
	}
}
/*
- (void) loadPatternFile
{
	NSString* contents = [NSString stringWithContentsOfFile:patternFilePath encoding:NSASCIIStringEncoding error:nil];
	if(contents){
		NSLog(@"loading Pattern file: <%@>\n",patternFilePath);
		NSScanner* scanner = [NSScanner scannerWithString:contents];
		int amplitude;
		[scanner scanInt:&amplitude];
		int i=0;
		int j=0;
		unsigned long time[256];
		unsigned long mask[20][256];
		int len = 0;
		BOOL status;
		while(1){
			status = [scanner scanHexInt:(unsigned*)&time[i]];
			if(!status)break;
			if(time[i] == 0){
				break;
			}
			for(j=0;j<20;j++){
				status = [scanner scanHexInt:(unsigned*)&mask[j][i]];
				if(!status)break;
			}
			i++;
			len++;
			if(i>256)break;
			if(!status)break;
		}
		
		@try {
			//collect all valid cards
			ORIpeFLTModel* cards[20];//TODO: OREdelweissSLTModel -tb-
			int i;
			for(i=0;i<20;i++)cards[i]=nil;
			
			NSArray* allFLTs = [[self crate] orcaObjects];
			NSEnumerator* e = [allFLTs objectEnumerator];
			id aCard;
			while(aCard = [e nextObject]){
				if([aCard isKindOfClass:NSClassFromString(@"ORIpeFireWireCard")])continue;//TODO: is this still true for v4? -tb-
				int index = [aCard stationNumber] - 1;
				if(index<20){
					cards[index] = aCard;
				}
			}
			for(i=0;i<20;i++){
				[cards[i] setFltRunMode: kIpeFlt_Test_Mode];
			}
			
			
			[self writeReg:kSltTestpulsAmpl value:amplitude];
			[self writeBlock:SLT_REG_ADDRESS(kSltTimingMemory) 
				  dataBuffer:time
					  length:len
				   increment:1];
			
			
			int j;
			for(j=0;j<20;j++){
				[cards[j] writeTestPattern:mask[j] length:len];
			}
			
			[self swTrigger];
			
			NSFont* aFont = [NSFont userFixedPitchFontOfSize:9];
			NSLogFont(aFont,@"-----------------------------------------------------------------------------\n");			
			NSLogFont(aFont,@"Index|  Time    | Mask                              Amplitude = %5d\n",amplitude);			
			NSLogFont(aFont,@"-----------------------------------------------------------------------------\n");			
			NSLogFont(aFont,@"     |    delta |  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20\n");			
			unsigned int delta = time[0];
			for(i=0;i<len;i++){
				NSMutableString* line = [NSMutableString stringWithFormat:@"  %2d |=%4d=%4d|",i,delta,time[i]];
				delta += time[i];
				for(j=0;j<20;j++){
					if(mask[j][i] != 0x1000000)[line appendFormat:@"%3s",mask[j][i]?"‚Ä¢":"-"];
					else [line appendFormat:@"%3s","="];
				}
				NSLogFont(aFont,@"%@\n",line);
			}
			NSLogFont(aFont,@"-----------------------------------------------------------------------------\n",amplitude);			
			
			
			for(i=0;i<20;i++){
				[cards[i] setFltRunMode: kIpeFltV4Katrin_Run_Mode];
			}
			
			
		}
		@catch(NSException* localException) {
			NSLogColor([NSColor redColor],@"Couldn't load Pattern file <%@>\n",patternFilePath);
		}
	}
	else NSLogColor([NSColor redColor],@"Couldn't open Pattern file <%@>\n",patternFilePath);
}

- (void) swTrigger
{
	[self writeReg:kSltSwTestpulsTrigger value:0];
}
*/

- (void) writeReg:(int)index value:(unsigned long)aValue
{
	[self write: [self getAddress:index] value:aValue];
}

- (void) writeReg:(int)index  forFifo:(int)fifoIndex value:(unsigned long)aValue
{
	[self write: ([self getAddress:index]|(fifoIndex << 14)) value:aValue];
}

- (void)		  rawWriteReg:(unsigned long) address  value:(unsigned long)aValue
//TODO: FOR TESTING AND DEBUGGING ONLY -tb-
{
    [self write: address value: aValue];
}

- (unsigned long) rawReadReg:(unsigned long) address
//TODO: FOR TESTING AND DEBUGGING ONLY -tb-
{
	return [self read: address];

}

- (unsigned long) readReg:(int) index
{
	return [self read: [self getAddress:index]];

}

- (unsigned long) readReg:(int) index forFifo:(int)fifoIndex;
{
	return [ self read: ([self getAddress:index] | (fifoIndex << 14)) ];

}

- (id) writeHardwareRegisterCmd:(unsigned long) regAddress value:(unsigned long) aValue
{
	return [ORPMCReadWriteCommand writeLongBlock:&aValue
									   atAddress:regAddress
									  numToWrite:1];
}

- (id) readHardwareRegisterCmd:(unsigned long) regAddress
{
	return [ORPMCReadWriteCommand readLongBlockAtAddress:regAddress
									  numToRead:1];
}

- (void) executeCommandList:(ORCommandList*)aList
{
	[pmcLink executeCommandList:aList];
}

- (void) readAllStatus
{
	//[self readControlReg];
	[self readStatusReg];
	//[self readReadOutControlReg];
	[self getTime];
	[self readEventFifoStatusReg];
}



- (unsigned long) readControlReg
{
	return [self readReg:kSltV4ControlReg];
}


- (void) writeControlReg
{
	[self writeReg:kSltV4ControlReg value:controlReg];
}

- (void) printControlReg
{
	unsigned long data = [self readControlReg];
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	NSLogFont(aFont,@"----Control Register %@ is 0x%08x ----\n",[self fullID],data);
	NSLogFont(aFont,@"OnLine  : 0x%02x\n",(data & kCtrlOnLine) >> 14);
	NSLogFont(aFont,@"LedOff  : 0x%02x\n",(data & kCtrlLedOff) >> 15);
	NSLogFont(aFont,@"Invert  : 0x%02x\n",(data & kCtrlInvert) >> 16);
}


- (unsigned long) readStatusReg
{
	unsigned long data = [self readReg:kSltV4StatusReg];
//DEBUG OUTPUT:  	NSLog(@"   %@::%@: kSltV4StatusReg: 0x%08x \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),data);//TODO: DEBUG testing ...-tb-
	[self setStatusReg:data];
	return data;
}

- (void) printStatusReg
{
	unsigned long data = [self readStatusReg];
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	NSLogFont(aFont,@"----Status Register %@ is 0x%08x ----\n",[self fullID],data);
	NSLogFont(aFont,@"IRQ           : 0x%02x\n",ExtractValue(data,kStatusIrq,31));
	NSLogFont(aFont,@"PixErr        : 0x%02x\n",ExtractValue(data,kStatusPixErr,16));
	NSLogFont(aFont,@"FLT0..15 Requ.: 0x%04x\n",ExtractValue(data,0xffff,0));
}




- (void) writePixelBusEnableReg
{
	[self writeReg:kSltV4PixelBusEnableReg value: [self pixelBusEnableReg]];
}

- (void) readPixelBusEnableReg
{
    unsigned long val;
	val = [self readReg:kSltV4PixelBusEnableReg];
	[self setPixelBusEnableReg:val];	
}










- (long) getSBCCodeVersion
{
	long theVersion = 0;
	if(![pmcLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	else {
		[pmcLink readGeneral:&theVersion operation:kGetSoftwareVersion numToRead:1];
		//implementation is in HW_Readout.cc, void doGeneralReadOp(SBC_Packet* aPacket,uint8_t reply)  ... -tb-
	}
	[pmcLink setSbcCodeVersion:theVersion];
	return theVersion;
}

- (long) getFdhwlibVersion
{
	long theVersion = 0;
	if(![pmcLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	else {
		[pmcLink readGeneral:&theVersion operation:kGetFdhwLibVersion numToRead:1];
	}
	return theVersion;
}

- (long) getSltPciDriverVersion
{
	long theVersion = 0;
	if(![pmcLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	else {
		[pmcLink readGeneral:&theVersion operation:kGetSltPciDriverVersion numToRead:1];
	}
	return theVersion;
}

//TODO: remove this, never usd -tb-
- (void) readEventStatus:(unsigned long*)eventStatusBuffer
{
	if(![pmcLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	[pmcLink readLongBlockPmc:eventStatusBuffer
					 atAddress:regV4[kSltV4EventFIFOStatusReg].addressOffset
					 numToRead: 1];
	
}

- (void) readEventFifoStatusReg
{
	[self setEventFifoStatusReg:[self readReg:kSltV4EventFIFOStatusReg]];
}


- (unsigned long long) readBoardID
{
	unsigned long low = [self readReg:kSltV4BoardIDLoReg];
	unsigned long hi  = [self readReg:kSltV4BoardIDHiReg];
	BOOL crc =(hi & 0x80000000)==0x80000000;
	if(crc){
		return (unsigned long long)(hi & 0xffff)<<32 | low;
	}
	else return 0;
}

//DEBUG OUTPUT: 	NSLog(@"WARNING: %@::%@: UNDER CONSTRUCTION! \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-


- (void) writeInterruptMask
{
	[self writeReg:kSltV4InterruptMaskReg value:interruptMask];
}

- (void) readInterruptMask
{
	[self setInterruptMask:[self readReg:kSltV4InterruptMaskReg]];
}

- (void) readInterruptRequest
{
	[self setInterruptMask:[self readReg:kSltV4InterruptRequestReg]];
}

- (void) printInterruptRequests
{
	[self printInterrupt:kSltV4InterruptRequestReg];
}

- (void) printInterruptMask
{
	[self printInterrupt:kSltV4InterruptMaskReg];
}

- (void) printInterrupt:(int)regIndex
{
	unsigned long data = [self readReg:regIndex];
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	if(!data)NSLogFont(aFont,@"Interrupt Mask is Clear (No interrupts %@)\n",regIndex==kSltV4InterruptRequestReg?@"Requested":@"Enabled");
	else {
		NSLogFont(aFont,@"The following interrupts are %@:\n",regIndex==kSltV4InterruptRequestReg?@"Requested":@"Enabled");
		NSLogFont(aFont,@"0x%04x\n",data & 0xffff);
	}
}

- (unsigned long) readHwVersion
{
	unsigned long value;
	@try {
		[self setHwVersion:[self readReg: kSltV4RevisionReg]];	
	}
	@catch (NSException* e){
	}
	return value;
}


- (unsigned long) readTimeLow
{
	return [self readReg:kSltV4TimeLowReg];
}

- (unsigned long) readTimeHigh
{
	return [self readReg:kSltV4TimeHighReg];
}

- (unsigned long long) getTime
{
	unsigned long th = [self readTimeHigh]; 
	unsigned long tl = [self readTimeLow]; 
	[self setClockTime: (((unsigned long long) th) << 32) | tl];
//DEBUG OUTPUT: 	NSLog(@"   %@::%@: tl: 0x%08x,  th: 0x%08x  clockTime: 0x%016qx\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),tl,th,clockTime);//TODO: DEBUG testing ...-tb-
	return clockTime;
}

- (void) initBoard
{

//TODO: initBoard: switch to online, event readout etc. -tb-
//TODO: initBoard: switch to online, event readout etc. -tb-
//TODO: initBoard: switch to online, event readout etc. -tb-
//TODO: initBoard: switch to online, event readout etc. -tb-
//TODO: initBoard: switch to online, event readout etc. -tb-
//TODO: initBoard: switch to online, event readout etc. -tb-
//TODO: initBoard: switch to online, event readout etc. -tb-

//DEBUG OUTPUT:
 	NSLog(@"WARNING: %@::%@: UNDER CONSTRUCTION! \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-



	[self writeControlReg];
	[self writeInterruptMask];
	[self writePixelBusEnableReg];
	//-----------------------------------------------
	//board doesn't appear to start without this stuff
	//[self writeReg:kSltActResetFlt value:0];
	//[self writeReg:kSltActResetSlt value:0];
	//usleep(10);
	//[self writeReg:kSltRelResetFlt value:0];
	//[self writeReg:kSltRelResetSlt value:0];
	//[self writeReg:kSltSwSltTrigger value:0];
	//[self writeReg:kSltSwSetInhibit value:0];
	
	//usleep(100);
	
//	int savedTriggerSource = triggerSource;
//	int savedInhibitSource = inhibitSource;
//	triggerSource = 0x1; //sw trigger only
//	inhibitSource = 0x3; 
//	[self writePageManagerReset];
	//unsigned long long p1 = ((unsigned long long)[self readReg:kPageStatusHigh]<<32) | [self readReg:kPageStatusLow];
	//[self writeReg:kSltSwRelInhibit value:0];
	//int i = 0;
	//unsigned long lTmp;
    //do {
	//	lTmp = [self readReg:kSltStatusReg];
		//NSLog(@"waiting for inhibit %x i=%d\n", lTmp, i);
		//usleep(10);
		//i++;
   // } while(((lTmp & 0x10000) != 0) && (i<10000));
	
   // if (i>= 10000){
		//NSLog(@"Release inhibit failed\n");
		//[NSException raise:@"SLT error" format:@"Release inhibit failed"];
	//}
/*	
	unsigned long long p2  = ((unsigned long long)[self readReg:kPageStatusHigh]<<32) | [self readReg:kPageStatusLow];
	if(p1 == p2) NSLog (@"No software trigger\n");
	[self writeReg:kSltSwSetInhibit value:0];
 */
//	triggerSource = savedTriggerSource;
	//inhibitSource = savedInhibitSource;
	//-----------------------------------------------
	
	[self printStatusReg];
	[self printControlReg];
}

- (void) reset
{
	[self hw_config];
	[self hw_reset];
}

- (void) hw_config
{
	NSLog(@"SLT: HW Configure\n");
	[ORTimer delay:1.5];
	[ORTimer delay:1.5];
	//[self readReg:kSltStatusReg];
	[guardian checkCards];
}

- (void) hw_reset
{
	NSLog(@"SLT: HW Reset\n");
	//[self writeReg:kSltSwRelInhibit value:0];
	//[self writeReg:kSltActResetFlt value:0];
	//[self writeReg:kSltActResetSlt value:0];
	usleep(10);
	//[self writeReg:kSltRelResetFlt value:0];
	//[self writeReg:kSltRelResetSlt value:0];
	//[self writeReg:kSltSwSltTrigger value:0];
	//[self writeReg:kSltSwSetInhibit value:0];				
}
/*
- (void) loadPulseAmp
{
	unsigned short theConvertedAmp = pulserAmp * 4095./4.;
	[self writeReg:kSltTestpulsAmpl value:theConvertedAmp];
	NSLog(@"Wrote %.2fV to SLT pulser Amplitude\n",pulserAmp);
}

- (void) loadPulseDelay
{
	//delay goes from 100ns to 3276.8us
	//writing 0x00 to hw gives longest delay. 
	//conversion equation:  hwValue = -10.0*delay + 32768.
	unsigned short theConvertedDelay = pulserDelay * -10.0 + 32768.;
	[self write:SLT_REG_ADDRESS(kSltTestpulsTiming)+0 value:theConvertedDelay];
	[self write:SLT_REG_ADDRESS(kSltTestpulsTiming)+1 value:theConvertedDelay];
	int i; //load the rest of the pulser memory with 0's
	for (i=2;i<256;i++) [self write:SLT_REG_ADDRESS(kSltTestpulsTiming)+i value:theConvertedDelay];
}


- (void) loadPulserValues
{
	[self loadPulseAmp];
	[self loadPulseDelay];
}
*/

- (void) setCrateNumber:(unsigned int)aNumber
{
	[guardian setCrateNumber:aNumber];
}

#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];
	[[self undoManager] disableUndoRegistration];
	
	[self setNumRequestedUDPPackets:[decoder decodeIntForKey:@"numRequestedUDPPackets"]];
	[self setCrateUDPDataReplyPort:[decoder decodeIntForKey:@"crateUDPDataReplyPort"]];
	[self setCrateUDPDataIP:[decoder decodeObjectForKey:@"crateUDPDataIP"]];
	[self setCrateUDPDataPort:[decoder decodeIntForKey:@"crateUDPDataPort"]];
	[self setPixelBusEnableReg:[decoder decodeInt32ForKey:@"pixelBusEnableReg"]];
	[self setSelectedFifoIndex:[decoder decodeIntForKey:@"selectedFifoIndex"]];
	[self setCrateUDPCommand:[decoder decodeObjectForKey:@"crateUDPCommand"]];
	[self setCrateUDPReplyPort:[decoder decodeIntForKey:@"crateUDPReplyPort"]];
	[self setCrateUDPCommandIP:[decoder decodeObjectForKey:@"crateUDPCommandIP"]];
	[self setCrateUDPCommandPort:[decoder decodeIntForKey:@"crateUDPCommandPort"]];
	[self setSltScriptArguments:[decoder decodeObjectForKey:@"sltScriptArguments"]];
	pmcLink = [[decoder decodeObjectForKey:@"PMC_Link"] retain];
	if(!pmcLink)pmcLink = [[PMC_Link alloc] initWithDelegate:self];
	else [pmcLink setDelegate:self];

	[self setControlReg:		[decoder decodeInt32ForKey:@"controlReg"]];
	if([decoder containsValueForKey:@"secondsSetInitWithHost"])
		[self setSecondsSetInitWithHost:[decoder decodeBoolForKey:@"secondsSetInitWithHost"]];
	else[self setSecondsSetInitWithHost: YES];
	

	//status reg
	[self setPatternFilePath:		[decoder decodeObjectForKey:@"OREdelweissSLTModelPatternFilePath"]];
	[self setInterruptMask:			[decoder decodeInt32ForKey:@"OREdelweissSLTModelInterruptMask"]];
	[self setPulserDelay:			[decoder decodeFloatForKey:@"OREdelweissSLTModelPulserDelay"]];
	[self setPulserAmp:				[decoder decodeFloatForKey:@"OREdelweissSLTModelPulserAmp"]];
		
	//special
    [self setNextPageDelay:			[decoder decodeIntForKey:@"nextPageDelay"]]; // ak, 5.10.07
	
	[self setReadOutGroup:			[decoder decodeObjectForKey:@"ReadoutGroup"]];
    [self setPoller:				[decoder decodeObjectForKey:@"poller"]];
	
    [self setPageSize:				[decoder decodeIntForKey:@"OREdelweissSLTPageSize"]]; // ak, 9.12.07
    [self setDisplayTrigger:		[decoder decodeBoolForKey:@"OREdelweissSLTDisplayTrigger"]];
    [self setDisplayEventLoop:		[decoder decodeBoolForKey:@"OREdelweissSLTDisplayEventLoop"]];
    	
    if (!poller)[self makePoller:0];
	
	//needed because the readoutgroup was added when the object was already in the config and so might not be in the configuration
	if(!readOutGroup){
		ORReadOutList* readList = [[ORReadOutList alloc] initWithIdentifier:@"ReadOut List"];
		[self setReadOutGroup:readList];
		[readList release];
	}
	
	[[self undoManager] enableUndoRegistration];

	[self registerNotificationObservers];
		
	return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
	[super encodeWithCoder:encoder];
	
	[encoder encodeInt:numRequestedUDPPackets forKey:@"numRequestedUDPPackets"];
	[encoder encodeInt:crateUDPDataReplyPort forKey:@"crateUDPDataReplyPort"];
	[encoder encodeObject:crateUDPDataIP forKey:@"crateUDPDataIP"];
	[encoder encodeInt:crateUDPDataPort forKey:@"crateUDPDataPort"];
	[encoder encodeInt32:pixelBusEnableReg forKey:@"pixelBusEnableReg"];
	[encoder encodeInt:selectedFifoIndex forKey:@"selectedFifoIndex"];
	[encoder encodeObject:crateUDPCommand forKey:@"crateUDPCommand"];
	[encoder encodeInt:crateUDPReplyPort forKey:@"crateUDPReplyPort"];
	[encoder encodeObject:crateUDPCommandIP forKey:@"crateUDPCommandIP"];
	[encoder encodeInt:crateUDPCommandPort forKey:@"crateUDPCommandPort"];
	[encoder encodeBool:secondsSetInitWithHost forKey:@"secondsSetInitWithHost"];
	[encoder encodeObject:sltScriptArguments forKey:@"sltScriptArguments"];
	[encoder encodeObject:pmcLink		forKey:@"PMC_Link"];
	[encoder encodeInt32:controlReg	forKey:@"controlReg"];
	
	//status reg
	[encoder encodeObject:patternFilePath forKey:@"OREdelweissSLTModelPatternFilePath"];
	[encoder encodeInt32:interruptMask	 forKey:@"OREdelweissSLTModelInterruptMask"];
	[encoder encodeFloat:pulserDelay	 forKey:@"OREdelweissSLTModelPulserDelay"];
	[encoder encodeFloat:pulserAmp		 forKey:@"OREdelweissSLTModelPulserAmp"];
		
	//special
    [encoder encodeInt:nextPageDelay     forKey:@"nextPageDelay"]; // ak, 5.10.07
	
	[encoder encodeObject:readOutGroup  forKey:@"ReadoutGroup"];
    [encoder encodeObject:poller         forKey:@"poller"];
	
    [encoder encodeInt:pageSize         forKey:@"OREdelweissSLTPageSize"]; // ak, 9.12.07
    [encoder encodeBool:displayTrigger   forKey:@"OREdelweissSLTDisplayTrigger"];
    [encoder encodeBool:displayEventLoop forKey:@"OREdelweissSLTDisplayEventLoop"];
		
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
	
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"OREdelweissSLTDecoderForEvent",				@"decoder",
								 [NSNumber numberWithLong:eventDataId],	@"dataId",
								 [NSNumber numberWithBool:NO],			@"variable",
								 [NSNumber numberWithLong:5],			@"length",
								 nil];
	
    [dataDictionary setObject:aDictionary forKey:@"EdelweissSLTEvent"];
	
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"OREdelweissSLTDecoderForMultiplicity",			@"decoder",
				   [NSNumber numberWithLong:multiplicityId],   @"dataId",
				   [NSNumber numberWithBool:NO],				@"variable",
				   [NSNumber numberWithLong:3+20*100],			@"length",
				   nil];
	
    [dataDictionary setObject:aDictionary forKey:@"EdelweissSLTMultiplicity"];
    
    return dataDictionary;
}

- (unsigned long) eventDataId        { return eventDataId; }
- (unsigned long) multiplicityId	 { return multiplicityId; }
- (void) setEventDataId: (unsigned long) aDataId    { eventDataId = aDataId; }
- (void) setMultiplicityId: (unsigned long) aDataId { multiplicityId = aDataId; }

- (void) setDataIds:(id)assigner
{
    eventDataId     = [assigner assignDataIds:kLongForm];
    multiplicityId  = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setEventDataId:[anotherCard eventDataId]];
    [self setMultiplicityId:[anotherCard multiplicityId]];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
	return objDictionary;
}

#pragma mark •••Data Taker
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{

//TODO: UNDER construction -tb-
//TODO: UNDER construction -tb-
//TODO: UNDER construction -tb-
NSLog(@"WARNING: %@::%@: UNDER CONSTRUCTION! \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-




    [self clearExceptionCount];
	
	//check that we can actually run
	if(![pmcLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Check the SLT connection"];
	}
	
    //----------------------------------------------------------------------------------------
    // Add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"OREdelweissSLTModel"];    
    //----------------------------------------------------------------------------------------	
	
	pollingWasRunning = [poller isRunning];
	if(pollingWasRunning) [poller stop];
	
	//[self writeSetInhibit];  //TODO: maybe move to readout loop to avoid dead time -tb-
	
    if([[userInfo objectForKey:@"doinit"]intValue]){
		[self initBoard];					
	}	
	
	dataTakers = [[readOutGroup allObjects] retain];		//cache of data takers.
	
	for(id obj in dataTakers){ //the SLT calls runTaskStarted:userInfo: for all FLTs -tb-
        [obj runTaskStarted:aDataPacket userInfo:userInfo];
    }
	
	
	[self readStatusReg];
//TODO: UNDER construction -tb-
//TODO: UNDER construction -tb-
//TODO: UNDER construction -tb-
	actualPageIndex = 0;
	eventCounter    = 0;
	first = YES;
	lastDisplaySec = 0;
	lastDisplayCounter = 0;
	lastDisplayRate = 0;
	lastSimSec = 0;
	
	//load all the data needed for the eCPU to do the HW read-out.
	[self load_HW_Config];
	[pmcLink runTaskStarted:aDataPacket userInfo:userInfo];
	
}

-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	if(!first){
		//event readout controlled by the SLT cpu now. ORCA reads out 
		//the resulting data from a generic circular buffer in the pmc code.
		[pmcLink takeData:aDataPacket userInfo:userInfo];
	}
	else {// the first time
		//TODO: -tb- [self writePageManagerReset];
		//TODO: -tb- [self writeClrCnt];
		unsigned long long runcount = [self getTime];
		[self shipSltEvent:kRunCounterType withType:kStartRunType eventCt:0 high: (runcount>>32)&0xffffffff low:(runcount)&0xffffffff ];

		[self shipSltSecondCounter: kStartRunType];
		first = NO;
	}
}

- (void) runIsStopping:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    for(id obj in dataTakers){
        [obj runIsStopping:aDataPacket userInfo:userInfo];
    }
	[pmcLink runIsStopping:aDataPacket userInfo:userInfo];
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{

	[self shipSltSecondCounter: kStopRunType];
	unsigned long long runcount = [self getTime];
	[self shipSltEvent:kRunCounterType withType:kStopRunType eventCt:0 high: (runcount>>32)&0xffffffff low:(runcount)&0xffffffff ];
	
    for(id obj in dataTakers){
		[obj runTaskStopped:aDataPacket userInfo:userInfo];
    }	
	
	[pmcLink runTaskStopped:aDataPacket userInfo:userInfo];
	
	if(pollingWasRunning) {
		[poller runWithTarget:self selector:@selector(readAllStatus)];
	}
	
	[dataTakers release];
	dataTakers = nil;

}

/** For the V4 SLT (Auger/KATRIN)the subseconds count 100 nsec tics! (Despite the fact that the ADC sampling has a 50 nsec base.)
  */ //-tb- 
- (void) shipSltSecondCounter:(unsigned char)aType
{
	//aType = 1 start run, =2 stop run, = 3 start subrun, =4 stop subrun, see #defines in OREdelweissSLTDefs.h -tb-
	unsigned long tl = [self readTimeLow]; 
	unsigned long th = [self readTimeHigh]; 

	

	[self shipSltEvent:kSecondsCounterType withType:aType eventCt:0 high:th low:tl ];
	#if 0
	unsigned long location = (([self crateNumber]&0x1e)<<21) | ([self stationNumber]& 0x0000001f)<<16;
	unsigned long data[5];
			data[0] = eventDataId | 5; 
			data[1] = location | (aType & 0xf);
			data[2] = 0;	
			data[3] = th;	
			data[4] = tl;
			[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
																object:[NSData dataWithBytes:data length:sizeof(long)*(5)]];
	#endif
}

- (void) shipSltEvent:(unsigned char)aCounterType withType:(unsigned char)aType eventCt:(unsigned long)c high:(unsigned long)h low:(unsigned long)l
{
	unsigned long location = (([self crateNumber]&0x1e)<<21) | ([self stationNumber]& 0x0000001f)<<16;
	unsigned long data[5];
			data[0] = eventDataId | 5; 
			data[1] = location | ((aCounterType & 0xf)<<4) | (aType & 0xf);
			data[2] = c;	
			data[3] = h;	
			data[4] = l;
			[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
																object:[NSData dataWithBytes:data length:sizeof(long)*(5)]];
}


- (BOOL) doneTakingData
{
	return [pmcLink doneTakingData];
}

- (unsigned long) calcProjection:(unsigned long *)pMult  xyProj:(unsigned long *)xyProj  tyProj:(unsigned long *)tyProj
{ 
	//temp----
	int i, j, k;
	int sltSize = pageSize * 20;	
	
	
	// Dislay the matrix of triggered pixel and timing
	// The xy-Projection is needed to readout only the triggered pixel!!!
	//unsigned long xyProj[20];
	//unsigned long tyProj[100];
	for (i=0;i<20;i++) xyProj[i] = 0;
	for (k=0;k<100;k++) tyProj[k] = 0;
	for (k=0;k<sltSize;k++){
		xyProj[k%20] = xyProj[k%20] | (pMult[k] & 0x3fffff);
	}  
	for (k=0;k<sltSize;k++){
		if (xyProj[k%20]) {
			tyProj[k/20] = tyProj[k/20] | (pMult[k] & 0x3fffff);
		}
	}
	
	int nTriggered = 0;
	for (i=0;i<20;i++){
		for(j=0;j<22;j++){
			if (((xyProj[i]>>j) & 0x1 ) == 0x1) nTriggered++;
		}
	}
	
	
	// Display trigger data
	if (displayTrigger) {	
		int i, j, k;
		NSFont* aFont = [NSFont userFixedPitchFontOfSize:9];
		
		for(j=0;j<22;j++){
			NSMutableString* s = [NSMutableString stringWithFormat:@"%2d: ",j];
			//matrix of triggered pixel
			for(i=0;i<20;i++){
				if (((xyProj[i]>>j) & 0x1) == 0x1) [s appendFormat:@"X"];
				else							   [s appendFormat:@"."];
			}
			[s appendFormat:@"  "];
			
			// trigger timing
			for (k=0;k<pageSize;k++){
				if (((tyProj[k]>>j) & 0x1) == 0x1 )[s appendFormat:@"="];
				else							   [s appendFormat:@"."];
			}
			NSLogFont(aFont, @"%@\n", s);
		}
		
		NSLogFont(aFont,@"\n");	
	}		
	return(nTriggered);
}

- (void) saveReadOutList:(NSFileHandle*)aFile
{
    [readOutGroup saveUsingFile:aFile];
}

- (void) loadReadOutList:(NSFileHandle*)aFile
{
    [self setReadOutGroup:[[[ORReadOutList alloc] initWithIdentifier:@"cPCI"]autorelease]];
    [readOutGroup loadUsingFile:aFile];
}
/*
- (void) dumpTriggerRAM:(int)aPageIndex
{
	
	//read page start address
	unsigned long lTimeL     = [self read: SLT_REG_ADDRESS(kSltLastTriggerTimeStamp) + aPageIndex];
	int iPageStart = (((lTimeL >> 10) & 0x7fe)  + 20) % 2000;
	
	unsigned long timeStampH = [self read: SLT_REG_ADDRESS(kSltPageTimeStamp) + 2*aPageIndex];
	unsigned long timeStampL = [self read: SLT_REG_ADDRESS(kSltPageTimeStamp) + 2*aPageIndex+1];
	
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:9];
	NSLogFont(aFont,@"Reading event from page %d, start=%d:  %ds %dx100us\n", 
			  aPageIndex+1, iPageStart, timeStampH, (timeStampL >> 11) & 0x3fff);
	
	//readout the SLT pixel trigger data
	unsigned long buffer[2000];
	unsigned long sltMemoryAddress = (SLTID << 24) | aPageIndex<<11;
	[self readBlock:sltMemoryAddress dataBuffer:(unsigned long*)buffer length:20*100 increment:1];
	unsigned long reorderBuffer[2000];
	// Re-organize trigger data to get it in a continous data stream
	unsigned long *pMult = reorderBuffer;
	memcpy( pMult, buffer + iPageStart, (2000 - iPageStart)*sizeof(unsigned long));  
	memcpy( pMult + 2000 - iPageStart, buffer, iPageStart*sizeof(unsigned long));  
	
	int i;
	int j;	
	int k;	
	
	// Dislay the matrix of triggered pixel and timing
	// The xy-Projection is needed to readout only the triggered pixel!!!
	unsigned long xyProj[20];
	unsigned long tyProj[100];
	for (i=0;i<20;i++) xyProj[i] = 0;
	for (k=0;k<100;k++) tyProj[k] = 0;
	for (k=0;k<2000;k++){
		xyProj[k%20] = xyProj[k%20] | (pMult[k] & 0x3fffff);
	}  
	for (k=0;k<2000;k++){
		if (xyProj[k%20]) {
			tyProj[k/20] = tyProj[k/20] | (pMult[k] & 0x3fffff);
		}
	}
	
	
	for(j=0;j<22;j++){
		NSMutableString* s = [NSMutableString stringWithFormat:@"%2d: ",j];
		//matrix of triggered pixel
		for(i=0;i<20;i++){
			if (((xyProj[i]>>j) & 0x1) == 0x1) [s appendFormat:@"X"];
			else							   [s appendFormat:@"."];
		}
		[s appendFormat:@"  "];
		
		// trigger timing
		for (k=0;k<100;k++){
			if (((tyProj[k]>>j) & 0x1) == 0x1 )[s appendFormat:@"="];
			else							   [s appendFormat:@"."];
		}
		NSLogFont(aFont, @"%@\n", s);
	}
	
	
	NSLogFont(aFont,@"\n");			
	
	
}
*/
- (void) autoCalibrate
{
	NSArray* allFLTs = [[self crate] orcaObjects];
	NSEnumerator* e = [allFLTs objectEnumerator];
	id aCard;
	while(aCard = [e nextObject]){
		if(![aCard isKindOfClass:NSClassFromString(@"ORIpeFireWireCard")]){  //remained from V3 ??? -tb-
			[aCard autoCalibrate];
		}
	}
}

- (void) tasksCompleted: (NSNotification*)aNote
{
	//nothing to do... this just removes a run-time exception
}

#pragma mark •••SBC_Linking protocol
- (NSString*) driverScriptName {return nil;} //no driver
- (NSString*) driverScriptInfo {return @"";}

- (NSString*) cpuName
{
	return [NSString stringWithFormat:@"IPE-DAQ-V4 EDELWEISS SLT Card (Crate %d)",[self crateNumber]];
}

- (NSString*) sbcLockName
{
	return OREdelweissSLTSettingsLock;
}

- (NSString*) sbcLocalCodePath
{
	return @"Source/Objects/Hardware/IPE/EdelweissSLT/EdelweissSLTv4_Readout_Code";
}

- (NSString*) codeResourcePath
{
	return [[self sbcLocalCodePath] lastPathComponent];
}


#pragma mark •••SBC Data Structure Setup
- (void) load_HW_Config
{
	int index = 0;
	SBC_crate_config configStruct;
	configStruct.total_cards = 0;
	[self load_HW_Config_Structure:&configStruct index:index];
	[pmcLink load_HW_Config:&configStruct];
}

- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id	= kSLTv4EW;	//should be unique
	configStruct->card_info[index].hw_mask[0] 	= eventDataId;
	configStruct->card_info[index].hw_mask[1] 	= multiplicityId;
	configStruct->card_info[index].slot			= [self stationNumber];
	configStruct->card_info[index].crate		= [self crateNumber];
	configStruct->card_info[index].add_mod		= 0;		//not needed for this HW
	
	configStruct->card_info[index].num_Trigger_Indexes = 1;	//Just 1 group of objects controlled by SLT
    int nextIndex = index+1;
    
	configStruct->card_info[index].next_Trigger_Index[0] = -1;
	for(id obj in dataTakers){
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
	configStruct->card_info[index].next_Card_Index 	= nextIndex;	
	return index+1;
}
@end

@implementation OREdelweissSLTModel (private)
- (unsigned long) read:(unsigned long) address
{
	if(![pmcLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	unsigned long theData;
	[pmcLink readLongBlockPmc:&theData
					  atAddress:address
					  numToRead: 1];
	return theData;
}

- (void) write:(unsigned long) address value:(unsigned long) aValue
{
	if(![pmcLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	[pmcLink writeLongBlockPmc:&aValue
					  atAddress:address
					 numToWrite:1];
}
@end

