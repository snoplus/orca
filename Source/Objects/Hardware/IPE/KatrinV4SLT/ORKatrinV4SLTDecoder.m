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
#import "ORKatrinV4FLTModel.h"
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
    unsigned long numEv=((*ptr) & 0x3ffff)/4-1;
    NSString* content=[NSString stringWithFormat:@"Num.Eevents= %lu\n",((*ptr) & 0x3ffff)/4-1];

	++ptr;		//skip the first word (dataID and length)
    unsigned long numCrate=(*ptr>>21) & 0xf;
    unsigned long numCard=(*ptr>>16) & 0x1f;
    NSString* crate = [NSString stringWithFormat:@"Crate      = %lu\n",(*ptr>>21) & 0xf];
    NSString* card  = [NSString stringWithFormat:@"Station    = %lu\n",(*ptr>>16) & 0x1f];
    
    ++ptr;
    ++ptr;
    ++ptr;
    unsigned long* eventPtr     = ptr;
    unsigned long f1            = ptr[0];
    unsigned long f2            = ptr[1];
    unsigned long f3            = ptr[2];
    unsigned long f4            = ptr[3];
    unsigned long flt           = (f1 >> 25) & 0x1f;
    unsigned long chan          = (f1 >> 20) & 0x1f;
    unsigned long energy        = f1  & 0xfffff;
    unsigned long sec           = f2;
    unsigned long subsec        = f3  & 0x1ffffff;
    unsigned long multiplicity  = (f3 >> 25) & 0x1f;
    unsigned long p             = (f3 >> 31) & 0x1;
    unsigned long toplen        = f4  & 0x1ff;
    unsigned long ediff         = (f4 >> 9) & 0xfff;
    unsigned long evID          = (f4 >> 21) & 0x7ff;
    
    NSString* info1 = [NSString stringWithFormat:@"First event:\n"
                       "FIFO entry:  flt: %lu,chan: %lu,energy: %lu,sec: %lu,subsec: %lu   \n",flt,chan,energy,sec,subsec ];//DEBUG -tb-
    NSString* info2 = [NSString stringWithFormat:@"FIFO entry:  multiplicity: %lu,p: %lu,toplen: %lu,ediff: %lu,evID: %lu   \n",
                       multiplicity,p,toplen,ediff,evID ];//DEBUG -tb-
