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
	long length = ExtractLength(ptr[0]);
	NSString* crateKey = [self getCrateKey:ShiftAndExtract(ptr[1],21,0x0000000f)];
	NSString* cardKey  = [self getCardKey: ShiftAndExtract(ptr[1],16,0x0000001f)];
	int cardType       = ShiftAndExtract(ptr[1],0,0x1);
    for( i = 2; i < length; i++ ){
		int dataType = ShiftAndExtract(ptr[i],24,0x7);
		if(dataType == 0x000){
			int qdcValue = ShiftAndExtract(ptr[i],0,0xffff);
			int chan;
			if(cardType == 1)chan = ShiftAndExtract(ptr[i],18,0x7);
			else			 chan = ShiftAndExtract(ptr[i],17,0xf);
			NSString* channelKey  = [self getChannelKey: chan];
			[aDataSet histogram:qdcValue numBins:0xffff sender:self withKeys:@"CAEN965 QDC",crateKey,cardKey,channelKey,nil];
        }
    }
    return length;
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
	long length = ExtractLength(ptr[0]);
    NSString* title= @"CAEN965 QDC Record\n\n";

    NSString* len	=[NSString stringWithFormat: @"# QDC = %d\n",length-2];
    NSString* crate = [NSString stringWithFormat:@"Crate = %d\n",(ptr[1] >> 21)&0x0000000f];
    NSString* card  = [NSString stringWithFormat:@"Card  = %d\n",(ptr[1] >> 16)&0x0000001f];    
   
    NSString* restOfString = [NSString string];
    int i;
    for( i = 2; i < length; i++ ){
		int dataType = ShiftAndExtract(ptr[i],24,0x7);
		if(dataType == 0x000){
			int qdcValue = ShiftAndExtract(ptr[i],0,0xffff);
			int channel  = ShiftAndExtract(ptr[i],16,0xf);
			restOfString = [restOfString stringByAppendingFormat:@"Chan  = %d  Value = %d\n",channel,qdcValue];
        }
    }

    return [NSString stringWithFormat:@"%@%@%@%@%@",title,len,crate,card,restOfString];               
}

@end

