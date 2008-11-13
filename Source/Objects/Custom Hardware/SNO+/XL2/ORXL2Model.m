//
//  ORXL2Model.m
//  Orca
//
//  Created by Mark Howe on Tue, Apr 30, 2008.
//  Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
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
#import "ORXL2Model.h"
#import "ORXL1Model.h"
#import "ORSNOCrateModel.h"
#import "ORSNOCard.h"

unsigned long xl2_register_offsets[] =
{	
	0,				// [ 0]  Select Register
	4,				// [ 1]  Data Available Register
	8,				// [ 2]  XL2 Control Status Register
	12,				// [ 3]  Mask Register
	16,				// [ 4]  Clock CSR
	20,				// [ 5]  HV Relay Control
	24,				// [ 6]  Xilinx User Control
	28, 			// [ 7]  General R/W display test register
	32,				// [ 8]  HV CSR
	36,				// [ 9]  HV Setpoints
	40,				// [10]  HV Voltage Readback
	44,				// [11]  HV Current Readback
};


@implementation ORXL2Model

#pragma mark •••Initialization
- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"XL2Card"]];
}


-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [inputConnector release];
    [outputConnector release];
    [super dealloc];
}

- (void) makeConnectors
{
    //make and cache our connector. However this connector will be 'owned' by another object (the SNORack)
    //so we don't add it to our list of connectors. It will be added to the true owner later.
    [self setInputConnector: [[[ORConnector alloc] initAt:NSZeroPoint withGuardian:self withObjectLink:self] autorelease]];
    [self setOutputConnector: [[[ORConnector alloc] initAt:NSZeroPoint withGuardian:self withObjectLink:self] autorelease]];
        
	[inputConnector setConnectorType: 'XL2I'];
	[inputConnector setConnectorImageType:kSmallDot]; 
	[inputConnector setIoType:kInputConnector];
	[inputConnector addRestrictedConnectionType: 'XL2O']; //can only connect to XL2O inputs
	[inputConnector addRestrictedConnectionType: 'XL1O']; //and XL1O inputs
	[inputConnector setOffColor:[NSColor colorWithCalibratedRed:0 green:.68 blue:.65 alpha:1.]];
	
	[outputConnector setConnectorType: 'XL2O'];
	[outputConnector setConnectorImageType:kSmallDot]; 
	[outputConnector setIoType:kOutputConnector];
	[outputConnector addRestrictedConnectionType: 'XL2I']; //can only connect to XL2I inputs
	[outputConnector setOffColor:[NSColor colorWithCalibratedRed:0 green:.68 blue:.65 alpha:1.]];

}

- (void) positionConnector:(ORConnector*)aConnector
{
	
	float x,y;
	NSRect aFrame = [[self guardian] frame];
	if(aConnector == inputConnector) {
		x = 0;      
		y = 0;
	}
	else {
		x = 0;      
		y = aFrame.size.height-10;
	}
	aFrame = [aConnector localFrame];
	aFrame.origin = NSMakePoint(x,y);
	[aConnector setLocalFrame:aFrame];
}

- (BOOL) solitaryInViewObject
{
	return YES;
}

#pragma mark •••Accessors

- (ORConnector*) inputConnector
{
    return inputConnector;
}

- (void) setInputConnector:(ORConnector*)aConnector
{
    [aConnector retain];
    [inputConnector release];
    inputConnector = aConnector;
}


- (ORConnector*) outputConnector
{
    return outputConnector;
}

- (void) setOutputConnector:(ORConnector*)aConnector
{
    [aConnector retain];
    [outputConnector release];
    outputConnector = aConnector;
}

- (void) setSlot:(int)aSlot
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSlot:[self slot]];
    [self setTag:aSlot];
    [self guardian:guardian positionConnectorsForCard:self];
    
    [[NSNotificationCenter defaultCenter]
			postNotificationName:ORSNOCardSlotChanged
                          object: self];
}

- (int) slotConv
{
    return [self slot];
}

- (int) crateNumber
{
    return [guardian crateNumber];
}


