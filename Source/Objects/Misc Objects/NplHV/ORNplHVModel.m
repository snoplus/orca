//
//  ORNplHVModel.m
//  Orca
//
//  Created by Mark Howe on Thurs Dec 6 2007
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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
#import "ORNplHVModel.h"
#import "NetSocket.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORHVRampItem.h"

NSString* ORNplHVModelWriteValueChanged		= @"ORNplHVModelWriteValueChanged";
NSString* ORNplHVModelFunctionChanged		= @"ORNplHVModelFunctionChanged";
NSString* ORNplHVModelChannelChanged		= @"ORNplHVModelChannelChanged";
NSString* ORNplHVModelBoardChanged			= @"ORNplHVModelBoardChanged";
NSString* ORNplHVModelCmdStringChanged		= @"ORNplHVModelCmdStringChanged";
NSString* ORNplHVModelIsConnectedChanged	= @"ORNplHVModelIsConnectedChanged";
NSString* ORNplHVModelIpAddressChanged		= @"ORNplHVModelIpAddressChanged";
NSString* ORNplHVLock						= @"ORNplHVLock";

@implementation ORNplHVModel

- (void) makeMainController
{
    [self linkToController:@"ORNplHVController"];
}

- (void) dealloc
{
	[socket close];
	[socket release];
    [super dealloc];
}

- (void) awakeAfterDocumentLoaded
{
	NS_DURING
		[self connect];
		[self connectionChanged];
	NS_HANDLER
	NS_ENDHANDLER
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"NplHVIcon"]];
}

- (void) addRampItem
{
	ORHVRampItem* aRampItem = [[ORHVRampItem alloc] initWithOwner:self];
	[rampItems addObject:aRampItem];
	[aRampItem release];
}

- (void) ensureMinimumNumberOfRampItems
{
	if(!rampItems)[self setRampItems:[NSMutableArray array]];
	if([rampItems count] == 0){
		int i;
		[[self undoManager] disableUndoRegistration];
		for(i=0;i<[self numberOfChannels];i++){
			ORHVRampItem* aRampItem = [[ORHVRampItem alloc] initWithOwner:self];
			[aRampItem setTargetName:[self className]];
			[aRampItem setChannelNumber:i];
			[aRampItem setParameterName:@"Voltage"];
			[aRampItem loadParams:self];
			[rampItems addObject:aRampItem];
			[aRampItem release];
		}
		[[self undoManager] enableUndoRegistration];
	}
}

#pragma mark ***Accessors
- (NSString*) lockName
{
	return ORNplHVLock;
}


- (int) writeValue
{
    return writeValue;
}

- (void) setWriteValue:(int)aWriteValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWriteValue:writeValue];
    
    writeValue = aWriteValue;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORNplHVModelWriteValueChanged object:self];
}

- (int) functionNumber
{
    return functionNumber;
}

- (void) setFunctionNumber:(int)aFunction
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFunctionNumber:functionNumber];
    
    functionNumber = aFunction;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORNplHVModelFunctionChanged object:self];
}

- (int) channel
{
    return channel;
}

- (void) setChannel:(int)aChannel
{
    [[[self undoManager] prepareWithInvocationTarget:self] setChannel:channel];
    
    channel = aChannel;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORNplHVModelChannelChanged object:self];
}

- (int) board
{
    return board;
}

- (void) setBoard:(int)aBoard
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBoard:board];
    
    board = aBoard;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORNplHVModelBoardChanged object:self];
}

- (NetSocket*) socket
{
	return socket;
}

- (void) setSocket:(NetSocket*)aSocket
{
	if(aSocket != socket)[socket close];
	[aSocket retain];
	[socket release];
	socket = aSocket;
    [socket setDelegate:self];
}

- (void) setIsConnected:(BOOL)aFlag
{
    isConnected = aFlag;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORNplHVModelIsConnectedChanged object:self];
}

- (NSString*) ipAddress
{
    return ipAddress;
}

- (void) setIpAddress:(NSString*)aIpAddress
{
	if(!aIpAddress)aIpAddress = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setIpAddress:ipAddress];
    
    [ipAddress autorelease];
    ipAddress = [aIpAddress copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORNplHVModelIpAddressChanged object:self];
}


- (void) connect
{
	if(!isConnected){
		[self setSocket:[NetSocket netsocketConnectedToHost:ipAddress port:kNplHVPort]];	
        [self setIsConnected:[socket isConnected]];
	}
	else {
		[self setSocket:nil];	
        [self setIsConnected:[socket isConnected]];
	}
}

- (BOOL) isConnected
{
	return isConnected;
}

- (int) adc:(int)aChan
{
	if(aChan>=0 && aChan < [self numberOfChannels])return adc[aChan];
	else return 0;
}

- (void) setAdc:(int)aChan withValue:(int)aValue
{
	if(aChan>=0 && aChan < [self numberOfChannels]){
		adc[aChan] = aValue;
	}
}

