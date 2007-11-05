/*
 *  ORCMC203Model.cpp
 *  Orca
 *
 *  Created by Mark Howe on Sat Nov 16 2002.
 *  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
 *
 */

#pragma mark ¥¥¥Imported Files
#import "ORCMC203Model.h"
#import "StatusLog.h"
#import "ORDataTypeAssigner.h"
#import "ORParamItem.h"
#import "ORDataDescriptionItem.h"
#import "ORHeaderSection.h"
#import "ORDataPacket.h"
#import "ORCamacControllerCard.h"
#import "ORCamacCrateModel.h"

NSString* ORCMC203ModelHistogramMaskChanged		= @"ORCMC203ModelHistogramMaskChanged";
NSString* ORCMC203ModelHistoBlockSizeChanged	= @"ORCMC203ModelHistoBlockSizeChanged";
NSString* ORCMC203ModelPingPongChanged			= @"ORCMC203ModelPingPongChanged";
NSString* ORCMC203ModelExtRenInputSigSelChanged = @"ORCMC203ModelExtRenInputSigSelChanged";
NSString* ORCMC203ModelEventTimeoutChanged		= @"ORCMC203ModelEventTimeoutChanged";
NSString* ORCMC203ModelOutputSelectionChanged	= @"ORCMC203ModelOutputSelectionChanged";
NSString* ORCMC203ModelLedAssigmentChanged		= @"ORCMC203ModelLedAssigmentChanged";
NSString* ORCMC203ModelVsnChanged				= @"ORCMC203ModelVsnChanged";
NSString* ORCMC203ModelBusyEndDelayChanged		= @"ORCMC203ModelBusyEndDelayChanged";
NSString* ORCMC203ModelGateTimeOutChanged		= @"ORCMC203ModelGateTimeOutChanged";
NSString* ORCMC203ModelMultiHistogramChanged	= @"ORCMC203ModelMultiHistogramChanged";
NSString* ORCMC203ModelHistogramControlChanged	= @"ORCMC203ModelHistogramControlChanged";
NSString* ORCMC203ModelFeraClrWidthChanged		= @"ORCMC203ModelFeraClrWidthChanged";
NSString* ORCMC203ModelTestGateWidthChanged		= @"ORCMC203ModelTestGateWidthChanged";
NSString* ORCMC203ModelDacValueChanged			= @"ORCMC203ModelDacValueChanged";
NSString* ORCMC203ModelReqDelayChanged			= @"ORCMC203ModelReqDelayChanged";
NSString* ORCMC203ModelControlRegChanged		= @"ORCMC203ModelControlRegChanged";
NSString* ORCMC203SettingsLock					= @"ORCMC203SettingsLock";

@implementation ORCMC203Model

#pragma mark ¥¥¥Initialization
- (id) init
{		
    self = [super init];
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"CMC203Card"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORCMC203Controller"];
}

#pragma mark ¥¥¥Accessors

- (unsigned short) histogramMask
{
    return histogramMask;
}

- (void) setHistogramMask:(unsigned short)aHistogramMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHistogramMask:histogramMask];
    
    histogramMask = aHistogramMask;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCMC203ModelHistogramMaskChanged object:self];
}

- (unsigned short) histoBlockSize
{
    return histoBlockSize;
}

- (void) setHistoBlockSize:(unsigned short)aHistoBlockSize
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHistoBlockSize:histoBlockSize];
    
    histoBlockSize = aHistoBlockSize;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCMC203ModelHistoBlockSizeChanged object:self];
}

- (unsigned short) pingPong
{
    return pingPong;
}

- (void) setPingPong:(unsigned short)aPingPong
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPingPong:pingPong];
    
    pingPong = aPingPong;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCMC203ModelPingPongChanged object:self];
}

- (unsigned short) extRenInputSigSel
{
    return extRenInputSigSel;
}

- (void) setExtRenInputSigSel:(unsigned short)aExtRenInputSigSel
{
    [[[self undoManager] prepareWithInvocationTarget:self] setExtRenInputSigSel:extRenInputSigSel];
    
    extRenInputSigSel = aExtRenInputSigSel;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCMC203ModelExtRenInputSigSelChanged object:self];
}

- (unsigned short) eventTimeout
{
    return eventTimeout;
}

