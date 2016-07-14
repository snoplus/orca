//
//  ORKatrinV4SLTDecoder.m
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


#import "ORKatrinV4SLTDecoder.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORKatrinV4SLTDefs.h"

@implementation ORKatrinV4SLTDecoderForEvent

//-------------------------------------------------------------
/** Data format for event:
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^^ ^^^^ ^^-----------------------data id
                 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs

xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^--------------------------------spare
        ^ ^^^---------------------------crate
             ^ ^^^^---------------------card
					^^^^ ^^^^-----------spare
					          ^^^^------counter type
					               ^^^^-record type (sub type)
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx eventCounter (when record type != 0 see below)
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx timeStamp Hi
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx timeStamp Lo
when record type != 0 the eventCounter is 0 (has no meaning) and for
record type = 1 = kStartRunType:	the timestamp is a run start timestamp
record type = 2 = kStopRunType:		the timestamp is a run stop timestamp
record type = 3 = kStartSubRunType: the timestamp is a subrun start timestamp
record type = 4 = kStopSubRunType:	the timestamp is a subrun stop timestamp

counter type = kSecondsCounterType, kVetoCounterType, kDeadCounterType, kRunCounterType
1:
**/
//-------------------------------------------------------------

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr = (unsigned long*)someData;
	unsigned long length	= ExtractLength(*ptr);	 //get length from first word
	[aDataSet loadGenericData:@" " sender:self withKeys:@"v4SLT",@"Test Record",nil];
    return length; //nothing to display at this time.. just return the length
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{

	NSString* title= @"Ipe SLTv4 Event Record\n\n";
	++ptr;		//skip the first word (dataID and length)
    
    NSString* crate = [NSString stringWithFormat:@"Crate      = %lu\n",(*ptr>>21) & 0xf];
    NSString* card  = [NSString stringWithFormat:@"Station    = %lu\n",(*ptr>>16) & 0x1f];
	int recordType = (*ptr) & 0xf;
	int counterType = ((*ptr)>>4) & 0xf;
	
	++ptr;		//point to event counter
	
	if (recordType == 0) {
		NSString* eventCounter    = [NSString stringWithFormat:@"Event     = %lu\n",*ptr++];
		NSString* timeStampHi     = [NSString stringWithFormat:@"Time Hi   = %lu\n",*ptr++];
		NSString* timeStampLo     = [NSString stringWithFormat:@"Time Lo   = %lu\n",*ptr];

		return [NSString stringWithFormat:@"%@%@%@%@%@%@",title,crate,card,
							eventCounter,timeStampHi,timeStampLo];               
	}
	
	++ptr;		//skip event counter
	//timestamp events
	NSString* counterString;
	switch (counterType) {
		case kSecondsCounterType:	counterString    = [NSString stringWithFormat:@"Seconds Counter\n"]; break;
		case kVetoCounterType:		counterString    = [NSString stringWithFormat:@"Veto Counter\n"]; break;
		case kDeadCounterType:		counterString    = [NSString stringWithFormat:@"Deadtime Counter\n"]; break;
		case kRunCounterType:		counterString    = [NSString stringWithFormat:@"Run  Counter\n"]; break;
		default:					counterString    = [NSString stringWithFormat:@"Unknown Counter\n"]; break;
	}
	NSString* typeString;
	switch (recordType) {
		case kStartRunType:		typeString    = [NSString stringWithFormat:@"Start Run Timestamp\n"]; break;
		case kStopRunType:		typeString    = [NSString stringWithFormat:@"Stop Run Timestamp\n"]; break;
		case kStartSubRunType:	typeString    = [NSString stringWithFormat:@"Start SubRun Timestamp\n"]; break;
		case kStopSubRunType:	typeString    = [NSString stringWithFormat:@"Stop SubRun Timestamp\n"]; break;
		default:				typeString    = [NSString stringWithFormat:@"Unknown Timestamp Type\n"]; break;
	}
	NSString* timeStampHi     = [NSString stringWithFormat:@"Time Hi   = %lu\n",*ptr++];
	NSString* timeStampLo     = [NSString stringWithFormat:@"Time Lo   = %lu\n",*ptr];		

	return [NSString stringWithFormat:@"%@%@%@%@%@%@%@",title,crate,card,
						counterString,typeString,timeStampHi,timeStampLo];               
}
@end









