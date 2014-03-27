//
//  ORCaenDataDecoders.m
//  Orca
//
//  Created by Mark Howe on Tues June 1 2010.
//  Copyright © 2010 University of North Carolina. All rights reserved.
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

#import "ORCaen792Decoders.h"
#import "ORDataSet.h"
#import "ORCaen792Model.h"

@implementation ORCAEN792DecoderForQdc
- (id) init
{
    self = [super init];
    getRatesFromDecodeStage = YES;
    return self;
}
- (void) dealloc
{
	[actualCards release];
    [super dealloc];
}
- (unsigned long) decodeData:(void*) aSomeData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*) aDataSet
{
    short i;
    long* ptr = (long*) aSomeData;
	long length = ExtractLength(ptr[0]);
    int crate = ShiftAndExtract(ptr[1],21,0x0000000f);
    int card  = ShiftAndExtract(ptr[1],16,0x0000001f);
    
	NSString* crateKey = [self getCrateKey:crate];
	NSString* cardKey  = [self getCardKey: card];
    NSString* dataKey  = [self dataKey];
    
    for( i = 2; i < length; i++ ){
		int dataType = ShiftAndExtract(ptr[i],24,0x7);
		if(dataType == 0x0){
			int qdcValue = ShiftAndExtract(ptr[i],0,0xfff);
			int chan     = [self channel:ptr[i]];
			NSString* channelKey  = [self getChannelKey: chan];
			[aDataSet histogram:qdcValue numBins:0xfff sender:self withKeys:dataKey,crateKey,cardKey,channelKey,nil];

            //get the actual object
            NSString* aKey = [crateKey stringByAppendingString:cardKey];
            
            if(!actualCards)actualCards = [[NSMutableDictionary alloc] init];
            ORCaen792Model* obj = [actualCards objectForKey:aKey];
            if(!obj){
                NSArray* listOfCards = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORCaen792Model")];
                NSEnumerator* e = [listOfCards objectEnumerator];
                ORCaen792Model* aCard;
                while(aCard = [e nextObject]){
                    if([aCard slot] == card){
                        [actualCards setObject:aCard forKey:aKey];
                        obj = aCard;
                        break;
                    }
                }
            }

            [obj bumpRateFromDecodeStage:chan];

        }
    }
    return length;
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
	long length = ExtractLength(ptr[0]);
    NSString* title= @"CAEN792 QDC Record\n\n";
	
    NSString* len	=[NSString stringWithFormat: @"# QDC = %lu\n",length-2];
    NSString* crate = [NSString stringWithFormat:@"Crate = %lu\n",(ptr[1] >> 21)&0x0000000f];
    NSString* card  = [NSString stringWithFormat:@"Card  = %lu\n",(ptr[1] >> 16)&0x0000001f];    
	
    NSString* restOfString = [NSString string];
    int i;
    for( i = 2; i < length; i++ ){
		int dataType = ShiftAndExtract(ptr[i],24,0x7);
		if(dataType == 0x0){
			int qdcValue = ShiftAndExtract(ptr[i],0,0xfff);
			int channel  = [self channel:ptr[i]];
			restOfString = [restOfString stringByAppendingFormat:@"Chan  = %d  Value = %d\n",channel,qdcValue];
        }
    }
	
    return [NSString stringWithFormat:@"%@%@%@%@%@",title,len,crate,card,restOfString];               
}

- (unsigned short) channel: (unsigned long) pDataValue
{
    return	ShiftAndExtract(pDataValue,16,0x1F);
}
- (NSString*) identifier
{
    return @"CAEN 792 QDC";
}
- (NSString*) dataKey
{
    return @"CAEN792 QDC";
}
@end

@implementation ORCAEN792NDecoderForQdc

- (unsigned short) channel: (unsigned long) pDataValue
{
    return	ShiftAndExtract(pDataValue,17,0xF);
}
- (NSString*) identifier
{
    return @"CAEN 792N QDC";
}
- (NSString*) dataKey
{
    return @"CAEN792N QDC";
}

@end

