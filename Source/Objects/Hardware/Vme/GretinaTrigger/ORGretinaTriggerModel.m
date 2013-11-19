//-------------------------------------------------------------------------
//  ORGretinaTriggerModel.m
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
#import "ORGretinaTriggerModel.h"
#import "ORVmeCrateModel.h"

NSString* ORGretinaTriggerModelInputLinkMaskChanged = @"ORGretinaTriggerModelInputLinkMaskChanged";
NSString* ORGretinaTriggerModelIsMasterChanged       = @"ORGretinaTriggerModelIsMasterChanged";
NSString* ORGretinaTriggerSettingsLock				 = @"ORGretinaTriggerSettingsLock";
NSString* ORGretinaTriggerRegisterLock				 = @"ORGretinaTriggerRegisterLock";
NSString* ORGretinaTriggerRegisterIndexChanged       = @"ORGretinaTriggerRegisterIndexChanged";
NSString* ORGretinaTriggerRegisterWriteValueChanged  = @"ORGretinaTriggerRegisterWriteValueChanged";
NSString* ORGretinaTriggerSerdesTPowerMaskChanged   = @"ORGretinaTriggerSerdesTPowerMaskChanged";
NSString* ORGretinaTriggerSerdesRPowerMaskChanged   = @"ORGretinaTriggerSerdesRPowerMaskChanged";
NSString* ORGretinaTriggerLvdsPreemphasisCtlMask   = @"ORGretinaTriggerLvdsPreemphasisCtlMask";

@implementation ORGretinaTriggerModel
#pragma mark •••Static Declarations
//offsets from the base address
typedef struct {
	unsigned long offset;
	NSString* name;
	BOOL accessType;
	BOOL hwType;
} GretinaTriggerRegisterInformation;

#define kReadOnly   0x1
#define kWriteOnly  0x2
#define kReadWrite  0x4
#define kMasterAndRouter    0x1
#define kMasterOnly         0x2
#define kRouterOnly         0x4
#define kDataGenerator      0x8