- (void) setEventTimeout:(unsigned short)aEventTimeout
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEventTimeout:eventTimeout];
    
    eventTimeout = aEventTimeout;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCMC203ModelEventTimeoutChanged object:self];
}

- (unsigned short) outputSelection
{
    return outputSelection;
}

- (void) setOutputSelection:(unsigned short)aOutputSelection
{
    [[[self undoManager] prepareWithInvocationTarget:self] setOutputSelection:outputSelection];
    
    outputSelection = aOutputSelection;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCMC203ModelOutputSelectionChanged object:self];
}

- (unsigned short) ledAssigment
{
    return ledAssigment;
}

- (void) setLedAssigment:(unsigned short)aLedAssigment
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLedAssigment:ledAssigment];
    
    ledAssigment = aLedAssigment;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCMC203ModelLedAssigmentChanged object:self];
}

- (unsigned short) vsn
{
    return vsn;
}

- (void) setVsn:(unsigned short)aVsn
{
    [[[self undoManager] prepareWithInvocationTarget:self] setVsn:vsn];
    
    vsn = aVsn;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCMC203ModelVsnChanged object:self];
}

- (unsigned short) busyEndDelay
{
    return busyEndDelay;
}

- (void) setBusyEndDelay:(unsigned short)aBusyEndDelay
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBusyEndDelay:busyEndDelay];
    
    busyEndDelay = aBusyEndDelay;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCMC203ModelBusyEndDelayChanged object:self];
}

- (unsigned short) gateTimeOut
{
    return gateTimeOut;
}

- (void) setGateTimeOut:(unsigned short)aGateTimeOut
{
    [[[self undoManager] prepareWithInvocationTarget:self] setGateTimeOut:gateTimeOut];
    
    gateTimeOut = aGateTimeOut;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCMC203ModelGateTimeOutChanged object:self];
}

- (unsigned short) multiHistogram
{
    return multiHistogram;
}

- (void) setMultiHistogram:(unsigned short)aMultiHistogram
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMultiHistogram:multiHistogram];
    
    multiHistogram = aMultiHistogram;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCMC203ModelMultiHistogramChanged object:self];
}

- (unsigned short) histogramControl
{
    return histogramControl;
}

- (void) setHistogramControl:(unsigned short)aHistogramControl
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHistogramControl:histogramControl];
    
    histogramControl = aHistogramControl;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCMC203ModelHistogramControlChanged object:self];
}

- (unsigned short) feraClrWidth
{
    return feraClrWidth;
}

- (void) setFeraClrWidth:(unsigned short)aFeraClrWidth
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFeraClrWidth:feraClrWidth];
    
    feraClrWidth = aFeraClrWidth;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCMC203ModelFeraClrWidthChanged object:self];
}

- (unsigned short) testGateWidth
{
    return testGateWidth;
}

- (void) setTestGateWidth:(unsigned short)aTestGateWidth
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTestGateWidth:testGateWidth];
    
    testGateWidth = aTestGateWidth;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCMC203ModelTestGateWidthChanged object:self];
}

- (unsigned short) dacValue
{
    return dacValue;
}

- (void) setDacValue:(unsigned short)aDacValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDacValue:dacValue];
    
    dacValue = aDacValue;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCMC203ModelDacValueChanged object:self];
}

- (unsigned short) reqDelay
{
    return reqDelay;
}

- (void) setReqDelay:(unsigned short)aReqDelay
{
    [[[self undoManager] prepareWithInvocationTarget:self] setReqDelay:reqDelay];
    
    reqDelay = aReqDelay;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCMC203ModelReqDelayChanged object:self];
}

- (unsigned short) controlReg
{
    return controlReg;
}

- (void) setControlReg:(unsigned short)aControlReg
{
    [[[self undoManager] prepareWithInvocationTarget:self] setControlReg:controlReg];
    
    controlReg = aControlReg;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCMC203ModelControlRegChanged object:self];
}


- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}
#pragma mark ¥¥¥Hardware Access
- (void) loadHardware
{
	[self writeControlReg:controlReg];
	[self writeReqDelay:reqDelay];
	[self writeDacValue:dacValue];
	[self writeTestGateWidth:testGateWidth];
	[self writeFeraClrWidth:feraClrWidth];
	[self writeHistogramControl:histogramControl];
	[self writeHistogramBlockSize:histoBlockSize];
	[self writeMultiHistogram:multiHistogram];
	[self writeGateTimeOut:gateTimeOut];
	[self writeBusyEndDelay:busyEndDelay];
	[self writeVsn:vsn];
	[self writePingPong:pingPong];
	[self writeLedAssigment:ledAssigment];
	[self writeOuputSel:outputSelection];
	[self writeEventTimeOut:eventTimeout];
	[self writeExtRenInputSigSel:extRenInputSigSel];
	[self writeHistogramMask:histogramMask];
	[self writeHistogramSize:histogramMask+1];
}

- (void) readAndReport
{
	NSLog(@"-----CMC203 Station %d Report-----\n",[self stationNumber]);
	unsigned short aValue;
	aValue = [self readControlReg];
	NSLog(@"Control Register: 0x%04x\n",aValue);
	switch(aValue&0x7){
		case 0: NSLog(@"--4301 emulation mode.\n"); break;
		case 1: NSLog(@"--modified 4301, with 2k FIFO.\n"); break;
		case 2: NSLog(@"--modified 4301, with 2k FIFO, with external REN/PASS.\n"); break;
		case 3: NSLog(@"--1M FIFO mode, CAMAC readout.\n"); break;
		case 4: NSLog(@"--16 bit histograms.\n"); break;
		case 5: NSLog(@"--32 bit histograms.\n"); break;
		default: NSLog(@"--undefined state.\n");
	}
	if(aValue & 0x8)NSLog(@"--Pass mode ends REN only when PASS input (PSI input on front panel) is received.\n");
	else			NSLog(@"--Normal REN (Readout Enable, REO output on front panel) mode ends REN when REQ input ends.\n");
	if(aValue & 0x10)NSLog(@"--Send CLEAR when radout is complete. Event ends when REQ ends, PASS(PSI) returns, or when gate timeout ends (if no REQ).\n");
	else			NSLog(@"--CLEAR not automatically sent at end of readout.\n");
	if(aValue & 0x20)NSLog(@"--WST ignored unless REO is asserted (event readout in progress)), and WST is deglitched (WST must be >10ns long).\n");
	else			NSLog(@"--WST always detected, regardless of GATE, REQ or REO.\n");
	if(aValue & 0x40)NSLog(@"--BUSY is also asserted when the FIFO count is grater than 7/8 of full. Busy stays on until the FIFO count drops below 1/2 of full.\n");
	else			NSLog(@"--Normal. BUSY is asserted during readout, when FIFO is full, and when the module is disabled.\n");
	if(aValue & 0x80)NSLog(@"--End BUSY after end of CLEAR. If end-of-busy delay reg is non-zero, also wait until end of delay.\n");
	else			NSLog(@"--End BUSY when Readout Enable (REO) arrives.\n");
	if(aValue & 0x100)NSLog(@"--No insertion of diagnostic gate header into data stream.\n");
	else			NSLog(@"--Insert gate header wen GATE is detected.\n");
	if(aValue & 0x200)NSLog(@"--No insertion of clear header into data stream.\n");
	else			NSLog(@"--Insert Clear header at beginning of CLEAR.\n");

	aValue = [self readReqDelay];
	NSLog(@"Request Delay Register: 0x%04x\n",aValue);
	if(aValue==0)NSLog(@"--value is defaulted to 400ns\n");
	else NSLog(@"--converted value = %dnS\n",aValue*40); 
	
	aValue = [self readDacValue];
	NSLog(@"DAC Register: %.4fV\n",aValue*10.2375/4095.);
	
	aValue = [self readTestGateWidth];
	NSLog(@"Test Gate Width Register: 0x%04x\n",aValue);
	NSLog(@"--converted value = %dnS\n",aValue*10); 
	
	aValue = [self readFeraClrWidth];
	NSLog(@"FERA Clear Width Register: 0x%04x\n",aValue);
	if(aValue==0)NSLog(@"--value is defaulted to 200ns\n");
	else NSLog(@"--converted value = %dnS\n",aValue*40);
	 
	aValue = [self readHistogramControl];
	NSLog(@"Histogram Control Register: 0x%04x\n",aValue);
	switch(aValue){
		case 0: NSLog(@"--Employs the entire 1MB memory to histogram data from ADCs in the zero-suppressed mode, with memory allocation determined by the SN and sub-address.\n"); break;
		case 1: NSLog(@"--Records a time-sequed of histograms for each sub-address of one ADC module, Requres zer-suppressed mode..\n"); break;
		case 2: NSLog(@"--Histograms spectra from multiple ADCs and sub-addresses according to readout sequence when the aCS are in the non-zero-supporessed readout mode.\n"); break;
		default: NSLog(@"--undefined state.\n");
	}
	
	aValue = [self readHistogramBlockSize];
	NSLog(@"Histogram Readout Block Size Register: 0x%04x\n",aValue);
	
	aValue = [self readMultiHistogram];
	NSLog(@"Multi Histogram Register: 0x%04x\n",aValue);

	aValue = [self readHistogramMask];
	NSLog(@"Histogram Mask Register: 0x%08x\n",aValue);
	
	aValue = [self readHistogramSize];
	NSLog(@"Histogram Size Register: 0x%08x\n",aValue);

	aValue = [self readGateTimeOut];
	NSLog(@"Gate Time-Out Register: 0x%04x\n",aValue);
	if(aValue==0)NSLog(@"--Function is disabled\n");
	else NSLog(@"--converted value = %dnS\n",aValue*40);
	
	aValue = [self readBusyEndDelay];
	NSLog(@"Busy End-Delay Register: 0x%04x\n",aValue);
	NSLog(@"--converted value = %dnS\n",aValue*40);
	
	aValue = [self readVsn];
	NSLog(@"VSN Register: 0x%04x\n",aValue);
	
	aValue = [self readPingPong];
	NSLog(@"Ping-Pong Interval Register: 0x%04x\n",aValue);
	NSLog(@"--converted value = %dnS\n",aValue*40);
	
	aValue = [self readLedAssigment];
	NSLog(@"LED Assignment Register: 0x%04x\n",aValue);
	
	aValue = [self readOuputSel];
	NSLog(@"External Output Selection Register: 0x%04x\n",aValue);
	
	aValue = [self readEventTimeOut];
	NSLog(@"Event Time-Out Register: 0x%04x\n",aValue);
	if(aValue==0)NSLog(@"--Function is disabled\n");
	else NSLog(@"--converted value = %dnS\n",aValue*640);
	
	aValue = [self readExtRenInputSigSel];
	NSLog(@"Extern REN (EXTREN) Input Signal Select Register: 0x%04x\n",aValue);
	switch(aValue){
		case 0: NSLog(@"--ecl CLR\n"); break;
		case 2: NSLog(@"--ecl readinh (RINH)\n"); break;
		case 4: NSLog(@"--ecl WAK\n"); break;
		case 8: NSLog(@"--ecl PSI\n"); break;
		case 16: NSLog(@"--nim CLR (C)\n"); break;
		case 32: NSLog(@"--nim readinh (I)\n"); break;
		case 64: NSLog(@"--nim wak (A)\n"); break;
		default: NSLog(@"--undefined state.\n");
	}
}

