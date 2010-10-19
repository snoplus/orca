//
//  ORSNOCrateModel.m
//  Orca
//
//  Created by Mark Howe on Tue, Apr 30, 2008.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORSNOCrateModel.h"
#import "ORSNOCard.h"
#import "ORSNOConstants.h"
#import "ORXL1Model.h"
#import "ORXL2Model.h"
#import "ORXL3Model.h"
#import "ORFec32Model.h"
#import "ObjectFactory.h"
#import "OROrderedObjManager.h"
#import "ORSelectorSequence.h"
#import "SBC_Link.h"
#import "VME_HW_Definitions.h"
#import "ORDataTypeAssigner.h"


const struct {
	unsigned long Register;	//XL2
	unsigned long Memory;	//XL2
	NSString* IPAddress;	//XL3
	unsigned long Port;	//XL3
} kSnoCrateBaseAddress[]={
{0x00002800, 	0x01400000,	@"10.0.0.1",	6001},	//0
{0x00003000,	0x01800000,	@"10.0.0.2",	6002},	//1
{0x00003800,	0x01c00000,	@"10.0.0.3",	6003},	//2
{0x00004000,	0x02000000,	@"10.0.0.4",	6004},	//3
{0x00004800,	0x02400000,	@"10.0.0.5",	6005},	//4
{0x00005000,	0x02800000,	@"10.0.0.6",	6006},	//5
{0x00005800,	0x02c00000,	@"10.0.0.7",	6007},	//6
{0x00006000,	0x03000000,	@"10.0.0.8",	6008},	//7
{0x00006800,	0x03400000,	@"10.0.0.9",	6009},	//8
{0x00007800,	0x03C00000,	@"10.0.0.10",	6010},	//9
{0x00008000,	0x04000000,	@"10.0.0.11",	6011},	//10
{0x00008800,	0x04400000,	@"10.0.0.12",	6012},	//11
{0x00009000,	0x04800000,	@"10.0.0.13",	6013},	//12
{0x00009800,	0x04C00000,	@"10.0.0.14",	6014},	//13
{0x0000a000,	0x05000000,	@"10.0.0.15",	6015},	//14
{0x0000a800,	0x05400000,	@"10.0.0.16",	6016},	//15
{0x0000b000,	0x05800000,	@"10.0.0.17",	6017},	//16
{0x0000b800,	0x05C00000,	@"10.0.0.18",	6018},	//17
{0x0000c000,	0x06000000,	@"10.0.0.19",	6019},	//18
//{0x0000c800,	0x06400000}	//crate 19 is really at 0xd000
{0x0000d000,	0x06800000,	@"10.0.0.20",	6020}	//19
};


NSString* ORSNOCrateSlotChanged = @"ORSNOCrateSlotChanged";

@interface ORSNOCrateModel (XL2)
- (id) xl2;
- (void) initCrateUsingXL2:(BOOL) loadTheFEC32XilinxFile phase:(int) phase;
- (void) loadXilinx;
- (void) loadClocks;
- (void) initFec32Cards;
- (void) initCTCDelays;
@end

@interface ORSNOCrateModel (XL3)
- (void) initCrateUsingXL3:(BOOL) loadTheFEC32XilinxFile phase:(int) phase;
@end


@implementation ORSNOCrateModel

#pragma mark •••initialization
- (void) makeConnectors
{	
}

- (void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so that each crate can have its own version for drawing into.
    //---------------------------------------------------------------------------------------------------
    NSImage* aCachedImage = [NSImage imageNamed:@"SNOCrate"];
    NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
    [i lockFocus];
    [aCachedImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
    if(powerOff){
        NSAttributedString* s = [[[NSAttributedString alloc] initWithString:@"No Pwr"
			attributes:[NSDictionary dictionaryWithObjectsAndKeys:
			[NSColor redColor],NSForegroundColorAttributeName,
			[NSFont fontWithName:@"Geneva" size:10],NSFontAttributeName,nil]] autorelease]; 
	[s drawAtPoint:NSMakePoint(25,5)];
    }
    
    if([[self orcaObjects] count]){
        NSAffineTransform* transform = [NSAffineTransform transform];
        [transform translateXBy:5 yBy:13];
        [transform scaleXBy:.39 yBy:.44];
        [transform concat];
        NSEnumerator* e  = [[self orcaObjects] objectEnumerator];
        OrcaObject* anObject;
        while(anObject = [e nextObject]){
            BOOL oldHighlightState = [anObject highlighted];
            [anObject setHighlighted:NO];
            [anObject drawSelf:NSMakeRect(0,0,500,[[self image] size].height)];
            [anObject setHighlighted:oldHighlightState];
        }
    }
    [i unlockFocus];
    [self setImage:i];
    [i release];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:OROrcaObjectImageChanged
	 object:self];
	
}