static GretinaTriggerRegisterInformation register_information[kNumberOfGretinaTriggerRegisters] = {
    {0x0800,    @"Input Link Mask",     kReadWrite, kMasterAndRouter},
    {0x0804,    @"LED Register",        kReadWrite, kMasterAndRouter},
    {0x0808,    @"Skew Ctl A",          kReadWrite, kMasterAndRouter},
    {0x080D,    @"Skew Ctl B",          kReadWrite, kMasterAndRouter},
    {0x0810,    @"Skew Ctl C",          kReadWrite, kMasterAndRouter},
    {0x0814,    @"Misc Clk Crl",        kReadWrite, kMasterAndRouter},
    {0x0818,    @"Aux IO Crl",          kReadWrite, kMasterAndRouter},
    {0x081C,    @"Aux IO Data",         kReadWrite, kMasterAndRouter},
    {0x0820,    @"Aux Input Select",    kReadWrite, kMasterAndRouter},
    {0x0824,    @"Aux Trigger Width",   kReadWrite, kMasterOnly},
    {0x0828,    @"Serdes TPower",       kReadWrite, kMasterAndRouter},
    {0x082C,    @"Serdes RPower",       kReadWrite, kMasterAndRouter},
    {0x0830,    @"Serdes Local Le",     kReadWrite, kMasterAndRouter},
    {0x0834,    @"Serdes Line Le",      kReadWrite, kMasterAndRouter},
    {0x0838,    @"Lvds PreEmphasis",    kReadWrite, kMasterAndRouter},
    {0x083C,    @"Link Lru Crl",        kReadWrite, kMasterAndRouter},
    {0x0840,    @"Misc Ctl1",           kReadWrite, kMasterAndRouter},
    {0x0844,    @"Misc Ctl2",           kReadWrite, kMasterAndRouter},

    {0x0848,    @"Generic Test Fifo",   kReadWrite, kMasterAndRouter},
    {0x084C,    @"Diag Pin Crl",        kReadWrite, kMasterAndRouter},
    {0x0850,    @"Trig Mask",           kReadWrite, kMasterOnly},
    {0x0854,    @"Trig Dist Mask",      kReadWrite, kMasterOnly},
    {0x0860,    @"Serdes Mult Thresh",  kReadWrite, kMasterOnly},
    {0x0864,    @"Tw Ethresh Crl",      kReadWrite, kMasterOnly},
    {0x0868,    @"Tw Ethresh Low",      kReadWrite, kMasterOnly},
    {0x086C,    @"Tw Ethresh Hi",       kReadWrite, kMasterOnly},
    {0x0870,    @"Raw Ethresh low",     kReadWrite, kMasterOnly},
    {0x0874,    @"Raw Ethresh Hi",      kReadWrite, kMasterOnly},
 
    //------
    //Next blocks are define differently in Master and Router
    {0x0878,    @"Isomer Thresh1",      kReadWrite, kMasterOnly},
    {0x087C,    @"Isomer Thresh2",      kReadWrite, kMasterOnly},
    {0x0880,    @"Isomer Time Window",  kReadWrite, kMasterOnly},
    {0x0884,    @"Fifo Raw Esum Thresh",kReadWrite, kMasterOnly},
    {0x0888,    @"Fifo Tw Esum Thresh", kReadWrite, kMasterOnly},
     //-------
    {0x0878,    @"CC Pattern1",         kReadWrite, kRouterOnly},
    {0x087C,    @"CC Pattern2",         kReadWrite, kRouterOnly},
    {0x0880,    @"CC Pattern3",         kReadWrite, kRouterOnly},
    {0x0884,    @"CC Pattern4",         kReadWrite, kRouterOnly},
    {0x0888,    @"CC Pattern5",         kReadWrite, kRouterOnly},
    {0x088C,    @"CC Pattern6",         kReadWrite, kRouterOnly},
    {0x0890,    @"CC Pattern7",         kReadWrite, kRouterOnly},
    {0x0894,    @"CC Pattern8",         kReadWrite, kRouterOnly},
    //End of Split
    //----------
    {0x08A0,    @"Mon1 Fifo Sel",       kReadWrite, kMasterAndRouter},
    {0x08A4,    @"Mon2 Fifo Sel",       kReadWrite, kMasterAndRouter},
    {0x08A8,    @"Mon3 Fifo Sel",       kReadWrite, kMasterAndRouter},
    {0x08AC,    @"Mon4 Fifo Sel",       kReadWrite, kMasterAndRouter},
    {0x08B0,    @"Mon5 Fifo Sel",       kReadWrite, kMasterAndRouter},
    {0x08B4,    @"Mon6 Fifo Sel",       kReadWrite, kMasterAndRouter},
    {0x08B8,    @"Mon7 Fifo Sel",       kReadWrite, kMasterAndRouter},
    {0x08BC,    @"Mon8 Fifo Sel",       kReadWrite, kMasterAndRouter},
    {0x08C0,    @"Chan Fifo Crl",       kReadWrite, kMasterAndRouter},

    {0x08C4,    @"Dig Misc Bits",       kReadWrite, kDataGenerator}, //spare in Master and Router
    {0x08C8,    @"Dig DiscBit Src",     kReadWrite, kDataGenerator}, //spare in Master and Router
    {0x08CC,    @"Den Bits",            kReadWrite, kDataGenerator}, //spare in Master and Router
    {0x08D0,    @"Ren Bits",            kReadWrite, kDataGenerator}, //spare in Master and Router
    {0x08D4,    @"Sync Bits",           kReadWrite, kDataGenerator}, //spare in Master and Router

    {0x08E0,    @"Pulsed Ctl1",         kReadWrite, kMasterAndRouter},
    {0x08E4,    @"Pulsed Ctl2",         kReadWrite, kMasterAndRouter},

    {0x08F0,    @"Fifo Resets",         kReadWrite, kMasterAndRouter},
    {0x08F4,    @"Async Cmd Fifo",      kReadWrite, kMasterAndRouter},
    {0x08F8,    @"Aux Cmd Fifo",        kReadWrite, kMasterAndRouter},
    {0x08FC,    @"Debug Cmd Fifo",      kReadWrite, kMasterAndRouter},
    {0xA000,    @"Mask",                kReadWrite, kMasterAndRouter},
    {0xE000,    @"Fast Strb Thresh",    kReadWrite, kMasterAndRouter},

    {0x0100,    @"Link Locked",         kReadOnly, kMasterAndRouter},
    {0x0104,    @"Link Den",            kReadOnly, kMasterAndRouter},
    {0x0108,    @"Link Ren",            kReadOnly, kMasterAndRouter},
    {0x010C,    @"Link Sync",           kReadOnly, kMasterAndRouter},
    {0x0110,    @"Chan Fifo Stat",      kReadOnly, kMasterAndRouter},
    {0x0114,    @"TimeStamp A",         kReadOnly, kMasterAndRouter},
    {0x0118,    @"TimeStamp B",         kReadOnly, kMasterAndRouter},
    {0x011C,    @"TimeStamp C",         kReadOnly, kMasterAndRouter},
    {0x0120,    @"MSM State",           kReadOnly, kMasterOnly},

    //------
    //Next blocks are define differently in Master and Router
    {0x0124,    @"Chan Pipe Status",    kReadOnly, kMasterOnly},
    //-------
    {0x0124,    @"Rc State",            kReadOnly, kRouterOnly},
    //End of Split
    //----------

    {0x0128,    @"Misc State",          kReadOnly, kMasterAndRouter},
    {0x012C,    @"Diagnostic A",        kReadOnly, kMasterAndRouter},
    {0x0130,    @"Diagnostic B",        kReadOnly, kMasterAndRouter},
    {0x0134,    @"Diagnostic C",        kReadOnly, kMasterAndRouter},
    {0x0138,    @"Diagnostic D",        kReadOnly, kMasterAndRouter},
    {0x013C,    @"Diagnostic E",        kReadOnly, kMasterAndRouter},
    {0x0140,    @"Diagnostic F",        kReadOnly, kMasterAndRouter},
    {0x0144,    @"Diagnostic G",        kReadOnly, kMasterAndRouter},
    {0x0148,    @"Diagnostic H",        kReadOnly, kMasterAndRouter},
    {0x014C,    @"Diag Stat",           kReadOnly, kMasterAndRouter},
    {0x0154,    @"Run Raw Esum",        kReadOnly, kMasterOnly},
    {0x0158,    @"Code Mode Date",      kReadOnly, kMasterAndRouter},
    {0x015C,    @"Code Revision",       kReadOnly, kMasterAndRouter},
    {0x0160,    @"Mon1 Fifo",           kReadOnly, kMasterAndRouter},
    {0x0164,    @"Mon2 Fifo",           kReadOnly, kMasterAndRouter},
    {0x0168,    @"Mon3 Fifo",           kReadOnly, kMasterAndRouter},
    {0x016C,    @"Mon4 Fifo",           kReadOnly, kMasterAndRouter},
    {0x0170,    @"Mon5 Fifo",           kReadOnly, kMasterAndRouter},
    {0x0174,    @"Mon6 Fifo",           kReadOnly, kMasterAndRouter},
    {0x0178,    @"Mon7 Fifo",           kReadOnly, kMasterAndRouter},
    {0x017C,    @"Mon8 Fifo",           kReadOnly, kMasterAndRouter},
    {0x0180,    @"Chan1 Fifo",          kReadOnly, kMasterAndRouter},
    {0x0184,    @"Chan2 Fifo",          kReadOnly, kMasterAndRouter},
    {0x0188,    @"Chan3 Fifo",          kReadOnly, kMasterAndRouter},
    {0x018C,    @"Chan4 Fifo",          kReadOnly, kMasterAndRouter},
    {0x0190,    @"Chan5 Fifo",          kReadOnly, kMasterAndRouter},
    {0x0194,    @"Chan6 Fifo",          kReadOnly, kMasterAndRouter},
    {0x0198,    @"Chan7 Fifo",          kReadOnly, kMasterAndRouter},
    {0x019C,    @"Chan8 Fifo",          kReadOnly, kMasterAndRouter},
    {0x01A0,    @"Mon Fifo State",      kReadOnly, kMasterAndRouter},
    {0x01A4,    @"Chan Fifo State",     kReadOnly, kMasterAndRouter},

    {0xA004,    @"Total Multiplicity",  kReadOnly, kMasterOnly},
    {0xA010,    @"RouterA Multiplicity",kReadOnly, kMasterOnly},
    {0xA014,    @"RouterB Multiplicity",kReadOnly, kMasterOnly},
    {0xA018,    @"RouterC Multiplicity",kReadOnly, kMasterOnly},
    {0xA01C,    @"RouterD Multiplicity",kReadOnly, kMasterOnly},

};