@implementation ORKatrinV4SLTDecoderForEventFifo

//-------------------------------------------------------------
/** Data format for event:
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^^ ^^^^ ^^-----------------------data id
 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs
 
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^--------------------------------spare
 ^ ^^^---------------------------crate
 ^ ^^^^---------------------card
 ^^^^ ^^^^-----------spare
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx Spare 1
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx Spare 2
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx EventFifo 1
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx EventFifo 2
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx EventFifo 3
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx EventFifo 4
 and optionally more blocks consisting of 4 word32s, containing EventFifo 1...4,
 max. number of blocks: 8192 (which is the max. DMA readout block) -tb-
 
 **/
//-------------------------------------------------------------

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr = (unsigned long*)someData;
	unsigned long length	= ExtractLength(*ptr);	 //get length from first word
	[aDataSet loadGenericData:@" " sender:self withKeys:@"v4SLT",@"Event Fifo Records",nil];
    
    /*
     //for debugging/testing -tb-
     int i=0;
     
     NSLog(@"EventFifoRecordLen: %i\n",length);
     int showMax=length;
     if(showMax>12){showMax=12;}
     for(i=2;i<showMax; i++){
     NSLog(@"word %i: 0x%08x\n",i,*(ptr+i));
     }
     */
    
    
    return length; //nothing to display at this time.. just return the length
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    
	NSString* title= @"Ipe SLTv4 Event FIFO Record\n\n";
    unsigned long numEv,numCrate,numCard;
    numEv=((*ptr) & 0x3ffff)/4-1;
    NSString* content=[NSString stringWithFormat:@"Num.Eevents= %lu\n",((*ptr) & 0x3ffff)/4-1];
    
    
	++ptr;		//skip the first word (dataID and length)
    numCrate=(*ptr>>21) & 0xf;
    numCard=(*ptr>>16) & 0x1f;
    NSString* crate = [NSString stringWithFormat:@"Crate      = %lu\n",(*ptr>>21) & 0xf];
    NSString* card  = [NSString stringWithFormat:@"Station    = %lu\n",(*ptr>>16) & 0x1f];
    
    ++ptr;
    ++ptr;
    ++ptr;
    unsigned long* eventPtr=ptr;
    unsigned long f1,f2,f3,f4;
    f1=ptr[0];
    f2=ptr[1];
    f3=ptr[2];
    f4=ptr[3];
    unsigned long flt,chan,energy,sec,subsec,multiplicity,p,toplen,ediff,evID;
    flt   = (f1 >> 25) & 0x1f;
    chan   = (f1 >> 20) & 0x1f;
    energy  = f1  & 0xfffff;
    sec = f2;
    subsec = f3  & 0x1ffffff;
    multiplicity  = (f3 >> 25) & 0x1f;
    p  = (f3 >> 31) & 0x1;
    toplen = f4  & 0x1ff;
    ediff  = (f4 >> 9) & 0xfff;
    evID   = (f4 >> 21) & 0x7ff;
    
#if 0
    NSString* info1 = @"";
    NSString* info2 = @"";
#else
    NSString* info1 = [NSString stringWithFormat:@"First event:\n"
                       "FIFO entry:  flt: %lu,chan: %lu,energy: %lu,sec: %lu,subsec: %lu   \n",flt,chan,energy,sec,subsec ];//DEBUG -tb-
    NSString* info2 = [NSString stringWithFormat:@"FIFO entry:  multiplicity: %lu,p: %lu,toplen: %lu,ediff: %lu,evID: %lu   \n",
                       multiplicity,p,toplen,ediff,evID ];//DEBUG -tb-
