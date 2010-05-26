//
//  ORSIS3800Decoders.m
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

#import "ORSIS3800Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORDataTypeAssigner.h"
#import "ORSIS3800Model.h"

/*
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^^ ^^^^ ^^----------------------- Data ID (from header)
 -----------------^^ ^^^^ ^^^^ ^^^^ ^^^^- length
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 --------^-^^^--------------------------- Crate number
 -------------^-^^^^--------------------- Card number
 --------------------------------------^- 1==SIS38001, 0==SIS3000 
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx-Trigger Event Word
 ^---------------------------------------1 if ADC0 in this event
 -^--------------------------------------1 if ADC1 in this event
 --^-------------------------------------1 if ADC2 in this event
 ---^------------------------------------1 if ADC3 in this event
 -----^----------------------------------1 if ADC4 in this event
 ------^---------------------------------1 if ADC5 in this event
 -------^--------------------------------1 if ADC6 in this event
 --------^-------------------------------1 if ADC7 in this event
 ------------^---------------------------1 if wrapped
 ---------------^^^^ ^^^^ ^^^^ ^^^^ ^^^^-Event Data End Address
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^^-------------------------------Event #
 ----------^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^-Time from previous event always zero unless in multievent mode
 
 waveform follows:
 Each word may have data for two ADC channels. The high order 16
 bits are for ADC0,2,4,6. The low order bits are for ADC1,3,5,7
 
 if SIS3800:
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^----------------------------------------Status of User Bit
 --------------------^--------------------Status of Gate Chaining Bit
 ---^-------------------^-----------------Out of Range Bit
 -----^^^^ ^^^^ ^^^^------^^^^ ^^^^ ^^^^--12 bit Data
 if SIS3301:
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^---------------------------------------Status of User Bit
 --------------------^-------------------Status of Gate Chaining Bit
 -^-------------------^------------------Out of Range Bit
 --^^ ^^^^ ^^^^ ^^^^---^^ ^^^^ ^^^^ ^^^^-14-bit Data
 */

@implementation ORSIS3800WaveformDecoder

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr = (unsigned long*)someData;
	unsigned long length = ExtractLength(*ptr);
 
    return length; //must return number of longs
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
	ptr++;
    NSString* title= @"SIS3800 Waveform Record\n\n";
    NSString* crate = [NSString stringWithFormat:@"Crate = %d\n",(*ptr&0x01e00000)>>21];
    NSString* card  = [NSString stringWithFormat:@"Card  = %d\n",(*ptr&0x001f0000)>>16];
	NSString* moduleID = (*ptr&0x1)?@"SIS3301":@"SIS3800";
	ptr++;
	NSString* triggerWord = [NSString stringWithFormat:@"TriggerWord  = 0x08%x\n",*ptr];
	ptr++;
	NSString* Event = [NSString stringWithFormat:@"Event  = 0x%08x\n",(*ptr>>24)&0xff];
	NSString* Time = [NSString stringWithFormat:@"Time Since Last Trigger  = 0x%08x\n",*ptr&0xffffff];

    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@",title,crate,card,moduleID,triggerWord,Event,Time];               
}

@end
