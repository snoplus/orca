//
//  ORXL3Decoders.m
//  Orca
//
//Created by Jarek Kaspar on Sun, September 12, 2010
//Copyright (c) 2010 CENPA, University of Washington. All rights reserved.
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

#import "ORXL3Decoders.h"
#import "XL3_Cmds.h"

@implementation ORXL3DecoderForXL3MegaBundle

#define swapLong(x) (((uint32_t)(x) << 24) | (((uint32_t)(x) & 0x0000FF00) <<  8) | (((uint32_t)(x) & 0x00FF0000) >>  8) | ((uint32_t)(x) >> 24))

- (NSString*) decodePMTBundle:(unsigned long*)ptr
{
	BOOL swapBundle = YES;
	if (0x0000ABCD != htonl(0x0000ABCD) && indexerSwaps) swapBundle = NO;
	if (0x0000ABCD == htonl(0x0000ABCD) && !indexerSwaps) swapBundle = NO;

    NSMutableString* dsc = [NSMutableString string];
    
    if (ptr[1] == 0x5F46414B && ptr[2] == 0x455F5F0A) {
        char fake_id[5];
        if (0x0000ABCD != htonl(0x0000ABCD)) ptr[0] = swapLong(ptr[0]);
        memcpy(fake_id, ptr, 4);
        fake_id[4] = '\0';
        [dsc appendFormat:@"XL3 fake id: %s\n", fake_id];
        if (0x0000ABCD != htonl(0x0000ABCD)) ptr[0] = swapLong(ptr[0]);
    }
    else {
        if (swapBundle) {
            ptr[0] = swapLong(ptr[0]);
            ptr[1] = swapLong(ptr[1]);
            ptr[2] = swapLong(ptr[2]);
        }
        
        [dsc appendFormat:@"GTId = 0x%06x\n", (*ptr & 0x0000ffff) | ((ptr[2] << 4) & 0x000f0000) | ((ptr[2] >> 8) & 0x00f00000)];
        [dsc appendFormat:@"CCCC: %d, %d, ", (*ptr >> 21) & 0x1fUL, (*ptr >> 26) & 0x0fUL];
        [dsc appendFormat:@"%d, %d\n", (*ptr >> 16) & 0x1fUL, (ptr[1] >> 12) & 0x0fUL];
        [dsc appendFormat:@"QHL = 0x%03x\n", ptr[2] & 0x0fffUL ^ 0x0800UL];
        [dsc appendFormat:@"QHS = 0x%03x\n", (ptr[1] >> 16) & 0x0fffUL ^ 0x0800UL];
        [dsc appendFormat:@"QLX = 0x%03x\n", ptr[1] & 0x0fffUL ^ 0x0800UL];
        [dsc appendFormat:@"TAC = 0x%03x\n", (ptr[2] >> 16) & 0x0fffUL ^ 0x0800UL];
        [dsc appendFormat:@"Sync errors CGT16: %@,\n", ((*ptr >> 30) & 0x1UL) ? @"Yes" : @"No"];
        [dsc appendFormat:@"CGT24: %@, ", ((*ptr >> 31) & 0x1UL) ? @"Yes" : @"No"];
        [dsc appendFormat:@"CMOS16: %@\n", ((ptr[1] >> 31) & 0x1UL) ? @"Yes" : @"No"];
        [dsc appendFormat:@"Missed count error: %@\n", ((ptr[1] >> 28) & 0x1UL) ? @"Yes" : @"No"];
        [dsc appendFormat:@"NC/CC: %@, ", ((ptr[1] >> 29) & 0x1UL) ? @"CC" : @"NC"];
        [dsc appendFormat:@"LGI: %@\n", ((ptr[1] >> 30) & 0x1UL) ? @"Long" : @"Short"];
        [dsc appendFormat:@"Wrd0 = 0x%08x\n", *ptr];
        [dsc appendFormat:@"Wrd1 = 0x%08x\n", ptr[1]];
        [dsc appendFormat:@"Wrd2 = 0x%08x\n\n", ptr[2]];

        //swap back the PMT bundle 
        if (swapBundle) {
            ptr[0] = swapLong(ptr[0]);
            ptr[1] = swapLong(ptr[1]);
            ptr[2] = swapLong(ptr[2]);
        }
    }
    
    return [[dsc retain] autorelease];
}


- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	unsigned long* ptr = (unsigned long*)someData;
	unsigned long length = ExtractLength(*ptr);
	indexerSwaps = [aDecoder needToSwap]; //won't work for multicatalogs with mixed endianness
	return length; //must return number of bytes processed.
}



- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
	/*
	the megaBundle is always big-endian, but ORRecordIndexer could have swapped it
	LE file & LE cpu indexer swaps? NO  datarecord BE swapneeded? YES
	LE file & BE cpu indexer swaps? YES datarecord LE swapneeded? YES  
	BE file & LE cpu indexer swaps? YES datarecord LE swapneeded? NO
	BE file & BE cpu indexer swaps? NO  datarecord BE swapneeded? NO
	*/

	BOOL swapBundle = YES;
	if (0x0000ABCD != htonl(0x0000ABCD) && indexerSwaps) swapBundle = NO;
	if (0x0000ABCD == htonl(0x0000ABCD) && !indexerSwaps) swapBundle = NO;

	unsigned long length = ExtractLength(*ptr);
	unsigned short i = 0;
    unsigned short version = 0;
	NSMutableString* dsc = [NSMutableString string];

    ptr += 1;
    version = ptr[0] >> 5 & 0x7;
    [dsc appendFormat:@"packet_num: %d\ncrate_num: %d\nversion: %d\n", ptr[0] >> 16, ptr[0] & 0x1f, version];
    ptr += 1;

    switch (version) {
        case 0:
            for (i=0; i<length/3; i++) {
                [dsc appendString:[self decodePMTBundle:ptr]];
                ptr += 3;
            }
            break;
            
        case 1:
            if (swapBundle) {
                ptr[0] = swapLong(ptr[0]); ptr[1] = swapLong(ptr[1]); ptr[2] = swapLong(ptr[2]);
            }
            unsigned int num_longs = ptr[0] & 0xffffff;
            [dsc appendFormat:@"\ncrate_num: %u\nnum_longs: %u\npass_min: %u\nxl3_clock: %u\n",
             ptr[0] >> 24, num_longs, ptr[1], ptr[2]];
            [dsc appendFormat:@"pass_min: 0x%08x\nxl3_clock: 0x%08x\n\n", ptr[1], ptr[2]];
            if (swapBundle) {
                ptr[0] = swapLong(ptr[0]); ptr[1] = swapLong(ptr[1]); ptr[2] = swapLong(ptr[2]);
            }
            
            if (num_longs * 4 > XL3_MAXPAYLOADSIZE_BYTES) {
                [dsc appendFormat:@"num longs > XL3_MAXPAYLOADSIZE_BYTES,\ntrimming to continue\n"];
                num_longs = XL3_MAXPAYLOADSIZE_BYTES / 4;
            }
            if (num_longs > length - 1) {
                [dsc appendFormat:@"num longs > orca packet length,\ntrimming to continue\n"];
                num_longs = length - 1;
            }
            
            ptr += 3; num_longs -= 2;
            
            unsigned int mini_header = 0;
            while (num_longs != 0) {
                mini_header = ptr[0];
                if (swapBundle) {
                    mini_header = swapLong(mini_header);
                }
                
                unsigned int mini_num_longs = mini_header & 0xffffff;
                unsigned char mini_card = mini_header >> 24 & 0xf;
                unsigned char mini_type = mini_header >> 31;
                
                [dsc appendFormat:@"\n---\nmini bundle\ncard: %d\ntype: %@\nnum_longs: %u\nhex: 0x%08x\n\n",
                 mini_card, mini_type?@"pass cur":@"pmt bundles", mini_num_longs, mini_header];
                ptr +=1;
                
                switch (mini_type) {
                    case 0:
                        //pmt bundles
                        if (mini_num_longs % 3 || num_longs < mini_num_longs) {
                            [dsc appendFormat:@"mini bundle header\ncorrupted, quit.\n"];
                            num_longs = 0;
                            break;
                        }

                        for (i = 0; i < mini_num_longs / 3; i++) {
                            [dsc appendString:[self decodePMTBundle:ptr]];
                            ptr += 3;
                        }

                        num_longs -= mini_num_longs + 1;
                        if (mini_num_longs != 0) {
                            ptr -= 2;   
                        }
                        break;
                        
                    case 1:
                        //pass cur
                        if (mini_num_longs != 1 || num_longs < 2) {
                            [dsc appendFormat:@"mini bundle header\ncorrupted, quit.\n"];
                            num_longs = 0;
                            break;
                        }
                        unsigned int pass_cur = ptr[0];
                        if (swapBundle) {
                            pass_cur = swapLong(pass_cur);
                        }
                        [dsc appendFormat:@"pass_cur: %u,\nhex: 0x%08x\n", pass_cur, pass_cur];
                        num_longs -= 2;
                        ptr += 1;
                        break;
                        
                    default:
                        break;
                }
            }
            break;

        default:
            [dsc appendFormat:@"\nnot implemented.\n"];
            break;
    }
	return [[dsc retain] autorelease];
}

