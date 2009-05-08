//
//  OR1DHistoDecoders.m
//  Orca
//
//  Created by Mark Howe on 9/21/04.
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


#import "ORMCA927Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "OR1DHisto.h"

@implementation ORMCA927SpectraDecoder

- (unsigned long) decodeData:(void*)someData fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr	 = (unsigned long*)someData;
    unsigned long length = ExtractLength(*ptr);
	ptr++; //location info
	int channel	 = (*ptr>>12)&0x1;
	int device	 = *ptr&0xFFF;
	NSString* channelKey = [self getChannelKey: channel];

	NSMutableData* tmpData = [NSMutableData dataWithLength:(length-10)*sizeof(long)];
	unsigned long* lPtr = (unsigned long*)[tmpData bytes];
	int i;
	//skip the spares
	ptr++;
	ptr++;
	ptr++;
	ptr++;
	ptr++;
	ptr++;
	ptr++;
	ptr++;

	for(i=0;i<length-10;i++){
		*lPtr++ = *ptr++;
	}
	[aDataSet loadSpectrum:tmpData 
				sender:self  
				  withKeys:[NSString stringWithFormat: @"MCA927 (%d)",device], @"Spectra",channelKey,nil];
	
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{    
    NSString* title= @"MCA927 Spectra Record\n\n";
    unsigned long spectrumLength = ExtractLength(*ptr) - 10;
	
    ptr++; //point at location;
    unsigned long channel = (*ptr>>12) & 0x1;
    unsigned long objectID = (*ptr) & 0xfff;
    ptr++; //point at liveTime
	float liveTime = *ptr * 0.02; //in seconds
    ptr++; //point at realTime
	float realTime = *ptr * 0.02; //in seconds
	
    return [NSString stringWithFormat:@"%@\nMCA927 (%d)\nChannel: %d\nLiveTime: %.2f\nRealTime: %.2f\n\nSpectum Length: %d",title,objectID,channel,liveTime,realTime,spectrumLength];               
}


@end

