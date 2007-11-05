//
//  ORDataGenDecoders.m
//  Orca
//
//  Created by Mark Howe on 9/22/04.
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


#import "ORDataGenDecoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORDataTypeAssigner.h"

#pragma mark •••Definitions

static NSString* kChanKey[8] = {
    //pre-make some keys for speed.
    @"Channel 0",  @"Channel 1",  @"Channel 2",  @"Channel 3",
    @"Channel 4",  @"Channel 5",  @"Channel 6",  @"Channel 7",
};

static NSString* kCardKey[8] = {
    //pre-make some keys for speed.
    @"Card 0",  @"Card 1",  @"Card 2",  @"Card 3",
    @"Card 4",  @"Card 5",  @"Card 6",  @"Card 7"

};


@implementation ORDataGenDecoderForTestData1D

- (NSString*) getChannelKey:(unsigned short)aChan
{
    if(aChan<32) return kChanKey[aChan];
    else return [NSString stringWithFormat:@"Channel %d",aChan];	
}

- (NSString*) getCardKey:(unsigned short)aCard
{
    if(aCard<16) return kCardKey[aCard];
    else return [NSString stringWithFormat:@"Card %d",aCard];			
}

- (unsigned long) decodeData:(void*)someData fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr = (unsigned long*)someData;
    unsigned long length = 2;
    ptr++;

    unsigned short crate = 0;
    unsigned short card  = (*ptr&0x000f0000)>>16;
    unsigned short chan  = (*ptr&0x0000f000)>>12;
    unsigned long  value = *ptr&0x00000fff;

    [aDataSet histogram:value numBins:4096  sender:self  withKeys:@"DataGen",
		kCardKey[card],
		kChanKey[chan],
        nil];
        
    if(gatesInstalled){
        [super prepareData:aDataSet crate:crate card:card channel:chan value:value];
    }
    
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"Data Gen Record\n\n";
    
    NSString* value  = [NSString stringWithFormat:@"Value = %d\n",ptr[1]&0x00000fff];    
    NSString* card  = [NSString stringWithFormat: @"Card  = %d\n",(ptr[1]&0x000f0000)>>16];    
    NSString* chan  = [NSString stringWithFormat: @"Chan  = %d\n",(ptr[1]&0x0000f000)>>12];    

    return [NSString stringWithFormat:@"%@%@%@%@",title,value,card,chan];               
}


@end

@implementation ORDataGenDecoderForTestData2D

- (NSString*) getChannelKey:(unsigned short)aChan
{
    if(aChan<32) return kChanKey[aChan];
    else return [NSString stringWithFormat:@"Channel %d",aChan];	
}

- (NSString*) getCardKey:(unsigned short)aCard
{
    if(aCard<16) return kCardKey[aCard];
    else return [NSString stringWithFormat:@"Card %d",aCard];			
}

- (unsigned long) decodeData:(void*)someData fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr = (unsigned long*)someData;
    unsigned long length = 3;

    [aDataSet histogram2DX:ptr[1]&0x00000fff y:ptr[2]&0x00000fff size:256  sender:self  withKeys:@"DataGen2D",
		kCardKey[(ptr[1]&0x000f0000)>>16],
		kChanKey[(ptr[1]&0x0000f000)>>12],
        nil];


    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"Data Gen Record (2D)\n\n";
    
    NSString* valueX  = [NSString stringWithFormat:@"ValueX = %d\n",ptr[1]&0x00000fff];    
    NSString* valueY  = [NSString stringWithFormat:@"ValueY = %d\n",ptr[2]&0x00000fff];    
    NSString* card  = [NSString stringWithFormat: @"Card  = %d\n",(ptr[1]&0x000f0000)>>16];    
    NSString* chan  = [NSString stringWithFormat: @"Chan  = %d\n",(ptr[1]&0x0000f000)>>12];    

    return [NSString stringWithFormat:@"%@%@%@%@%@",title,valueX,valueY,card,chan];               
}


@end


@implementation ORDataGenDecoderForTestDataWaveform

- (NSString*) getChannelKey:(unsigned short)aChan
{
    if(aChan<32) return kChanKey[aChan];
    else return [NSString stringWithFormat:@"Channel %d",aChan];	
}

- (NSString*) getCardKey:(unsigned short)aCard
{
    if(aCard<16) return kCardKey[aCard];
    else return [NSString stringWithFormat:@"Card %d",aCard];			
}

- (unsigned long) decodeData:(void*)someData fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr = (unsigned long*)someData;
    unsigned long length = ExtractLength(*ptr);
	NSData* data = [NSData dataWithBytes:&ptr[2] length:(length-2)*sizeof(long)];
    [aDataSet loadWaveform:data offset:0 unitSize:sizeof(long) sender:self withKeys:@"DataGenWaveform",
		kCardKey[(ptr[1]&0x000f0000)>>16],
		kChanKey[(ptr[1]&0x0000f000)>>12],
        nil];


    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"Data Gen Record (Waveform)\n\n";
    
    NSString* card  = [NSString stringWithFormat: @"Card  = %d\n",(ptr[1]&0x000f0000)>>16];    
    NSString* chan  = [NSString stringWithFormat: @"Chan  = %d\n",(ptr[1]&0x0000f000)>>12];    

    return [NSString stringWithFormat:@"%@%@%@",title,card,chan];               
}


@end