- (void) writeControlReg:(unsigned short)aValue
{
    [[self adapter] camacShortNAF:[self stationNumber] a:1 f:16 data:&aValue];
}
- (unsigned short) readControlReg
{
	unsigned short aValue = 0;
    [[self adapter] camacShortNAF:[self stationNumber] a:1 f:0 data:&aValue];
	return aValue;
}
- (void) writeReqDelay:(unsigned short)aValue
{
    [[self adapter] camacShortNAF:[self stationNumber] a:2 f:16 data:&aValue];
}
- (unsigned short) readReqDelay
{
	unsigned short aValue = 0;
    [[self adapter] camacShortNAF:[self stationNumber] a:2 f:0 data:&aValue];
	return aValue;
}
- (void) writeDacValue:(unsigned short)aValue
{
    [[self adapter] camacShortNAF:[self stationNumber] a:0 f:16 data:&aValue];
}
- (unsigned short) readDacValue
{
	unsigned short aValue = 0;
    [[self adapter] camacShortNAF:[self stationNumber] a:0 f:0 data:&aValue];
	return aValue;
}
- (void) writeTestGateWidth:(unsigned short)aValue
{
    [[self adapter] camacShortNAF:[self stationNumber] a:3 f:16 data:&aValue];
}
- (unsigned short) readTestGateWidth
{
	unsigned short aValue = 0;
    [[self adapter] camacShortNAF:[self stationNumber] a:3 f:0 data:&aValue];
	return aValue;
}
- (void) writeFeraClrWidth:(unsigned short)aValue
{
    [[self adapter] camacShortNAF:[self stationNumber] a:4 f:16 data:&aValue];
}
- (unsigned short) readFeraClrWidth
{
	unsigned short aValue = 0;
    [[self adapter] camacShortNAF:[self stationNumber] a:4 f:0 data:&aValue];
	return aValue;
}

