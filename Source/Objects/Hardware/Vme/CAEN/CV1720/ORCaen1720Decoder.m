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


//--------------------------------------------------------------------------------
// Implementation ORCaen1720Decoder
//--------------------------------------------------------------------------------
@implementation ORCaen1720Decoder
- (unsigned long) decodeData:(void*)someData fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr = (unsigned long*)someData;
	unsigned long length = ExtractLength(*ptr);

	ptr++; //point to location
	unsigned char crate   = (*ptr&0x01e00000)>>21;
	unsigned char card   = (*ptr& 0x001f0000)>>16;
	NSString* crateKey = [self getCrateKey: crate];
	NSString* cardKey = [self getCardKey: card];
	
   // [aDataSet histogram:*ptr&0x00000fff numBins:4096 sender:self  withKeys:@"Shaper", crateKey,cardKey,channelKey,nil];
	
    return length; //must return number of bytes processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
     
    return @"";               
}

@end

