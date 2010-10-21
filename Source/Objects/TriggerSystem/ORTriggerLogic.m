//
//  ORTriggerLogic.m
//  Orca
//
//  Created by Mark Howe on 10/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Physics and 
//Astrophysics Department sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORTriggerLogic.h"
#import "ORDataPacket.h"
#import "ORLogicInBitModel.h"
#import "ORLogicOutBitModel.h"
#import "ORDataTaker.h"

@implementation ORTriggerLogic
- (id) initWithDelegate:(id)aDelegate
{
	self = [super init];
	delegate = aDelegate;
	triggeredChildren   = [[NSMutableArray array] retain];
	inputLogicElements  = [[self collectInputLogic] retain];
	outputLogicElements = [[self collectOutputLogic] retain];
	
	
	for(id anElement in outputLogicElements) {
		[anElement reset];
	}
	
	return self;
}

- (void) dealloc
{
	[triggeredChildren release];
	[outputLogicElements release];
	[inputLogicElements release];
	[super dealloc];
}

#pragma mark •••Triger Logic
- (NSArray*) collectOutputLogic
{
	NSMutableArray* array = [NSMutableArray array];
	for(id anObj in [delegate orcaObjects]){
		if([anObj conformsToProtocol:NSProtocolFromString(@"TriggerBitSetting")] ||
		   [anObj conformsToProtocol:NSProtocolFromString(@"TriggerChildReadingEndNode")]){
			
			[array addObject:anObj];
		}
	}
	return array;
}

- (NSArray*) collectInputLogic
{
	NSMutableArray* array = [NSMutableArray array];
	for(id anObj in [delegate orcaObjects]){
		if([anObj conformsToProtocol:NSProtocolFromString(@"TriggerBitReading")] || 
		   [anObj conformsToProtocol:NSProtocolFromString(@"TriggerPatternReading")]){
			[array addObject:anObj];
		}
	}
	return array;
}


- (void) scheduleChildForRead:(int)index
{
	id aChild = [delegate triggerChild:index];
	if(aChild)  {
		[triggeredChildren addObject:aChild];
	}
}

- (void) evaluate:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	//subclasses must override
}
@end

@implementation ORTriggerLogicIO

- (id) initWithDelegate:(id)aDelegate
{
	self = [super initWithDelegate:aDelegate];
	
	inputLogicMask  = 0x0;
	outputLogicMask = 0x0;
	for(id anElement in inputLogicElements)  {
		if([anElement respondsToSelector:@selector(bit)])inputLogicMask  |= (0x1L<<[anElement bit]);
	}
	
	for(id anElement in outputLogicElements) {
		if([anElement respondsToSelector:@selector(bit)])outputLogicMask  |= (0x1L<<[anElement bit]);
	}
	
	return self;
}

- (void) evaluate:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	if([outputLogicElements count]){
		
		outputLogicValue = 0x0;
		
		if(inputLogicMask) {
			inputLogicValue  = [delegate getInputWithMask:inputLogicMask];
		}
		
		for(id anOutputElement in outputLogicElements){
			[anOutputElement evalWithDelegate:self];
		}
				
		if(outputLogicMask){
			[delegate setOutputWithMask:outputLogicMask value:outputLogicValue];
		}
		
		for(id obj in triggeredChildren){
			[obj takeData:aDataPacket userInfo:userInfo];
		}
		[triggeredChildren removeAllObjects];
	}
}

- (unsigned long) inputValue:(short)index
{
	if(index>=0 && index<32)return (inputLogicValue & (1<<index)) != 0;
	else return 0;
}

- (unsigned long) inputLogicValue
{
	return inputLogicValue;
}

- (void) setOutputLogicBit:(int)aBit
{
	outputLogicValue |= (0x1L << aBit);
}
@end

@implementation ORTriggerLogicScaler

- (id) initWithDelegate:(id)aDelegate
{
	self = [super initWithDelegate:aDelegate];
		
	for(id anElement in outputLogicElements) {
		//if([anElement respondsToSelector:@selector(bit)])outputLogicMask  |= (0x1L<<[anElement bit]);
	}
	
	return self;
}

- (void) evaluate:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	if([outputLogicElements count]){
				
		for(id anOutputElement in outputLogicElements){
			[anOutputElement evalWithDelegate:self];
		}
				
		for(id obj in triggeredChildren){
			[obj takeData:aDataPacket userInfo:userInfo];
		}
		[triggeredChildren removeAllObjects];
	}
}
- (unsigned long) counts:(int)index
{
	return [delegate counts:index];
}
- (void) shipData:(BOOL)forceShip
{
	return [delegate shipData:forceShip];
}

@end

