//
//  ORKatrinFLTDecoder.m
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


#import "ORKatrinFLTDecoder.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORKatrinFLTDefs.h"

@implementation ORKatrinFLTDecoderForEnergy

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
	katrinEventDataStruct* ePtr;

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
	++ptr;	
	
	// Get the global data from the first event
    // ptr to event data
	ePtr = (katrinEventDataStruct*) ptr;			//recast to event structure

    //NSLog(@"Channel %08x - %8d %8d\n", ePtr->channelMap, ePtr->sec, ePtr->subSec);
			
	[aDataSet histogram:ePtr->energy 
					  numBins:32768 
					  sender:self  
					  withKeys: @"FLT",@"Energy",crateKey,stationKey,channelKey,nil];

    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"Katrin FLT Energy Record\n\n";
	++ptr;		//skip the first word (dataID and length)
    
    NSString* crate = [NSString stringWithFormat:@"Crate      = %d\n",(*ptr>>21) & 0xf];
    NSString* card  = [NSString stringWithFormat:@"Station    = %d\n",(*ptr>>16) & 0x1f];
    NSString* chan  = [NSString stringWithFormat:@"Channel    = %d\n",(*ptr>>8)  & 0xff];

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
	NSString* chMap	    	= [NSString stringWithFormat:@"Channelmap = 0x%06x\n", ePtr->channelMap & 0x3ffff];	
		

    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@",title,crate,card,chan,
	                    energy,eventDate,eventTime,seconds,subSec,eventID,nPages,chMap];               

}
@end


@implementation ORKatrinFLTDecoderForWaveForm

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
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx sec
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx subSec
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx 
^^^^ ^^^^------------------------------ channel (0..22)
            ^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ channel Map (22bit, 1 bit set denoting the channel number)  
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx 
        ^ ^^^^ ^^^^-------------------- number of page in hardware buffer
		                   ^^ ^^^^ ^^^^ eventID (0..1024)
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx energy
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx sec of restart
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx subsec of restart 
followed by waveform data (n x 1024 16-bit words)
</pre>
  *
  * All data is stored in the orignal format except for the short data type arrays of the waveform data. 
  * The litle endian machines will store the orignal data that comes from the electronics. 
  * The electronics uses also little endian byte order. The organisation is as follows
<pre>  
1H 1L 2H 2L 3H 3L 4H 4L ...
</pre>
  *
  * The big endian machines will swap the bytes (under the assumption of a long array)
  *
<pre>
2L 2H 2L 1H 4L 4H 3L 3H ...
</pre>
  * This is the byte format stored by the big endian machines.
  * In order to display the waveforms in the correct order a second correction is necessary
  * Before display 1 -2, 3 -4 , .. have to be changed.
  * The little endian machines will apply the normal endian swap to the stored data 
  * and can display the data correctly without any further operation.
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
		
	++ptr;		//point to event struct
	
	
	katrinEventDataStruct* ePtr = (katrinEventDataStruct*) ptr;
	
	[aDataSet histogram:ePtr->energy 
			  numBins:32768 
			  sender:self  
			  withKeys: @"FLT",@"Energy",crateKey,stationKey,channelKey,nil];

	
	// Change order of shorts in the ADC trace for PowerPC CPUs	
	// Note: This the endian swap itself is handled by the firewire drivers.
	//       The swap of the shorts has been moved from the model code
	// ak, 29.2.08
	if (ntohl(1) == 1) { // big endian host
		// Point to ADC data
		ptr += (sizeof(katrinEventDataStruct)+sizeof(katrinDebugDataStruct))/sizeof(unsigned long);
		
		// The order of the shorts has to be switched (endianess)
		int i;
		int traceLen = (length / 512) * 512;
		
		for (i=0;i< traceLen;i++)
		    ptr[i] = (ptr[i] >> 16)  |  (ptr[i] << 16);
    }
	
	// Set up the waveform
	NSData* waveFormdata = [NSData dataWithBytes:someData length:length*sizeof(long)];


	[aDataSet loadWaveform: waveFormdata							//pass in the whole data set
					offset: (2*sizeof(long)+sizeof(katrinEventDataStruct)+sizeof(katrinDebugDataStruct))/2	// Offset in bytes (2 header words + katrinEventDataStruct)
				    unitSize: sizeof(short)							// unit size in bytes
					sender: self 
					withKeys: @"FLT", @"Waveform",crateKey,stationKey,channelKey,nil];
					

    ptr = ptr + (sizeof(katrinEventDataStruct) + sizeof(katrinDebugDataStruct)) / sizeof(long);
	//NSLog(@" len = %d (%d), %x %x %x\n", length, ptr - (unsigned long *) someData , ptr[0], ptr[1], ptr[2]);
					
    return length; //must return number of longs processed.
}


