//
//  ORIpeV4FLTDecoder.m
//  Orca
//
//  Created by Mark Howe on 10/18/05.
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


#import "ORIpeV4FLTDecoder.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORIpeV4FLTDefs.h"

@implementation ORIpeV4FLTDecoderForEnergy

//-------------------------------------------------------------
/** Data format for energy mode:
 *
 <pre>
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^^ ^^^^ ^^-----------------------data id
                  ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs
 
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^--------------------------------spare
 ^ ^^^---------------------------crate
 ^ ^^^^---------------------card
 ^^^^ ^^^^ ----------channel
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx sec
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx subSec
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx 
 ^^^^ ^^^^------------------------------ channel (0..22)
 ^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ channel Map (22bit, 1 bit set denoting the channel number)  
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx 
 ^ ^^^^ ^^^^-------------------- number of page in hardware buffer
 ^^ ^^^^ ^^^^ eventID (0..1024)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx energy
 </pre>
 *
 */
//-------------------------------------------------------------


- (unsigned long) decodeData:(void*)someData fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr = (unsigned long*)someData;
	unsigned long length	= ExtractLength(*ptr);	 //get length from first word
	++ptr;										 
	//crate and card from second word
	unsigned char crate		= (*ptr>>21) & 0xf;
	unsigned char card		= (*ptr>>16) & 0x1f;
	unsigned char chan		= (*ptr>>8) & 0xff;
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* stationKey	= [self getStationKey: card];	
	NSString* channelKey	= [self getChannelKey: chan];	
	++ptr;	//point to the sec
	++ptr;	//point to the sub sec
	++ptr;	//point to the channel map
	++ptr;	//point to the eventID
	++ptr;	//point to the energy
		
	//channel by channel histograms
	unsigned long energy = *ptr/16;
	[aDataSet histogram:energy 
				numBins:65535 
				 sender:self  
			   withKeys: @"FLT",@"Energy",crateKey,stationKey,channelKey,nil];
	
	//accumulated card level histograms
	[aDataSet histogram:energy 
				numBins:65535 
				 sender:self  
			   withKeys: @"FLT",@"Total Card Energy",crateKey,stationKey,nil];
	
	//accumulated crate level histograms
	[aDataSet histogram:energy
				numBins:65535 
				 sender:self  
			   withKeys: @"FLT",@"Total Crate Energy",crateKey,nil];
	
	
	
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"Katrin FLT Energy Record\n\n";
	++ptr;		//skip the first word (dataID and length)
    
    NSString* crate = [NSString stringWithFormat:@"Crate      = %d\n",(*ptr>>21) & 0xf];
    NSString* card  = [NSString stringWithFormat:@"Station    = %d\n",(*ptr>>16) & 0x1f];
    NSString* chan  = [NSString stringWithFormat:@"Channel    = %d\n",(*ptr>>8)  & 0xff];
	
	
	/*
	++ptr;		//point to event struct
	katrinEventDataStruct* ePtr = (katrinEventDataStruct*)ptr;			//recast to event structure
	
	NSString* energy        = [NSString stringWithFormat:@"Energy     = %d\n",ePtr->energy];
	
	NSCalendarDate* theDate = [NSCalendarDate dateWithTimeIntervalSinceReferenceDate:(NSTimeInterval)ePtr->sec];
	NSString* eventDate     = [NSString stringWithFormat:@"Date       = %@\n", [theDate descriptionWithCalendarFormat:@"%m/%d/%y"]];
	NSString* eventTime     = [NSString stringWithFormat:@"Time       = %@\n", [theDate descriptionWithCalendarFormat:@"%H:%M:%S"]];
	
	NSString* seconds		= [NSString stringWithFormat:@"Seconds    = %d\n", ePtr->sec];
	NSString* subSec        = [NSString stringWithFormat:@"SubSeconds = %d\n", ePtr->subSec];
	NSString* eventID		= [NSString stringWithFormat:@"Event ID   = %d\n", ePtr->eventID & 0xffff];
    NSString* nPages		= [NSString stringWithFormat:@"Stored Pg  = %d\n", ePtr->eventID >> 16];
	NSString* chMap	    	= [NSString stringWithFormat:@"Channelmap = 0x%06x\n", ePtr->channelMap & 0x3fffff];	
	
	
    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@",title,crate,card,chan,
			energy,eventDate,eventTime,seconds,subSec,eventID,nPages,chMap];               
	*/ ///todo......
    return [NSString stringWithFormat:@"%@%@%@%@",title,crate,card,chan];
    	
	return @"to be done";
}
@end

