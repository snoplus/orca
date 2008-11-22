//
//  ORMacModel.m
//  Orca
//
//  Created by Mark Howe on Fri Nov 22 2002.
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


#pragma mark ¥¥¥Imported Files
#import "ORMacModel.h"
#import "ORVmeAdapter.h"
#import "ORSerialPortList.h"
#import "ORSerialPort.h"

#import "ORFireWireInterface.h"
#import "ORCrate.h"
#import "ORFireWireBus.h"
#import "ORUSB.h"

NSString* ORMacModelEolTypeChanged = @"ORMacModelEolTypeChanged";
NSString* ORMacModelSerialPortsChanged = @"ORMacModelSerialPortsChanged";
NSString* ORMacModelUSBChainVerified   = @"ORMacModelUSBChainVerified";

static NSString *ORMacFireWireConnection = @"ORMacFireWireConnection";
static NSString *ORMacUSBConnection		 = @"ORMacUSBConnection";


void registryChanged(
	id	sender,
	io_service_t			service,
	natural_t				messageType,
	void *					messageArgument )
{
	// only update when root goes not busy
	//if(messageArgument == 0)[(NSNotificationCenter*)[ NSNotificationCenter defaultCenter ] postNotificationName:@"test" object:sender ];
}

@implementation ORMacModel

#pragma mark ¥¥¥initialization
- (id) init
{
	self = [super init];
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[fwBus release];
	[usb release];
    [serialPorts release];
    [super dealloc];
}

- (void) awakeAfterDocumentLoaded
{
	NS_DURING
		id anObj = [[[self connectors] objectForKey:ORMacFireWireConnection] connectedObject];
		[anObj setCrateNumber:0];

		[[NSNotificationCenter defaultCenter] addObserver : self
						 selector : @selector(objectsAdded:)
							 name : ORGroupObjectsAdded
						   object : nil];

		[[NSNotificationCenter defaultCenter] addObserver : self
						 selector : @selector(objectsRemoved:)
							 name : ORGroupObjectsRemoved
						   object : nil];

		usb = [[ORUSB alloc] init];
		[usb awakeAfterDocumentLoaded];
	NS_HANDLER
	NS_ENDHANDLER

}

- (int) crateNumber
{
	return 0;
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"Mac"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORMacController"];
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"%@ %d",[self className],[self tag]];
}

-(void)makeConnectors
{
	//we  have three permanent connectors. The rest we manage for the pci objects.
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize - 2, 2*kConnectorSize+2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORMacFireWireConnection];
    [aConnector setOffColor:[NSColor magentaColor]];
    [aConnector setConnectorType:'FWrO'];
	[ aConnector addRestrictedConnectionType: 'FWrI' ]; //can only connect to FireWire Inputs
    [aConnector release];

    aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize - 2, kConnectorSize+1) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORMacUSBConnection];
    [aConnector setOffColor:[NSColor yellowColor]];
    [aConnector setConnectorType:'USBO'];
	[ aConnector addRestrictedConnectionType: 'USBI' ]; //can only connect to USB Inputs
    [aConnector release];
}

- (void) positionConnector:(ORConnector*)aConnector forCard:(id)aCard
{
	//position our managed connectors.
	NSRect aFrame = [aConnector localFrame];
	aFrame.origin = NSMakePoint([self frame].size.width - kConnectorSize - 2 , 3*(kConnectorSize+2) + [aCard slot]*(kConnectorSize+2));
	[aConnector setLocalFrame:aFrame];
}

- (BOOL) solitaryObject
{
    return YES;
}


#pragma mark ¥¥¥Accessors

- (int) eolType
{
    return eolType;
}

- (void) setEolType:(int)aEolType
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEolType:eolType];
    
    eolType = aEolType;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMacModelEolTypeChanged object:self];
}


- (NSMutableArray*) serialPorts
{
    return serialPorts;
}

- (void) setSerialPorts:(NSMutableArray*)somePorts
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSerialPorts:serialPorts];
    
    [somePorts retain];
    [serialPorts release];
    serialPorts = somePorts;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMacModelSerialPortsChanged object:self];
}

- (id) serialPort:(int)index
{
    return [serialPorts objectAtIndex:index];
}