- (void) makeMainController
{
    [self linkToController:@"ORSNOCrateController"];
}

- (void) connected
{
	[[self orcaObjects] makeObjectsPerformSelector:@selector(connected)];
}

- (void) disconnected
{
	[[self orcaObjects] makeObjectsPerformSelector:@selector(disconnected)];
}

- (BOOL) acceptsGuardian: (OrcaObject *)aGuardian
{
    return [aGuardian isKindOfClass:[self guardianClass]];	
}

- (Class) guardianClass 
{
	return NSClassFromString(@"ORSNORackModel");
}

- (void) setSlot:(int)aSlot
{
	slot = aSlot;
	NSEnumerator* e  = [[self orcaObjects] objectEnumerator];
    id anObject;
    while(anObject = [e nextObject]){
		[anObject guardian:self positionConnectorsForCard:anObject];
    }
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORSNOCrateSlotChanged
	 object:self];
}

- (int) slot
{
	return slot;
}

- (eFecMonitorState) voltageStatus
{
	return voltageStatus;
}

- (BOOL) autoInit
{
	return autoInit;
}

- (void) setAutoInit:(BOOL)anAutoInit
{
	autoInit = anAutoInit;
}
	
- (void) setVoltageStatus:(eFecMonitorState)aState
{
	voltageStatus = aState;
}

#pragma mark •••Accessors
- (unsigned long) memoryBaseAddress
{
	int index =  [self crateNumber];
	if(index>=0 && index<=kMaxSNOCrates) return kSnoCrateBaseAddress[index].Memory;
	else {
		[[NSException exceptionWithName:@"SNO Crate" reason:@"SNO Crate Index out of bounds" userInfo:nil] raise];
		return 0; //to get rid of compiler warning, can't really get here
	}
}

- (unsigned long) registerBaseAddress
{
	int index =  [self crateNumber];
	if(index>=0 && index<=kMaxSNOCrates) return kSnoCrateBaseAddress[index].Register;
	else {
		[[NSException exceptionWithName:@"SNO Crate" reason:@"SNO Crate Index out of bounds" userInfo:nil] raise];
		return 0; //to get rid of compiler warning, can't really get here
	}
}

- (NSString*) iPAddress
{
	int index =  [self crateNumber];
	if(index>=0 && index<=kMaxSNOCrates) return kSnoCrateBaseAddress[index].IPAddress;
	else {
		[[NSException exceptionWithName:@"SNO Crate" reason:@"SNO Crate Index out of bounds" userInfo:nil] raise];
		return 0; //to get rid of compiler warning, can't really get here
	}
}

- (unsigned long) portNumber
{
	int index =  [self crateNumber];
	if(index>=0 && index<=kMaxSNOCrates) return kSnoCrateBaseAddress[index].Port;
	else {
		[[NSException exceptionWithName:@"SNO Crate" reason:@"SNO Crate Index out of bounds" userInfo:nil] raise];
		return 0; //to get rid of compiler warning, can't really get here
	}
}

- (void) assumeDisplayOf:(ORConnector*)aConnector
{
    [guardian assumeDisplayOf:aConnector];
}

- (void) removeDisplayOf:(ORConnector*)aConnector
{
    [guardian removeDisplayOf:aConnector];
}


- (void) setGuardian:(id)aGuardian
{
    id oldGuardian = guardian;
    [super setGuardian:aGuardian];
    
    NSEnumerator* e  = [[self orcaObjects] objectEnumerator];
    id anObject;
    while(anObject = [e nextObject]){
        if(aGuardian == nil){
            [anObject guardianRemovingDisplayOfConnectors:oldGuardian ];
        }
        [anObject guardianAssumingDisplayOfConnectors:aGuardian];
        if(aGuardian != nil){
            [anObject guardian:self positionConnectorsForCard:anObject];
        }
    }
}

