//
//  SNOMonitoredHardware.h
//  Orca
//
//  Created by H S  Wan Chan Tseung on 11/18/11.
//  Copyright (c) 2011 CENPA, University of Washington. All rights reserved.
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


#import "SNOMonitoredHardware.h"
#import "SynthesizeSingleton.h"
#import "YAJL/YAJL.h"
#define TubeInRange(crate,card,channel) ((crate>=0) && (crate<kMaxSNOCrates) && (card>=0) && (card<kNumSNOCards) && (channel>=0) && (channel<kNumSNOPmts))

@implementation SNOMonitoredHardware

SYNTHESIZE_SINGLETON_FOR_CLASS(SNOMonitoredHardware);

- (void) readCableDBDocumentFromOrcaDB
{ 
	NSURLRequest *request;
	NSHTTPURLResponse *response;
	NSError *connectionError;
	NSString *urlName, *jsonStr;
	NSData *responseData;
	
	//get the id of the cableDB document
	urlName=[NSString stringWithFormat:@"http://localhost:5984/orca/_design/cable/_view/all"];	
	request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlName]];	
	responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&connectionError];
    jsonStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
	NSDictionary *jsonAllView = [jsonStr yajl_JSON];
	[jsonStr release];
	NSArray *allview = [jsonAllView objectForKey:@"rows"];
	NSString *docid = [[allview objectAtIndex:0] objectForKey:@"id"];
	
	//get the cableDB document and store it in a dictionary
	urlName=[NSString stringWithFormat:@"http://localhost:5984/orca/%@",docid];	
	request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlName]];	
	responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&connectionError];
    jsonStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
	NSDictionary *jsonCableDB = [jsonStr yajl_JSON];
	[jsonStr release];
	
	//init to defaults
	int crate,card,channel;
	for(crate=0;crate<kMaxSNOCrates+2;crate++){
		short card;
		for(card=0;card<kNumSNOCards;card++){
			short channel;
			for(channel=0;channel<kNumSNOPmts;channel++){
				SNOCrate[crate].Card[card].Pmt[channel].tubeType = kTubeTypeUnknown;
				SNOCrate[crate].Card[card].Pmt[channel].x				= 0;
				SNOCrate[crate].Card[card].Pmt[channel].y				= 0;
				SNOCrate[crate].Card[card].Pmt[channel].z				= 0;
				SNOCrate[crate].Card[card].Pmt[channel].cmosRate		= 0;
				SNOCrate[crate].Card[card].Pmt[channel].pmtBaseCurrent	= 0;
				SNOCrate[crate].Card[card].Pmt[channel].pmtID		 = @"----";
				SNOCrate[crate].Card[card].Pmt[channel].cableID		 = @"----";
				SNOCrate[crate].Card[card].Pmt[channel].paddleCardID = @"----";
			}
		}
	}
	
	for(id key in jsonCableDB){
		//NSLog(@"key=%@ value=%@\n", key, [jsonCableDB objectForKey:key]);
		if(![key isEqualToString:@"----"] && ![key isEqualToString:@"doc_type"] && ![key isEqualToString:@"time_stamp"]
	       && ![key isEqualToString:@"_id"] && ![key isEqualToString:@"_rev"]){
			[self decode:key crate:&crate card:&card channel:&channel];
			
			NSArray *position=[[jsonCableDB objectForKey:key] objectForKey:@"position"];
			NSArray *ids=[[jsonCableDB objectForKey:key] objectForKey:@"ids"];
			short tubetype=[[[jsonCableDB objectForKey:key] objectForKey:@"tube_type"] shortValue];
			
			if(TubeInRange(crate,card,channel)){
				SNOCrate[crate].Card[card].Pmt[channel].x = [[position objectAtIndex:0] floatValue];
				SNOCrate[crate].Card[card].Pmt[channel].y = [[position objectAtIndex:1] floatValue];
				SNOCrate[crate].Card[card].Pmt[channel].z = [[position objectAtIndex:2] floatValue];
				SNOCrate[crate].Card[card].Pmt[channel].pmtID		 = [[ids objectAtIndex:1] copy];
				SNOCrate[crate].Card[card].Pmt[channel].cableID		 = [[ids objectAtIndex:0] copy];
				SNOCrate[crate].Card[card].Pmt[channel].paddleCardID = [[ids objectAtIndex:2] copy];
				SNOCrate[crate].Card[card].Pmt[channel].tubeType     = tubetype;
			}
			//NSLog(@" key %@ crate %i, card %i, channel %i, x %f, y %f, z %f, tubetype %i, %@\n",key, crate,card,channel, 
			//	  [[position objectAtIndex:0] floatValue],[[position objectAtIndex:1] floatValue],
			//	  [[position objectAtIndex:2] floatValue], tubetype, [ids objectAtIndex:0]);
		}else {
			
		}
    }
	
	//NSLog(@"%i %i %i %i %i\n",kTubeTypeOwl, kTubeTypeLowGain, kTubeTypeButt, kTubeTypeNeck, kTubeTypeNormal);
	
}