#pragma mark ***Initialization
- (id) init 
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self setAddressModifier:0x09];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc 
{
    int i;
    for(i=0;i<9;i++){
        [linkConnector[i] release];
    }
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"GretinaTrigger"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORGretinaTriggerController"];
}

//- (NSString*) helpURL
//{
//	return @"VME/Gretina.html";
//}

- (Class) guardianClass
{
	return NSClassFromString(@"ORVme64CrateModel");
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,baseAddress+0xffff);
}

- (void) setSlot:(int)aSlot
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSlot:[self slot]];
    [self setTag:aSlot];
    [self guardian:guardian positionConnectorsForCard:self];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORVmeCardSlotChangedNotification
	 object: self];
}

- (void) makeConnectors
{
    //make and cache our connector. However these connectors will be 'owned' by another object (the crate)
    //so we don't add it to our list of connectors. It will be added to the true owner later.
    int i;
    for(i=0;i<9;i++){
        [self setLink:i connector: [[[ORConnector alloc] initAt:NSZeroPoint withGuardian:self withObjectLink:self] autorelease]];
        [linkConnector[i] setSameGuardianIsOK:YES];
        [linkConnector[i] setConnectorImageType:kSmallDot];
        if(i<8){
            [linkConnector[i] setConnectorType: 'LNKO' ];
            [linkConnector[i] addRestrictedConnectionType: 'LNKI' ];
        }
        else {
            [linkConnector[i] setConnectorType: 'LNKI' ];
            [linkConnector[i] addRestrictedConnectionType: 'LNKO' ];
        }
        [linkConnector[i] setOffColor:[NSColor colorWithCalibratedRed:1 green:1 blue:.3 alpha:1.]];
        if(i<8)[linkConnector[i] setIdentifer:'A'+i];
        else   [linkConnector[i] setIdentifer:'L'];
    }
}