- (void) positionConnector:(ORConnector*)aConnector forCard:(id)aCard
{
	NSRect aFrame = [aConnector localFrame];
    float x =  7+[aCard slot] * 17 * .285 ;
    float y = 40 + [self slot] * [self frame].size.height +  ([self slot]*17);
	if([aConnector ioType] == kOutputConnector)y += 35;
    aFrame.origin = NSMakePoint(x,y);
    [aConnector setLocalFrame:aFrame];
}


#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
	[super registerNotificationObservers];
	
    [notifyCenter addObserver : self
                     selector : @selector(viewChanged:)
                         name : ORSNOCardSlotChanged
                       object : nil];
	
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"SNO Crate %d",[self crateNumber]];
}


#pragma mark •••HW Access

- (void) scanWorkingSlot
{
	pauseWork = NO;
	BOOL adapterOK = YES;
	@try {
		[[self adapter] selectCards:1L<<[self stationForSlot:workingSlot]];	
	}
	@catch(NSException* localException) {
		adapterOK = NO;
		NSLog(@"Unable to reach XL2/3 in crate: %d (Not inited?)\n",[self crateNumber]);
	}
	if(!adapterOK)working = NO;
	if(working){
		@try {
			
			ORFec32Model* proxyFec32 = [ObjectFactory makeObject:@"ORFec32Model"];
			[proxyFec32 setGuardian:self];
			
			NSString* boardID = [proxyFec32 performBoardIDRead:MC_BOARD_ID_INDEX];
			if(![boardID isEqual: @"0000"] && ![boardID isEqual: @"0000"]){
				NSLog(@"Crate %2d Fec %2d BoardID: %@\n",[self crateNumber],[self stationForSlot:workingSlot],boardID);
				ORFec32Model* theCard = [[OROrderedObjManager for:self] objectInSlot:workingSlot];
				if(!theCard){
					[self addObjects:[NSArray arrayWithObject:proxyFec32]];
					[self place:proxyFec32 intoSlot:workingSlot];
					theCard = proxyFec32;
				}
				pauseWork = YES;
				[theCard setBoardID:boardID];
				[theCard scan:@selector(scanWorkingSlot)];
				workingSlot--;
				//if (workingSlot == 0) working = NO;
			}
			else {
				NSLog(@"Crate %2d Fec %2d BoardID: %@\n",[self crateNumber],[self stationForSlot:workingSlot],boardID);
				ORFec32Model* theCard = [[OROrderedObjManager for:self] objectInSlot:workingSlot];
				if(theCard)[self removeObject:theCard];
			}
		}
		@catch(NSException* localException) {
			NSLog(@"Crate %2d Fec %2d BoardID: -----\n",[self crateNumber],[self stationForSlot:workingSlot]);
			ORFec32Model* theCard = [[OROrderedObjManager for:self] objectInSlot:workingSlot];
			if(theCard)[self removeObject:theCard];
		}
	}
	if(!pauseWork){
		workingSlot--;
		if(working && (workingSlot>0)){
			[self performSelector:@selector(scanWorkingSlot)withObject:nil afterDelay:0];
		}	
		else {
			[[self adapter] deselectCards];
		}
	}
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
	[[self undoManager] disableUndoRegistration];
    
    [self setSlot:[decoder decodeIntForKey:@"slot"]];
	[[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	[encoder encodeInt:[self slot] forKey:@"slot"];
}
- (short) numberSlotsUsed
{
	return 1;
}


- (BOOL) adapterIsXL3
{
	return [[self adapter] isKindOfClass:NSClassFromString(@"ORXL3Model")];
}

- (void) initCrate:(BOOL) loadTheFEC32XilinxFile phase:(int) phase
{
	if([self adapterIsXL3])	[self initCrateUsingXL3:loadTheFEC32XilinxFile phase:phase];
	else			[self initCrateUsingXL2:loadTheFEC32XilinxFile phase:phase];
}

- (void) initCrateDone
{
	NSLog(@"Initialization of the crate %d done.\n", [self crateNumber]);
}

//get ready for the XL3 card
- (void) resetCrate
{
	[[self adapter] reset];
}


#pragma mark •••Data Taker
- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
	dataId = DataId;
}

// todo: add cmos data id
- (void) setDataIds:(id)assigner
{
	dataId = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherSNOCrate
{
	[self setDataId:[anotherSNOCrate dataId]];
}

- (NSDictionary*) dataRecordDescription
{
	NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
	NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				     @"ORSNOCrateDecoderForPMT",	@"decoder",
				     [NSNumber numberWithLong:dataId],	@"dataId",
				     [NSNumber numberWithBool:NO],	@"variable",
				     [NSNumber numberWithLong:4],	@"length",  //modified kLong header
				     nil];
	[dataDictionary setObject:aDictionary forKey:@"PMT"];
	
	return dataDictionary;
}

- (void) reset
{
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
/*
	if(![[self adapter] controllerCard]){
		[NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
	}
*/	
	[aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORSNOCrateModel"];	
}

// XL3 only
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	
	//never called, data come from an SBC at VME_Readout_Code/ORSNOCrateReadout.cc
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	//stop cmos rate if ecal
}

//XL2 only
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id		= kSnoCrate;		//should be unique 
	configStruct->card_info[index].hw_mask[0]		= dataId;		//better be unique
	configStruct->card_info[index].slot			= [self slot];
	configStruct->card_info[index].add_mod			= 0x29UL;
	configStruct->card_info[index].base_add			= [self registerBaseAddress];
	
	configStruct->card_info[index].deviceSpecificData[0] = [self memoryBaseAddress];
	configStruct->card_info[index].deviceSpecificData[1] = 0x09UL;
	configStruct->card_info[index].deviceSpecificData[2] = [[self xl2] xl2RegAddress:XL2_DATA_AVAILABLE_REG];
	configStruct->card_info[index].deviceSpecificData[3] = [self registerBaseAddress] + FEC32_FIFO_POINTER_DIFF_REG;

	configStruct->card_info[index].num_Trigger_Indexes = 0; //no children
	configStruct->card_info[index].next_Card_Index = index + 1;
	
	return index + 1;	
}
@end

