//
//  ORKatrinV4FLTDecoder.m
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

#import "ORKatrinV4FLTDecoder.h"
#import "ORKatrinV4FLTModel.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORKatrinV4FLTDefs.h"
#import "SLTv4_HW_Definitions.h"

@implementation ORKatrinV4FLTDecoderForEnergy

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
                                 ^^------boxcarLen  
                                    ^^^^-filterShapingLength  
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx sec
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx subSec
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx 
           ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ channel Map (24bit, 1 bit set denoting the channel number)  
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx eventID+infos (called now 'eventInfo' for OrcaROOT):
 -----^^^^-------------------------------flt run mode
 ----------^^^^--------------------------FIFO Flags: FF, AF, AE, EF
 -----------------^^---------------------time precision(2 bit)
 --------------------^^^^ ^^-------------number of page in hardware buffer (0..63, 6 bit)
 ---------------------------^^ ^^^^ ^^^^-readPtr/eventID (0..511, 10 bit!)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx fifoEventID + energy
 ^^^^ ^^^^ ^^^^--------------------------fifoEventID
                ^^^^ ^^^^ ^^^^ ^^^^ ^^^^-energy
 </pre>
 *
 */
//-------------------------------------------------------------


// removed                                ^^^^------filterIndex and replaced by boxcarLen 2012-11 -tb-

- (id) init
{
    self = [super init];
    getRatesFromDecodeStage = YES;
    getFifoFlagsFromDecodeStage = YES;
    return self;
}

- (void) dealloc
{
	[actualFlts release];
    [super dealloc];
}

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
{
    unsigned long* ptr = (unsigned long*)someData;
	unsigned long length	= ExtractLength(ptr[0]);								 
	unsigned char crate		= ShiftAndExtract(ptr[1],21,0xf);
	unsigned char card		= ShiftAndExtract(ptr[1],16,0x1f);
	unsigned char chan		= ShiftAndExtract(ptr[1],8,0xff);
	unsigned char fifoFlags = ShiftAndExtract(ptr[5],20,0xf);
	int boxcarLen = ShiftAndExtract(ptr[1],4,0x3);
	int filterShapingLength = ShiftAndExtract(ptr[1],0,0xf);
	unsigned short filterDiv;
	unsigned long histoLen;
	histoLen = 4096;//=max. ADC value for 12 bit ADC
	filterDiv = 1L << filterShapingLength;
	if(filterShapingLength==0){
		filterDiv = boxcarLen + 1;
	}
	
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* stationKey	= [self getStationKey: card];	
	NSString* channelKey	= [self getChannelKey: chan];	

	//note the ptr[6] shares the eventID and the energy
	//the eventID must be masked off
	unsigned long energy = (ptr[6] & 0xfffff)/filterDiv;
		
	//channel by channel histograms
	[aDataSet histogram:energy
				numBins:histoLen sender:self  
			   withKeys:@"FLT", @"Energy", crateKey,stationKey,channelKey,nil];
	
	//accumulated card level histograms
	[aDataSet histogram:energy
				numBins:histoLen sender:self  
			   withKeys:@"FLT", @"Total Card Energy", crateKey,stationKey,nil];
	
	//accumulated crate level histograms
	[aDataSet histogram:energy 
				numBins:histoLen sender:self  
			   withKeys:@"FLT", @"Total Crate Energy", crateKey,nil];

	//get the actual object
	if(getRatesFromDecodeStage || getFifoFlagsFromDecodeStage){
		NSString* fltKey = [crateKey stringByAppendingString:stationKey];
		if(!actualFlts)actualFlts = [[NSMutableDictionary alloc] init];
		ORKatrinV4FLTModel* obj = [actualFlts objectForKey:fltKey];
		if(!obj){
			NSArray* listOfFlts = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORKatrinV4FLTModel")];
			for(ORKatrinV4FLTModel* aFlt in listOfFlts){
				if(/*[aFlt crateNumber] == crate &&*/ [aFlt stationNumber] == card){
					[actualFlts setObject:aFlt forKey:fltKey];
					obj = aFlt;
					break;
				}
			}
		}
		if(getRatesFromDecodeStage)    getRatesFromDecodeStage     = [obj bumpRateFromDecodeStage:chan];
		if(getFifoFlagsFromDecodeStage)  {
			if(fifoFlags != oldFifoFlags[chan]){
				getFifoFlagsFromDecodeStage = [obj setFromDecodeStage:chan fifoFlags:fifoFlags];
				fifoFlags = oldFifoFlags[chan];
			}
	    }
    }
	
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"Katrin V4 FLT Energy Record\n\n";    
    NSString* crate = [NSString stringWithFormat:@"Crate      = %lu\n",ShiftAndExtract(ptr[1],21,0xf)];
    NSString* card  = [NSString stringWithFormat:@"Station    = %lu\n",ShiftAndExtract(ptr[1],16,0x1f)];
    NSString* chan  = [NSString stringWithFormat:@"Channel    = %lu\n",ShiftAndExtract(ptr[1],8,0xff)];
		
	
	NSDate* theDate = [NSDate dateWithTimeIntervalSinceReferenceDate:(NSTimeInterval)ptr[2]];
	NSString* eventDate     = [NSString stringWithFormat:@"Date       = %@\n", [theDate descriptionFromTemplate:@"MM/dd/yy"]];
	NSString* eventTime     = [NSString stringWithFormat:@"Time       = %@\n", [theDate descriptionFromTemplate:@"HH:mm:ss"]];
	
	NSString* seconds		= [NSString stringWithFormat:@"Seconds    = %lu\n",     ptr[2]];
	NSString* subSec        = [NSString stringWithFormat:@"SubSeconds = %lu\n",     ptr[3]];
	NSString* chMap	    	= [NSString stringWithFormat:@"Channelmap = 0x%06lx\n", ptr[4]];
    NSString* nPages		= [NSString stringWithFormat:@"EventFlags = 0x%lx\n",     ptr[5]];
	
	NSString* fifoEventId   = [NSString stringWithFormat:@"FifoEventId = %lu\n",     ShiftAndExtract(ptr[6],20,0xfff) ];
	NSString* energy        = [NSString stringWithFormat:@"Energy      = %lu\n",     ShiftAndExtract(ptr[6],0,0xffff)];

	
    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@",title,crate,card,chan,
			fifoEventId,energy,eventDate,eventTime,seconds,subSec,nPages,chMap];               
    	
}