#if 1
    //draw full content on debugger console - for DEBUGGING -tb-
    fprintf(stdout,"Event Record for crate %li, card/FLT %li contains %li events:\n",numCrate,numCard,numEv);
    int i;
    for(i=0;i<numEv;i++){
        unsigned long f1 = eventPtr[0];
        unsigned long f2 = eventPtr[1];
        unsigned long f3 = eventPtr[2];
        unsigned long f4 = eventPtr[3];
        unsigned long flt   = (f1 >> 25) & 0x1f;
        unsigned long chan   = (f1 >> 20) & 0x1f;
        unsigned long energy  = f1  & 0xfffff;
        unsigned long sec = f2;
        unsigned long subsec = f3  & 0x1ffffff;
        unsigned long multiplicity  = (f3 >> 25) & 0x1f;
        unsigned long p  = (f3 >> 31) & 0x1;
        unsigned long toplen = f4  & 0x1ff;
        unsigned long ediff  = (f4 >> 9) & 0xfff;
        unsigned long evID   = (f4 >> 21) & 0x7ff;
        
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
static NSString* kSLTCrate[4] = {
    //pre-make some keys for speed.
    @"SLT0.FLT.Energy", @"SLT0.FLT.Energy", @"SLT0.FLT.Energy", @"SLT0.FLT.Energy",
 };
static NSString* kSLTStation[32] = {
    //pre-make some keys for speed.
    @"Station  0", @"Station  1", @"Station  2", @"Station  3",
    @"Station  4", @"Station  5", @"Station  6", @"Station  7",
    @"Station  8", @"Station  9", @"Station 10", @"Station 11",
    @"Station 12", @"Station 13", @"Station 14", @"Station 15",
    @"Station 16", @"Station 17", @"Station 18", @"Station 19",
    @"Station 20", @"Station 21", @"Station 22", @"Station 23",
    @"Station 24", @"Station 25", @"Station 26", @"Station 27",
    @"Station 28", @"Station 29", @"Station 30", @"Station 31"
};
static NSString* kFLTChanKey[24] = {
    //pre-make some keys for speed.
    @"Channel  0", @"Channel  1", @"Channel  2", @"Channel  3",
    @"Channel  4", @"Channel  5", @"Channel  6", @"Channel  7",
    @"Channel  8", @"Channel  9", @"Channel 10", @"Channel 11",
    @"Channel 12", @"Channel 13", @"Channel 14", @"Channel 15",
    @"Channel 16", @"Channel 17", @"Channel 18", @"Channel 19",
    @"Channel 20", @"Channel 21", @"Channel 22", @"Channel 23"
};

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
- (id) init {
    self = [super init];
    return self;
}
- (void) dealloc
{
    [actualFlts release];
    [super dealloc];
}

- (int) filterShapingLength //this is to  return a dummy value, if the FLT card cannot be found (see below) -tb-
{return 8;}//I return the maximum value


- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr = (unsigned long*)someData;
	unsigned long length	= ExtractLength(*ptr);	 //get length from first word
	unsigned char crate		= ShiftAndExtract(ptr[1],21,0xf);
    
 	NSString* crateKey = @"??";
    if(crate<4)crateKey= kSLTCrate[crate];
    
    unsigned long headerlen = 4;
    unsigned long numEv=(length-headerlen)/6;
    
    //prepare decoding
    if(!actualFlts)actualFlts = [[NSMutableDictionary alloc] init];

    ptr+=headerlen;
    int i;
    for(i=0;i<numEv;i++){
//      unsigned long f1        = ptr[0]; //word#,subseconds
      //unsigned long f2        = ptr[1]; //seconds
        unsigned long f3        = ptr[2]; //flt,ch,multi,eventID
//      unsigned long f4        = ptr[3]; //aPeak, aPeak
//      unsigned long f5        = ptr[4]; //tValley, aValley
        unsigned long f6        = ptr[5]; //Energy

        unsigned char card      = (f3 >> 24) & 0x1f;
        unsigned char chan      = (f3 >> 19) & 0x1f;
//      unsigned long multiplicity  = (f3 >> 14) & 0x1f;
//      unsigned long evID    = f3  & 0x3fff;
        
//      unsigned long tPeak     = (f4 >> 16) & 0x1ff;
//      unsigned long aPeak     =  f4        & 0xfff;
        
//      unsigned long tValley   = (f5 >> 16) & 0x1ff;
//      unsigned long aValley   =  4096 - (f5   & 0xfff);
//      unsigned long aValley   =  f5        & 0xfff;
        unsigned long energy    =  f6        & 0xfffff;
        //unsigned long lostEvents    =  (f6>>20)&0x1ff;;
        
        //get the keys faster than the usual way
        NSString* stationKey = @"??";
	    if(card<32)stationKey  = kSLTStation[card];
        
        NSString* channelKey  = @"??";
	    if(chan<24)channelKey = kFLTChanKey[chan];
//        
//		NSString* fltKey = [crateKey stringByAppendingString:stationKey];
//		id obj = [actualFlts objectForKey:fltKey];
//		if(!obj){
//			NSArray* listOfFlts = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORKatrinV4FLTModel")];
//			for(ORKatrinV4FLTModel* aFlt in listOfFlts){
//				if([aFlt stationNumber] == card){
//					[actualFlts setObject:aFlt forKey:fltKey];
//					obj = aFlt;
//					break;
//				}
//			}
//            if(!obj){
//                [actualFlts setObject:self forKey:fltKey];
//                obj=self;
//            }
//		}
//        int filterShapingLength = 0;
//        if(obj) filterShapingLength = [obj filterShapingLength];
    
        [aDataSet histogram:energy >> 8 /*energy >> filterShapingLength*/  //scale to 4096 bins for now
                    numBins:4096 sender:self
                   withKeys: crateKey,stationKey,channelKey,nil];
        
//	    [aDataSet histogram:aPeak
//	    			numBins:4096 sender:self  
//	    		   withKeys:@"SLT", @"FLTthruSLT", @"PeakADC", crateKey,stationKey,channelKey,nil];
//               
//	    [aDataSet histogram:aValley
//	    			numBins:4096 sender:self  
//	    		   withKeys:@"SLT", @"FLTthruSLT", @"ValleyADC", crateKey,stationKey,channelKey,nil];
//	
//	    [aDataSet histogram:tPeak
//	    			numBins:4096 sender:self  
//	    		   withKeys:@"SLT", @"FLTthruSLT", @"PeakPos", crateKey,stationKey,channelKey,nil];
//               
//	    [aDataSet histogram:tValley
//	    			numBins:4096 sender:self  
//	    		   withKeys:@"SLT", @"FLTthruSLT", @"ValleyPos", crateKey,stationKey,channelKey,nil];
        
        ptr+=6;//next event
    }
    
    return length;
}

- (NSString*) dataRecordDescription:(unsigned long*)dataPtr
{
	unsigned long length	= ExtractLength(dataPtr[0]);
    
    unsigned long numEv = (length-4)/6;

    int crateNum = (dataPtr[1]>>21) & 0xf;
    NSString* content   = [NSString stringWithFormat:@"SLTv4 Energy Record\n\nEvents In Record: %lu\nCrate: %d\n",numEv,crateNum];
    unsigned long* ptr = &dataPtr[4];
    int i;
    for(i=0;i<numEv;i++){
        unsigned long event = i*6;
        
        unsigned long f1 = ptr[event + 0];
        unsigned long f2 = ptr[event + 1];
        unsigned long f3 = ptr[event + 2];
        unsigned long f4 = ptr[event + 3];
        unsigned long f5 = ptr[event + 4];
        unsigned long f6 = ptr[event + 5];
        
        unsigned long subsec   = f1 & 0x0fffffff;
        unsigned long sec      = f2;
        unsigned long flt      = (f3 >> 24) & 0x1f;
        unsigned long chan     = (f3 >> 19) & 0x1f;
        unsigned long mult     = (f3 >> 14) & 0x1f;
        unsigned long eventID  = f3  & 0x3fff;
        unsigned long tPeak    = (f4 >> 16) & 0x1ff;
        unsigned long aPeak    = f4 & 0x7ff; // & 0xfff; bit 12 unused and always 1 -tb-
        unsigned long tValley  = (f5 >> 16) & 0x1ff;
        unsigned long aValley  =  4096 - (f5 & 0xfff);
        unsigned long energy   = f6  & 0xfffff;
        
        content = [content stringByAppendingFormat:@"Event: %d EventID: %lu \nSeconds: %lu.%lu\nFLT: %lu  Chan: %lu\n",i,eventID,sec,subsec,flt,chan];
        content = [content stringByAppendingFormat:@"TPeak: %lu TValley: %lu\n",tPeak,tValley];
        content = [content stringByAppendingFormat:@"APeak: %lu AValley: %lu\n",aPeak,aValley];
        content = [content stringByAppendingFormat:@"Multi: %lu Energy: %lu\n",mult,energy];
    }
    return content;
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


