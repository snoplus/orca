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
- (unsigned long) decodeData:(void*)someData fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr = (unsigned long*)someData;
	unsigned long length = ExtractLength(*ptr);

	ptr++; //point to location
	NSString* crateKey	= [self getCrateKey: (*ptr&0x01e00000)>>21];
	NSString* cardKey	= [self getCardKey: (*ptr& 0x001f0000)>>16];
	BOOL packed = *ptr& 0x00000001;
	
	ptr++; //point to start of event
	//unsigned long eventSize = *ptr & 0x0fffffff;
	
	ptr++; //point to 2nd word
	unsigned long channelMask = *ptr & 0x0000000f;
	short numChans = 0;
	short chan[8];
	int i;
	for(i=0;i<8;i++){
		if(channelMask & (1<<i)){
			chan[numChans] = i;
			numChans++;
		}
	}
	for(i=0;i<numChans;i++){
//		NSMutableData* tmpData = [NSMutableData dataWithCapacity:512*2];
		
//		[tmpData setLength:packetLength*sizeof(long)];
//		unsigned short* dPtr = (unsigned short*)[tmpData bytes];
//		int i;
//		int wordCount = 0;
//		for(i=0;i<packetLength;i++){
//			dPtr[wordCount++] =	0x00000fff & *ptr;		
//			dPtr[wordCount++] =	(0x0fff0000 & *ptr) >> 16;		
//			ptr++;
//		}
//		[aDataSet loadWaveform:tmpData 
//						offset:0 //bytes!
//					  unitSize:2 //unit size in bytes!
//						sender:self  
//					  withKeys:@"Gretina", @"Waveforms",crateKey,cardKey,channelKey,nil];
	}
    return length; //must return number of bytes processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
     
    return @"";               
}

@end