@end

@implementation ORKatrinV4FLTDecoderForWaveForm

//-------------------------------------------------------------
/** Data format for waveform
 *
 <pre>  
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^^ ^^^^ ^^-----------------------data id
 -----------------^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs
 
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^--------------------------------spare
 ------- ^ ^^^---------------------------crate
 -------------^ ^^^^---------------------card
 --------------------^^^^ ^^^^-----------channel
                                 ^^------boxcarLen  
                                    ^^^^-filterShapingLength  
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx sec
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx subSec
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx 
 ----------^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ channel Map (24bit, 1 bit set denoting the channel number)  
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx eventID+infos (called now 'eventInfo' for OrcaROOT):
 -----^^^^-------------------------------flt run mode
 ----------^^^^--------------------------FIFO Flags: FF, AF, AE, EF
 -----------------^^---------------------time precision(2 bit)
 --------------------^^^^ ^^-------------number of page in hardware buffer (0..63, 6 bit)
 ---------------------------^^ ^^^^ ^^^^-readPtr/eventID (0..511, 10 bit!)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx fifoEventID + energy
 ^^^^ ^^^^ ^^^^--------------------------fifoEventID
                ^^^^ ^^^^ ^^^^ ^^^^ ^^^^-energy
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx eventFlags
                 ^^^ ^^^^ ^^^^-----------traceStart16 (first trace value in short array, 11 bit, 0..2047)
                                 ^-------append flag is in this record (append to previous record)
                                  ^------append next waveform record
                                    ^^^^-number which defines the content of the record (kind of version number)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx not yet defined ... (started to store there postTriggTime -tb-)
 
 followed by waveform data (up to 2048 16-bit words)
 <pre>  
 */ 
 
 // removed                                ^^^^------filterIndex and replaced by boxcarLen 2012-11 -tb-

 
