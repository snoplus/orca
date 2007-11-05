//
//  ORCMC203Decoders.h
//  Orca
//
//  Created by Mark Howe on 9/21/04.
//  Copyright 2004 CENPA, University of Washington. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ORCamacCardDecoder.h"

@class ORDataPacket;
@class ORDataSet;

@interface ORCMC203DecoderForAdc : ORCamacCardDecoder {
    @private 
}
- (unsigned long) decodeData:(void*)someData fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)dataPtr;
@end