@end

@implementation ORXL3DecoderForCmosRate

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	unsigned long* ptr = (unsigned long*)someData;
	unsigned long length = ExtractLength(*ptr);
	return length; //must return number of bytes processed.    
}

- (NSString*) dataRecordDescription:(unsigned long*)dataPtr
{
    NSMutableString* dsc = [NSMutableString stringWithFormat: @"CMOS rates crate %d\n\nslot mask: 0x%x\n", dataPtr[1], dataPtr[2]];
    unsigned char slot = 0;
    for (slot=0; slot<16; slot++) {
        [dsc appendFormat:@"ch mask slot %2d: 0x%08x\n", slot, dataPtr[3+slot]];
    }
    [dsc appendFormat:@"delay: %d ms\n\nerror flags: 0x%08x\n", dataPtr[19], dataPtr[20]];

    unsigned char ch, slot_idx = 0;
    for (slot=0; slot<16; slot++) {
        if ((dataPtr[2] >> slot) & 0x1) {
            [dsc appendFormat:@"\nslot %d\n", slot];
            for (ch = 0; ch < 32; ch++) {
                [dsc appendFormat:@"ch %2d: %f\n", ch, *(float*)&dataPtr[21 + slot_idx*32 + ch]];
            }
            slot_idx++;
        }
    }
    return [[dsc retain] autorelease];
}

@end

@implementation ORXL3DecoderForFifo

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	unsigned long* ptr = (unsigned long*)someData;
	unsigned long length = ExtractLength(*ptr);
    indexerSwaps = [aDecoder needToSwap];
	return length; //must return number of bytes processed.    
}

- (NSString*) dataRecordDescription:(unsigned long*)dataPtr
{
    NSMutableString* dsc = [NSMutableString stringWithFormat: @"FIFO state crate %d\n\n", dataPtr[1]];
    unsigned char slot = 0;

    BOOL swapBundle = YES;
	if (0x0000ABCD != htonl(0x0000ABCD) && indexerSwaps) swapBundle = NO;
	if (0x0000ABCD == htonl(0x0000ABCD) && !indexerSwaps) swapBundle = NO;
    
    dataPtr += 2;

    unsigned long fifo;
    for (slot=0; slot<16; slot++) {
        fifo = dataPtr[slot];
		if (swapBundle) fifo = swapLong(fifo);        
        [dsc appendFormat:@"slot %2d: 0x%08x\n", slot, fifo];
    }

    return [[dsc retain] autorelease];
}

@end
