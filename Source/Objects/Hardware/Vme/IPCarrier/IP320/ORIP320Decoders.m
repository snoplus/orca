//
//  ORIP320Decoders.m
//  Orca
//
//  Created by Mark Howe on 3/4/08.
//  Copyright 2008 CENPA, University of Washington. All rights reserved.
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


#import "ORIP320Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORDataTypeAssigner.h"
#import "ORIP320Model.h"

@implementation ORIP320DecoderForAdc
- (id) init
{
    self = [super init];
    getValuesFromDecoderStage = YES;
    return self;
}

- (void) dealloc
{
	[actualIP320s release];
    [super dealloc];
}

- (unsigned long) decodeData:(void*)someData fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr	 = (unsigned long*)someData;
    unsigned long length = ExtractLength(*ptr);
	ptr++;
	unsigned char crate  = (*ptr&0x01e00000)>>21;
	unsigned char card   = (*ptr& 0x001f0000)>>16;
	unsigned char ipSlot = *ptr&0x0000000f;
	NSString* crateKey	 = [self getCrateKey: crate];
	NSString* cardKey	 = [self getCardKey: card];
	NSString* ipSlotKey  = [NSString stringWithFormat:@"IPSlot %2d",ipSlot];
	
	[aDataSet loadGenericData:@" " sender:self withKeys:@"IP320",crateKey,cardKey,ipSlotKey,nil];

	//get the actual object
	if(getValuesFromDecoderStage){
		NSString* ip320Key = [crateKey stringByAppendingString:cardKey];
		if(!actualIP320s)actualIP320s = [[NSMutableDictionary alloc] init];
		ORIP320Model* obj = [actualIP320s objectForKey:ip320Key];
		if(!obj){
			NSArray* listOfIP320s = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORIP320Model")];
			NSEnumerator* e = [listOfIP320s objectEnumerator];
			ORIP320Model* anIP320;
			while(anIP320 = [e nextObject]){
				if([anIP320 crateNumber] == crate && [[anIP320 guardian] slot] == card && [anIP320 slot] == ipSlot){
					[actualIP320s setObject:anIP320 forKey:ip320Key];
					obj = anIP320;
					break;
				}
			}
		}
		getValuesFromDecoderStage = [obj processDataBlock:(unsigned long*)someData length:length];
	}

	
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    unsigned long length = ExtractLength(*ptr);
    NSString* title= @"IP320 ADC Record\n\n";

	ptr++;
    NSString* crate			= [NSString stringWithFormat:@"Crate = %d\n",(*ptr&0x01e00000)>>21];
    NSString* card			= [NSString stringWithFormat:@"Card  = %d\n",(*ptr&0x001f0000)>>16];
	NSString* ipSlotKey		= [NSString stringWithFormat:@"IPSlot %2d\n",*ptr&0x0000000f];

	ptr++;
	NSCalendarDate* date = [NSCalendarDate dateWithTimeIntervalSince1970:*ptr];
	[date setCalendarFormat:@"%m/%d/%y %H:%M:%S %z"];

	NSString* adcString = @"";
	int n = length - 3;
	int i;
	for(i=0;i<n;i++){
		ptr++;
		adcString   = [adcString stringByAppendingFormat:@"ADC(%02d) = 0x%x\n",(*ptr>>16)&0x000000ff, *ptr&0x00000fff];
    }
    return [NSString stringWithFormat:@"%@%@%@%@%@%@",title,crate,card,ipSlotKey,date,adcString];               
}


@end