//-------------------------------------------------------------

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{

	unsigned long* ptr = (unsigned long*)someData;
	unsigned long length	= ExtractLength(ptr[0]);
	unsigned char crate		= ShiftAndExtract(ptr[1],21,0xf);
	unsigned char card		= ShiftAndExtract(ptr[1],16,0x1f);
	unsigned char chan		= ShiftAndExtract(ptr[1],8,0xff);
	unsigned char fifoFlags = ShiftAndExtract(ptr[5],20,0xf);
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* stationKey	= [self getStationKey: card];	
	NSString* channelKey	= [self getChannelKey: chan];	
	int boxcarLen = ShiftAndExtract(ptr[1],4,0x3);
	int filterShapingLength = ShiftAndExtract(ptr[1],0,0xf);
	//	NSLog(@"Called %@::%@: boxcarLen %i,filterShapingLength  %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),boxcarLen,filterShapingLength);//TODO: DEBUG -tb-
	unsigned short filterDiv;
	unsigned long histoLen;
	histoLen = 4096;//=max. ADC value for 12 bit ADC
	filterDiv = 1L << filterShapingLength;
	if(filterShapingLength==0){
		filterDiv = boxcarLen + 1;
	}
	
	
	unsigned long startIndex= ShiftAndExtract(ptr[7],8,0x7ff);

	//channel by channel histograms
	//note the ptr[6] shares the eventID and the energy
	//the eventID must be masked off
	unsigned long energy = (ptr[6] & 0xfffff)/filterDiv;
	// NSLog(@"Called %@::%@: energy %i,energyADC  %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),(ptr[6] & 0xfffff),energy);//TODO: DEBUG -tb-

	//uint32_t subsec         = ptr[3]; // ShiftAndExtract(ptr[1],0,0xffffffff);//TODO: DEBUG -tb- //commented out since unused MAH 9/14/10
	//uint32_t eventID        = ptr[5];//commented out since unused MAH 9/14/10
    uint32_t eventFlags     = ptr[7];
    uint32_t traceStart16 = ShiftAndExtract(eventFlags,8,0x7ff);//start of trace in short array
	
//TODO: DEBUG -tb- NSLog(@"energy on chan %i is %i (%i), subsec %i , page# %i, traceStart16 %i\n", chan, ptr[6] ,energy, subsec, ShiftAndExtract(eventID,10,0x3f),traceStart16);//TODO: DEBUG -tb-

	//channel by channel histograms  NSScanner
	[aDataSet histogram:energy 
				numBins:histoLen sender:self  
			   withKeys:@"FLT", @"Energy", crateKey,stationKey,channelKey,nil];
	
	//accumulated card level histograms
	[aDataSet histogram:energy 
				numBins:histoLen sender:self  
			   withKeys:@"FLT", @"Total Card Energy", crateKey,stationKey,nil];
	
	//accumulated crate level histograms
	[aDataSet histogram:energy 
				numBins:histoLen sender:self  
			   withKeys:@"FLT", @"Total Crate Energy", crateKey,nil];
	
	
	// Set up the waveform
	NSData* waveFormdata = [NSData dataWithBytes:someData length:length*sizeof(long)];
//TODO: no offset -tb-
startIndex=traceStart16;
    //startIndex=0;
    
    //NSLog(@" traceStart16 %i\n",traceStart16);//
	//NSLog(@" %@::%@   traceStart16 %i \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),traceStart16 );//TODO: DEBUG -tb-
    
	[aDataSet loadWaveform: waveFormdata					//pass in the whole data set
					offset: 9*sizeof(long)					// Offset in bytes (past header words)
				  unitSize: sizeof(short)					// unit size in bytes
				startIndex:	startIndex+6					// first Point Index (past the header offset!!!)
					  mask:	0x0FFF							// when displayed all values will be masked with this value
			   specialBits:0xF000						
				  bitNames: [NSArray arrayWithObjects:@"---",@"appPg",@"inhibit", @"trigger",nil]
					sender: self 
				  withKeys: @"FLT", @"Waveform",crateKey,stationKey,channelKey,nil];

	//get the actual object
	if(getRatesFromDecodeStage || getFifoFlagsFromDecodeStage){
		NSString* fltKey = [crateKey stringByAppendingString:stationKey];
		if(!actualFlts)actualFlts = [[NSMutableDictionary alloc] init];
		ORKatrinV4FLTModel* obj = [actualFlts objectForKey:fltKey];
		if(!obj){
			NSArray* listOfFlts = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORKatrinV4FLTModel")];
			for(ORKatrinV4FLTModel* aFlt in listOfFlts){
				if(/*[aFlt crateNumber] == crate &&*/ [aFlt stationNumber] == card){
					[actualFlts setObject:aFlt forKey:fltKey];
					obj = aFlt;
					break;
				}
			}
		}
		if(getRatesFromDecodeStage)    getRatesFromDecodeStage     = [obj bumpRateFromDecodeStage:chan];
		if(getFifoFlagsFromDecodeStage){
			if(fifoFlags != oldFifoFlags[chan]){
				getFifoFlagsFromDecodeStage = [obj setFromDecodeStage:chan fifoFlags:fifoFlags];
				fifoFlags = oldFifoFlags[chan];
			}
		}
	}
	
										
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{

	unsigned long length	= ExtractLength(ptr[0]);
	//unsigned char crate		= ShiftAndExtract(ptr[1],21,0xf);
	//unsigned char card		= ShiftAndExtract(ptr[1],16,0x1f);
	//unsigned char chan		= ShiftAndExtract(ptr[1],8,0xff);
    uint32_t sec            = ptr[2];
    uint32_t subsec         = ptr[3]; // ShiftAndExtract(ptr[1],0,0xffffffff);
    uint32_t chmap          = ptr[4];
    uint32_t eventID        = ptr[5];
    uint32_t fifoEventID    = ShiftAndExtract(ptr[6],20,0xfff);
    uint32_t energy         = ShiftAndExtract(ptr[6],0,0xfffff);
    uint32_t eventFlags     = ptr[7];
    uint32_t traceStart16 = ShiftAndExtract(eventFlags,8,0x7ff);//start of trace in short array
    
    NSString* title= @"Katrin V4 FLT Waveform Record\n\n";

	++ptr;		//skip the first word (dataID and length)
    
    NSString* crate			 = [NSString stringWithFormat:@"Crate       = %lu\n",(*ptr>>21) & 0xf];
    NSString* card			 = [NSString stringWithFormat:@"Station     = %lu\n",(*ptr>>16) & 0x1f];
    NSString* chan			 = [NSString stringWithFormat:@"Channel     = %lu\n",(*ptr>>8) & 0xff];
    NSString* secStr		 = [NSString stringWithFormat:@"Sec         = %d\n", sec];
    NSString* subsecStr		 = [NSString stringWithFormat:@"SubSec      = %d\n", subsec];
    NSString* fifoEventIdStr = [NSString stringWithFormat:@"FifoEventId = %d\n", fifoEventID];
    NSString* energyStr		 = [NSString stringWithFormat:@"Energy      = %d\n", energy];
    NSString* chmapStr		 = [NSString stringWithFormat:@"ChannelMap  = 0x%x\n", chmap];
    NSString* eventIDStr	 = [NSString stringWithFormat:@"ReadPtr,Pg# = %d,%d\n", ShiftAndExtract(eventID,0,0x3ff),ShiftAndExtract(eventID,10,0x3f)];
    NSString* offsetStr		 = [NSString stringWithFormat:@"Offset16    = %d\n", traceStart16];
    NSString* versionStr	 = [NSString stringWithFormat:@"RecVersion  = %d\n", ShiftAndExtract(eventFlags,0,0xf)];
    NSString* eventFlagsStr
							 = [NSString stringWithFormat:@"Flag(a,ap)  = %d,%d\n", ShiftAndExtract(eventFlags,4,0x1),ShiftAndExtract(eventFlags,5,0x1)];
    NSString* lengthStr		 = [NSString stringWithFormat:@"Length      = %lu\n", length];
    
    
    NSString* evFlagsStr     = [NSString stringWithFormat:@"EventFlags = 0x%x\n", eventFlags ];

    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@",title,crate,card,chan,  
                secStr, subsecStr, fifoEventIdStr, energyStr, chmapStr, eventIDStr, offsetStr, versionStr, eventFlagsStr, lengthStr,   evFlagsStr]; 
}