@implementation ORSNOCrateModel (OROrderedObjHolding)
- (int) maxNumberOfObjects
{
    return kNumSNOCrateSlots;
}

- (int) objWidth
{
    return 12;
}

- (int) stationForSlot:(int)aSlot
{
	return 16-aSlot;
}

- (NSRange) legalSlotsForObj:(id)anObj
{
	if( [anObj isKindOfClass:NSClassFromString(@"ORXL2Model")]){
		return NSMakeRange(17,1);
	}
	else if( [anObj isKindOfClass:NSClassFromString(@"ORXL3Model")]){
		return NSMakeRange(17,1);
	}	
	else {
		return  NSMakeRange(1,[self maxNumberOfObjects]-2);
	}
}


@end


@implementation ORSNOCrateModel (XL2)
- (id) xl2
{
	return [self adapter];
}

- (void) initCrateUsingXL2:(BOOL) loadTheFEC32XilinxFile phase:(int) phase
{
	
	//don't proceed to load the XilinX if this crate is supplying high voltage!
	//MAH TBC implement this check somehow
	//			if( theHVStatus.IsThisSNOCrateSupplyingHV(its_SC_Number) ) {
	//				SetStatustoWarningStyle();
	//				StatusPrintf("Can not load Xilinx on crate %d",its_SC_Number);
	//				StatusPrintf("As the crate is supplying HV!!");
	//				StatusPrintf("Xilinx load skipped for crate %d",its_SC_Number);
	//				RestoreStatusStyle();
	//			}
	
	@try {
		if (phase == 0) {
			NSLog(@"Starting crate %d init process: (load Xilinx: %@) (autoInit: %@)\n", [self crateNumber], loadTheFEC32XilinxFile?@"YES":@"NO", autoInit?@"YES":@"NO");
			
			[self resetCrate];
			[self loadClocks];
			
			// don't load the Xilinx if this crate is supplying voltage
			if (loadTheFEC32XilinxFile) {
				[self loadXilinx];
				if(![[self xl2] adapterIsSBC]) phase = 1;
			}
			else phase = 1;
		}
		
		if (phase == 1) {
			[self initFec32Cards];
			[self initCTCDelays];
			[self initCrateDone];
		}
	}
	@catch(NSException* localException) {		
		NSLog(@"***Initialization of the crate %d (%@ Xilinx, %@ autoInit) failed!***\n", 
		      [self crateNumber], loadTheFEC32XilinxFile?@"with":@"no", autoInit?@"with":@"no");
		NSLog(@"Exception: %@\n",localException);
		[localException raise];		
	}
}