- (void) positionConnector:(ORConnector*)aConnector
{
    NSRect aFrame = [aConnector localFrame];
    int i;
    for(i=0;i<9;i++){
        if(aConnector == linkConnector[i]){
            float x =  17 + [self slot] * 16*.62 ;
            float y =  95 - (kConnectorSize-4)*i;
            if(i==8)y -= 10;
            aFrame.origin = NSMakePoint(x,y);
            [aConnector setLocalFrame:aFrame];
            break;
        }
    }
}

- (void) setGuardian:(id)aGuardian
{
    id oldGuardian = guardian;
	
	[super setGuardian:aGuardian];
	
    int i;
    if(oldGuardian != aGuardian){
        for(i=0;i<9;i++){
            [oldGuardian removeDisplayOf:linkConnector[i]];
        }
    }
	
    for(i=0;i<9;i++){
        [aGuardian assumeDisplayOf:linkConnector[i]];
    }
    [self guardian:aGuardian positionConnectorsForCard:self];
}

- (void) guardian:(id)aGuardian positionConnectorsForCard:(id)aCard
{
    int i;
    for(i=0;i<9;i++){
        [aGuardian positionConnector:linkConnector[i] forCard:self];
    }
}

- (void) guardianRemovingDisplayOfConnectors:(id)aGuardian
{
    int i;
    for(i=0;i<9;i++){
        [aGuardian removeDisplayOf:linkConnector[i]];
    }
}

- (void) guardianAssumingDisplayOfConnectors:(id)aGuardian
{
    int i;
    for(i=0;i<9;i++){
        [aGuardian assumeDisplayOf:linkConnector[i]];
    }
}

#pragma mark ***Accessors
- (unsigned long) inputLinkMask
{
    return inputLinkMask;
}

- (void) setInputLinkMask:(unsigned long)aInputLinkMask
{
    inputLinkMask = aInputLinkMask;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerModelInputLinkMaskChanged object:self];
}

- (unsigned long) serdesTPowerMask
{
    return serdesTPowerMask;
}

- (void) setSerdesTPowerMask:(unsigned long)aMask
{
    serdesTPowerMask = aMask;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerSerdesTPowerMaskChanged object:self];
}

- (unsigned long) serdesRPowerMask
{
    return serdesRPowerMask;
  
}

