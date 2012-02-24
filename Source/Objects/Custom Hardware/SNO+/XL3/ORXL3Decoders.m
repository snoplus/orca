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
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORSNOCrateModel.h"
#import "ORDataTypeAssigner.h"

@implementation ORXL3DecoderForXL3MegaBundle

#define swapLong(x) (((uint32_t)(x) << 24) | (((uint32_t)(x) & 0x0000FF00) <<  8) | (((uint32_t)(x) & 0x00FF0000) >>  8) | ((uint32_t)(x) >> 24))

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
	
	ptr += 2;
	unsigned short i = 0;
	NSMutableString* dsc = [NSMutableString string];
	
	for (i=0; i<length/3; i++) {
		if (swapBundle) {
			ptr[0] = swapLong(ptr[0]);
			ptr[1] = swapLong(ptr[1]);
			ptr[2] = swapLong(ptr[2]);
		}
		
		if (ptr[1] == 0x5F46414B && ptr[2] == 0x455F5F0A) {
			char fake_id[5];
			if (0x0000ABCD != htonl(0x0000ABCD)) ptr[0] = swapLong(ptr[0]);
			memcpy(fake_id, ptr, 4);
			fake_id[4] = '\0';
			[dsc appendFormat:@"XL3 fake id: %s\n", fake_id];
			if (0x0000ABCD != htonl(0x0000ABCD)) ptr[0] = swapLong(ptr[0]);
		}
		else {
			NSString* sGTId = [NSString stringWithFormat:@"GTId = 0x%06x\n",
				(*ptr & 0x0000ffff) | ((ptr[2] << 4) & 0x000f0000) | ((ptr[2] >> 8) & 0x00f00000)];
			NSString* sCrate = [NSString stringWithFormat:@"CCCC: %d, ", (*ptr >> 21) & 0x1fUL];
			NSString* sBoard = [NSString stringWithFormat:@"%d, ", (*ptr >> 26) & 0x0fUL];
			NSString* sChannel = [NSString stringWithFormat:@"%d, ", (*ptr >> 16) & 0x1fUL];
			NSString* sCell = [NSString stringWithFormat:@"%d\n", (ptr[1] >> 12) & 0x0fUL];
			NSString* sQHL = [NSString stringWithFormat:@"QHL = 0x%03x\n", ptr[2] & 0x0fffUL ^ 0x0800UL];
			NSString* sQHS = [NSString stringWithFormat:@"QHS = 0x%03x\n", (ptr[1] >> 16) & 0x0fffUL ^ 0x0800UL];
			NSString* sQLX = [NSString stringWithFormat:@"QLX = 0x%03x\n", ptr[1] & 0x0fffUL ^ 0x0800UL];
			NSString* sTAC = [NSString stringWithFormat:@"TAC = 0x%03x\n", (ptr[2] >> 16) & 0x0fffUL ^ 0x0800UL];
			NSString* sCGT16 = [NSString stringWithFormat:@"Sync errors CGT16: %@,\n",
				((*ptr >> 30) & 0x1UL) ? @"Yes" : @"No"];
			NSString* sCGT24 = [NSString stringWithFormat:@"CGT24: %@, ",
				((*ptr >> 31) & 0x1UL) ? @"Yes" : @"No"];
			NSString* sES16 = [NSString stringWithFormat:@"CMOS16: %@\n",
				((ptr[1] >> 31) & 0x1UL) ? @"Yes" : @"No"];
			NSString* sMissed = [NSString stringWithFormat:@"Missed count error: %@\n",
				((ptr[1] >> 28) & 0x1UL) ? @"Yes" : @"No"];
			NSString* sNC = [NSString stringWithFormat:@"NC/CC: %@, ",
				((ptr[1] >> 29) & 0x1UL) ? @"CC" : @"NC"];
			NSString* sLGI = [NSString stringWithFormat:@"LGI: %@\n",
				((ptr[1] >> 30) & 0x1UL) ? @"Long" : @"Short"];
			NSString* sWrd0 = [NSString stringWithFormat:@"Wrd0 = 0x%08x\n", *ptr];
			NSString* sWrd1 = [NSString stringWithFormat:@"Wrd1 = 0x%08x\n", ptr[1]];
			NSString* sWrd2 = [NSString stringWithFormat:@"Wrd2 = 0x%08x\n\n", ptr[2]];

			[dsc appendFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@", 
				sGTId, sCrate, sBoard, sChannel, sCell, sQHL, sQHS, sQLX, sTAC, sCGT16,
				sCGT24, sES16, sMissed, sNC, sLGI, sWrd0, sWrd1, sWrd2];
		}

		//swap back the PMT bundle 
		if (swapBundle) {
			ptr[0] = swapLong(ptr[0]);
			ptr[1] = swapLong(ptr[1]);
			ptr[2] = swapLong(ptr[2]);
		}
		
		ptr += 3;
	}
	return dsc;
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
                [dsc appendFormat:@"ch %2d: %f\n", ch, dataPtr[21 + slot_idx*32 + ch]];
            }
            slot_idx++;
        }
    }
    return dsc;
}

@end
