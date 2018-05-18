//
//  ORSIS3316Decoders.m
//  Orca
//
//  Created by Mark A. Howe on Wednesday 9/30/08.
//  Copyright (c) 2015 CENPA. University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolinaponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#import "ORSIS3316Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORDataTypeAssigner.h"
#import "ORSIS3316Model.h"

/*
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^^ ^^^^ ^^----------------------- Data ID (from header)
 -----------------^^ ^^^^ ^^^^ ^^^^ ^^^^- length
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 --------^-^^^--------------------------- Crate number
 -------------^-^^^^--------------------- Card number
 
 raw data follows:
 
  */

@implementation ORSIS3316WaveformDecoder
- (id) init

{
    self = [super init];
    getRatesFromDecodeStage = YES;
    return self;
}

- (void) dealloc
{
	[actualSIS3316Cards release];
    [super dealloc];
}

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr = (unsigned long*)someData;
	unsigned long length = ExtractLength(ptr[0]);
    int crate = (ptr[1]&0x01e00000)>>21;
    int card  = (ptr[1]&0x001f0000)>>16;
    int channel  = (ptr[1]&0x0000ff00)>>8;

	NSString* crateKey		= [self getCrateKey: crate];
    NSString* cardKey       = [self getCardKey: card];
    NSString* channelKey    = [self getChannelKey: channel];

	long numDataWords = length-2;
    unsigned char* bPtr = (unsigned char*)&ptr[2]; //ORCA header + TBD !!! work out what the raw header is
    NSData* recordAsData = [NSData dataWithBytes:bPtr length:numDataWords*sizeof(long)];


    [aDataSet loadWaveform:recordAsData
                    offset:9 * sizeof(unsigned long) //bytes!
                  unitSize:4 //unit size in bytes!
                      mask:0x3FFF
                    sender:self
                  withKeys:@"SIS3316", @"Waveforms",crateKey,cardKey,channelKey,nil];
    
    
    //get the actual object
    if(getRatesFromDecodeStage && !skipRateCounts){
        NSString* aKey = [crateKey stringByAppendingString:cardKey];
        if(!actualSIS3316Cards)actualSIS3316Cards = [[NSMutableDictionary alloc] init];
        ORSIS3316Model* obj = [actualSIS3316Cards objectForKey:aKey];
        if(!obj){
            NSArray* listOfCards = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORSIS3316Model")];
            NSEnumerator* e = [listOfCards objectEnumerator];
            ORSIS3316Model* aCard;
            while(aCard = [e nextObject]){
                if([aCard slot] == card){
                    [actualSIS3316Cards setObject:aCard forKey:aKey];
                    obj = aCard;
                    break;
                }
            }
        }
        getRatesFromDecodeStage = [obj bumpRateFromDecodeStage:channel];
    }
			

 
    return length; //must return number of longs
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"SIS3316 Waveform Record\n\n";
    NSString* crate = [NSString stringWithFormat:@"Crate = %lu\n",(ptr[1]&0x01e00000)>>21];
    NSString* card  = [NSString stringWithFormat:@"Card  = %lu\n",(ptr[1]&0x001f0000)>>16];

    return [NSString stringWithFormat:@"%@%@%@",title,crate,card];
}

@end