#endif
    
    
#if 1
    //draw full content on debugger console - for DEBUGGING -tb-
    fprintf(stdout,"Event Record for crate %li, card/FLT %li contains %li events:\n",numCrate,numCard,numEv);
    int i;
    for(i=0;i<numEv;i++){
        unsigned long f1,f2,f3,f4;
        f1=eventPtr[0];
        f2=eventPtr[1];
        f3=eventPtr[2];
        f4=eventPtr[3];
        unsigned long flt,chan,energy,sec,subsec,multiplicity,p,toplen,ediff,evID;
        flt   = (f1 >> 25) & 0x1f;
        chan   = (f1 >> 20) & 0x1f;
        energy  = f1  & 0xfffff;
        sec = f2;
        subsec = f3  & 0x1ffffff;
        multiplicity  = (f3 >> 25) & 0x1f;
        p  = (f3 >> 31) & 0x1;
        toplen = f4  & 0x1ff;
        ediff  = (f4 >> 9) & 0xfff;
        evID   = (f4 >> 21) & 0x7ff;
        
        fprintf(stdout,"FIFO entry:  flt: %li,chan: %li,energy: %li,sec: %li,subsec: %li   \n",flt,chan,energy,sec,subsec);
        fprintf(stdout,"FIFO entry:  multiplicity: %li,p: %li,toplen: %li,ediff: %li,evID: %li   \n",  multiplicity,p,toplen,ediff,evID);
        
        //go to next event block
        eventPtr+=4;
        
    }
    fprintf(stdout,"END of event Record.\n");
    
#endif
    
    /*
     int recordType = (*ptr) & 0xf;
     int counterType = ((*ptr)>>4) & 0xf;
     
     ++ptr;		//point to event counter
     if (recordType == 0) {
     NSString* eventCounter    = [NSString stringWithFormat:@"Event     = %lu\n",*ptr++];
     NSString* timeStampHi     = [NSString stringWithFormat:@"Time Hi   = %lu\n",*ptr++];
     NSString* timeStampLo     = [NSString stringWithFormat:@"Time Lo   = %lu\n",*ptr];
     
     return [NSString stringWithFormat:@"%@%@%@%@%@%@",title,crate,card,
     eventCounter,timeStampHi,timeStampLo];
     }
     
     ++ptr;		//skip event counter
     //timestamp events
     NSString* counterString;
     switch (counterType) {
     case kSecondsCounterType:	counterString    = [NSString stringWithFormat:@"Seconds Counter\n"]; break;
     case kVetoCounterType:		counterString    = [NSString stringWithFormat:@"Veto Counter\n"]; break;
     case kDeadCounterType:		counterString    = [NSString stringWithFormat:@"Deadtime Counter\n"]; break;
     case kRunCounterType:		counterString    = [NSString stringWithFormat:@"Run  Counter\n"]; break;
     default:					counterString    = [NSString stringWithFormat:@"Unknown Counter\n"]; break;
     }
     NSString* typeString;
     switch (recordType) {
     case kStartRunType:		typeString    = [NSString stringWithFormat:@"Start Run Timestamp\n"]; break;
     case kStopRunType:		typeString    = [NSString stringWithFormat:@"Stop Run Timestamp\n"]; break;
     case kStartSubRunType:	typeString    = [NSString stringWithFormat:@"Start SubRun Timestamp\n"]; break;
     case kStopSubRunType:	typeString    = [NSString stringWithFormat:@"Stop SubRun Timestamp\n"]; break;
     default:				typeString    = [NSString stringWithFormat:@"Unknown Timestamp Type\n"]; break;
     }
     NSString* timeStampHi     = [NSString stringWithFormat:@"Time Hi   = %lu\n",*ptr++];
     NSString* timeStampLo     = [NSString stringWithFormat:@"Time Lo   = %lu\n",*ptr];
     */
	return [NSString stringWithFormat:@"%@%@%@%@%@%@",title,content,crate,card,
            info1,info2];
}
@end