-(void) readXL3StateDocumentFromMorca
{	
	//initialize to zero first
	int crate, card, pmt;
	for (crate=0;crate<kMaxSNOCrates;crate++){
		for(card=0;card<kNumSNOCards;card++){
			for(pmt=0;pmt<kNumSNOPmts;pmt++){
				SNOCrate[crate].Card[card].Pmt[pmt].cmosRate = 0.0;
			}
		}
	}
	
	NSHTTPURLResponse *response = nil;
	NSError *connectionError = [[NSError alloc] init];
	
	//get the id of the cableDB document
	NSString *urlName=[[NSString alloc] initWithFormat:@"http://localhost:5984/morca/_design/timestamps/_view/all"];	
	NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:urlName]];	
	NSData *responseData = [[NSData alloc] initWithData:[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&connectionError]];
    NSString *jsonStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
	NSDictionary *jsonAllView = [[NSDictionary alloc] initWithDictionary:[jsonStr yajl_JSON]];
	NSArray *allview = [[NSArray alloc] initWithArray:[jsonAllView objectForKey:@"rows"]];
	NSString *docid = [[allview objectAtIndex:0] objectForKey:@"id"];
	[jsonStr release];
	[responseData release];
	[urlName release];
	[request release];
	
	//get the XL3 document and store it in a dictionary
	urlName=[[NSString alloc] initWithFormat:@"http://localhost:5984/morca/%@",docid];	
	request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:urlName]];	
	responseData = [[NSData alloc] initWithData:[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&connectionError]];
    jsonStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
	NSDictionary *jsonMorcaDB = [[NSDictionary alloc] initWithDictionary:[jsonStr yajl_JSON]];

	crate = [[jsonMorcaDB objectForKey:@"xl3_num"] intValue];
	
	for(id key in jsonMorcaDB){
		if([key isEqualToString:@"cmos_rt"]){
			int cardindex;
			for(cardindex=0;cardindex<kNumSNOCards;++cardindex){
				int pmtindex;
				for(pmtindex=0;pmtindex<kNumSNOPmts;++pmtindex){
					SNOCrate[crate].Card[cardindex].Pmt[pmtindex].cmosRate = 
					    [[[[jsonMorcaDB objectForKey:key] objectAtIndex:cardindex] objectAtIndex:pmtindex] floatValue];
				}
			}
		}else if ([key isEqualToString:@"pmt_base_i"]){
			int cardindex;
			for(cardindex=0;cardindex<kNumSNOCards;++cardindex){
				int pmtindex;
				for(pmtindex=0;pmtindex<kNumSNOPmts;++pmtindex){
					SNOCrate[crate].Card[cardindex].Pmt[pmtindex].pmtBaseCurrent = 
				    	[[[[jsonMorcaDB objectForKey:key] objectAtIndex:cardindex] objectAtIndex:pmtindex] floatValue];
					//NSLog(@"%f %f\n",[self baseCurrent:crate card:cardindex channel:pmtindex],[[[[jsonMorcaDB objectForKey:key] objectAtIndex:cardindex] objectAtIndex:pmtindex] floatValue]);
				} 
			}
		}else if ([key isEqualToString:@"fec_fifo"]){
			int cardindex;
			for(cardindex=0;cardindex<kNumSNOCards;++cardindex){
				SNOCrate[crate].Card[cardindex].fecFifo = 
					[[[jsonMorcaDB objectForKey:key] objectAtIndex:cardindex] floatValue];
			}
		}else if ([key isEqualToString:@"xl3_pckrt"]){
			SNOCrate[crate].xl3PacketRate = [[jsonMorcaDB objectForKey:key] floatValue];
		}
    }
	
	[jsonStr release];
	[responseData release];
	[jsonMorcaDB release];
	[jsonAllView release];
	[allview release];
	[urlName release];
	[request release];
	//[response release];
	[connectionError release];
}


