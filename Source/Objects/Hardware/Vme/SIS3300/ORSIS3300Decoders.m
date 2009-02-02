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
				^^ ^^^^ ^^^^ ^^^^ ^^^^- length
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
--------^-^^^--------------------------- Crate number
             ^-^^^^--------------------- Card number
                                      ^- 1==SIS33001, 0==SIS3000 
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx -Trigger Event Word
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^^--------------------------------Event #
           ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^--Time from previous event
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
	int moduleID = (*ptr & 0x1);
	ptr++; //event trigger word
	unsigned long triggerWord= *ptr;
	
	ptr++; //point to the event# and timestamp (timestamp always zero unless in multievent mode)
	ptr++; //point to the data

	NSString* crateKey		= [self getCrateKey: crate];
	NSString* cardKey		= [self getCardKey: card];
	
	long numDataWords = length-4;
	//any of the channels may have triggered, so have to check each bit in the adc mask
	int channel;
	unsigned long aMask = moduleID?0x3fff:0xfff;
	for(channel=0;channel<8;channel++){
		if(triggerWord & (0x80000000 >> channel)){
			NSMutableData* tmpData = [NSMutableData dataWithLength:numDataWords*sizeof(short)];
			short* sPtr = (short*)[tmpData bytes];
			NSString* channelKey = [self getChannelKey: channel];
			int i;
			if(channel%2){
				for(i=0;i<(length-3);i++) {
					sPtr[i] = ptr[i] & aMask;	
				}
			}
			else {
				for(i=0;i<(length-3);i++) {
					sPtr[i] = (ptr[i]>>16) & aMask;	
				}
			}
			
			[aDataSet loadWaveform:tmpData
							offset:0 //bytes!
						  unitSize:2 //unit size in bytes!
							sender:self  
						  withKeys:@"SIS3300", @"Waveforms",crateKey,cardKey,channelKey,nil];
			
			//get the actual object
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
			
			
		}
	}

 
    return length; //must return number of longs
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
	ptr++;
    NSString* title= @"SIS3300 Waveform Record\n\n";
    NSString* crate = [NSString stringWithFormat:@"Crate = %d\n",(*ptr&0x01e00000)>>21];
    NSString* card  = [NSString stringWithFormat:@"Card  = %d\n",(*ptr&0x001f0000)>>16];
	NSString* moduleID = (*ptr&0x1)?@"SIS3301":@"SIS3300";
	ptr++;
	NSString* triggerWord = [NSString stringWithFormat:@"TriggerWord  = 0x08%x\n",*ptr];
	ptr++;
	NSString* Event = [NSString stringWithFormat:@"Event  = 0x08%x\n",(*ptr>>24)&0xff];
	NSString* Time = [NSString stringWithFormat:@"Time Since Last Trigger  = 0x08%x\n",*ptr&0xffffff];

    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@",title,crate,card,moduleID,triggerWord,Event,Time];               
}

@end
