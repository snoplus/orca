//
//  ORShaperDecoders.m
//  Orca
//
//  Created by Mark Howe on 9/21/04.
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


#import "ORShaperDecoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORShaperModel.h"
#import "ORDataTypeAssigner.h"

@implementation ORShaperDecoderForShaper

- (id) init
{
    self = [super init];
    getRatesFromDecodeStage = YES;
    return self;
}

- (void) dealloc
{
	[actualShapers release];
    [super dealloc];
}

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long length;
    unsigned long* ptr = (unsigned long*)someData;
    if(IsShortForm(*ptr)){
        length = 1;
    }
    else  {       //oh, we have been assign the long form--skip to the next long word for the data
        ptr++;
        length = 2;
    }
    
	unsigned char crate   = (*ptr&0x01e00000)>>21;
	unsigned char card   = (*ptr& 0x001f0000)>>16;
	unsigned char channel = (*ptr&0x0000f000)>>12;
	NSString* crateKey = [self getCrateKey: crate];
	NSString* cardKey = [self getCardKey: card];
	NSString* channelKey = [self getChannelKey: channel];
	
    [aDataSet histogram:*ptr&0x00000fff numBins:4096 sender:self  withKeys:@"Shaper", crateKey,cardKey,channelKey,nil];
	
	//get the actual object
	if(getRatesFromDecodeStage){
		NSString* shaperKey = [crateKey stringByAppendingString:cardKey];
		if(!actualShapers)actualShapers = [[NSMutableDictionary alloc] init];
		ORShaperModel* obj = [actualShapers objectForKey:shaperKey];
		if(!obj){
			NSArray* listOfShapers = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORShaperModel")];
			NSEnumerator* e = [listOfShapers objectEnumerator];
			ORShaperModel* aShaper;
			while(aShaper = [e nextObject]){
				if(/*[aShaper crateNumber] == crate &&*/ [aShaper slot] == card){
					[actualShapers setObject:aShaper forKey:shaperKey];
					obj = aShaper;
					break;
				}
			}
		}
		getRatesFromDecodeStage = [obj bumpRateFromDecodeStage:channel];
	}
    return length; //must return number of bytes processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    if(!IsShortForm(*ptr)){
        ptr++;
    }

    NSString* title= @"Shaper ADC Record\n\n";
    
    NSString* crate = [NSString stringWithFormat:@"Crate = %d\n",(*ptr&0x01e00000)>>21];
    NSString* card  = [NSString stringWithFormat:@"Card  = %d\n",(*ptr&0x001f0000)>>16];
    NSString* chan  = [NSString stringWithFormat:@"Chan  = %d\n",(*ptr&0x0000f000)>>12];
    NSString* adc   = [NSString stringWithFormat:@"ADC   = 0x%x\n",*ptr&0x00000fff];
    
    return [NSString stringWithFormat:@"%@%@%@%@%@",title,crate,card,chan,adc];               
}


@end

@implementation ORShaperDecoderForScalers
- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr   = (unsigned long*)someData;
    unsigned long length;
    length = ExtractLength(ptr[0]);
    
    NSString* gtidString = [NSString stringWithFormat:@"%d",ptr[1]];
    
    short crate = (ptr[2] & 0x1e000000)>>25;
    short card  = (ptr[2] & 0x01f00000)>>20;
    NSString* globalScaler = [NSString stringWithFormat:@"%d",ptr[3]];
	NSString* crateKey = [self getCrateKey: crate];
	NSString* cardKey = [self getCardKey: card];
    [aDataSet loadGenericData:gtidString sender:self withKeys:@"Scalers",@"Shaper",  crateKey,cardKey,@"GTID",nil];
    [aDataSet loadGenericData:globalScaler sender:self withKeys:@"Scalers",@"Shaper", crateKey,cardKey,@"Global",nil];

    short index = 4;
    do {
        short crate     = (ptr[index] & 0x1e000000)>>25;
        short card      = (ptr[index] & 0x01f00000)>>20;
        short channel   = (ptr[index] & 0x000f0000)>>16;

        NSString* crateKey = [self getCrateKey: crate];
        NSString* cardKey = [self getCardKey: card];
        NSString* channelKey = [self getChannelKey: channel];
        
        NSString* scaler = [NSString stringWithFormat:@"%d",ptr[index]&0x0000ffff];
        [aDataSet loadGenericData:scaler sender:self withKeys:@"Scalers",@"Shaper", crateKey,cardKey,channelKey,nil];
        index++;

    }while(index < length);

    return length;
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    unsigned long length = (ptr[0] & 0x003ffff);

    NSString* title= @"Shaper Scaler Record\n\n";
    
    NSString* gtid  = [NSString stringWithFormat:@"GTID  = %d\n",ptr[1]];
    NSString* crate = [NSString stringWithFormat:@"Crate = %d\n",(ptr[2] & 0x1e000000)>>25];
    NSString* card  = [NSString stringWithFormat:@"Card  = %d\n",(ptr[2] & 0x01f00000)>>20];    
    NSString* global= [NSString stringWithFormat:@"Total = %d\n",ptr[3]];
    NSString* subTitle =@"\nScalers by Card,Chan\n\n";
   
    short index = 4;
    NSString* restOfString = @"";
    do {
        restOfString = [restOfString stringByAppendingFormat:@"%2d,%2d  = %d\n",(ptr[index] & 0x01f00000)>>20,(ptr[index] & 0x000f0000)>>16,ptr[index]&0x0000ffff];
        index++;
    }while(index < length);

    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@",title,crate,card,gtid,global,subTitle,restOfString];               
}