@implementation ORKatrinV4SLTDecoderForEnergy

//-------------------------------------------------------------
/** Data format for event:
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^^ ^^^^ ^^-----------------------data id
                  ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs
 
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^--------------------------------spare
         ^ ^^^---------------------------crate
              ^ ^^^^---------------------card (always = SLT ID/SLT slot)
                     ^^^^ ^^^^-----------spare
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx Spare 1
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx Spare 2
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx EventFifo 1
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx EventFifo 2
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx EventFifo 3
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx EventFifo 4
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx EventFifo 5
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx EventFifo 6
 and optionally more blocks consisting of 6 word32s, containing EventFifo 1...6,
 max. number of bytes: 8192 (which is the max. DMA readout block) -tb-
 
 **/
//-------------------------------------------------------------

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr = (unsigned long*)someData;
	unsigned long length	= ExtractLength(*ptr);	 //get length from first word
	unsigned char crate		= ShiftAndExtract(ptr[1],21,0xf);
	unsigned char card		= 0;//ShiftAndExtract(ptr[1],16,0x1f);
	unsigned char chan		= 0;//ShiftAndExtract(ptr[1],8,0xff);
    
    unsigned long headerlen, f1,f2,f3,f4,f5,f6;
    unsigned long energy,sec,subsec,multiplicity,p,toplen,ediff,evID, tpeak, tvalley, apeak, avalley;
    headerlen = 4;
    f1=ptr[headerlen];
    f2=ptr[headerlen+1];
    f3=ptr[headerlen+2];
    f4=ptr[headerlen+3];
    f5=ptr[headerlen+4];
    f6=ptr[headerlen+5];
    
    card   = (f3 >> 24) & 0x1f;
    chan   = (f3 >> 19) & 0x1f;
    //multiplicity  = (f3 >> 14) & 0x1f;
    //evID   = f3  & 0x3fff;
    //toplen = f4  & 0x1ff;
    //ediff  = (f4 >> 9) & 0xfff;
    //tpeak    = (f4 >> 16) & 0x1ff;
    tpeak    = (f4 >> 16) & 0x1ff;
    apeak    =  f4   & 0x7ff;
    //tvalley  = (f5 >> 16) & 0x1ff;
    tvalley  = (f5 >> 16) & 0x1ff;
    avalley  =  4096 - (f5   & 0xfff);
    
    energy  = f6  & 0xfffff;


	NSString* crateKey		= [self getCrateKey: crate];
	NSString* stationKey	= [self getStationKey: card];	
	NSString* channelKey	= [self getChannelKey: chan];	
    
	unsigned long histoLen;
	histoLen = 32768;//4096;//=max. ADC value for 12 bit ADC
    
    // count datasets
	[aDataSet loadGenericData:@" " sender:self withKeys:@"v4SLT",@"Energy Records",nil];
    
	//channel by channel histograms 'energy'
	[aDataSet histogram:energy
				numBins:histoLen sender:self  
			   withKeys:@"SLT", @"FLTthruSLT", @"Energy", crateKey,stationKey,channelKey,nil];
	
	//channel by channel histograms 'bipolar energy peak'
	[aDataSet histogram:apeak
				numBins:4096 sender:self  
			   withKeys:@"SLT", @"FLTthruSLT", @"PeakADC", crateKey,stationKey,channelKey,nil];
               
	//channel by channel histograms 'bipolar energy valley'
	[aDataSet histogram:avalley
				numBins:4096 sender:self  
			   withKeys:@"SLT", @"FLTthruSLT", @"ValleyADC", crateKey,stationKey,channelKey,nil];
	
	//channel by channel histograms 'bipolar energy peak' time
	[aDataSet histogram:tpeak
				numBins:4096 sender:self  
			   withKeys:@"SLT", @"FLTthruSLT", @"PeakPos", crateKey,stationKey,channelKey,nil];
               
	//channel by channel histograms 'bipolar energy valley' time
	[aDataSet histogram:tvalley
				numBins:4096 sender:self  
			   withKeys:@"SLT", @"FLTthruSLT", @"ValleyPos", crateKey,stationKey,channelKey,nil];
	
    
    /*
     //for debugging/testing -tb-
     int i=0;
     
     NSLog(@"EventFifoRecordLen: %i\n",length);
     int showMax=length;
     if(showMax>12){showMax=12;}
     for(i=2;i<showMax; i++){
     NSLog(@"word %i: 0x%08x\n",i,*(ptr+i));
     }
     */
    
    
    return length; //nothing to display at this time.. just return the length
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    
	unsigned long length	= ExtractLength(ptr[0]);
    
	NSString* title= @"Katrin SLTv4 Energy Record\n\n";
    unsigned long numCrate,numCard;
    unsigned long numEv=(length-4)/6;    //(((*ptr) & 0x3ffff)-4)/6;
    NSString* content=[NSString stringWithFormat:@"Num.Eevents= %lu\n",numEv];
    
    
	++ptr;		//skip the first word (dataID and length)
    numCrate=(*ptr>>21) & 0xf;
    numCard=(*ptr>>16) & 0x1f;
    NSString* crate = [NSString stringWithFormat:@"Crate      = %lu\n",(*ptr>>21) & 0xf];
    NSString* card  = [NSString stringWithFormat:@"Station    = %lu\n",(*ptr>>16) & 0x1f];
    
    ++ptr;
    ++ptr;
    ++ptr;
    unsigned long* eventPtr=ptr;
    unsigned long f1,f2,f3,f4,f5,f6;
    f1=ptr[0];
    f2=ptr[1];
    f3=ptr[2];
    f4=ptr[3];
    f5=ptr[4];
    f6=ptr[5];
    
