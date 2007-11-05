//
//  ORCMC203Decoders.m
//  Orca
//
//  Created by Mark Howe on 9/21/04.
//  Copyright 2004 CENPA, University of Washington. All rights reserved.
//

#import "ORCMC203Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORCMC203Model.h"
#import "ORDataTypeAssigner.h"

@implementation ORCMC203DecoderForAdc

- (id) init
{
    self = [super init];
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (unsigned long) decodeData:(void*)someData fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long length;
    unsigned long* ptr = (unsigned long*)someData;
    if(IsShortForm(*ptr) || [aDataPacket version]<2){
        length = 1;
    }
    else  {       //oh, we have been assign the long form--skip to the next long word for the data
        ptr++;
        length = 2;
    }
    
	unsigned char crate   = (*ptr&0x01e00000)>>21;
	unsigned char card   = (*ptr& 0x001f0000)>>16;
	unsigned char channel = (*ptr&0x0000f000)>>12;
	NSString* crateKey = [self getCrateKey: crate];
	NSString* cardKey = [self getStationKey: card];
	NSString* channelKey = [self getChannelKey: channel];
    unsigned long  value = *ptr&0x00000fff;
	
    [aDataSet histogram:value numBins:2048 sender:self  withKeys:@"CMC203", crateKey,cardKey,channelKey,nil];

    if(gatesInstalled){
        [super prepareData:aDataSet crate:crate card:card channel:channel value:value];
    }
    
    return length; //must return number of bytes processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    if(!IsShortForm(*ptr)){
        ptr++;
    }
    
    NSString* title= @"CMC203 ADC Record\n\n";
    
    NSString* crate = [NSString stringWithFormat:@"Crate    = %d\n",(*ptr&0x01e00000)>>21];
    NSString* card  = [NSString stringWithFormat:@"Station  = %d\n",(*ptr&0x001f0000)>>16];
    NSString* chan  = [NSString stringWithFormat:@"Chan     = %d\n",(*ptr&0x0000f000)>>12];
    NSString* adc   = [NSString stringWithFormat:@"ADC      = 0x%x\n",*ptr&0x00000fff];
    
    return [NSString stringWithFormat:@"%@%@%@%@%@",title,crate,card,chan,adc];               
}


@end

