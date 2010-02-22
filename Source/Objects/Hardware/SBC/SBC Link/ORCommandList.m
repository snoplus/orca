//
//  ORCommandList.m
//  Orca
//
//  Created by Mark Howe on 12/11/08.
//  Copyright 2008 University of North Carolina. All rights reserved.
//
/*-----------------------------------------------------------
 This program was prepared for the Regents of the University of 
 Washington at the Center for Experimental Nuclear Physics and 
 Astrophysics (CENPA) sponsored in part by the United States 
 Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
 The University has certain rights in the program pursuant to 
 the contract and the program should not be copied or distributed 
 outside your organization.  The DOE and the University of 
 Washington reserve all rights in the program. Neither the authors,
 University of Washington, or U.S. Government make any warranty, 
 express or implied, or assume any liability or responsibility 
 for the use of this software.
 -------------------------------------------------------------*/

#import "ORCommandList.h"

@implementation ORCommandList 
+ (id) commandList
{
	return [[[ORCommandList alloc] init] autorelease];
}

- (void) dealloc
{
	[commands release];
	[super dealloc];
}
- (NSEnumerator*) objectEnumerator
{
	return [commands objectEnumerator];
}
- (NSMutableArray*) commands
{
	return commands;
}

- (int) addCommand:(id)aCommand
{
	if(aCommand){
		if(!commands)commands = [[NSMutableArray array] retain];
		[commands addObject:aCommand];
		return [commands count] - 1;
	}
	else return -1;
}
- (int) addCommands:(ORCommandList*)anOtherList
{
	if(anOtherList){
		if(!commands)commands = [[NSMutableArray array] retain];
		[commands addObjectsFromArray:[anOtherList commands]];
		return [commands count] - 1;
	}
	else return -1;
}

- (id) command:(int)index
{
	if(index>=0 && index<[commands count]){
		return [commands objectAtIndex:index];
	}
	else return nil;
}

- (SBC_Packet) SBCPacket
{
	//make the main header
	SBC_Packet blockPacket;
	blockPacket.cmdHeader.destination			= kSBC_Process;
	blockPacket.cmdHeader.cmdID					= kSBC_CmdBlock;
	blockPacket.cmdHeader.numberBytesinPayload	= 0; //fill in as we go
	char* blockPayloadPtr				= (char*)blockPacket.payload;
	
	id aCmd; //TBD ..make generic
	NSEnumerator* e = [commands objectEnumerator];
	while(aCmd = [e nextObject]){
		SBC_Packet cmdPacket = [aCmd SBCPacket];
		memcpy(blockPayloadPtr,&cmdPacket,cmdPacket.numBytes);
		blockPacket.cmdHeader.numberBytesinPayload += cmdPacket.numBytes;
		blockPayloadPtr += cmdPacket.numBytes;
	}
	return blockPacket;
}

- (void) extractData:(SBC_Packet*) aPacket
{
	unsigned long totalBytesToProcess = aPacket->cmdHeader.numberBytesinPayload;
	char* dataToProcess = (char*) aPacket->payload;
	NSEnumerator* e = [commands objectEnumerator];
	id aCmd; //TBD ..make generic
	while(aCmd = [e nextObject]){
		SBC_Packet* packetToProcess = (SBC_Packet*)dataToProcess;
		[aCmd extractData:packetToProcess];
		dataToProcess += packetToProcess->numBytes;
		totalBytesToProcess -= packetToProcess->numBytes;
		if(totalBytesToProcess<=0)break; //we should drop out after all cmds processed, but just in case
	}
}
- (long) longValueForCmd:(int)anIndex
{
	if(anIndex<[commands count]){
		return [[commands objectAtIndex:anIndex] longValue];
	}
	else return 0;
}

- (short) shortValueForCmd:(int)anIndex
{
	if(anIndex<[commands count]){
		return [[commands objectAtIndex:anIndex] shortValue];
	}
	else return 0;
}
- (NSData*) dataForCmd:(int)anIndex
{
	if(anIndex<[commands count]){
		return [commands objectAtIndex:anIndex];
	}
	else return 0;
}

@end