- (int) dac:(int)aChan
{
	if(aChan>=0 && aChan < [self numberOfChannels])return dac[aChan];
	else return 0;
}

- (void) setDac:(int)aChan withValue:(int)aValue
{
	if(aChan>=0 && aChan < [self numberOfChannels]){
		dac[aChan] = aValue;
	}
}

- (int) current:(int)aChan
{
	if(aChan>=0 && aChan < [self numberOfChannels])return current[aChan];
	else return 0;
}

- (void) setCurrent:(int)aChan withValue:(int)aValue
{
	if(aChan>=0 && aChan < [self numberOfChannels]){
		current[aChan] = aValue;
	}
}

- (int) controlReg:(int)aChan
{
	if(aChan>=0 && aChan < [self numberOfChannels])return controlReg[aChan];
	else return 0;
}

- (void) setControlReg:(int)aChan withValue:(int)aValue
{
	if(aChan>=0 && aChan < [self numberOfChannels]){
		controlReg[aChan] = aValue;
	}
}

#pragma mark ***Delegate Methods
- (void) netsocketConnected:(NetSocket*)inNetSocket
{
    if(inNetSocket == socket){
        [self setIsConnected:[socket isConnected]];
    }
}

- (void) netsocket:(NetSocket*)inNetSocket dataAvailable:(unsigned)inAmount
{
    if(inNetSocket == socket){
		NSData* theData = [inNetSocket readData];
		char* theBytes = (char*)[theData bytes];
		int i;
		for(i=0;i<[theData length];i++){
			NSLog(@"From NPL HV [%d]: 0x%x\n",i,theBytes[i]);
		}
	}
}

- (void) netsocketDisconnected:(NetSocket*)inNetSocket
{
    if(inNetSocket == socket){
        [self setIsConnected:NO];
		[socket autorelease];
		socket = nil;
    }
}


#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setWriteValue:	[decoder decodeIntForKey:	@"writeValue"]];
    [self setFunctionNumber:[decoder decodeIntForKey:	@"function"]];
    [self setChannel:		[decoder decodeIntForKey:	@"channel"]];
    [self setBoard:			[decoder decodeIntForKey:	@"board"]];
	[self setIpAddress:		[decoder decodeObjectForKey:@"ipAddress"]];
    [[self undoManager] enableUndoRegistration];    
		
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:writeValue		forKey: @"writeValue"];
    [encoder encodeInt:functionNumber	forKey: @"function"];
    [encoder encodeInt:channel			forKey: @"channel"];
    [encoder encodeInt:board			forKey: @"board"];
    [encoder encodeObject:ipAddress		forKey: @"ipAddress"];
}

- (void) sendCmd
{	
	//send the values from the basic ops
	char bytes[6];
	bytes[0] = 5;
	bytes[1] = ((board & 0xf)<<4) | ((channel & 0x3)<<2) | (functionNumber & 0x3);
	bytes[2] = 0;
	bytes[3] = (writeValue>>16 & 0xf);
	bytes[4] = (writeValue>>8 & 0xf); 
	bytes[5] = writeValue & 0xf; 
	[socket write:bytes length:6];
}

- (SEL) getMethodSelector
{
	return @selector(dac:);
}

- (SEL) setMethodSelector
{
	return @selector(setDac:withValue:);
}

- (SEL) initMethodSelector
{
	//fake out, so we can actually do the load ourselves
	return @selector(junk);
}

- (void) junk
{
}

- (void) loadDac:(int)aChan
{
	//send the values from the basic ops
	char bytes[6];
	bytes[0] = 5;
	bytes[1] = ((1 & 0xf)<<4) | ((aChan & 0x3)<<2) | (2 & 0x3); //set dac
	bytes[2] = 0;
	int aValue = dac[aChan];
	bytes[3] = (aValue>>16 & 0xf);
	bytes[4] = (aValue>>8 & 0xf); 
	bytes[5] = aValue & 0xf; 
	[socket write:bytes length:6];
}

#pragma mark •••HW Wizard
//the next two methods exist only to 'fake' out Hardware wizard and the Ramper so this item can be selected
- (int) crateNumber	{	return 0;	}
- (int) slot		{	return [self tag];	}

- (int) numberOfChannels
{
    return 8;
}

- (BOOL) hasParmetersToRamp
{
	return YES;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Voltage"];
    [p setFormat:@"##0" upperLimit:3000 lowerLimit:0 stepSize:1 units:@"V"];
    [p setSetMethod:@selector(setDac:withValue:) getMethod:@selector(dac:)];
	[p setInitMethodSelector:@selector(sendCmd)];
	[p setCanBeRamped:YES];
    [a addObject:p];
	    
    return a;
}

- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel name:@"Crate"	className:@"ORNplHVModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Card"		className:@"ORNplHVModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel"	className:@"ORNplHVModel"]];
    return a;
	
}

@end
