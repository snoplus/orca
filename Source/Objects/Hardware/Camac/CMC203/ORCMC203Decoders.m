//
//  ORCMC203Decoders.m
//  Orca
//
//  Created by Mark Howe on 8/5/05.
//  Copyright 2004 CENPA, University of Washington. All rights reserved.
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


#import "ORCMC203Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORCMC203Model.h"

@implementation ORCMC203DecoderForHistogram
- (id) init
{
    self = [super init];
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

//---------------------------------------------------------------
//Data format
/*
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^^ ^^^^ ^^-----------------------data id
                 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs

xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
        ^ ^^^---------------------------crate
             ^ ^^^^---------------------card
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx-total histo counts ls part
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx-total histo counts ms part
//followed by the histogram data to fill out the required number of longs
*/
//--------------------------------------------------------------------


- (unsigned long) decodeData:(void*)someData fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr = (unsigned long*)someData;
    unsigned long length = ExtractLength(*ptr); //get the length

	ptr++;
	unsigned char crate  = (*ptr>>21) & 0xf;
	unsigned char card   = (*ptr>>16) & 0x1f;
 	NSString* crateKey		= [self getCrateKey: crate];
	NSString* cardKey		= [self getCardKey: card];
	ptr++; //point to ls count
	ptr++; //point ms count
	ptr++; //point to data
	[aDataSet loadWaveform:someData 
					offset:2*sizeof(long)	//bytes!
				  unitSize:sizeof(long)		//unit size in bytes!
					sender:self  
				  withKeys:@"MC203", @"Histogram",crateKey,cardKey,nil];
	
    return length; //must return number of bytes processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)someData
{
    NSMutableString* totalString = [NSMutableString stringWithCapacity:1024];
    [totalString appendString:@"CMC203 Histogram\n\n"]; 

    unsigned long* ptr = (unsigned long*)someData;
	unsigned long length = ExtractLength(ptr[0]) - kCMC203ReservedHistoHeaderWords; //get the length
   
	[totalString appendString:[NSString stringWithFormat:@"Crate    = %d\n",(ptr[1]>>21) & 0xf]];
    [totalString appendString:[NSString stringWithFormat:@"Station  = %d\n",(ptr[1]>>16) & 0x1f]];
    [totalString appendString:[NSString stringWithFormat:@"Total Count  = %d %d\n",ptr[3],ptr[2]]];
    [totalString appendString:[NSString stringWithFormat:@"Histogram Length = %d\n",length]]; 
	
    return totalString;               
}
@end

@implementation ORCMC203DecoderForFifo
- (id) init
{
    self = [super init];
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

//---------------------------------------------------------------
//Data format
/*
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^^ ^^^^ ^^-----------------------data id
				  ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
         ^ ^^^---------------------------crate
		      ^ ^^^^---------------------card
 //followed by the data to fill out the required number of longs
 */
//--------------------------------------------------------------------


- (unsigned long) decodeData:(void*)someData fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr = (unsigned long*)someData;
    unsigned long length = ExtractLength(*ptr); //get the length
	
	ptr++;
	unsigned char crate  = (*ptr>>21) & 0xf;
	unsigned char card   = (*ptr>>16) & 0x1f;
 	NSString* crateKey		= [self getCrateKey: crate];
	NSString* cardKey		= [self getCardKey: card];
	
	int i;
	for(i=0;i<length-kCMC203ReservedFifoHeaderWords;i++){
		ptr++;
		[aDataSet histogram:*ptr numBins:8192 sender:self  withKeys:@"MC203",@"FIFO Histogram",crateKey,cardKey,nil];
	}
    return length; //must return number of bytes processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)someData
{
    NSMutableString* totalString = [NSMutableString stringWithCapacity:1024];
    [totalString appendString:@"CMC203 Histogram\n\n"]; 
	
    unsigned long* ptr = (unsigned long*)someData;
	unsigned long length = ExtractLength(ptr[0]) - kCMC203ReservedFifoHeaderWords; //get the length
	
	[totalString appendString:[NSString stringWithFormat:@"Crate    = %d\n",(ptr[1]>>21) & 0xf]];
    [totalString appendString:[NSString stringWithFormat:@"Station  = %d\n",(ptr[1]>>16) & 0x1f]];
    [totalString appendString:[NSString stringWithFormat:@"Record Length  = %d\n",length]]; 
	
    return totalString;               
}


@end