@end



@implementation ORKatrinV4FLTDecoderForEnergyTrace

//-------------------------------------------------------------
/** Data format for energy+trace:
 *  2011-02-01 Till Bergmann (STILL UNDER CONSTRUCTION, NOT YET USED)
 *  This is the new general Erergy+Trace data structure. The main difference is: we use the same format for
 *  energy and energy+trace events. The idea is to omit the trace at high rates and ship only the pure energy event data.
 *  At low rates we try to read out as much traces as possible.
 *  After the basic data record we append a variable length data block containing some ADC related data and the ADC data itself.
 *  The first data block is designed to be as short as possible to allow high data rates.
 *  
 *  Note (2013-12-11 -tb-): This plan has been canceled, as the collaboration prefers to keep the old format.
 <pre>  
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^^ ^^^^ ^^-----------------------data id
 -----------------^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs (energy event: length==9; trace event: length>=15 (6 additional words+trace))
 
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^--------------------------------spare
 ------- ^ ^^^---------------------------crate
 -------------^ ^^^^---------------------card
 --------------------^^^^ ^^^^-----------channel
                                 ^^------boxcarLen  
                                    ^^^^-filterShapingLength  
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx sec
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx subSec
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx 
 ----------^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ channel Map (24bit, 1 bit set denoting the channel number)  
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx eventID+eventInfo:
 -----^^^^-------------------------------    run mode
 ------------^^-^^^^---------------------    page number
 ----------------------^^----------------    precision (from FIFO2)
 -------------------------^^^^-^^^^-^^^^-    event ID (from FIFO1+2)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx event FIFO status
 --^^------------------^^----------------FIFO Flags: AE, EF, FF, AF
 -------^^ ^^^^ ^^^^---------------------readPtr   (0..511, 10 bit!)
 ---------------------------^^ ^^^^ ^^^^-writePtr  (0..511, 10 bit!)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx energy
 ------------------- ^^^^ ^^^^ ^^^^ ^^^^   energy 16bit  
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx spare


Variable section: exists if trace length !=0
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx trace length, 11 bit  (last "trace length" words contain the ADC values)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx postTriggTime
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx eventFlags
                 ^^^ ^^^^ ^^^^-----------traceStart16 (first trace value in short array, 11 bit, 0..2047)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx status register
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx spare
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx spare

 followed by waveform data (up to 2048 16-bit words)

 
 OLD RECORD STRUCTURE
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx eventID+infos:
 -----^^^^-------------------------------flt run mode
 ----------^^^^--------------------------FIFO Flags: FF, AF, AE, EF
 -----------------^^---------------------time precision(2 bit)
 --------------------^^^^ ^^-------------number of page in hardware buffer (0..63, 6 bit)
 ---------------------------^^ ^^^^ ^^^^-readPtr/eventID (0..511, 10 bit!)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx energy
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx eventFlags
                 ^^^ ^^^^ ^^^^-----------traceStart16 (first trace value in short array, 11 bit, 0..2047)
                                 ^-------append flag is in this record (append to previous record)
                                  ^------append next waveform record
                                    ^^^^-number which defines the content of the record (kind of version number)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx not yet defined ... named eventInfo (started to store there postTriggTime -tb-)
 
 followed by waveform data (up to 2048 16-bit words)
 <pre>  
 */ 
