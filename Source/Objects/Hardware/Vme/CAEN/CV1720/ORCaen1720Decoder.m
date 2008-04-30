//
//ORCaen1720Decoder.m
//Orca
//
//Created by Mark Howe on Mon Apr 14 2008.
//Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
//
//-------------------------------------------------------------
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
#import "ORCaen1720Decoder.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORCaen1720Model.h"
/*
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^^ ^^^^ ^^----------------------- Data ID (from header)
-----------------^^ ^^^^ ^^^^ ^^^^ ^^^^- length
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
--------^-^^^--------------------------- Crate number
-------------^-^^^^--------------------- Card number
--------------------------------------^- 1=Standard, 0=Pack2.5
....Followed by the event as described in the manual
*/

@implementation ORCaen1720WaveformDecoder

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

- (unsigned long) decodeData:(void*)someData fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr = (unsigned long*)someData;
	unsigned long length = ExtractLength(*ptr);
	ptr++; //point to location
	int crate = (*ptr&0x01e00000)>>21;
	int card  = (*ptr& 0x001f0000)>>16;
	NSString* crateKey	= [self getCrateKey: crate ];
	NSString* cardKey	= [self getCardKey:  card];
	
	ptr++; //point to start of event
	unsigned long eventSize = *ptr & 0x0fffffff;
    if ( eventSize != length - 2 ) return length;
	ptr++; //point to 2nd word of event
	unsigned long channelMask = *ptr & 0x000000ff;
	//NSLog(@"Channel Mask: %d Len: %d Size: %d\n",channelMask,length,eventSize);
	ptr++; //point to 3rd word of event
	ptr++; //point to 4th word of event
	ptr++; //point to start of data
	
	short numChans = 0;
	short chan[8];
	int i;
	for(i=0;i<8;i++){
		if(channelMask & (1<<i)){
			chan[numChans] = i;
			numChans++;
		}
	}
	eventSize -= 4;
	eventSize = eventSize/numChans;
    int j;
	for(j=0;j<numChans;j++){
		NSMutableData* tmpData = [NSMutableData dataWithCapacity:2*eventSize*sizeof(unsigned short)];
		
		[tmpData setLength:2*eventSize*sizeof(unsigned short)];
		unsigned short* dPtr = (unsigned short*)[tmpData bytes];
		int k;
		int wordCount = 0;
		for(k=0;k<eventSize;k++){
			dPtr[wordCount++] =	0x00000fff & *ptr;		
			dPtr[wordCount++] =	(0x0fff0000 & *ptr) >> 16;		
			ptr++;
		}
		[aDataSet loadWaveform:tmpData 
						offset:0 //bytes!
					  unitSize:2 //unit size in bytes!
						sender:self  
					  withKeys:@"CAEN1720", @"Waveforms",crateKey,cardKey,[self getChannelKey: chan[j]],nil];
					  
		if(getRatesFromDecodeStage){
			NSString* aKey = [crateKey stringByAppendingString:cardKey];
			if(!actualCards)actualCards = [[NSMutableDictionary alloc] init];
			ORCaen1720Model* obj = [actualCards objectForKey:aKey];
			if(!obj){
				NSArray* listOfCards = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORCaen1720Model")];
				NSEnumerator* e = [listOfCards objectEnumerator];
				ORCaen1720Model* aCard;
				while(aCard = [e nextObject]){
					if([aCard crateNumber] == crate && [aCard slot] == card){
						[actualCards setObject:aCard forKey:aKey];
						obj = aCard;
						break;
					}
				}
			}
			getRatesFromDecodeStage = [obj bumpRateFromDecodeStage:chan[j]];
		}

	}
	
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
     
    return @"";               
}

@end