- (void) setSerdesRPowerMask:(unsigned long)aMask
{
    serdesRPowerMask = aMask;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerSerdesRPowerMaskChanged object:self];
}

- (unsigned long) lvdsPreemphasisCtlMask
{
    return lvdsPreemphasisCtlMask;
}
- (void) setLvdsPreemphasisCtlMask:(unsigned long)aMask
{
    lvdsPreemphasisCtlMask = aMask;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerLvdsPreemphasisCtlMask object:self];
    
}


- (ORConnector*) linkConnector:(int)index
{
    if(index>=0 && index<9)return linkConnector[index];
    else return nil;
}

- (void) setLink:(int)index connector:(ORConnector*)aConnector
{
    if(index>=0 && index<9){
        [aConnector retain];
        [linkConnector[index] release];
        linkConnector[index] = aConnector;
    }
}

- (BOOL) isMaster
{
    return isMaster;
}

- (void) setIsMaster:(BOOL)aIsMaster
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIsMaster:isMaster];
    
    isMaster = aIsMaster;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerModelIsMasterChanged object:self];
}
- (int) registerIndex
{
    return registerIndex;
}

- (void) setRegisterIndex:(int)aRegisterIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRegisterIndex:registerIndex];
    registerIndex = aRegisterIndex;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerRegisterIndexChanged object:self];
}

- (unsigned long) registerWriteValue
{
    return registerWriteValue;
}

- (void) setRegisterWriteValue:(unsigned long)aWriteValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRegisterWriteValue:registerWriteValue];
    registerWriteValue = aWriteValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerRegisterWriteValueChanged object:self];
}

- (NSString*) registerNameAt:(unsigned int)index
{
	if (index >= kNumberOfGretinaTriggerRegisters) return @"";
	return register_information[index].name;
}

- (unsigned long) readRegister:(unsigned int)index
{
	if (index >= kNumberOfGretinaTriggerRegisters) return -1;
	if (![self canReadRegister:index]) return -1;
	unsigned long theValue = 0;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + register_information[index].offset
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
    return theValue;
}

- (void) writeRegister:(unsigned int)index withValue:(unsigned long)value
{
	if (index >= kNumberOfGretinaTriggerRegisters) return;
	if (![self canWriteRegister:index]) return;
    [[self adapter] writeLongBlock:&value
                         atAddress:[self baseAddress] + register_information[index].offset
                         numToWrite:1
					    withAddMod:[self addressModifier]
					 usingAddSpace:0x01];	
}

- (void) setLink:(char)linkName state:(BOOL)aState
{
    if(linkName>='A' && linkName<='U'){
        unsigned long aMask = inputLinkMask;
        int index = (int)(linkName - 'A');
        if(aState)  aMask |= (0x1 << index);
        else        aMask &= ~(0x1 << index);
        [self setInputLinkMask:aMask];
    }
}

- (BOOL) canReadRegister:(unsigned int)index
{
	if (index >= kNumberOfGretinaTriggerRegisters) return NO;
	return (register_information[index].accessType & kReadOnly) || (register_information[index].accessType & kReadWrite);
}

- (BOOL) canWriteRegister:(unsigned int)index
{
	if (index >= kNumberOfGretinaTriggerRegisters) return NO;
	return (register_information[index].accessType & kWriteOnly) || (register_information[index].accessType & kReadWrite);
}

