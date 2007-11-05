//
//  ORIpeSLTDecoder.m
//  Orca
//
//  Created by Mark Howe on 9/30/07.
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


#import "ORIpeSLTDecoder.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORIpeSLTDefs.h"

@implementation ORIpeSLTDecoderForEvent

//-------------------------------------------------------------
/** Data format for event:
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^^ ^^^^ ^^-----------------------data id
                 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs

xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^--------------------------------spare
        ^ ^^^---------------------------crate
             ^ ^^^^---------------------card
					^^^^ ^^^^ ^^^^ ^^^^-spare
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx eventCounter
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx timeStamp Hi
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx timeStamp Lo
**/
//-------------------------------------------------------------

- (unsigned long) decodeData:(void*)someData fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr = (unsigned long*)someData;
	unsigned long length	= ExtractLength(*ptr);	 //get length from first word

    return length; //nothing to display at this time.. just return the length
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{

	NSString* title= @"Ipe SLT Event Record\n\n";
	++ptr;		//skip the first word (dataID and length)
    
    NSString* crate = [NSString stringWithFormat:@"Crate      = %d\n",(*ptr>>21) & 0xf];
    NSString* card  = [NSString stringWithFormat:@"Station    = %d\n",(*ptr>>16) & 0x1f];

	++ptr;		//point to event counter
	
	NSString* eventCounter    = [NSString stringWithFormat:@"Event     = %d\n",*ptr++];
	NSString* timeStampHi     = [NSString stringWithFormat:@"Time Hi   = %d\n",*ptr++];
	NSString* timeStampLo     = [NSString stringWithFormat:@"Time Lo   = %d\n",*ptr++];		

    return [NSString stringWithFormat:@"%@%@%@%@%@%@",title,crate,card,
	                    eventCounter,timeStampHi,timeStampLo];               

}
@end


@implementation ORIpeSLTDecoderForMultiplicity

//-------------------------------------------------------------
/** Data format for multiplicity
  *
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^^ ^^^^ ^^-----------------------data id
                 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs

xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^--------------------------------spare
        ^ ^^^---------------------------crate
             ^ ^^^^---------------------card
			        ^^^^ ^^^^ ^^^^ ^^^^-spare
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx eventCount
followed by multiplicity data (20 longwords -- 1 pixel mask per card)
  *
  */
//-------------------------------------------------------------


- (unsigned long) decodeData:(void*)someData fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet:(ORDataSet*)aDataSet
{

    unsigned long* ptr = (unsigned long*)someData;
	unsigned long length	= ExtractLength(*ptr);	 //get length from first word

	++ptr;											//crate, card,channel from second word
	unsigned char crate		= (*ptr>>21) & 0xf;
	unsigned char card		= (*ptr>>16) & 0x1f;
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* stationKey	= [self getStationKey: card];	
		
	++ptr;		//point to event count
	NSString* eventCount = [NSString stringWithFormat:@"%d",*ptr];
	[aDataSet loadGenericData:eventCount sender:self withKeys:@"EventCount",@"Ipe SLT", crateKey,stationKey,nil];
					
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{

    NSString* title= @"Auger FLT Waveform Record\n\n";
	++ptr;		//skip the first word (dataID and length)
    
    NSString* crate = [NSString stringWithFormat:@"Crate      = %d\n",(*ptr>>21) & 0xf];
    NSString* card  = [NSString stringWithFormat:@"Station    = %d\n",(*ptr>>16) & 0x1f];
	++ptr;		//point to next structure
	
	NSString* eventCount		= [NSString stringWithFormat:@"Event Count = %d\n",*ptr];

    return [NSString stringWithFormat:@"%@%@%@%@",title,crate,card,eventCount]; 
}

@end


