//
//  ORGateGroup.m
//  Orca
//
//  Created by Mark Howe on 1/24/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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


#import "ORGateGroup.h"
#import "ORGate.h"
#import "ORDataPacket.h"
#import "ORDataTypeAssigner.h"

NSString* ORGateArrayChangedNotification = @"ORGateArrayChangedNotification";


@implementation ORGateGroup

+ (id) gateGroup
{
    return [[[ORGateGroup alloc] init] autorelease];
}

#pragma mark ***Accessors

- (id) init
{
    self = [super init];
    [self setDataGates:[NSMutableArray array]];
    return self;
}

- (void) dealloc
{
    [dataStore release];
    [dataGates release];
    [super dealloc];
}

- (NSMutableData*) dataStore
{
    return dataStore;
}

- (void) setDataStore:(NSMutableData*)aDataStore
{
    [aDataStore retain];
    [dataStore release];
    dataStore = aDataStore;
}
- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}

- (NSMutableArray *) dataGates
{
    return dataGates; 
}

- (void) setDataGates: (NSMutableArray *) aDataGates
{
    [aDataGates retain];
    [dataGates release];
    dataGates = aDataGates;
}

- (NSUndoManager *)undoManager
{
    return [[NSApp delegate] undoManager];
}

- (id) objectAtIndex:(int)i
{
    return [dataGates objectAtIndex:i];
}

- (unsigned) count
{
    return [dataGates count]; 
}

- (void) installGates:(id)obj
{
    [dataGates makeObjectsPerformSelector:@selector(installGates:) withObject:obj];
}

- (ORGate*) gateWithName:(NSString*)aName
{
    NSEnumerator* e = [dataGates objectEnumerator];
    ORGate* aGate;
    while(aGate = [e nextObject]){
        if([[aGate gateName] isEqualToString:aName])return aGate;
    }
    return nil;
}

- (void) newDataGate
{

    int i = 1;
    NSString* name;
    BOOL nameExists;
    while(1){
        name = [NSString stringWithFormat:@"gate_%d",i];
        NSEnumerator* e = [dataGates objectEnumerator];
        id aGate;
        nameExists = NO;
        while(aGate = [e nextObject]){
            if([[aGate gateName] isEqualToString:name]){
                nameExists = YES;
                break;
            }
        }
        if(!nameExists){
            ORGate* aGate = [ORGate gateWithName:name];
            [[[self undoManager] prepareWithInvocationTarget:self] deleteGate:aGate];
            [dataGates addObject:aGate];
            break;
        }
        else i++;
    }
    
	[[NSNotificationCenter defaultCenter] 
			postNotificationName:ORGateArrayChangedNotification 
			object: self 
			userInfo: nil];

}

- (void) deleteGate:(ORGate*)aGate
{
    [[[self undoManager] prepareWithInvocationTarget:self] undeleteGate:aGate];
    [dataGates removeObject:aGate];
	[[NSNotificationCenter defaultCenter] 
			postNotificationName:ORGateArrayChangedNotification 
			object: self 
			userInfo: [NSDictionary dictionaryWithObjectsAndKeys:[aGate gateName],@"deletedGateName",nil]];
    
}

- (void) undeleteGate:(ORGate*)aGate
{
    [[[self undoManager] prepareWithInvocationTarget:self] deleteGate:aGate];
    [dataGates addObject:aGate];
	[[NSNotificationCenter defaultCenter] 
			postNotificationName:ORGateArrayChangedNotification 
			object: self 
			userInfo: nil];
}
- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kShortForm]; //short form preferred
}

- (void) syncDataIdsWith:(id)anotherShaper
{
    [self setDataId:[anotherShaper dataId]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORGateGroupDecoderForEvent",                  @"decoder",
        [NSNumber numberWithLong:dataId],               @"dataId",
        [NSNumber numberWithBool:NO],                   @"variable",
        [NSNumber numberWithLong:1],                    @"length",
        nil];
    [dataDictionary setObject:aDictionary forKey:@"Event"];
    
    return dataDictionary;
}


- (NSMutableDictionary*) captureCurrentState:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* gateDictionary = [NSMutableDictionary dictionary];

    NSEnumerator* e = [dataGates objectEnumerator];
    ORGate* aGate;
    while(aGate = [e nextObject]){
        gateDictionary = [aGate captureCurrentState:gateDictionary];
    }
    
    [dictionary setObject:gateDictionary forKey:@"Gates"];

    return dictionary;
}

- (void) addProcessFlag:(ORDataPacket*)aDataPacket
{
    [aDataPacket addLongsToFrameBuffer:&dataId length:1];
}


- (void) encodeWithCoder: (NSCoder *)coder 
{
    [coder encodeObject: dataGates forKey: @"dataGates"];
}

- (id) initWithCoder: (NSCoder *)coder 
{
    if (self = [super init]) {
        dataGates = [[coder decodeObjectForKey: @"dataGates"] retain];
    }
    return self;
}

- (BOOL) prepareData:(ORDataSet*)aDataSet
               crate:(unsigned short)aCrate 
                card:(unsigned short)aCard 
             channel:(unsigned short)aChannel 
               value:(unsigned long)aValue
{
    if(!dataStore){
        [self setDataStore:[NSMutableData dataWithCapacity:2048*sizeof(gateData)]];
    }
    gateData someData;
    someData.crate   = aCrate;
    someData.card    = aCard;
    someData.channel = aChannel;
    someData.value   = aValue;
    
    [dataStore appendBytes:&someData length:sizeof(gateData)];
    return YES;
}

- (void) processEventIntoDataSet:(ORDataSet*)aDataSet
{
    if([dataStore length]>0){
        int count = [dataGates count];
        int i;
        for(i=0;i<count;i++){
            [[dataGates objectAtIndex:i] processEvent:dataStore intoDataSet:aDataSet];
        }
        [dataStore setLength:0];
    }
}
@end

@implementation ORGateGroupDecoderForEvent
- (id) init
{
    self = [super init];
    gateGroup = [[[NSApp delegate] document] gateGroup];
    return self;
}

- (unsigned long) decodeData:(void*)someData fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet:(ORDataSet*)aDataSet
{
    [gateGroup processEventIntoDataSet:aDataSet];
    return 1;
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    return @"Gate Control Record\n";               
}

@end

