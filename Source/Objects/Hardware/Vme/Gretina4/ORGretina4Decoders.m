//
//  ORGretina4Decoders.m
//  Orca
//
//  Created by Mark Howe on 02/07/07.
//  Copyright 2007 CENPA, University of Washington. All rights reserved.
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


#import "ORGretina4Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORDataTypeAssigner.h"

@implementation ORGretina4WaveformDecoder

- (unsigned long) decodeData:(void*)someData fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr = (unsigned long*)someData;
	unsigned long length = ExtractLength(*ptr);
	ptr++; //point to location info
    int crate = (*ptr&0x01e00000)>>21;
    int card  = (*ptr&0x001f0000)>>16;

	ptr++; //first word of the actual card packet
	int channel		 = *ptr&0xF;
	int packetLength = (*ptr>>16) - 7;
	
/*	ptr++; //point to led0-15 && 16-31
	unsigned short led1 = *ptr & 0xffff;
	unsigned short led2 = (*ptr & 0xffff0000)>>8;
 
	ptr++;
	unsigned short led3 = *ptr & 0xffff;

	NSLog(@"0x%08x 0x%08x 0x%08x\n",led3,led2,led1);
*/	
	ptr += 2; //point to Energy low word
	unsigned long energy = *ptr >> 16;
	ptr++;	  //point to Energy second word
	energy += (*ptr & 0x000001ff) << 16;
	
	// energy is in 2's complement, taking abs value if necessary
    //if((energy >> 22) & 0x1) energy = (~energy + 1) & 0x7fffff;

	NSString* crateKey = [self getCrateKey: crate];
	NSString* cardKey = [self getCardKey: card];
	NSString* channelKey = [self getChannelKey: channel];


    [aDataSet histogram:(energy & 0x3FFF) numBins:32768 sender:self  withKeys:@"Gretina4", @"Energy",crateKey,cardKey,channelKey,nil];
	
	ptr += 4; //point to the data

    NSMutableData* tmpData = [NSMutableData dataWithCapacity:512*2];
	
	//note:  there is something wrong here. The package length should be in longs but the
	//packet is always half empty.   
	[tmpData setLength:packetLength*sizeof(long)];
	unsigned short* dPtr = (unsigned short*)[tmpData bytes];
	int i;
	int wordCount = 0;
	for(i=0;i<packetLength;i++){
		dPtr[wordCount++] =	0x00003fff & *ptr;		
		dPtr[wordCount++] =	(0x3fff0000 & *ptr) >> 16;		
		ptr++;
	}
    [aDataSet loadWaveform:tmpData 
					offset:0 //bytes!
				  unitSize:2 //unit size in bytes!
					sender:self  
				  withKeys:@"Gretina4", @"Waveforms",crateKey,cardKey,channelKey,nil];
	 
    return length; //must return number of longs
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
	ptr++;

    NSString* title= @"Gretina4 Waveform Record\n\n";
    
    NSString* crate = [NSString stringWithFormat:@"Crate = %d\n",(*ptr&0x01e00000)>>21];
    NSString* card  = [NSString stringWithFormat:@"Card  = %d\n",(*ptr&0x001f0000)>>16];
	ptr++;
    NSString* chan  = [NSString stringWithFormat:@"Chan  = %d\n",*ptr&0x7];
	ptr+=2;
	unsigned long energy = *ptr >> 16;
	ptr++;	  //point to Energy second word
	energy += (*ptr & 0x0000007f) << 16;
	
	// energy is in 2's complement, taking abs value if necessary
    if((energy >> 22) & 0x1) energy = (~energy + 1) & 0x7fffff;
	NSString* energyStr  = [NSString stringWithFormat:@"Energy  = %d\n",energy];
    return [NSString stringWithFormat:@"%@%@%@%@%@",title,crate,card,chan,energyStr];               
}

@end