- (void) writeHistogramControl:(unsigned short)aValue
{
    [[self adapter] camacShortNAF:[self stationNumber] a:3 f:17 data:&aValue];
}
- (unsigned short) readHistogramControl
{
	unsigned short aValue = 0;
    [[self adapter] camacShortNAF:[self stationNumber] a:3 f:1 data:&aValue];
	return aValue;
}

- (void) writeHistogramBlockSize:(unsigned short)aValue
{
    [[self adapter] camacShortNAF:[self stationNumber] a:5 f:16 data:&aValue];
}
- (unsigned short) readHistogramBlockSize
{
	unsigned short aValue = 0;
    [[self adapter] camacShortNAF:[self stationNumber] a:5 f:0 data:&aValue];
	return aValue;
}

- (void) writeMultiHistogram:(unsigned short)aValue
{
    [[self adapter] camacShortNAF:[self stationNumber] a:6 f:16 data:&aValue];
}
- (unsigned short) readMultiHistogram
{
	unsigned short aValue = 0;
    [[self adapter] camacShortNAF:[self stationNumber] a:6 f:0 data:&aValue];
	return aValue;
}

- (void) writeGateTimeOut:(unsigned short)aValue
{
    [[self adapter] camacShortNAF:[self stationNumber] a:7 f:16 data:&aValue];
}
- (unsigned short) readGateTimeOut
{
	unsigned short aValue = 0;
    [[self adapter] camacShortNAF:[self stationNumber] a:7 f:0 data:&aValue];
	return aValue;
}

- (void) writeBusyEndDelay:(unsigned short)aValue
{
    [[self adapter] camacShortNAF:[self stationNumber] a:8 f:16 data:&aValue];
}
- (unsigned short) readBusyEndDelay
{
	unsigned short aValue = 0;
    [[self adapter] camacShortNAF:[self stationNumber] a:8 f:0 data:&aValue];
	return aValue;
}

- (void) writeVsn:(unsigned short)aValue
{
    [[self adapter] camacShortNAF:[self stationNumber] a:9 f:16 data:&aValue];
}
- (unsigned short) readVsn
{
	unsigned short aValue = 0;
    [[self adapter] camacShortNAF:[self stationNumber] a:9 f:0 data:&aValue];
	return aValue;
}

- (void) writePingPong:(unsigned short)aValue
{
    [[self adapter] camacShortNAF:[self stationNumber] a:11 f:16 data:&aValue];
}
- (unsigned short) readPingPong
{
	unsigned short aValue = 0;
    [[self adapter] camacShortNAF:[self stationNumber] a:11 f:0 data:&aValue];
	return aValue;
}

- (void) writeLedAssigment:(unsigned short)aValue
{
    [[self adapter] camacShortNAF:[self stationNumber] a:12 f:16 data:&aValue];
}
- (unsigned short) readLedAssigment
{
	unsigned short aValue = 0;
    [[self adapter] camacShortNAF:[self stationNumber] a:12 f:0 data:&aValue];
	return aValue;
}

- (void) writeOuputSel:(unsigned short)aValue
{
    [[self adapter] camacShortNAF:[self stationNumber] a:13 f:16 data:&aValue];
}
- (unsigned short) readOuputSel
{
	unsigned short aValue = 0;
    [[self adapter] camacShortNAF:[self stationNumber] a:13 f:0 data:&aValue];
	return aValue;
}