@implementation ORIpeV4FLTDecoderForWaveForm

//-------------------------------------------------------------
/** Data format for waveform
  *
<pre>  
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^^ ^^^^ ^^-----------------------data id
                 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs

xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^--------------------------------spare
        ^ ^^^---------------------------crate
             ^ ^^^^---------------------card
			        ^^^^ ^^^^-----------channel
followed by waveform data (n x 1024 16-bit words)
</pre>
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
	unsigned char chan		= (*ptr>>8) & 0xff;
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* stationKey	= [self getStationKey: card];	
	NSString* channelKey	= [self getChannelKey: chan];
			
	// Set up the waveform
	NSData* waveFormdata = [NSData dataWithBytes:someData length:length*sizeof(long)];

	[aDataSet loadWaveform: waveFormdata					//pass in the whole data set
					offset: 2*sizeof(long)					// Offset in bytes (2 header words)
				    unitSize: sizeof(short)					// unit size in bytes
					mask:	0x0FFF							// when displayed all values will be masked with this value
					sender: self 
					withKeys: @"FLT", @"Waveform",crateKey,stationKey,channelKey,nil];
										
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{

    NSString* title= @"Ipe FLT Waveform Record\n\n";
	++ptr;		//skip the first word (dataID and length)
    
    NSString* crate = [NSString stringWithFormat:@"Crate      = %d\n",(*ptr>>21) & 0xf];
    NSString* card  = [NSString stringWithFormat:@"Station    = %d\n",(*ptr>>16) & 0x1f];
    NSString* chan  = [NSString stringWithFormat:@"Channel    = %d\n",(*ptr>>8) & 0xff];

    return [NSString stringWithFormat:@"%@%@%@%@",title,crate,card,chan]; 
}

@end

@implementation ORIpeV4FLTDecoderForHitRate

//-------------------------------------------------------------
/** Data format for hit rate mode:
 *
 <pre>
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^^ ^^^^ ^^-----------------------data id
                  ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs
 
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^--------------------------------spare
         ^ ^^^---------------------------crate
              ^ ^^^^---------------------card
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx sec
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx hitRate length
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx total hitRate
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx 
      ^^^^ ^^^^-------------------------- channel (0..22)
			       ^--------------------- overflow  
				     ^^^^ ^^^^ ^^^^ ^^^^- hitrate
 ...more 
 </pre>
 *
 */
//-------------------------------------------------------------


- (unsigned long) decodeData:(void*)someData fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr = (unsigned long*)someData;
	unsigned long length	= ExtractLength(*ptr);	 //get length from first word
	++ptr;										 
	//crate and card from second word
	unsigned char crate		= (*ptr>>21) & 0xf;
	unsigned char card		= (*ptr>>16) & 0x1f;
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* stationKey	= [self getStationKey: card];	
	++ptr;	//point to the sec
	unsigned long seconds= *ptr;
	++ptr;	//point to hit rate length
	++ptr;	//point to total hitrate
	unsigned long hitRateTotal = *ptr;
	++ptr;	//point to total hitrate
	int i;
	int n = length - 5;
	for(i=0;i<n;i++){
		NSString* channelKey	= [self getChannelKey: (*ptr>>20) & 0xff];	
		unsigned long hitRate = *ptr & 0xffff;
		[aDataSet histogram:hitRate
					numBins:65536 
					 sender:self  
				   withKeys: @"FLT",@"HitrateHistogram",crateKey,stationKey,channelKey,nil];
		++ptr;
	}
	
	[aDataSet loadTimeSeries: hitRateTotal
                      atTime:seconds
					  sender:self  
					withKeys: @"FLT",@"HitrateTimeSeries",crateKey,stationKey,nil];
	
	
	
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"Katrin FLT Hit Rate Record\n\n";
	++ptr;		//skip the first word (dataID and length)
    
    NSString* crate = [NSString stringWithFormat:@"Crate      = %d\n",(*ptr>>21) & 0xf];
    NSString* card  = [NSString stringWithFormat:@"Station    = %d\n",(*ptr>>16) & 0x1f];
	
    return [NSString stringWithFormat:@"%@%@%@",title,crate,card];
	
	return @"to be done";
}
@end


