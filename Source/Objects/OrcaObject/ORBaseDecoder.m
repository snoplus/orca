//
//  ORBaseDecoder.m
//  Orca
//
//  Created by Mark Howe on 1/21/05.
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


#import "ORBaseDecoder.h"
#import "ORDataSet.h"
#import "ORGateElement.h"

static NSString* kChanKey[32] = {
	//pre-make some keys for speed.
	@"Channel  0", @"Channel  1", @"Channel  2", @"Channel  3",
	@"Channel  4", @"Channel  5", @"Channel  6", @"Channel  7",
	@"Channel  8", @"Channel  9", @"Channel 10", @"Channel 11",
	@"Channel 12", @"Channel 13", @"Channel 14", @"Channel 15",
	@"Channel 16", @"Channel 17", @"Channel 18", @"Channel 19",
	@"Channel 20", @"Channel 21", @"Channel 22", @"Channel 23",
	@"Channel 24", @"Channel 25", @"Channel 26", @"Channel 27",
	@"Channel 28", @"Channel 29", @"Channel 30", @"Channel 31"
};

static NSString* kCrateKey[16] = {
	//pre-make some keys for speed.
	@"Crate  0", @"Crate  1", @"Crate  2", @"Crate  3",
	@"Crate  4", @"Crate  5", @"Crate  6", @"Crate  7",
	@"Crate  8", @"Crate  9", @"Crate 10", @"Crate 11",
	@"Crate 12", @"Crate 13", @"Crate 14", @"Crate 15"
};

@implementation ORBaseDecoder

- (void) dealloc
{
    [gates release];
    [super dealloc];
}

- (NSString*) getChannelKey:(unsigned short)aChan
{
	if(aChan<32) return kChanKey[aChan];
	else return [NSString stringWithFormat:@"Channel %2d",aChan];	
}

- (NSString*) getCrateKey:(unsigned short)aCrate
{
	if(aCrate<16) return kCrateKey[aCrate];
	else return [NSString stringWithFormat:@"Crate %2d",aCrate];		
}

- (void) addGate: (ORGateElement *) aGate
{
    if(!gates)gates = [[NSMutableArray alloc] init];
    gatesInstalled = YES;
    [gates addObject:aGate];
}

- (BOOL) prepareData:(ORDataSet*)aDataSet 
                  crate:(unsigned short)aCrate 
                   card:(unsigned short)aCard 
                channel:(unsigned short)aChannel
                  value:(unsigned long)aValue
{

    int i;
    int count = [gates count];
    for(i=0;i<count;i++){
        if([[gates objectAtIndex:i] prepareData:aDataSet crate:aCrate card:aCard channel:aChannel value:aValue]){
            return YES;
        }
    }   
    return NO; 
}

- (void) swapData:(void*)someData
{
	unsigned long* ptr = (unsigned long*)someData;
	*ptr = CFSwapInt32(*ptr);
	unsigned long length = ExtractLength(*ptr);
	unsigned long i;
	for(i=1;i<length;i++){
		ptr[i] = CFSwapInt32(ptr[i]);
	}
}

@end
