//
//  ORRunningAverage.h
//  Orca
//
//  Created by Wenqin on 3/23/16.
//
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

@interface ORRunningAverage : NSObject
{
    float runningAverage;
    int windowLength;
    NSMutableArray*	inComingData;
    int tag;
    int groupTag;
}
//- (id)   initwithwindowLength:(int) wl;
- (id) initWithTag:(short)aTag andLength:(short)wl;
- (void) dealloc;
- (void) setWindowLength:(int) wl;
- (float) updateAverage:(float)datapoint;
- (float) updateAveragewNSN:(NSNumber*)datapoint;
- (void) updateAveragewObj:(id)obj;
- (void) resetCounter:(float) rate;
///- (NSNumber *)oldestDataRemoval;
- (float)oldestDataRemoval;
- (float)getAverage;
- (void) dump;
- (int)tag;
- (void) setTag:(int)newTag;
- (int) groupTag;
- (void) setGroupTag:(int)newGroupTag;
@end



@interface NSObject (ORRunningAverage_Catagory)
- (unsigned long) getRate:(int)tag forGroup:(int)aGroupTag;
@end



