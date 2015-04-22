//
//  ORGretina4ADecoders.m
//  Orca
//
//  Created by Mark A. Howe on Wednesday 11/20/14.
//  Copyright (c) 2014 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//Washington sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//Washington reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------


#import "ORGretina4ADecoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORDataTypeAssigner.h"
#import "ORGretina4AModel.h"

#define kIntegrateTimeKey @"Integration Time"
#define kHistEMultiplierKey @"Hist E Multiplier"

@implementation ORGretina4AWaveformDecoder
- (id) init
{
    self = [super init];
    getRatesFromDecodeStage = YES;
    return self;
}

- (void) dealloc
{
	[actualGretinaCards release];
    [super dealloc];
}

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    #define koffset -8192
	if(![self cacheSetUp]){
		[self cacheCardLevelObject:kIntegrateTimeKey fromHeader:[aDecoder fileHeader]];
		[self cacheCardLevelObject:kHistEMultiplierKey fromHeader:[aDecoder fileHeader]];
	}
	
    unsigned long* ptr = (unsigned long*)someData;
	unsigned long length = ExtractLength(ptr[0]);
    //point to ORCA location info
    ptr++;
    int crate           = (*ptr&0x01e00000)>>21;
    int card            = (*ptr&0x001f0000)>>16;
    NSString* crateKey	= [self getCrateKey: crate];
    NSString* cardKey	= [self getCardKey: card];
    
    unsigned long amountProcessed = 0;
    do {
        ptr++; //should be the separator
        if(*ptr == 0xAAAAAAAA){
            ptr++; //Geo Addr ...
            int channel      = *ptr & 0xF;
            int packetLength = (*ptr >> 16) & 0x7ff;
            NSString* channelKey = [self getChannelKey: channel];
           
            ptr++; //timestamp of descrimiator
            ptr++; //header Length ...
            int headerLength = (*ptr >> 26) & 0x3f;
            int dataLength = packetLength - headerLength/2;

            ptr++; //Timestamp of previous descriminator ...
            ptr++; //CFD sample 0
            ptr++; //Sample baseline bits 23:0
            ptr++; //CFD sample 2
            ptr++; //post-rise sum (7:0) ...
            ptr++; //Timestamp of peak detect bits 15:0 ..
            ptr++; //Timestamp of peak detect bits 47:16..
            ptr++; //Post-rise end samle ...
            ptr++; //Pre-rise end sample ...
            ptr++; //Base sample ...
        
            long peakSample = (long)(*ptr & 0x3fff);
            peakSample += koffset;
            if(peakSample>=0){
                [aDataSet histogram:peakSample numBins:0x3fff sender:self  withKeys:@"Gretina4A", @"Energy",crateKey,cardKey,channelKey,nil];
            }
            
            if(headerLength!=0){
                ptr++; //point to data
                
                if(dataLength>0){
                    NSData* waveformData = [NSData dataWithBytes:ptr length:dataLength*sizeof(long)];
                    
                    [aDataSet loadWaveform: waveformData            //pass in the whole data set
                                    offset: 0                       // Offset in bytes (past header words)
                                  unitSize: sizeof(short)			// unit size in bytes
                                startIndex:	0                       // first Point Index (past the header offset!!!)
                               scaleOffset: koffset                 // offset the value by this
                                      mask:	0x3FFF					// when displayed all values will be masked with this value
                               specialBits: 0x4000
                                  bitNames: [NSArray arrayWithObjects:@"Trig",nil]
                                    sender: self 
                                  withKeys: @"Gretina4A", @"Waveforms",crateKey,cardKey,channelKey,nil];
                }
            }
            //get the actual object
            NSString* aKey = [crateKey stringByAppendingString:cardKey];
            if(!actualGretinaCards)actualGretinaCards = [[NSMutableDictionary alloc] init];
            ORGretina4AModel* obj = [actualGretinaCards objectForKey:aKey];
            if(!obj){
                NSArray* listOfCards = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORGretina4AModel")];
                NSEnumerator* e = [listOfCards objectEnumerator];
                ORGretina4AModel* aCard;
                while(aCard = [e nextObject]){
                    if([aCard slot] == card){
                        [actualGretinaCards setObject:aCard forKey:aKey];
                        obj = aCard;
                        break;
                    }
                }
            }
            [obj bumpRateFromDecodeStage:channel];
            ptr += dataLength;

            amountProcessed += packetLength;
        }
        else break;
        
    }while (amountProcessed < length);
	 
    return length; //must return number of longs
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    unsigned long* headerStartPtr = ptr+2;

    NSString* title= @"Gretina4A Waveform Record\n\n";
    
    NSString* crate = [NSString stringWithFormat:@"Crate = %lu\n",(ptr[1]&0x01e00000)>>21];
    NSString* card  = [NSString stringWithFormat:@"Card  = %lu\n",(ptr[1]&0x001f0000)>>16];

    NSString* crateKey			= [self getCrateKey: (ptr[1]&0x01e00000)>>21];
	NSString* cardKey			= [self getCardKey: (ptr[1]&0x001f0000)>>16];

    //recast pointer to short and point to the actual data header
    unsigned short* headerPtr = (unsigned short*)(ptr+2);
    NSString* chan  = [NSString stringWithFormat:@"Chan  = %d\n",headerPtr[2]&0xf];
    
	unsigned long energy = headerPtr[7] + (headerPtr[8] << 16);
	
	// energy is in 2's complement, taking abs value if necessary
	if (energy & 0x1000000) energy = (~energy & 0x1ffffff) + 1;
    
    NSString* rawEnergyStr = [NSString stringWithFormat:@"Raw Energy  = 0x%08lx\n",energy];

    int histEMultiplier = [[self objectForNestedKey:crateKey,cardKey,kHistEMultiplierKey,nil] intValue];
    if(histEMultiplier) energy *= histEMultiplier;
    
    int integrateTime = [[self objectForNestedKey:crateKey,cardKey,kIntegrateTimeKey,nil] intValue];
    if(integrateTime) energy /= integrateTime;
    
	NSString* energyStr  = [NSString stringWithFormat:@"Energy  = %lu\n",energy];
    
    unsigned long long timeStamp = ((unsigned long long)headerPtr[6] << 32) + ((unsigned long long)headerPtr[5] << 16) + (unsigned long long)headerPtr[4];
    NSString* timeStampString = [NSString stringWithFormat:@"Time: %lld\n",timeStamp];
    
    NSString* header = @"Header (Raw)\n";
    int i;
    for(i=0;i<15;i++){
        header = [header stringByAppendingFormat:@"%d: 0x%08lx\n",i,headerStartPtr[i]];
    }
    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@",title,crate,card,chan,timeStampString,rawEnergyStr,energyStr,header];
}

@end
