//
//  MJDPreAmpModel.m
//  Orca
//
//  Created by Mark Howe on Wed Jan 18 2012.
//  Copyright © 2012 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------


#pragma mark ¥¥¥Imported Files
#import "ORMJDPreAmpModel.h"

#pragma mark ¥¥¥Notification Strings
NSString* MJDPreAmpSettingsLock		= @"MJDPreAmpSettingsLock";

#pragma mark ¥¥¥Local Strings
static NSString* MJDPreAmpInputConnector      = @"MJDPreAmpInputConnector";

@implementation ORMJDPreAmpModel
#pragma mark ¥¥¥initialization
- (id) init //designated initializer
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
     
    
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint(2,[self frame].size.height/2 - kConnectorSize/2) withGuardian:self withObjectLink:self];
	[aConnector setConnectorType: 'SPII' ];
	[aConnector addRestrictedConnectionType: 'SPIO' ]; 
	[aConnector setOffColor:[NSColor colorWithCalibratedRed:0 green:.68 blue:.65 alpha:1.]];
    [[self connectors] setObject:aConnector forKey:MJDPreAmpInputConnector];
    [aConnector release];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"MJDPreAmp"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORMJDPreAmpController"];
}

#pragma mark ¥¥¥Accessors
- (NSString*) helpURL
{
	return nil;
}

#pragma mark ¥¥¥HW Access
- (void) readFromHW
{
	id connectedObj = [self objectConnectedTo:MJDPreAmpInputConnector];
	if([connectedObj respondsToSelector:@selector(readFromSPI)]){
		NSData* data = [connectedObj readFromSPI];
		NSLog(@"MJD Preamp got: %@\n",data);
	}
}

- (void)  writeToHW
{
	id connectedObj = [self objectConnectedTo:MJDPreAmpInputConnector];
	if([connectedObj respondsToSelector:@selector(writeToSPI:)]){
		long testValue = 0x666;
		[connectedObj writeToSPI:[NSData dataWithBytes:&testValue length:sizeof(long)]];
	}
}

#pragma mark ¥¥¥Archival
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
    NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];
    [objDictionary setObject:NSStringFromClass([self class]) forKey:@"Class Name"];
    [objDictionary setObject:[NSNumber numberWithInt:[self uniqueIdNumber]] forKey:@"preampID"];
    
    [dictionary setObject:objDictionary forKey:[self identifier]];
    return objDictionary;
}



@end
