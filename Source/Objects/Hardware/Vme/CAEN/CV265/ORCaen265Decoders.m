//
//  ORCaen265Decoders.m
//  Orca
//
//  Created by Mark Howe on 12/7/07
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


#import "ORCaen265Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORCaen265Model.h"
#import "ORDataTypeAssigner.h"

@implementation ORCaen265DecoderForAdc

- (unsigned long) decodeData:(void*)someData fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long length;
    unsigned long* ptr = (unsigned long*)someData;
	if(IsLongForm(*ptr))ptr++;
	unsigned char crate   = (*ptr&0x01e00000)>>21;
	unsigned char card   = (*ptr& 0x001f0000)>>16;
	NSString* crateKey = [self getCrateKey: crate];
	NSString* cardKey = [self getCardKey: card];
	if(IsLongForm(*ptr))ptr++;
	short chan = (*ptr >> 13) & 0x7;
	[aDataSet histogram:*ptr&0x00000fff numBins:4096 sender:self  withKeys:@"Caen265", crateKey,cardKey,[self getChannelKey: chan],nil];
    return length; //must return number of bytes processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"Caen265 ADC Record\n\n";
	if(IsLongForm(*ptr))ptr++;
    NSString* crate = [NSString stringWithFormat:@"Crate = %d\n",(*ptr&0x01e00000)>>21];
    NSString* card  = [NSString stringWithFormat:@"Card  = %d\n",(*ptr&0x001f0000)>>16];
	if(IsLongForm(*ptr))ptr++;
    NSString* chan  = [NSString stringWithFormat:@"Card  = %d\n",(*ptr>>13)&0x7];
	NSString* data  = [NSString stringWithFormat:@"Value = 0x%x\n",*ptr&0x00000fff];
	    
    return [NSString stringWithFormat:@"%@%@%@%@%@",title,crate,card,chan,data];               
}


@end