-(void) decode:(NSString*)s crate:(int*)crate card:(int*)card channel:(int*) channel
{
	const char* chan_info = [s cStringUsingEncoding:NSASCIIStringEncoding];
	int aCrate, aCard, aChannel;
	//decode the chanInfo into crate,card,channel numbers
	aCrate 	= chan_info[0] - 'A'; 
	aCard  	= chan_info[1] - 'A';
	aCard    = 15-aCard; 		//channel A-P --> card 15-0
	//special case for the owl tubes...wrap the cards one slot to the right
	if(aCrate == 3 || aCrate == 13 || aCrate == 17 || aCrate == 18){
		aCard--;
		if(aCard<0)aCard=15;
	}
	
	aChannel = atoi(&chan_info[2]);	
	aChannel	= 32-aChannel;  	//channel 1-32 --> channel 31-0
	*crate = aCrate;
	*card = aCard;
	*channel = aChannel;
}

- (BOOL) getCrate:(int)aCrate card:(int)aCard channel:(int)aChannel x:(float*)x y:(float*)y
{
	if(TubeInRange(aCrate,aCard,aChannel)){
		*x = SNOCrate[aCrate].Card[aCard].Pmt[aChannel].x;
		*y = SNOCrate[aCrate].Card[aCard].Pmt[aChannel].y;
		return YES;
	}
	else return NO;
	
}

- (int)  tubeTypeCrate:(int)aCrate card:(int)aCard channel:(int)aChannel
{
	if(TubeInRange(aCrate,aCard,aChannel)){
		return SNOCrate[aCrate].Card[aCard].Pmt[aChannel].tubeType;
	}
	else return kTubeTypeUnknown;
}

- (float) cmosRate:(int)aCrate card:(int)aCard channel:(int)aChannel
{
	if(TubeInRange(aCrate,aCard,aChannel)){
		return SNOCrate[aCrate].Card[aCard].Pmt[aChannel].cmosRate;
	}
	else return 0;
}

- (float) baseCurrent:(int)aCrate card:(int)aCard channel:(int)aChannel
{
	if(TubeInRange(aCrate,aCard,aChannel)){
		return SNOCrate[aCrate].Card[aCard].Pmt[aChannel].pmtBaseCurrent;
	}
	else return 0;
}

- (float) fifo:(int)aCrate card:(int)aCard
{
	return SNOCrate[aCrate].Card[aCard].fecFifo;
}

- (float) xl3Rate:(int)aCrate
{
	return SNOCrate[aCrate].xl3PacketRate;
}

- (float)  xpos:(int)aCrate card:(int)aCard channel:(int)aChannel
{
	if(TubeInRange(aCrate,aCard,aChannel)){
		return SNOCrate[aCrate].Card[aCard].Pmt[aChannel].x;
	}
	else return 0;
}

- (float)  ypos:(int)aCrate card:(int)aCard channel:(int)aChannel
{
	if(TubeInRange(aCrate,aCard,aChannel)){
		return SNOCrate[aCrate].Card[aCard].Pmt[aChannel].y;
	}
	else return 0;
}

- (float)  zpos:(int)aCrate card:(int)aCard channel:(int)aChannel
{
	if(TubeInRange(aCrate,aCard,aChannel)){
		return SNOCrate[aCrate].Card[aCard].Pmt[aChannel].z;
	}
	else return 0;
}

- (NSString*)  pmtID:(int)aCrate card:(int)aCard channel:(int)aChannel
{
	if(TubeInRange(aCrate,aCard,aChannel)){
		return SNOCrate[aCrate].Card[aCard].Pmt[aChannel].pmtID;
	}
	else return @"----";
}

- (NSColor*)  pmtColor:(int)aCrate card:(int)aCard channel:(int)aChannel
{
	if(TubeInRange(aCrate,aCard,aChannel)){
		int type = SNOCrate[aCrate].Card[aCard].Pmt[aChannel].tubeType;
		switch(type){
			case kTubeTypeUnknown:	return [NSColor blackColor];	break;
			case kTubeTypeNormal:	return [NSColor greenColor];	break;
			case kTubeTypeOwl:		return [NSColor blueColor];		break;
			case kTubeTypeLowGain:	return [NSColor yellowColor];	break;
			case kTubeTypeButt:		return [NSColor brownColor];	break;
			case kTubeTypeNeck:		return [NSColor cyanColor];		break;
			default:				return [NSColor blackColor];	break;
		}
	}
	else return [NSColor blackColor];
}

@end