- (NSString*) dataRecordDescription:(unsigned long*)ptr
{

    NSString* title= @"Katrin FLT Waveform Record\n\n";
	++ptr;		//skip the first word (dataID and length)
    
    NSString* crate = [NSString stringWithFormat:@"Crate      = %d\n",(*ptr>>21) & 0xf];
    NSString* card  = [NSString stringWithFormat:@"Station    = %d\n",(*ptr>>16) & 0x1f];
    NSString* chan  = [NSString stringWithFormat:@"Channel    = %d\n",(*ptr>>8) & 0xff];
	++ptr;		//point to next structure
	
	katrinEventDataStruct* ePtr = (katrinEventDataStruct*)ptr;			//recast to event structure
	
	NSString* energy		= [NSString stringWithFormat:@"Energy     = %d\n",ePtr->energy];

	NSCalendarDate* theDate = [NSCalendarDate dateWithTimeIntervalSinceReferenceDate:(NSTimeInterval)ePtr->sec];
	NSString* eventDate     = [NSString stringWithFormat:@"Date       = %@\n", [theDate descriptionWithCalendarFormat:@"%m/%d/%y"]];
	NSString* eventTime     = [NSString stringWithFormat:@"Time       = %@\n", [theDate descriptionWithCalendarFormat:@"%H:%M:%S"]];

	NSString* seconds		= [NSString stringWithFormat:@"Seconds    = %d\n", ePtr->sec];
	NSString* subSec    	= [NSString stringWithFormat:@"Subseconds = %d\n", ePtr->subSec];
	NSString* eventID		= [NSString stringWithFormat:@"Event ID   = %d\n", ePtr->eventID & 0xffff];
	NSString* chMap   		= [NSString stringWithFormat:@"Channelmap = 0x%06x\n", ePtr->channelMap & 0x3ffff];	


    // Decode extra debug information
	ptr = ptr + sizeof(katrinEventDataStruct) / sizeof(unsigned long);
	katrinDebugDataStruct* dPtr = (katrinDebugDataStruct*) ptr;

	NSString* resetSec		= [NSString stringWithFormat:@"ResetSec   = %d\n", dPtr->resetSec];
	NSString* resetSubSec  	= [NSString stringWithFormat:@"ResetSubSec= %d\n", dPtr->resetSubSec];


    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@%@",title,crate,card,chan,
	                       energy,eventDate,eventTime,seconds,subSec,eventID,chMap,
	                       resetSec,resetSubSec]; 
}



@end


@implementation ORKatrinFLTDecoderForHitRate

//-------------------------------------------------------------
/** Data format for frequency plot
  *
  * - Threshold 16bit 0..65000
  * - Frequency 23bit + 1 bit overflow  
  *
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
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx 
^^^^ ^^^^------------------------------ channel (0..22)
            ^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ channel Map (22bit, 1 bit set denoting the channel number) 
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx Threshold
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx Hitrate
</pre>
  *
  */
//-------------------------------------------------------------


- (unsigned long) decodeData:(void*)someData fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet:(ORDataSet*)aDataSet
{
    int i;
	//int j;
	//int mult;
	int width;
	int energy;

    unsigned long* ptr = (unsigned long*)someData;
	unsigned long length	= ExtractLength(*ptr);	 //get length from first word
	++ptr;										 //crate and card from second word
	
	unsigned char crate		= (*ptr>>21) & 0xf;
	unsigned char card		= (*ptr>>16) & 0x1f;
	unsigned char chan		= (*ptr>>8) & 0xff;
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* stationKey	= [self getStationKey: card];	
	NSString* channelKey	= [self getChannelKey: chan];
	++ptr;		//point to event struct
	
	
	katrinHitRateDataStruct* ePtr = (katrinHitRateDataStruct*) ptr;
	
/*
    // Calculate the multiplicity of the bin 
	// TODO: Check the relation between threshold and energy
	energy = ePtr->threshold << 1; 
	width = energy - lastEnergy[chan];
	mult =  lastHitrate[chan] - ePtr->hitrate;  // / width ?!
    mult =  ((float) mult) / width;


	//NSLog(@"Data arrived in ch %d: width = %d, mult = %d rate = %d / %d, energy=%d %d\n", 
	//        chan, width, mult, ePtr->hitrate, lastHitrate[chan], 
	//		energy, lastEnergy[chan]);

    // Fill in the number 
	if (lastEnergy[chan] > 0){
	  for (i=lastEnergy[chan]; i< energy;i++){
	    for (j=0;j<mult;j++){
		  [aDataSet histogram:i
					  numBins:32768 
					  sender:self  
					  withKeys: @"FLT",@"Hitrate",crateKey,stationKey,channelKey,nil];
		}			  
	  }
	}  
*/	


    // Display the hitrates
	// TODO: Howto plot a list of points?!
	// Plot: (ePtr->threshold, ePtr->hitrate)
	//
	energy = ePtr->threshold; 
	width = energy - lastEnergy[chan];
	
	//NSLog(@"Hitrate: (%d .. %d) - %d\n", lastEnergy[chan], energy, width);
	 
	if (lastEnergy[chan] > 0){
	  for (i=lastEnergy[chan]+1;i<=energy;i++){
	    [aDataSet histogramWW:i
		              weight:ePtr->hitrate
					  numBins:32768 
					  sender:self  
					  withKeys: @"FLT",@"Hitrate",crateKey,stationKey,channelKey,nil];
	  }
	}  	
	
	lastEnergy[chan] = energy;
	lastHitrate[chan] = ePtr->hitrate;

    return length; //must return number of longs processed.

}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{

    NSString* title= @"Katrin FLT Hitrate Record\n\n";
	++ptr;		//skip the first word (dataID and length)
    
    NSString* crate     = [NSString stringWithFormat:@"Crate      = %d\n",(*ptr>>21) & 0xf];
    NSString* card      = [NSString stringWithFormat:@"Station    = %d\n",(*ptr>>16) & 0x1f];
    NSString* chan      = [NSString stringWithFormat:@"Channel    = %d\n",(*ptr>>8) & 0xff];
	++ptr;		//point to next structure
	
	katrinHitRateDataStruct* ePtr = (katrinHitRateDataStruct*)ptr;			//recast to event structure
	
	NSString* threshold	= [NSString stringWithFormat:@"Threshold  = %d\n",ePtr->threshold];
	NSString* hitrate	= [NSString stringWithFormat:@"Hitrate    = %d\n",ePtr->hitrate];
	NSString* chMap   	= [NSString stringWithFormat:@"Channelmap = 0x%06x\n", ePtr->channelMap & 0x3ffff];	

    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@",title,crate,card,chan,
	                       threshold,hitrate,chMap];
}

@end