#pragma mark •••set up routines
- (void) initAsOneMasterOneRouter
{
    //first check that we are a Master
    if(isMaster){
        unsigned long connectedRouterMask = [self findRouters];
        int numBitsSet = 0;
        int i;
        for(i=0;i<32;i++){
            if(connectedRouterMask & (0x1<<i))numBitsSet++;
        }
        if(numBitsSet){
            //1a. Mask out all unused channels
            [self setInputLinkMask:  ~connectedRouterMask]; //A set bit disables a channel
            [self writeRegister:kInputLinkMask withValue:inputLinkMask];
            
            //1b. Set the matching bit in the serdes tpower and rpower registers
            [self setSerdesTPowerMask:connectedRouterMask]; //A set bit enables power
            [self setSerdesRPowerMask:connectedRouterMask]; //A set bit enables power
            [self writeRegister:kSerdesTPower withValue:serdesRPowerMask];
            [self writeRegister:kSerdesRPower withValue:serdesRPowerMask];
            
           //1c. Turn on the driver enable bits for the used channels
            unsigned long preMask = 0;
            if(connectedRouterMask & 0xf) preMask  |= 0x1; //Links A,B,C,D
            if(connectedRouterMask & 0x70)preMask  |= 0x2; //Links E,F,G
            if(connectedRouterMask & 0x780)preMask |= 0x4; //Links H,L,R,U
            [self setLvdsPreemphasisCtlMask:preMask];
            [self writeRegister:kLvdsPreEmphasis withValue:lvdsPreemphasisCtlMask];
            
            //1d. Release the link-init machine by clearing the reset bit in the misc-ctl register
            unsigned long currValue = [self readRegister:kMiscCtl1];
            currValue &= ~kResetLinkInitMachBit;
            [self writeRegister:kMiscCtl1 withValue:currValue];
            //verify that we are waiting to lock onto the data stream of the router
            unsigned long miscStat = [self readRegister:kMiscStatus];
            if(((miscStat & kLinkInitStateMask)>>8) != 0x3){
                NSLog(@"HW issue: Master Trigger %@ not waiting for data stream from Router.\n",[self fullID]);
            }
            else {
                //so far so good. Next setup the Router and lave it to this Master
                //find the Router
                ORGretinaTriggerModel* routerObj = nil;
                int i;
                for(i=0;i<8;i++){
                    ORConnector* otherConnector = [linkConnector[i] connector];
                    if([otherConnector identifer] == 'L'){
                        routerObj = [otherConnector objectLink];
                        break;
                    }
                }
                [routerObj slaveToMaster];
            }
        }
        else {
            if(numBitsSet==0)NSLog(@"Opps, tried to initialize %@ for clock distribution but it is not connected to any routers\n",[self fullID]);
            else NSLog(@"Opps, tried to initialize %@ for clock distribution but it is  connected to more than one router\n",[self fullID]);
         }
    }
    else {
        NSLog(@"Opps, tried to initialize %@ for clock distribution but it is not set to be a Master\n",[self fullID]);
    }
}

- (void) slaveToMaster
{
    //2a. Enable the "L" link
    [self setSerdesTPowerMask:0x0100]; //A set bit enables power
    [self setSerdesRPowerMask:0x0100]; //A set bit enables power
    [self writeRegister:kSerdesTPower withValue:serdesRPowerMask];
    [self writeRegister:kSerdesRPower withValue:serdesRPowerMask];
    //2b. Turn on the DEN, REN, and SYNC for Link "L"
    [self writeRegister:kLinkLruCrl withValue:0x700];
    //2c. Enble the Link "L" driver
    [self setLvdsPreemphasisCtlMask:0x4];
    [self writeRegister:kLvdsPreEmphasis withValue:lvdsPreemphasisCtlMask];
}

- (unsigned long)findRouters
{
    unsigned long aMask = 0x0;
    int i;
    for(i=0;i<8;i++){
        ORConnector* otherConnector = [linkConnector[i] connector];
        if([otherConnector identifer] == 'L')aMask |= (0x1<<i);
    }
    return aMask;
}

#pragma mark •••Hardware Access
- (unsigned long) baseAddress
{
	return (([self slot]+1)&0x1f)<<20;
}

- (unsigned long) readCodeRevision
{
    unsigned long theValue = 0;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + register_information[kCodeRevision].offset
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
    return theValue;
}

- (unsigned long) readCodeDate
{
    unsigned long theValue = 0;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + register_information[kCodeModeDate].offset
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
    return theValue & 0xfff;
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setInputLinkMask:[decoder decodeInt32ForKey:@"inputLinkMask"]];
    [self setIsMaster: [decoder decodeBoolForKey:@"isMaster"]];
    int i;
    for(i=0;i<9;i++){
        [self setLink:i connector:[decoder decodeObjectForKey:[NSString stringWithFormat:@"linkConnector%d",i]]];
    }
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt32:inputLinkMask forKey:@"inputLinkMask"];
    [encoder encodeBool:isMaster	forKey:@"isMaster"];
    int i;
    for(i=0;i<9;i++){
        [encoder encodeObject:linkConnector[i] forKey:[NSString stringWithFormat:@"linkConnector%d",i]];
    }
}




@end