//-------------------------------------------------------------
- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{

	unsigned long* ptr = (unsigned long*)someData;
	unsigned long length	= ExtractLength(ptr[0]);
	unsigned char crate		= ShiftAndExtract(ptr[1],21,0xf);
	unsigned char card		= ShiftAndExtract(ptr[1],16,0x1f);
	unsigned char chan		= ShiftAndExtract(ptr[1],8,0xff);
	unsigned char fifoFlags = ShiftAndExtract(ptr[5],20,0xf);//TODO:  <=============== changed!!!!! -tb-
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* stationKey	= [self getStationKey: card];	
	NSString* channelKey	= [self getChannelKey: chan];	
	//int filterIndex = ShiftAndExtract(ptr[1],4,0xf); if(filterIndex == 0xf) filterIndex=-1;//TODO: replace by filterShapingLength in the future -tb-
	int filterShapingLength = ShiftAndExtract(ptr[1],0,0xf);
	unsigned short filterDiv;
	unsigned long histoLen;
	histoLen = 4096;//TODO: make a configurable parameter whether we want see original energy value or "normalized" value -tb- ?
	filterDiv = 1L << filterShapingLength;
	
	
	unsigned long startIndex= ShiftAndExtract(ptr[7],8,0x7ff);

	//channel by channel histograms
	unsigned long energy = (ptr[6] & 0xfffff)/filterDiv;

	//uint32_t subsec         = ptr[3]; // ShiftAndExtract(ptr[1],0,0xffffffff);//TODO: DEBUG -tb- //commented out since unused MAH 9/14/10
	//uint32_t eventID        = ptr[5];//commented out since unused MAH 9/14/10
    uint32_t eventFlags     = ptr[7];
    uint32_t traceStart16 = ShiftAndExtract(eventFlags,8,0x7ff);//start of trace in short array
	

	//channel by channel histograms  NSScanner
	[aDataSet histogram:energy 
				numBins:histoLen sender:self  
			   withKeys:@"FLT", @"Energy", crateKey,stationKey,channelKey,nil];
	
	//accumulated card level histograms
	[aDataSet histogram:energy 
				numBins:histoLen sender:self  
			   withKeys:@"FLT", @"Total Card Energy", crateKey,stationKey,nil];
	
	//accumulated crate level histograms
	[aDataSet histogram:energy 
				numBins:histoLen sender:self  
			   withKeys:@"FLT", @"Total Crate Energy", crateKey,nil];
	
	
	// Set up the waveform
	NSData* waveFormdata = [NSData dataWithBytes:someData length:length*sizeof(long)];
    //TODO: no offset -tb-
    startIndex=traceStart16;
	[aDataSet loadWaveform: waveFormdata					//pass in the whole data set
					offset: 9*sizeof(long)					// Offset in bytes (past header words)
				  unitSize: sizeof(short)					// unit size in bytes
				startIndex:	startIndex					// first Point Index (past the header offset!!!)
					  mask:	0x0FFF							// when displayed all values will be masked with this value
			   specialBits:0xF000						
				  bitNames: [NSArray arrayWithObjects:@"---",@"appPg",@"inhibit", @"trigger",nil]
					sender: self 
				  withKeys: @"FLT", @"Waveform",crateKey,stationKey,channelKey,nil];

	//get the actual object
	if(getRatesFromDecodeStage || getFifoFlagsFromDecodeStage){
		NSString* fltKey = [crateKey stringByAppendingString:stationKey];
		if(!actualFlts)actualFlts = [[NSMutableDictionary alloc] init];
		ORKatrinV4FLTModel* obj = [actualFlts objectForKey:fltKey];
		if(!obj){
			NSArray* listOfFlts = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORKatrinV4FLTModel")];
			for(ORKatrinV4FLTModel* aFlt in listOfFlts){
				if(/*[aFlt crateNumber] == crate &&*/ [aFlt stationNumber] == card){
					[actualFlts setObject:aFlt forKey:fltKey];
					obj = aFlt;
					break;
				}
			}
		}
		if(getRatesFromDecodeStage)    getRatesFromDecodeStage     = [obj bumpRateFromDecodeStage:chan];
		if(getFifoFlagsFromDecodeStage)  {
			if(fifoFlags != oldFifoFlags[chan]){
				getFifoFlagsFromDecodeStage = [obj setFromDecodeStage:chan fifoFlags:fifoFlags];
			}
		}	
	}
	
										
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{

	unsigned long length	= ExtractLength(ptr[0]);
	//unsigned char crate		= ShiftAndExtract(ptr[1],21,0xf);
	//unsigned char card		= ShiftAndExtract(ptr[1],16,0x1f);
	//unsigned char chan		= ShiftAndExtract(ptr[1],8,0xff);
    uint32_t sec            = ptr[2];
    uint32_t subsec         = ptr[3]; // ShiftAndExtract(ptr[1],0,0xffffffff);
    uint32_t chmap          = ptr[4];
    uint32_t eventID        = ptr[5];
    uint32_t fifoEventId    = ShiftAndExtract(ptr[6],20,0xfff);
    uint32_t energy         = ShiftAndExtract(ptr[6],0,0xfffff);
    uint32_t eventFlags     = ptr[7];
    uint32_t traceStart16 = ShiftAndExtract(eventFlags,8,0x7ff);//start of trace in short array
    
    NSString* title= @"Katrin V4 FLT Waveform Record\n\n";

	++ptr;		//skip the first word (dataID and length)
    
    NSString* crate     = [NSString stringWithFormat:@"Crate      = %lu\n",(*ptr>>21) & 0xf];
    NSString* card      = [NSString stringWithFormat:@"Station    = %lu\n",(*ptr>>16) & 0x1f];
    NSString* chan      = [NSString stringWithFormat:@"Channel    = %lu\n",(*ptr>>8) & 0xff];
    NSString* secStr    = [NSString stringWithFormat:@"Sec        = %d\n", sec];
    NSString* subsecStr = [NSString stringWithFormat:@"SubSec     = %d\n", subsec];
    NSString* fifoEventIdStr 
					    = [NSString stringWithFormat:@"FifoEventId= %d\n", fifoEventId];
    NSString* energyStr = [NSString stringWithFormat:@"Energy     = %d\n", energy];
    NSString* chmapStr  = [NSString stringWithFormat:@"ChannelMap = 0x%x\n", chmap];
    NSString* eventIDStr= [NSString stringWithFormat:@"ReadPtr,Pg#= %d,%d\n", ShiftAndExtract(eventID,0,0x3ff),ShiftAndExtract(eventID,10,0x3f)];
    NSString* offsetStr = [NSString stringWithFormat:@"Offset16   = %d\n", traceStart16];
    NSString* versionStr= [NSString stringWithFormat:@"RecVersion = %d\n", ShiftAndExtract(eventFlags,0,0xf)];
    NSString* eventFlagsStr
                        = [NSString stringWithFormat:@"Flag(a,ap) = %d,%d\n", ShiftAndExtract(eventFlags,4,0x1),ShiftAndExtract(eventFlags,5,0x1)];
    NSString* lengthStr = [NSString stringWithFormat:@"Length     = %lu\n", length];
    
    
    NSString* evFlagsStr= [NSString stringWithFormat:@"EventFlags = 0x%x\n", eventFlags ];

    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@",title,crate,card,chan,  
                secStr, subsecStr, fifoEventIdStr, energyStr, chmapStr, eventIDStr, offsetStr, versionStr, eventFlagsStr, lengthStr,   evFlagsStr]; 
}

