//
//  ORMTCDecoders.m
//  Orca
//
//Created by Mark Howe on Fri, May 2, 2008
//Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
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


#import "ORMTCDecoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORMTCModel.h"
#import "ORDataTypeAssigner.h"

@implementation ORMTCDecoderForMTC

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr = (unsigned long*)someData;
	unsigned long length = ExtractLength(*ptr);
    return length; //must return number of bytes processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
	ptr++;
	NSString* sCnt10Mhz = [NSString stringWithFormat:@"10 Mhz = 0x%014qx\n",
		((unsigned long long) (ptr[1] & 0x001fffff) << 32 | *ptr)];
	ptr++;
	NSString* sCnt50Mhz = [NSString stringWithFormat:@"50 Mhz = 0x%011qx\n",
		((unsigned long long) ptr[1]) << 11 | (*ptr & 0xffe00000) >> 21];
	ptr +=2;
	NSString* sGTId = [NSString stringWithFormat:@"GTId = 0x%06lx\n", *ptr & 0x00ffffff];

	NSString* sGTMask = [NSString stringWithFormat:@"GTMask = 0x%07lx\n",
		((*ptr >> 24) & 0xff) | ((ptr[1] & 0x0003ffff) << 8)];  
	ptr++;
	NSString* sMissTrg = [NSString stringWithFormat:@"Missed Trigger: %@\n",
		(*ptr & 0x00040000) ? @"Yes" : @"No"];

	NSString* sVlt = [NSString stringWithFormat:@"Voltage peak = 0x%03lx\n",
			      *ptr >> 19 & 0x01ff];

	NSString* sSlp = [NSString stringWithFormat:@"Voltage slope = 0x%03lx\n",
			  *ptr >> 29 | ((ptr[1] & 0x7fUL) << 3 )];
	ptr++;
	NSString* sInt = [NSString stringWithFormat:@"Integral thr = 0x%03lx\n",
			  *ptr >> 7 & 0x3ffUL];

	NSString* sWrd5 = [NSString stringWithFormat:@"wrd5_hi = 0x%04lx\n", *ptr >> 16];
	
	return [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@", 
		sCnt10Mhz, sCnt50Mhz, sGTId, sGTMask, sMissTrg, sVlt, sSlp, sInt, sWrd5];
}


@end


@implementation ORMTCDecoderForMTCStatus

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr = (unsigned long*)someData;
	unsigned long length = ExtractLength(*ptr);
    return length; //must return number of bytes processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
	return @"";
}

@end
