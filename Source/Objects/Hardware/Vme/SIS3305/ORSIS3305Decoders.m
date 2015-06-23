//
//  ORSIS3305Decoders.m
//  Orca
//
//  Created by Mark A. Howe on Wednesday 9/30/08.
//  Copyright (c) 2008 CENPA. University of Washington. All rights reserved.
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

#import "ORSIS3305Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORDataTypeAssigner.h"
#import "ORSIS3305Model.h"


@implementation ORSIS3305DecoderForWaveform
//------------------------------------------------------------------
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//^^^^ ^^^^ ^^^^ ^^-----------------------data id
//                 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//^^^^ ^^^--------------------------------most  sig bits of num records lost
//------------------------------^^^^-^^^--least sig bits of num records lost
//        ^ ^^^---------------------------crate
//             ^ ^^^^---------------------card
//                    ^^^^ ^^^^-----------channel
//                                      ^--buffer wrap mode
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx-length of waveform (longs)
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx-length of energy   (longs)
// ---- followed by the data record as read 
//from hardware. see the manual. Be careful-- the new 15xx firmware data structure 
//is slightly diff (two extra words -- if the buffer wrap bit is set)
// ---- should end in 0xdeadbeef
//------------------------------------------------------------------
#define kPageLength (65*1024)

- (id) init
{
    self = [super init];
    getRatesFromDecodeStage = YES;
    return self;
}

- (void) dealloc
{
	[actualSIS3305Cards release];
    [super dealloc];
}


- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr	= (unsigned long*)someData;
	unsigned long length= ExtractLength(ptr[0]);
	int crate			= ShiftAndExtract(ptr[1],21,0xf);
	int card			= ShiftAndExtract(ptr[1],16,0x1f);
	int channel			= ShiftAndExtract(ptr[1],8,0xff);
	BOOL wrapMode		= ShiftAndExtract(ptr[1],0,0x1);
	
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* cardKey		= [self getCardKey: card];
	NSString* channelKey	= [self getChannelKey: channel];
	
	//int waveformLength1	 = ptr[2];
	//int energyLength1	 = ptr[3];
	//int waveformLength2	 = ptr[6];

	long sisHeaderLength;
	if(wrapMode)sisHeaderLength = 16;
	else		sisHeaderLength = 4;
    //unsigned long energy = ptr[length - 4];
    
 //??????? delete   [aDataSet histogram:energy numBins:65536 sender:self  withKeys:@"SIS3305", @"Energy", crateKey,cardKey,channelKey,nil];
    
    unsigned long waveformLength = ptr[2]; //each long word is two 16 bit adc samples

    if(waveformLength /*&& (waveformLength == (length - 3))*/){
        NSMutableData*  recordAsData = [NSMutableData dataWithCapacity:waveformLength*3];
        if(wrapMode){
            unsigned long nof_wrap_samples = ptr[6] ;
            if(nof_wrap_samples <= waveformLength*2){
                unsigned long wrap_start_index = ptr[7] ;
                unsigned short* dataPtr			  = (unsigned short*)[recordAsData bytes];
                unsigned short* ushort_buffer_ptr = (unsigned short*) &ptr[8];
                int i;
                unsigned long j	=	wrap_start_index; 
                for (i=0;i<nof_wrap_samples;i++) { 
                    if(j >= nof_wrap_samples ) j=0;
                    dataPtr[i] = ushort_buffer_ptr[j++];
                }
            }
        }
        else {
            [recordAsData setLength:1024*3];
            unsigned long* lptr = (unsigned long*)&ptr[3 + sisHeaderLength]; //ORCA header + SIS header
            int i;
            unsigned short* waveData = (unsigned short*)[recordAsData bytes];
            int waveformIndex = 0;
            for(i=0;i<waveformLength/3;i++){
                waveData[waveformIndex++] = lptr[i]&0x3ff;
                waveData[waveformIndex++] = (lptr[i]>>10)&0x3ff;
                waveData[waveformIndex++] = (lptr[i]>>20)&0x3ff;
            }
            
            
        }
        if(recordAsData)[aDataSet loadWaveform:recordAsData
                        offset: 0 //bytes!
                      unitSize: 2 //unit size in bytes!
                        sender: self  
                      withKeys: @"SIS3305", @"Waveform",crateKey,cardKey,channelKey,nil];
    }
	
    return length; //must return number of longs
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
	
	//TODO ---- 
	/*
	 ptr++;
	 NSString* title= @"SIS3305 Waveform Record\n\n";
	 NSString* crate = [NSString stringWithFormat:@"Crate = %d\n",(*ptr&0x01e00000)>>21];
	 NSString* card  = [NSString stringWithFormat:@"Card  = %d\n",(*ptr&0x001f0000)>>16];
	 NSString* moduleID = (*ptr&0x1)?@"SIS3301":@"SIS3305";
	 ptr++;
	 NSString* triggerWord = [NSString stringWithFormat:@"TriggerWord  = 0x08%x\n",*ptr];
	 ptr++;
	 NSString* Event = [NSString stringWithFormat:@"Event  = 0x%08x\n",(*ptr>>24)&0xff];
	 NSString* Time = [NSString stringWithFormat:@"Time Since Last Trigger  = 0x%08x\n",*ptr&0xffffff];
	 
	 return [NSString stringWithFormat:@"%@%@%@%@%@%@%@",title,crate,card,moduleID,triggerWord,Event,Time];       
	 */
	return @"Description not implemented yet";
}
@end