@end








@implementation ORKatrinV4FLTDecoderForHitRate

//-------------------------------------------------------------
//2013-04-24 -tb- extended data format to support 32 bit hitrate register (added additional set of words at end of old record format)
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
			         ---^ ^^^^-----------number of channels NOC (=num of contained HR values)                        //2013-04-24 added -tb-
                                       ^-record version (0x0 old (wrong) version; 0x1: appending 32-bit HR registers //2013-04-24 added -tb-
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx sec (readout second!)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx hitRate length
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx total hitRate
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx                             
      ^^^^ ^^^^-------------------------- channel (0..23)
			       ^--------------------- overflow  
				     ^^^^ ^^^^ ^^^^ ^^^^- hitrate ('hitrate')
 ...  (NOC) x times
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  'hitrate32': 32 bit hitrate register (channel number: stored in according 'hitrate' words) //2013-04-24 added -tb-                            
 ...  (NOC) x times
 </pre>
 *
 */
//-------------------------------------------------------------


- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr = (unsigned long*)someData;
	unsigned long length	= ExtractLength(ptr[0]);
	unsigned char crate		= ShiftAndExtract(ptr[1],21,0xf);
	unsigned char card		= ShiftAndExtract(ptr[1],16,0x1f);
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* stationKey	= [self getStationKey: card];	
	unsigned long seconds	= ptr[2];
	unsigned long hitRateTotal = ptr[4];
	int i;
	int n = length - 5;
	for(i=0;i<n;i++){
		int chan = ShiftAndExtract(ptr[5+i],20,0xff);
		NSString* channelKey	= [self getChannelKey:chan];
		unsigned long hitRate = ShiftAndExtract(ptr[5+i],0,0xffff);
		if(hitRate){
			[aDataSet histogram:hitRate
							   numBins:65536 
								sender:self  
							  withKeys: @"FLT",@"HitrateHistogram",crateKey,stationKey,channelKey,nil];
			
			[aDataSet loadData2DX:card y:chan z:hitRate size:25  sender:self  withKeys:@"FLT",@"HitRate_2D",crateKey, nil];
			[aDataSet sumData2DX:card y:chan z:hitRate size:25  sender:self  withKeys:@"FLT",@"HitRateSum_2D",crateKey, nil];
		}
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
    NSString* crate = [NSString stringWithFormat:@"Crate      = %lu\n",ShiftAndExtract(ptr[1],21,0xf)];
    NSString* card  = [NSString stringWithFormat:@"Station    = %lu\n",ShiftAndExtract(ptr[1],16,0x1f)];
	
	unsigned long length		= ExtractLength(ptr[0]);
    uint32_t ut_time			= ptr[2];
    uint32_t hitRateLengthSec	= ptr[3]; // ShiftAndExtract(ptr[1],0,0xffffffff);
    uint32_t newTotal			= ptr[4];

	NSDate* date = [NSDate dateWithTimeIntervalSince1970:ut_time];
	
	NSMutableString *hrString;


    uint32_t version                = ShiftAndExtract(ptr[1],0,0x1);    //bit 1 = version
    uint32_t countHREnabledChans    = ShiftAndExtract(ptr[1],8,0x1f);   //NOC in record
    if(version==1) title= @"Katrin FLT Hit Rate Record v1\n\n";

	int i;
    
    
    if(version==0x1){
	    hrString = [NSMutableString stringWithFormat:@"SLTsecond     = %d\nHitrateLen = %d\nTotal HR   = %d\n",
						  ut_time,hitRateLengthSec,newTotal];
        for(i=0; i<countHREnabledChans; i++){
            uint32_t chan	= ShiftAndExtract(ptr[5+i],20,0xff);
            uint32_t over	= ShiftAndExtract(ptr[5+countHREnabledChans+i],23,0x1);
            uint32_t hitrate= ShiftAndExtract(ptr[5+countHREnabledChans+i], 0,0x7fffff);
            uint32_t pileupcount= ShiftAndExtract(ptr[5+countHREnabledChans+i], 24,0xff);
            if(over)
                [hrString appendString: [NSString stringWithFormat:@"Chan %2d    = OVERFLOW\n", chan] ];
            else
                [hrString appendString: [NSString stringWithFormat:@"Chan %2d    = %d\n", chan,hitrate] ];
            //[hrString appendString: [NSString stringWithFormat:@"PilUpCnt %2d    = %d\n", chan,  pileupcount] ];
            [hrString appendString: [NSString stringWithFormat:    @"  PilUpCnt = %d\n",   pileupcount] ];
        }
        
    }else{
	    hrString = [NSMutableString stringWithFormat:@"UTTime     = %d\nHitrateLen = %d\nTotal HR   = %d\n",
						  ut_time,hitRateLengthSec,newTotal];
        for(i=0; i<length-5; i++){
            uint32_t chan	= ShiftAndExtract(ptr[5+i],20,0xff);
            uint32_t over	= ShiftAndExtract(ptr[5+i],16,0x1);
            uint32_t hitrate= ShiftAndExtract(ptr[5+i], 0,0xffff);
            if(over)
                [hrString appendString: [NSString stringWithFormat:@"Chan %2d    = OVERFLOW\n", chan] ];
            else
                [hrString appendString: [NSString stringWithFormat:@"Chan %2d    = %d\n", chan,hitrate] ];
        }
    }
    
    
    return [NSString stringWithFormat:@"%@%@%@%@%@",title,crate,card,[date descriptionFromTemplate:@"MM/dd/yy HH:mm:ss z\n"],hrString];
}
@end




@implementation ORKatrinV4FLTDecoderForHistogram

//-------------------------------------------------------------
/** Data format for hardware histogram
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
                                 ^^------boxcarLen  (<-- not necessary; temporarily set to have same header for all except hitrate record -tb-)
                                    ^^^^-filterShapingLength    (<-- not necessary; temporarily set to have same header for all except hitrate record -tb-)
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx readoutSec
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx refreshTime  (was recordingTimeSec)
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx firstBin
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx lastBin
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx histogramLength
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx maxHistogramLength
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx binSize
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx offsetEMin
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx histogramID
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx histogramInfo (some flags; some spare for future extensions)
                                      ^-pageAB flag
									 ^--is set for sum histogram (mask 0x02)
                                    ^---is set for between-subrun sum histogram (mask 0x04)
</pre>

  * For more infos: see
  * readOutHistogramDataV3:(ORDataPacket*)aDataPacket userInfo:(id)userInfo (in model)
  *
  */
//-------------------------------------------------------------

- (id) init
{
    //NSLog(@"DEBUG: Calling %@ :: %@   <<<<------ wie oft?\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG init is called twice at run start and once at 'start subrun' ...-tb-
    self = [super init];
    getHistoReceivedNoteFromDecodeStage = YES;
    return self;
}

- (void) dealloc
{
	[actualFlts release];
    [super dealloc];
}


- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
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
	
	katrinV4HistogramDataStruct* ePtr = (katrinV4HistogramDataStruct*) ptr;

    ptr = ptr + (sizeof(katrinV4HistogramDataStruct)/sizeof(long));// points now to the histogram data -tb-
    
	int isSumHistogram = ePtr->histogramInfo & 0x2; //the bit1 marks the Sum Histograms
    // this counts one histogram as one event in data monitor -tb-
    //if(ePtr->histogramLength){ //uncommented -  I want to see empty histograms
	if(!isSumHistogram) {
        int numBins = 2048; //TODO: this has changed for V4 to 2048!!!! -tb-512;
		if(ePtr->maxHistogramLength>numBins) numBins=ePtr->maxHistogramLength;
        unsigned long data[numBins];// v3: histogram length is 512 -tb-
        int i;
        for(i=0; i< numBins;i++) data[i]=0;
        for(i=0; i< ePtr->histogramLength;i++){
            data[i+(ePtr->firstBin)]=*(ptr+i);
            //NSLog(@"Decoder: HistoEntry %i: bin %i val %i\n",i,i+(ePtr->firstBin),data[i+(ePtr->firstBin)]);
        }
        NSMutableArray*  keyArray = [NSMutableArray arrayWithCapacity:5];
        [keyArray insertObject:@"FLT" atIndex:0];
        [keyArray insertObject:@"Energy Histogram (HW)" atIndex:1]; //TODO: 1. use better name 2. keep memory clean -tb-
        [keyArray insertObject:crateKey atIndex:2];
        [keyArray insertObject:stationKey atIndex:3];
        [keyArray insertObject:channelKey atIndex:4];
        
        [aDataSet mergeHistogram:  data  
                         numBins:  numBins  // is fixed in the current FPGA version -tb- 2008-03-13 
                    withKeyArray:  keyArray];
    }
    else {
        int numBins = 2048; //TODO: this has changed for V4 to 2048!!!! -tb-512;
		if(ePtr->maxHistogramLength>numBins) numBins=ePtr->maxHistogramLength;
        unsigned long data[numBins];// v3: histogram length is 512 -tb-
        int i;
        for(i=0; i< numBins;i++) data[i]=0;
        for(i=0; i< ePtr->histogramLength;i++){
            data[i+(ePtr->firstBin)]=*(ptr+i);
            //NSLog(@"Decoder: HistoEntry %i: bin %i val %i\n",i,i+(ePtr->firstBin),data[i+(ePtr->firstBin)]);
        }
        NSMutableArray*  keyArray = [NSMutableArray arrayWithCapacity:6];
        [keyArray insertObject:@"FLT" atIndex:0];
        [keyArray insertObject:@"Energy Histogram (HW) Summed" atIndex:1]; //TODO: 1. use better name 2. keep memory clean -tb-
        [keyArray insertObject:crateKey atIndex:2];
        [keyArray insertObject:stationKey atIndex:3];
        [keyArray insertObject:channelKey atIndex:4];
        if(ePtr->histogramInfo & 0x4) [keyArray insertObject:@"BetweenSubruns" atIndex:5];
        
        [aDataSet mergeHistogram:  data  
                         numBins:  numBins  // is fixed in the current FPGA version -tb- 2008-03-13 
                    withKeyArray:  keyArray];
    }
    

	//get the actual object
	if(getHistoReceivedNoteFromDecodeStage){
		NSString* fltKey = [crateKey stringByAppendingString:stationKey];
		if(!actualFlts)actualFlts = [[NSMutableDictionary alloc] init];
		ORKatrinV4FLTModel* obj = [actualFlts objectForKey:fltKey];
		if(!obj){
			NSArray* listOfFlts = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORKatrinV4FLTModel")];
			for(ORKatrinV4FLTModel* aFlt in listOfFlts){
				if(/*[aFlt crateNumber] == crate &&*/ [aFlt stationNumber] == card){ //TODO: we might have multiple crates in the future -tb-
					[actualFlts setObject:aFlt forKey:fltKey];
					obj = aFlt;
					break;
				}
			}
		}
		if(getHistoReceivedNoteFromDecodeStage)    [obj addToSumHistogram: someData];
		if(getHistoReceivedNoteFromDecodeStage)    getHistoReceivedNoteFromDecodeStage  =  [obj setFromDecodeStageReceivedHistoForChan:chan ];
    }
    

    return length; //must return number of longs processed.
}