#pragma mark ¥¥¥Serial Ports
- (void) scanForSerialPorts
{
	// get an port enumerator
	NSEnumerator *enumerator = [ORSerialPortList portEnumerator];
	ORSerialPort *aPort;
    if(!serialPorts) [self setSerialPorts:[NSMutableArray array]];
	while (aPort = [enumerator nextObject]) {
        [serialPorts addObject:aPort];
	}
    if([serialPorts count]){
        NSLog(@"%d serial port%@found\n",[serialPorts count],[serialPorts count]>1?@"s ":@" ");
        NSEnumerator *enumerator = [serialPorts objectEnumerator];
        int i = 0;
        while (aPort = [enumerator nextObject]) {
            NSLog(@"Port %d: %@\n",i++,[aPort name]);
        }
    }
}
#pragma mark ¥¥¥FireWire
- (id) getFireWireInterface:(unsigned long)aVenderID
{
	if(!fwBus){
		fwBus = [[ORFireWireBus alloc] init];
	}
	return [fwBus getFireWireInterface:aVenderID];
}

#pragma mark ¥¥¥USB

- (id) getUSBController
{
	return usb;
}

- (void) objectsAdded:(NSNotification*)aNote
{
	[usb objectsAdded:[[aNote userInfo] objectForKey:ORGroupObjectList]];
}

- (void) objectsRemoved:(NSNotification*)aNote
{
	[usb objectsRemoved:[[aNote userInfo] objectForKey:ORGroupObjectList]];
}

- (unsigned) usbDeviceCount
{
	return [usb deviceCount];
}

- (id) usbDeviceAtIndex:(unsigned)index;
{
	return [usb deviceAtIndex:index];
}


#pragma mark ¥¥¥IP
- (NSString*) ipAddress:(int)desiredNetwork
{
	//desiredNetwork == 0 for main network
	//desiredNetwork == 1 for first found private network
	//desiredNetwork == 2 for next private network,
	//...
	
	
	NSString* theResult = @"";
	NSArray* names =  [[NSHost currentHost] addresses];
	NSEnumerator* e = [names objectEnumerator];
	id aName;
	int index = 0;
	while(aName = [e nextObject]){
		if([aName rangeOfString:@"::"].location == NSNotFound){
			if(desiredNetwork == 0 && [aName rangeOfString:@".0.0."].location == NSNotFound){
				theResult = aName;
				break;
			}
			else if(desiredNetwork == index){
				theResult =  aName;
				break;
			}
			index++;
		}
	}
	return theResult;
}


#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
    [self setEolType:[decoder decodeIntForKey:@"ORMacModelEolType"]];
    //[self setSerialPorts:[decoder decodeObjectForKey:@"serialPorts"]];
    [[self undoManager] enableUndoRegistration];
	[self scanForSerialPorts];
	
	if(!usb){
		usb = [[ORUSB alloc] init];
		[usb awakeAfterDocumentLoaded];
	}
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeInt:eolType forKey:@"ORMacModelEolType"];
    //[encoder encodeObject:serialPorts forKey:@"serialPorts"];
    [super encodeWithCoder:encoder];	
}


#pragma mark ¥¥¥OROrderedObjHolding Protocol
- (int) maxNumberOfObjects	{ return 4; }
- (int) objWidth			{ return 20; }
- (int) groupSeparation		{ return 0; }
- (NSString*) slotName:(int)aSlot	{ return [NSString stringWithFormat:@"PCI Slot %d",aSlot]; }

- (BOOL) slot:(int)aSlot excludedFor:(id)anObj { return NO;}

- (NSRange) legalSlotsForObj:(id)anObj
{
	return NSMakeRange(0,[self maxNumberOfObjects]);
}

- (int) slotAtPoint:(NSPoint)aPoint 
{
	return floor(((int)aPoint.y)/[self objWidth]);
}

- (NSPoint) pointForSlot:(int)aSlot 
{
	return NSMakePoint(0,aSlot*[self objWidth]);
}

- (void) place:(id)anObj intoSlot:(int)aSlot
{
	[anObj setSlot: aSlot];
	[anObj moveTo:[self pointForSlot:aSlot]];
}

@end

