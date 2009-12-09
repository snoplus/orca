//
//  ORCaen965Decoder.m
//  Orca
//
//  Created by Mark Howe on Wed Dec 9, 2009.
//  Copyright (c) 2009 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Carolina reserve all rights in the program. Neither the authors,
//University of Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORCaen965Decoder.h"
#import "ORDataSet.h"

@implementation ORCaen965Decoder

- (unsigned long) decodeData:(void*) aSomeData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*) aDataSet
{
    short i;
    long* ptr = (long*) aSomeData;
    long length;
    NSString* crateKey;
    NSString* cardKey;
	length = *ptr & 0x3ffff;
	++ptr; //point to the header word with the crate and channel info
	crateKey = [self getCrateKey:(*ptr >> 21)&0x0000000f];
	cardKey  = [self getCardKey: (*ptr >> 16)&0x0000001f];
            
    ++ptr; //point past the header
    for( i = 0; i < length-2; i++ ){
        if( [self isHeader: *ptr] ){
            //ignore the header for now
        }
        else if( [self isValidDatum: *ptr] ){
            [aDataSet histogram:[self adcValue: *ptr] numBins:4096 sender:self 
                withKeys:[self identifier],
                crateKey,
                cardKey,
                [self getChannelKey:[self channel: *ptr]],
                nil];
        }
        else if( [self isEndOfBlock: *ptr] ){
            //ignore end of block for now
        }
        else if( [self isNotValidDatum: *ptr] ){
            NSLogError(@"",[NSString stringWithFormat:@"%@ Data Record Error",[self identifier]],crateKey,cardKey,nil);
        }
		++ptr;
    }
    return length;
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    unsigned long length = (ptr[0] & 0x003ffff);

    NSString* title= [NSString stringWithFormat:@"%@ Record\n\n",[self identifier]];
    
    NSString* len =[NSString stringWithFormat:   @"Record Length = %d\n",length-2];
    NSString* crate = [NSString stringWithFormat:@"Crate = %d\n",(ptr[1] >> 21)&0x0000000f];
    NSString* card  = [NSString stringWithFormat:@"Card  = %d\n",(ptr[1] >> 16)&0x0000001f];    
   
    NSString* restOfString = [NSString string];
    int i;
    for( i = 2; i < length; i++ ){
         if( [self isValidDatum: ptr[i]] ){
            restOfString = [restOfString stringByAppendingFormat:@"Chan  = %d  Value = %d\n",[self channel: ptr[i]],[self adcValue: ptr[i]]];
        }
    }

    return [NSString stringWithFormat:@"%@%@%@%@%@",title,len,crate,card,restOfString];               
}

@end