- (void) writeEventTimeOut:(unsigned short)aValue
{
    [[self adapter] camacShortNAF:[self stationNumber] a:14 f:16 data:&aValue];
}
- (unsigned short) readEventTimeOut
{
	unsigned short aValue = 0;
    [[self adapter] camacShortNAF:[self stationNumber] a:14 f:0 data:&aValue];
	return aValue;
}

- (void) writeExtRenInputSigSel:(unsigned short)aValue
{
    [[self adapter] camacShortNAF:[self stationNumber] a:15 f:16 data:&aValue];
}
- (unsigned short) readExtRenInputSigSel
{
	unsigned short aValue = 0;
    [[self adapter] camacShortNAF:[self stationNumber] a:15 f:0 data:&aValue];
	return aValue;
}

- (void) writeHistogramMask:(unsigned short)aValue
{
    [[self adapter] camacShortNAF:[self stationNumber] a:4 f:17 data:&aValue];
}
- (unsigned short) readHistogramMask
{
	unsigned short aValue = 0;
    [[self adapter] camacShortNAF:[self stationNumber] a:4 f:1 data:&aValue];
	return aValue;
}

- (void) writeHistogramSize:(unsigned short)aValue
{
    [[self adapter] camacShortNAF:[self stationNumber] a:5 f:17 data:&aValue];
}
- (unsigned short) readHistogramSize
{
	unsigned short aValue = 0;
    [[self adapter] camacShortNAF:[self stationNumber] a:5 f:1 data:&aValue];
	return aValue;
}


#pragma mark ¥¥¥DataTaker

- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kShortForm]; //short form preferred
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
}

- (void) reset
{
	//[self initBoard];    
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORCMC203DecoderForAdc",                        @"decoder",
        [NSNumber numberWithLong:dataId],               @"dataId",
        [NSNumber numberWithBool:NO],                   @"variable",
        [NSNumber numberWithLong:IsShortForm(dataId)?1:2],@"length",
        [NSNumber numberWithBool:YES],                  @"canBeGated",
        nil];
    [dataDictionary setObject:aDictionary forKey:@"ADC"];
    return dataDictionary;
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	
    if(![self adapter]){
		[NSException raise:@"Not Connected" format:@"You must connect to a PCI-CAMAC Controller (i.e. a CC32)."];
    }
	
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORCMC203Model"];    
    
    //----------------------------------------------------------------------------------------
    controller = [[self adapter] controller]; //cache the controller for alittle bit more speed.
    unChangingDataPart   = (([self crateNumber]&0xf)<<21) | (([self stationNumber]& 0x0000001f)<<16); //doesn't change so do it here.
	cachedStation = [self stationNumber];
    [self clearExceptionCount];
        
    if([[userInfo objectForKey:@"doinit"]intValue]){
		[self loadHardware];
    }
}

//**************************************************************************************
// Function:	TakeData
// Description: Read data from a card
//**************************************************************************************

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    NSString* errorLocation;
    NS_DURING
        
  /*      //check the LAM
        unsigned short dummy;
        unsigned short status = [controller camacShortNAF:cachedStation a:12 f:8 data:&dummy];
        if(isQbitSet(status)) { //LAM status comes back in the Q bit
			resetDone = NO;
			int i;
			for(i=0;i<onlineChannelCount;i++){
				//read one adc channnel
				unsigned short adcValue;
				[controller camacShortNAF:cachedStation a:onlineList[i] f:2 data:&adcValue];
				if(!(suppressZeros && adcValue==0)){
					if(IsShortForm(dataId)){
						unsigned long data = dataId | unChangingDataPart | (onlineList[i]&0xf)<<12 | (adcValue & 0xfff);
						[aDataPacket addLongsToFrameBuffer:&data length:1];
					}
					else {
						unsigned long data[2];
						data[0] =  dataId | 2;
						data[1] =  unChangingDataPart | (onlineList[i]&0xf)<<12 | (adcValue & 0xfff);
						[aDataPacket addLongsToFrameBuffer:data length:2];
					}
				}
				if(i == 7) resetDone = YES;
				
			}
			//read of last channel with this command clears
			if(!resetDone) [controller camacShortNAF:[self stationNumber] a:7 f:2 data:&dummy]; 
            
  		}*/
		NS_HANDLER
			NSLogError(@"",@"CMC203 Card Error",errorLocation,nil);
			[self incExceptionCount];
			[localException raise];
		NS_ENDHANDLER
}


- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
}

#pragma mark ¥¥¥Archival

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
    [self setHistogramMask:[decoder decodeIntForKey:@"ORCMC203ModelHistogramMask"]];
    [self setHistoBlockSize:[decoder decodeIntForKey:@"ORCMC203ModelHistoBlockSize"]];
    [self setPingPong:[decoder decodeIntForKey:@"ORCMC203ModelPingPong"]];
    [self setExtRenInputSigSel:[decoder decodeIntForKey:@"ORCMC203ModelExtRenInputSigSel"]];
    [self setEventTimeout:[decoder decodeIntForKey:@"ORCMC203ModelEventTimeout"]];
    [self setOutputSelection:[decoder decodeIntForKey:@"ORCMC203ModelOutputSelection"]];
    [self setLedAssigment:[decoder decodeIntForKey:@"ORCMC203ModelLedAssigment"]];
    [self setVsn:[decoder decodeIntForKey:@"ORCMC203ModelVsn"]];
    [self setBusyEndDelay:[decoder decodeIntForKey:@"ORCMC203ModelBusyEndDelay"]];
    [self setGateTimeOut:[decoder decodeIntForKey:@"ORCMC203ModelGateTimeOut"]];
    [self setMultiHistogram:[decoder decodeIntForKey:@"ORCMC203ModelMultiHistogram"]];
    [self setMultiHistogram:[decoder decodeIntForKey:@"ORCMC203ModelMultiHistogram"]];
    [self setHistogramControl:[decoder decodeIntForKey:@"ORCMC203ModelHistogramControl"]];
    [self setFeraClrWidth:[decoder decodeIntForKey:@"ORCMC203ModelFeraClrWidth"]];
    [self setTestGateWidth:[decoder decodeIntForKey:@"ORCMC203ModelTestGateWidth"]];
    [self setDacValue:[decoder decodeIntForKey:@"ORCMC203ModelDacValue"]];
    [self setReqDelay:[decoder decodeIntForKey:@"ORCMC203ModelReqDelay"]];
    [self setControlReg:[decoder decodeIntForKey:@"ORCMC203ModelControlReg"]];
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:histogramMask forKey:@"ORCMC203ModelHistogramMask"];
    [encoder encodeInt:histoBlockSize forKey:@"ORCMC203ModelHistoBlockSize"];
    [encoder encodeInt:pingPong forKey:@"ORCMC203ModelPingPong"];
    [encoder encodeInt:extRenInputSigSel forKey:@"ORCMC203ModelExtRenInputSigSel"];
    [encoder encodeInt:eventTimeout forKey:@"ORCMC203ModelEventTimeout"];
    [encoder encodeInt:outputSelection forKey:@"ORCMC203ModelOutputSelection"];
    [encoder encodeInt:ledAssigment forKey:@"ORCMC203ModelLedAssigment"];
    [encoder encodeInt:vsn forKey:@"ORCMC203ModelVsn"];
    [encoder encodeInt:busyEndDelay forKey:@"ORCMC203ModelBusyEndDelay"];
    [encoder encodeInt:gateTimeOut forKey:@"ORCMC203ModelGateTimeOut"];
    [encoder encodeInt:multiHistogram forKey:@"ORCMC203ModelMultiHistogram"];
    [encoder encodeInt:multiHistogram forKey:@"ORCMC203ModelMultiHistogram"];
    [encoder encodeInt:histogramControl forKey:@"ORCMC203ModelHistogramControl"];
    [encoder encodeInt:feraClrWidth forKey:@"ORCMC203ModelFeraClrWidth"];
    [encoder encodeInt:testGateWidth forKey:@"ORCMC203ModelTestGateWidth"];
    [encoder encodeInt:dacValue forKey:@"ORCMC203ModelDacValue"];
    [encoder encodeInt:reqDelay forKey:@"ORCMC203ModelReqDelay"];
    [encoder encodeInt:controlReg forKey:@"ORCMC203ModelControlReg"];
	
}


- (NSMutableDictionary*) captureCurrentState:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super captureCurrentState:dictionary];
    [objDictionary setObject:[NSNumber numberWithInt:controlReg] forKey:@"ORCMC203ModelControlReg"];
    return objDictionary;
}

@end