- (NSString*) dataRecordDescription:(unsigned long*)ptr
{

    NSString* title; //= @"Katrin V4 FLT Histogram Record\n\n";
	++ptr;		//skip the first word (dataID and length)
    
    NSString* crate = [NSString stringWithFormat:@"Crate      = %lu\n",(*ptr>>21) & 0xf];
    NSString* card  = [NSString stringWithFormat:@"Station    = %lu\n",(*ptr>>16) & 0x1f];
    NSString* chan  = [NSString stringWithFormat:@"Channel    = %lu\n",(*ptr>>8) & 0xff];
	++ptr;		//point to next structure

	katrinV4HistogramDataStruct* ePtr = (katrinV4HistogramDataStruct*)ptr;			//recast to event structure

	int isSumHistogram = ePtr->histogramInfo & 0x2; //the bit1 marks the Sum Histograms
	if(!isSumHistogram) title= @"Katrin V4 FLT Histogram Record\n\n";
	else                title= @"Katrin V4 FLT Summed Histogram Record\n\n";
	
	NSString* readoutSec	= [NSString stringWithFormat:@"ReadoutSec = %d\n",ePtr->readoutSec];
	NSString* refreshTimeSec	= [NSString stringWithFormat:@"recordingTimeSec = %d\n",ePtr->refreshTimeSec];
	NSString* firstBin	= [NSString stringWithFormat:@"firstBin = %d\n",ePtr->firstBin];
	NSString* lastBin	= [NSString stringWithFormat:@"lastBin  = %d\n",ePtr->lastBin];
	NSString* histogramLength		= [NSString stringWithFormat:@"histogramLength    = %d\n",ePtr->histogramLength];
	NSString* maxHistogramLength	= [NSString stringWithFormat:@"maxHistogramLength = %d\n",ePtr->maxHistogramLength];
	NSString* binSize		= [NSString stringWithFormat:@"binSize    = %d\n",ePtr->binSize];
	NSString* offsetEMin	= [NSString stringWithFormat:@"offsetEMin = %d\n",ePtr->offsetEMin];
	NSString* histIDInfo	= [NSString stringWithFormat:@"ID         = %d.%c\n",ePtr->histogramID,(ePtr->histogramInfo&0x1)?'B':'A'];


    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@%@",title,crate,card,chan,
	                       readoutSec,refreshTimeSec,firstBin,lastBin,histogramLength,
                           maxHistogramLength,binSize,offsetEMin,histIDInfo]; 
}

@end