- (void) setGuardian:(id)aGuardian
{
    id oldGuardian = guardian;

	[super setGuardian:aGuardian];
      
    if(oldGuardian != aGuardian){
		[oldGuardian setAdapter:nil];	//old crate can't use this card any more
        [oldGuardian removeDisplayOf:[self inputConnector]];
        [oldGuardian removeDisplayOf:[self outputConnector]];
    }
    [aGuardian setAdapter:self];		//our new crate will use this card for hardware access
	
    [aGuardian assumeDisplayOf:[self inputConnector]];
    [aGuardian assumeDisplayOf:[self outputConnector]];
    [self guardian:aGuardian positionConnectorsForCard:self];
}
- (void) guardian:(id)aGuardian positionConnectorsForCard:(id)aCard
{
    [aGuardian positionConnector:[self inputConnector] forCard:self];
    [aGuardian positionConnector:[self outputConnector] forCard:self];
}

- (void) guardianRemovingDisplayOfConnectors:(id)aGuardian
{
    [aGuardian removeDisplayOf:[self inputConnector]];
    [aGuardian removeDisplayOf:[self outputConnector]];
}

- (void) guardianAssumingDisplayOfConnectors:(id)aGuardian
{
    [aGuardian assumeDisplayOf:[self inputConnector]];
    [aGuardian assumeDisplayOf:[self outputConnector]];
}

- (id) adapter
{
	id anAdapter = [self getXL1]; //should chain all the way back to the IC XL1
	if(anAdapter)return anAdapter;
	else [NSException raise:@"No XL1" format:@"Check that connections are made all the way back to an XL1.\n"];
	return nil;
}


- (id) getXL1
{
	id obj = [inputConnector connectedObject];
	return [obj getXL1];
}

- (void) connectionChanged
{
	ORXL1Model* theXL1 = [self getXL1];
	[theXL1 setCrateNumbers];
}

- (void) setCrateNumber:(int)crateNumber
{
	[[self guardian] setCrateNumber:crateNumber];
	id nextXL2 = [outputConnector connectedObject];
	[nextXL2 setCrateNumber:crateNumber+1];
}



#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setInputConnector:		[decoder decodeObjectForKey:@"inputConnector"]];
    [self setOutputConnector:		[decoder decodeObjectForKey:@"outputConnector"]];
	[self setSlot:					[decoder decodeIntForKey:   @"slot"]];
   
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:[self inputConnector]		 forKey:@"inputConnector"];
    [encoder encodeObject:[self outputConnector]	 forKey:@"outputConnector"];
    [encoder encodeInt:	  [self slot]			     forKey:@"slot"];
}

#pragma mark •••Hardware Access
- (void) selectCards:(unsigned long) selectBits
{
	[self writeToXL2Register:XL2_SELECT_REG value: selectBits]; // select the cards by writing to the XL2 REG 0 
}

- (void) deselectCards
{
	[self writeToXL2Register:XL2_SELECT_REG value:0UL];	//deselect the cards by writing to the XL2 REG 0
}

- (void) select:(ORSNOCard*) aCard
{
	unsigned long selectBits = (1L<<[aCard stationNumber]);
	[self writeToXL2Register:XL2_SELECT_REG value: selectBits]; // select the cards by writing to the XL2 REG 0 
}

- (void) writeToXL2Register:(unsigned long) aRegister value:(unsigned long) aValue
{
	if (aRegister > XL2_MASK_REG) {   //Higer registers require that bit 17 be set in the XL2 select register
		[[self adapter] writeHardwareRegister:[self xl2RegAddress:XL2_SELECT_REG] value:0x20000];
	}
	[[self adapter] writeHardwareRegister:[self xl2RegAddress:aRegister] value:aValue]; 		//Now write the value	
}

- (unsigned long) xl2RegAddress:(unsigned long)aRegOffset
{
	return [[self guardian] registerBaseAddress] + xl2_register_offsets[aRegOffset];
}

// read bit pattern from specified register on XL2
- (unsigned long) readFromXL2Register:(unsigned long) aRegister
{
	if (aRegister > XL2_MASK_REG){   //Higer registers require that bit 17 be set in the XL2 select register
		[self writeHardwareRegister:[self xl2RegAddress:XL2_SELECT_REG] value:0x20000];
	}

	// Now read the value
	return  [self  readHardwareRegister:[self xl2RegAddress:aRegister]]; 	
}

//call thrus for the Fec hardware access
- (void) writeHardwareRegister:(unsigned long) anAddress value:(unsigned long) aValue
{
	[[self adapter] writeHardwareRegister:anAddress value:aValue];
}

- (unsigned long) readHardwareRegister:(unsigned long) regAddress
{
	return [[self adapter] readHardwareRegister:regAddress];
}


@end