#if 0
    //quickfix
    f1=ptr[1];
    f2=ptr[0];
    f3=ptr[3];
    f4=ptr[2];
    f5=ptr[5];
    f6=ptr[4];
    //quickfix
#endif
    
    unsigned long flt,chan,energy,sec,subsec,multiplicity,p,toplen,ediff,evID, tpeak, tvalley, apeak, avalley;
    p  = (f1 >> 28) & 0x1;
    subsec = (f1  & 0x0ffffff8) >> 3;
    sec = (f2 & 0x1fffffff) | ((f1  & 0x7) << 29);
    flt   = (f3 >> 24) & 0x1f;
    chan   = (f3 >> 19) & 0x1f;
    multiplicity  = (f3 >> 14) & 0x1f;
    evID   = f3  & 0x3fff;
    //toplen = f4  & 0x1ff;
    //ediff  = (f4 >> 9) & 0xfff;
    tpeak    = (f4 >> 16) & 0x1ff;
    apeak    =  f4   & 0x7ff; // & 0xfff; bit 12 unused and always 1 -tb-
    tvalley  = (f5 >> 16) & 0x1ff;
    //avalley  =  f5   & 0xfff; is negative
    avalley  =  4096 - (f5 & 0xfff);
    
    energy  = f6  & 0xfffff;
    
#if 0
    NSString* info1 = @"";
    NSString* info2 = @"";
#else
    NSString* info1 = [NSString stringWithFormat:@"First event:\n"
                       "FIFO entry:  flt: %lu,chan: %lu,energy: %lu,sec: %lu,subsec: %lu   \n",flt,chan,energy,sec,subsec ];//DEBUG -tb-
    NSString* info2 = [NSString stringWithFormat:@"FIFO entry:  multiplicity: %lu,p: %lu,Epeak: %lu,Evalley: %lu,t_peak: %lu,t_valley: %lu,evID: %lu   \n",
                       multiplicity,p,apeak,avalley,tpeak,tvalley,evID ];//DEBUG -tb-
