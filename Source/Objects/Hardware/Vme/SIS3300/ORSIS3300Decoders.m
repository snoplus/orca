//
//  ORSIS3300Decoders.m
//  Orca
//
//  Created by Mark A. Howe on Wednesday 9/30/08.
//  Copyright (c) 2008 CENPA. University of Washington. All rights reserved.
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

#import "ORSIS3300Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORDataTypeAssigner.h"
#import "ORSIS3300Model.h"

/*
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^^ ^^^^ ^^----------------------- Data ID (from header)
-----------------^^ ^^^^ ^^^^ ^^^^ ^^^^- length
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
--------^-^^^--------------------------- Crate number
-------------^-^^^^--------------------- Card number
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx -Trigger Event Word
waveform follows

*/

@implementation ORSIS3300WaveformDecoder
- (id) init

{
    self = [super init];
    getRatesFromDecodeStage = YES;
    return self;
}

- (void) dealloc
{
	[actualSIS3300Cards release];
    [super dealloc];
}

- (unsigned long) decodeData:(void*)someData fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr = (unsigned long*)someData;
	unsigned long length = ExtractLength(*ptr);
	ptr++; //point to location info
    int crate = (*ptr&0x01e00000)>>21;
    int card  = (*ptr&0x001f0000)>>16;

	ptr++; //event trigger word
	unsigned long triggerWord= *ptr;
	
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* cardKey		= [self getCardKey: card];

	ptr++; //point to the data

	unsigned long* dataStart = ptr;
	long numDataWords = length-3;
	NSMutableData* tmpData = [NSMutableData dataWithLength:numDataWords*sizeof(short)]; //plot buffer
	unsigned short* sPtr = (unsigned short*)[tmpData bytes];
	//any of the channels may have triggered, so have to check each bit in the adc mask
	int channel;
	BOOL loadedOnce = NO;
	for(channel=0;channel<8;channel+=2){
		if(triggerWord & (0x80000000 >> channel)){
			NSString* channelKey	= [self getChannelKey: channel];
			int i;
			if(!loadedOnce){
				for(i=0;i<(length-3);i++)sPtr[i] =	dataStart[i] & 0x3fff;	
				loadedOnce = YES;
			}
			[aDataSet loadWaveform:tmpData 
							offset:0 //bytes!
						  unitSize:2 //unit size in bytes!
							sender:self  
						  withKeys:@"SIS3300", @"Waveforms",crateKey,cardKey,channelKey,nil];
			
		}
	}
	//now the odd channels
	loadedOnce = NO;
	for(channel=1;channel<8;channel+=2){
		if(triggerWord & (0x80000000 >> channel)){
			NSString* channelKey	= [self getChannelKey: channel];
			int i;
			if(!loadedOnce){
				for(i=0;i<(length-3);i++)sPtr[i] =	(dataStart[i]>>16) & 0x3fff;	
				loadedOnce = YES;
			}
			[aDataSet loadWaveform:tmpData 
							offset:0 //bytes!
						  unitSize:2 //unit size in bytes!
							sender:self  
						  withKeys:@"SIS3300", @"Waveforms",crateKey,cardKey,channelKey,nil];
			
		}
	}

		/*		//get the actual object
		if(getRatesFromDecodeStage){
			NSString* aKey = [crateKey stringByAppendingString:cardKey];
			if(!actualSIS3300Cards)actualSIS3300Cards = [[NSMutableDictionary alloc] init];
			ORSIS3300Model* obj = [actualSIS3300Cards objectForKey:aKey];
			if(!obj){
				NSArray* listOfCards = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORSIS3300Model")];
				NSEnumerator* e = [listOfCards objectEnumerator];
				ORSIS3300Model* aCard;
				while(aCard = [e nextObject]){
					if([aCard slot] == card){
						[actualSIS3300Cards setObject:aCard forKey:aKey];
						obj = aCard;
						break;
					}
				}
			}
			getRatesFromDecodeStage = [obj bumpRateFromDecodeStage:channel];
		}
 */
	

	 
    return length; //must return number of longs
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
	ptr++;

    NSString* title= @"SIS3300 Waveform Record\n\n";
    
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