- (void) loadXilinx
{
	unsigned long selectBits = 0L;
	if (autoInit) {
		selectBits = 0xffff;
	}
	else {
		NSEnumerator* e  = [[self collectObjectsOfClass:NSClassFromString(@"ORFec32Model")] objectEnumerator];
		ORFec32Model* proxyFec32;
		while(proxyFec32 = [e nextObject]) {
			selectBits |= 1L << [proxyFec32 stationNumber];
		}
	}
	
	[[self xl2] loadTheXilinx:selectBits];
	
}

- (void) loadClocks
{
	[[self xl2] loadTheClocks];
}


- (void) initFec32Cards
{
	NSMutableArray* slotList = [NSMutableArray arrayWithCapacity:16];
	ORFec32Model* proxyFec32;
	
	if (autoInit) {
		// will be replaced with the config data
		int i;
		for (i = 16; i > 0; i--) [slotList addObject:[NSNumber numberWithInt:i]];
	}
	else {
		NSEnumerator* e  = [[self collectObjectsOfClass:NSClassFromString(@"ORFec32Model")] objectEnumerator];
		while(proxyFec32 = [e nextObject]) {
			[slotList addObject:[NSNumber numberWithInt:[proxyFec32 slot]]];
		}
	}
	
	NSEnumerator* eSlot = [slotList objectEnumerator];
	NSNumber* iSlot;
	
	while (iSlot = [eSlot nextObject]) {		
		//1. select the channel
		@try {
			[[self xl2] selectCards:1L<<[self stationForSlot:[iSlot	intValue]]];
			NSLog(@"Select, data, and csr: 0x%08x, 0x%08x, 0x%08x.\n", [[self xl2] readFromXL2Register:XL2_SELECT_REG], [[self xl2] readFromXL2Register:XL2_DATA_AVAILABLE_REG], [[self xl2] readFromXL2Register:XL2_CONTROL_STATUS_REG]);
		}
		@catch(NSException* localException) {
			NSLog(@"Unable to reach XL2 in crate: %d\n",[self crateNumber]);
			[[self xl2] deselectCards];
			[localException raise];
		}
		
		//2. readboard id; finds out if the card is there
		@try {
			proxyFec32 = [ObjectFactory makeObject:@"ORFec32Model"];
			[proxyFec32 setGuardian:self];
			
			NSString* boardID = [proxyFec32 performBoardIDRead:MC_BOARD_ID_INDEX];
			if(![boardID isEqual: @"0000"] && ![boardID isEqual: @"ffff"]){
				NSLog(@"Crate %2d Fec %2d BoardID: %@\n", [self crateNumber], [self stationForSlot:[iSlot intValue]], boardID);
				ORFec32Model* theCard = [[OROrderedObjManager for:self] objectInSlot:[iSlot intValue]];
				if(!theCard){
					[self addObjects:[NSArray arrayWithObject:proxyFec32]];
					[self place:proxyFec32 intoSlot:[iSlot intValue]];
					theCard = proxyFec32;
				}
				[theCard setBoardID:boardID];
				proxyFec32 = theCard;
			}
			else {
				@throw [NSException exceptionWithName:@"SNO Crate" reason:@"FEC with unknown board ID found." userInfo:nil];
				NSLog(@"Crate %2d Fec %2d xBoardID: %@\n", [self crateNumber], [self stationForSlot:[iSlot intValue]], boardID);
				ORFec32Model* theCard = [[OROrderedObjManager for:self] objectInSlot:[iSlot intValue]];
				if(theCard && autoInit)[self removeObject:theCard];
				proxyFec32 = nil; //do not continue with the inititialization
			}
		}
		@catch(NSException* localException) {
			NSLog(@"Crate %2d Fec %2d BoardID: ----\n", [self crateNumber], [self stationForSlot:[iSlot intValue]]);
			ORFec32Model* theCard = [[OROrderedObjManager for:self] objectInSlot:[iSlot intValue]];
			if (theCard) {
				//is the XilinX loaded? (the sharc way)
				@try{
					[[self xl2] deselectCards];
					unsigned long xilinx_loaded = ([[self xl2] readFromXL2Register:XL2_CONTROL_STATUS_REG] & (unsigned long) XL2_CONTROL_DONE_PROG);
					unsigned long clear_csr = xilinx_loaded?(0UL | XL2_CONTROL_DONE_PROG):0UL;
					[[self xl2] writeToXL2Register:XL2_CONTROL_STATUS_REG value:clear_csr];
					[[self xl2] select:theCard];
					[[self xl2] writeToXL2Register:XL2_CONTROL_STATUS_REG value:XL2_CONTROL_BIT11];
					xilinx_loaded = [[self xl2] readFromXL2Register:XL2_CONTROL_STATUS_REG] & XL2_CONTROL_DONE_PROG;
					[[self xl2] writeToXL2Register:XL2_CONTROL_STATUS_REG value:clear_csr]; // set bit 11 low
					if (xilinx_loaded) {
						NSLog(@"FEC card not present.\n");
						//proxyFec32 = nil;
					}
					else NSLog(@"Xilinx code is not running in the FEC.\n");
					[[self xl2] deselectCards];
				}
				@catch(NSException* localException) {
					NSLog(@"Not able to access the card to find the XilinX code.\n");
					[[self xl2] deselectCards];
				}
			}
			if(theCard && autoInit)[self removeObject:theCard];
			proxyFec32 = nil;
		}
		
		//3. daughter boards
		
		if (proxyFec32) {
			[[self xl2] select:proxyFec32];
			NSMutableArray* dcList = [NSMutableArray arrayWithCapacity:4];
			ORFecDaughterCardModel* proxyDC;
			
			if (autoInit) {
				// get ready for the configDB
				int i;
				for (i = 0; i < 4; i++) [dcList addObject:[NSNumber numberWithInt:i]];
			}
			else {
				NSEnumerator* e  = [proxyFec32 objectEnumerator];
				while(proxyDC = [e nextObject]) {
					[dcList addObject:[NSNumber numberWithInt:[proxyDC slot]]];
				}
			}
			
			NSEnumerator* eDC = [dcList objectEnumerator];
			NSNumber* iDC;
			while (iDC = [eDC nextObject]) {
				@try {
					proxyDC = [ObjectFactory makeObject:@"ORFecDaughterCardModel"];
					[proxyDC setGuardian:proxyFec32];
					
					NSString* aBoardID = [proxyDC performBoardIDRead:[iDC intValue]];
					if(![aBoardID isEqual: @"0000"]){
						NSLog(@"\tDC Slot: %d BoardID: %@\n", [iDC intValue], aBoardID);
						ORFecDaughterCardModel* theCard = [[OROrderedObjManager for:proxyFec32] objectInSlot:[iDC intValue]];
						if(!theCard){
							NSLog(@"New dc for slot %d\n", [iDC intValue]);
							[proxyFec32 addObject:proxyDC];
							[proxyFec32 place:proxyDC intoSlot:[iDC intValue]];
							theCard = proxyDC;
						}
						[theCard setBoardID:aBoardID];
					}
					else {
						NSLog(@"\tDC Slot: %d BoardID: BAD\n", [iDC intValue]);
						ORFecDaughterCardModel* theCard = [[OROrderedObjManager for:proxyFec32] objectInSlot:[iDC intValue]];
						if(theCard && autoInit)[proxyFec32 removeObject:theCard];
					}
				}
				@catch(NSException* localException) {
					NSLog(@"\tDC Slot: %d BoardID: ----\n", [iDC intValue]);
					ORFecDaughterCardModel* theCard = [[OROrderedObjManager for:proxyFec32] objectInSlot:[iDC intValue]];
					if(theCard && autoInit)[proxyFec32 removeObject:theCard];
				}
			}
		}
		
		//call the fec32 init function...
		if (proxyFec32) {
			@try {
				//correct the different trigger selection for auto and nonauto
				//correct the selection mask if the daughter card is missing
				NSLog(@"calling fec init...\n");
				[proxyFec32 initTheCard:autoInit];
			}
			@catch(NSException* localException) {
				[localException raise];
			}
		}
		
		[[self xl2] deselectCards];
	}
}

- (void) initCTCDelays
{
	
	//CTC_Control *theTCControl = NIL_POINTER;
	//TRY {
	//	theTCControl = new CTC_Control;
	//	FailNil(theTCControl);
	//	theTCControl->ITC_Control (Get_IC_Number(), Get_SC_Number(), theConfigDB);
	//	theTCControl->Init20NSDelays();
	//	delete theTCControl;
	//} 	
	//CATCH {
	//	if(theTCControl)delete theTCControl;
	//}
	//DONE
	
}

@end


@implementation ORSNOCrateModel (XL3)

- (void) initCrateUsingXL3:(BOOL) loadTheFEC32XilinxFile phase:(int) phase
{
	[[self adapter] initCrateWithXilinx:loadTheFEC32XilinxFile autoInit:[self autoInit]];
}

@end