#endif
    
    
#if 0
    //draw full content on debugger console - for DEBUGGING -tb-
    fprintf(stdout,"Event Record for crate %li, card/FLT %li contains %li events:\n",numCrate,numCard,numEv);
    int i;
    for(i=0;i<numEv;i++){
        unsigned long f1,f2,f3,f4;
        f1=eventPtr[0];
        f2=eventPtr[1];
        f3=eventPtr[2];
        f4=eventPtr[3];
        unsigned long flt,chan,energy,sec,subsec,multiplicity,p,toplen,ediff,evID;
        flt   = (f1 >> 25) & 0x1f;
        chan   = (f1 >> 20) & 0x1f;
        energy  = f1  & 0xfffff;
        sec = f2;
        subsec = f3  & 0x1ffffff;
        multiplicity  = (f3 >> 25) & 0x1f;
        p  = (f3 >> 31) & 0x1;
        toplen = f4  & 0x1ff;
        ediff  = (f4 >> 9) & 0xfff;
        evID   = (f4 >> 21) & 0x7ff;
        
        fprintf(stdout,"FIFO entry:  flt: %li,chan: %li,energy: %li,sec: %li,subsec: %li   \n",flt,chan,energy,sec,subsec);
        fprintf(stdout,"FIFO entry:  multiplicity: %li,p: %li,toplen: %li,ediff: %li,evID: %li   \n",  multiplicity,p,toplen,ediff,evID);
        
        //go to next event block
        eventPtr+=4;
        
    }
    fprintf(stdout,"END of event Record.\n");
    
#endif
    
    /*
     int recordType = (*ptr) & 0xf;
     int counterType = ((*ptr)>>4) & 0xf;
     
     ++ptr;		//point to event counter
     if (recordType == 0) {
     NSString* eventCounter    = [NSString stringWithFormat:@"Event     = %lu\n",*ptr++];
     NSString* timeStampHi     = [NSString stringWithFormat:@"Time Hi   = %lu\n",*ptr++];
     NSString* timeStampLo     = [NSString stringWithFormat:@"Time Lo   = %lu\n",*ptr];
     
     return [NSString stringWithFormat:@"%@%@%@%@%@%@",title,crate,card,
     eventCounter,timeStampHi,timeStampLo];
     }
     
     ++ptr;		//skip event counter
     //timestamp events
     NSString* counterString;
     switch (counterType) {
     case kSecondsCounterType:	counterString    = [NSString stringWithFormat:@"Seconds Counter\n"]; break;
     case kVetoCounterType:		counterString    = [NSString stringWithFormat:@"Veto Counter\n"]; break;
     case kDeadCounterType:		counterString    = [NSString stringWithFormat:@"Deadtime Counter\n"]; break;
     case kRunCounterType:		counterString    = [NSString stringWithFormat:@"Run  Counter\n"]; break;
     default:					counterString    = [NSString stringWithFormat:@"Unknown Counter\n"]; break;
     }
     NSString* typeString;
     switch (recordType) {
     case kStartRunType:		typeString    = [NSString stringWithFormat:@"Start Run Timestamp\n"]; break;
     case kStopRunType:		typeString    = [NSString stringWithFormat:@"Stop Run Timestamp\n"]; break;
     case kStartSubRunType:	typeString    = [NSString stringWithFormat:@"Start SubRun Timestamp\n"]; break;
     case kStopSubRunType:	typeString    = [NSString stringWithFormat:@"Stop SubRun Timestamp\n"]; break;
     default:				typeString    = [NSString stringWithFormat:@"Unknown Timestamp Type\n"]; break;
     }
     NSString* timeStampHi     = [NSString stringWithFormat:@"Time Hi   = %lu\n",*ptr++];
     NSString* timeStampLo     = [NSString stringWithFormat:@"Time Lo   = %lu\n",*ptr];
     */
	return [NSString stringWithFormat:@"%@%@%@%@%@%@",title,content,crate,card,
            info1,info2];
}
@end












