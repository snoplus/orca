//
//  ORBurstMonitorDecoders.m
//  Orca
//
//  Created by Mark Howe on 08/1/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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


#import "ORBurstMonitorDecoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"

//------------------------------------------------------------------------------------------------
// Data Format
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
// ^^^^ ^^^^ ^^^^ ^^------------------------data id
//                  ^^ ^^^^ ^^^^ ^^^^ ^^^^--length in longs
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  ut time
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  burst count
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  numSecTilBurst
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  float duration encoded as long
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  counts in burst
//-----------------------------------------------------------------------------------------------

@implementation ORBurstMonitorDecoderForBurst

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr = (unsigned long*)someData;
		
    NSString* valueString = [NSString stringWithFormat:@"%ld",ptr[2]];
    
	[aDataSet loadGenericData:valueString sender:self withKeys:@"BurstMonitor",@"BurstCount",nil];
	
     return ExtractLength(ptr[0]); //must return the length
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"Burst Info Record\n\n";

    //get the duration
    union {
        long theLong;
        float theFloat;
    }duration;
    duration.theLong = ptr[4];
    
    NSString* theDuration           = [NSString stringWithFormat:@"Duration = %.3f seconds\n",duration.theFloat];
    NSString* theBurstCount         = [NSString stringWithFormat:@"Burst Count = %ld\n",ptr[2]];
    NSString* theNumSecTilBurst     = [NSString stringWithFormat:@"Sec Til Burst = %ld\n",ptr[3]];
    NSString* countsInBurst         = [NSString stringWithFormat:@"Counts in burst = %ld\n",ptr[5]];
    
    return [NSString stringWithFormat:@"%@%s%@%@%@%@",title,ctime((const time_t *)(&ptr[1])),theDuration,theBurstCount,theNumSecTilBurst,countsInBurst];
}
@end