@end

//------------------------------------------------------------------
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//^^^^ ^^^^ ^^^^ ^^-----------------------data id
//                 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//^^^^ ^^^--------------------------------spare
//        ^ ^^^---------------------------crate
//             ^ ^^^^---------------------card
//                    ^^^^ ^^^^-----------channel
//								^^^^ ^^^--spare
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx-seconds
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx-millisconds
//------------------------------------------------------------------

@implementation ORShaperDecoderForTime
- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr   = (unsigned long*)someData;
    unsigned long length = ExtractLength(ptr[0]);
    
	int crate	= ShiftAndExtract(ptr[1],21,0xf);
	int card	= ShiftAndExtract(ptr[1],16,0x1f);
	int channel = ShiftAndExtract(ptr[1],8,0xff);
	
 	NSString* crateKey		= [self getCrateKey: crate];
	NSString* cardKey		= [self getCardKey: card];
	NSString* channelKey	= [self getChannelKey: channel];

	NSString* infoString = [NSString stringWithFormat:@"%hu.%hu",ptr[2],ptr[3]];

    [aDataSet loadGenericData:infoString sender:self withKeys:@"Time",@"Shaper", crateKey, cardKey, channelKey, @"Time Record",nil];
	

    return length;
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{ 	
    NSString* title= @"Shaper Time Stamp\n\n";
 	int crate	= ShiftAndExtract(ptr[1],21,0xf);
	int card	= ShiftAndExtract(ptr[1],16,0x1f);
	int channel = ShiftAndExtract(ptr[1],8,0xff);
	
    NSString* crateString		= [NSString stringWithFormat:@"Crate = %d\n",crate];
    NSString* cardString		= [NSString stringWithFormat:@"Card  = %d\n",card];    
    NSString* channelString	= [NSString stringWithFormat:	 @"Channel = %d\n",channel];
	NSString* seconds	= [NSString stringWithFormat:		 @"Seconds = %hu.%hu\n",ptr[2],ptr[3]];
	
    return [NSString stringWithFormat:@"%@%@%@%@%@",title,crateString,cardString,channelString,seconds];               
}

@end




//ARGGGGGG -- because of a cut/paste error some data around jan '07 gat taken with a bugus decoder name
//temp insert this decoder so the data can be replayed.
@implementation ORShaperDecoderFORAxisrs
- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr   = (unsigned long*)someData;
    unsigned long length;
    length = ExtractLength(ptr[0]);
    
    NSString* gtidString = [NSString stringWithFormat:@"%d",ptr[1]];
    
    short crate = (ptr[2] & 0x1e000000)>>25;
    short card  = (ptr[2] & 0x01f00000)>>20;
    NSString* globalScaler = [NSString stringWithFormat:@"%d",ptr[3]];
	NSString* crateKey = [self getCrateKey: crate];
	NSString* cardKey = [self getCardKey: card];
    [aDataSet loadGenericData:gtidString sender:self withKeys:@"Scalers",@"Shaper",  crateKey,cardKey,@"GTID",nil];
    [aDataSet loadGenericData:globalScaler sender:self withKeys:@"Scalers",@"Shaper", crateKey,cardKey,@"Global",nil];

    short index = 4;
    do {
        short crate     = (ptr[index] & 0x1e000000)>>25;
        short card      = (ptr[index] & 0x01f00000)>>20;
        short channel   = (ptr[index] & 0x000f0000)>>16;

        NSString* crateKey = [self getCrateKey: crate];
        NSString* cardKey = [self getCardKey: card];
        NSString* channelKey = [self getChannelKey: channel];
        
        NSString* scaler = [NSString stringWithFormat:@"%d",ptr[index]&0x0000ffff];
        [aDataSet loadGenericData:scaler sender:self withKeys:@"Scalers",@"Shaper", crateKey,cardKey,channelKey,nil];
        index++;

    }while(index < length);

    return length;
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    unsigned long length = (ptr[0] & 0x003ffff);

    NSString* title= @"Shaper Scaler Record\n\n";
    
    NSString* gtid  = [NSString stringWithFormat:@"GTID  = %d\n",ptr[1]];
    NSString* crate = [NSString stringWithFormat:@"Crate = %d\n",(ptr[2] & 0x1e000000)>>25];
    NSString* card  = [NSString stringWithFormat:@"Card  = %d\n",(ptr[2] & 0x01f00000)>>20];    
    NSString* global= [NSString stringWithFormat:@"Total = %d\n",ptr[3]];
    NSString* subTitle =@"\nScalers by Card,Chan\n\n";
   
    short index = 4;
    NSString* restOfString = @"";
    do {
        restOfString = [restOfString stringByAppendingFormat:@"%2d,%2d  = %d\n",(ptr[index] & 0x01f00000)>>20,(ptr[index] & 0x000f0000)>>16,ptr[index]&0x0000ffff];
        index++;
    }while(index < length);

    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@",title,crate,card,gtid,global,subTitle,restOfString];               
}

@end

