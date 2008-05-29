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
#import "ORCrate.h"
#import "ORSNOCard.h"

@implementation ORXL2Model

#pragma mark •••Initialization
- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"XL2Card"]];
}


-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [inputConnectorName release];
    [outputConnectorName release];
    [inputConnector release];
    [outputConnector release];
    [super dealloc];
}

- (void) makeConnectors
{
    //make and cache our connector. However this connector will be 'owned' by another object (the crate)
    //so we don't add it to our list of connectors. It will be added to the true owner later.
    [self setInputConnector: [[[ORConnector alloc] initAt:NSZeroPoint withGuardian:self withObjectLink:self] autorelease]];
    [self setOutputConnector: [[[ORConnector alloc] initAt:NSZeroPoint withGuardian:self withObjectLink:self] autorelease]];
        
	[inputConnector setConnectorType: 'XL2I'];
	[inputConnector addRestrictedConnectionType: 'XL2O']; //can only connect to XL2O inputs
	[inputConnector addRestrictedConnectionType: 'XL1O']; //and XL1O inputs
	[inputConnector setOffColor:[NSColor colorWithCalibratedRed:0 green:.68 blue:.65 alpha:1.]];
	
	[outputConnector setConnectorType: 'XL2O'];
	[outputConnector addRestrictedConnectionType: 'XL2I']; //can only connect to XL2I inputs
	[outputConnector setOffColor:[NSColor colorWithCalibratedRed:0 green:.68 blue:.65 alpha:1.]];

}

- (void) positionConnector:(ORConnector*)aConnector
{
	//the SNO Crate is a special object, always arranged in a circle to mimic the actual layout in the SNO Cave.
	//to make the layout look good, we arrange the XL2 connectors in a custom way.
	int crateNumber = [[self guardian] crateNumber];
	float x,y;
	NSRect aFrame = [[self guardian] frame];
	float rightX	= aFrame.size.width - 10;
	float topY		= aFrame.size.height-10;
	float bottomY	= 0;
	if(aConnector == inputConnector){
		if(      crateNumber>=0  && crateNumber <= 3)	{x = 0;      y = bottomY;}
		else if( crateNumber>=4  && crateNumber <= 6)	{x = rightX; y = bottomY;}
		else if( crateNumber>=7  && crateNumber <= 13)	{x = rightX; y = topY;}
		else if( crateNumber>=14 && crateNumber <= 16)	{x = 0;      y = topY;}
		else										    {x = 0;      y = bottomY;}
	}
	else {
		if(      crateNumber>=0  && crateNumber <= 3)	{x = 0;      y = topY;}
		else if( crateNumber>=4  && crateNumber <= 6)	{x = 0;      y = bottomY;}
		else if( crateNumber>=7  && crateNumber <= 13)	{x = rightX; y = bottomY;}
		else if( crateNumber>=14 && crateNumber <= 16)	{x = rightX; y = topY;}
		else										    {x = 0;      y = topY;}
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
- (NSString*) inputConnectorName
{
    return inputConnectorName;
}
- (void) setInputConnectorName:(NSString*)aName
{
    [aName retain];
    [inputConnectorName release];
    inputConnectorName = aName;
    
}

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

- (NSString*) outputConnectorName
{
    return outputConnectorName;
}

- (void) setOutputConnectorName:(NSString*)aName
{
    [aName retain];
    [outputConnectorName release];
    outputConnectorName = aName;
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
        [oldGuardian removeDisplayOf:[self inputConnector]];
        [oldGuardian removeDisplayOf:[self outputConnector]];
    }
    
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



#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setInputConnectorName:	[decoder decodeObjectForKey:@"inputConnectorName"]];
    [self setInputConnector:		[decoder decodeObjectForKey:@"inputConnector"]];
    [self setOutputConnectorName:	[decoder decodeObjectForKey:@"outputConnectorName"]];
    [self setOutputConnector:		[decoder decodeObjectForKey:@"outputConnector"]];
	[self setSlot:					[decoder decodeIntForKey:   @"slot"]];
    
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:[self inputConnectorName]	 forKey:@"inputConnectorName"];
    [encoder encodeObject:[self inputConnector]		 forKey:@"inputConnector"];
    [encoder encodeObject:[self outputConnectorName] forKey:@"outputConnectorName"];
    [encoder encodeObject:[self outputConnector]	 forKey:@"outputConnector"];
    [encoder encodeInt:	  [self slot]			     forKey:@"slot"];
}

@end