@implementation ORKatrinV4SLTDecoderForMultiplicity

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


- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{

    unsigned long* ptr = (unsigned long*)someData;
	unsigned long length	= ExtractLength(*ptr);	 //get length from first word

	++ptr;											//crate, card,channel from second word
	unsigned char crate		= (*ptr>>21) & 0xf;
	unsigned char card		= (*ptr>>16) & 0x1f;
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* stationKey	= [self getStationKey: card];	
		
	++ptr;		//point to event count
	//NSString* eventCount = [NSString stringWithFormat:@"%d",*ptr];
	//[aDataSet loadGenericData:eventCount sender:self withKeys:@"EventCount",@"Ipe SLT", crateKey,stationKey,nil];
					
				
	// Display data, ak 12.2.08
	++ptr;		//point to trigger data
	unsigned long *pMult = ptr;
	int i, j, k;
	//NSFont* aFont = [NSFont userFixedPitchFontOfSize:9];
    unsigned long xyProj[20];
	unsigned long tyProj[100];
	unsigned long pageSize = length/20;
	
	for (i=0;i<20;i++) xyProj[i] = 0;
	for (k=0;k<100;k++) tyProj[k] = 0;
	
	for (k=0;k<20*pageSize;k++){
		xyProj[k%20] = xyProj[k%20] | (pMult[k] & 0x3fffff);
	}  
	for (k=0;k<20*pageSize;k++){
		if (xyProj[k%20]) {
			tyProj[k/20] = tyProj[k/20] | (pMult[k] & 0x3fffff);
		}
	}
	
	int nTriggered = 0;
	for (i=0;i<20;i++){
		for(j=0;j<22;j++){
			if (((xyProj[i]>>j) & 0x1 ) == 0x1) nTriggered++;
		}
	}
	
	
	// Clear dataset
    [aDataSet clear];	
	
	for(j=0;j<22;j++){
		//NSMutableString* s = [NSMutableString stringWithFormat:@"%2d: ",j];
		//matrix of triggered pixel
		for(i=0;i<20;i++){
			//if (((xyProj[i]>>j) & 0x1) == 0x1) [s appendFormat:@"X"];
			//else							   [s appendFormat:@"."];
			
			if (((xyProj[i]>>j) & 0x1) == 0x1) {
	          [aDataSet histogram2DX: i 
                    y: j
					size: 130                          
					sender: self 
					withKeys: @"SLTv4", @"TriggerData",crateKey,stationKey,nil];
			}
		}
		//[s appendFormat:@"   "];
		
		// trigger timing
		for (k=0;k<pageSize;k++){
			//if (((tyProj[k]>>j) & 0x1) == 0x1 )[s appendFormat:@"="];
			//else							   [s appendFormat:@"."];
			
			if (((tyProj[k]>>j) & 0x1) == 0x1 ){
	          [aDataSet histogram2DX: k+30 
                    y: j
					size: 130                          
					sender: self 
					withKeys: @"SLTv4", @"TriggerData",crateKey,stationKey,nil];
			}			
		}
		//NSLogFont(aFont, @"%@\n", s);
		
	}
	
	//NSLogFont(aFont,@"\n");	
	
					
    return length; //must return number of longs processed.
}


- (NSString*) dataRecordDescription:(unsigned long*)ptr
{

    NSString* title= @"Auger FLT Waveform Record\n\n";
	++ptr;		//skip the first word (dataID and length)
    
    NSString* crate = [NSString stringWithFormat:@"Crate      = %lu\n",(*ptr>>21) & 0xf];
    NSString* card  = [NSString stringWithFormat:@"Station    = %lu\n",(*ptr>>16) & 0x1f];
	++ptr;		//point to next structure
	
	NSString* eventCount		= [NSString stringWithFormat:@"Event Count = %lu\n",*ptr];

    return [NSString stringWithFormat:@"%@%@%@%@",title,crate,card,eventCount]; 
}

@end


